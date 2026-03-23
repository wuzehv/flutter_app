import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/models/codeup.dart';

class CodeUpMrDiff extends StatefulWidget {
  final CodeUpModel codeup;
  final int projectId;
  final int mrId;
  final String mrTitle;
  final String? sourcePatchSetBizId;
  final String? targetPatchSetBizId;

  const CodeUpMrDiff({
    super.key,
    required this.codeup,
    required this.projectId,
    required this.mrId,
    required this.mrTitle,
    this.sourcePatchSetBizId,
    this.targetPatchSetBizId,
  });

  @override
  State<CodeUpMrDiff> createState() => _CodeUpMrDiffState();
}

class _CodeUpMrDiffState extends State<CodeUpMrDiff> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _mrDetail;
  Map<String, dynamic>? _changeTree;
  List<Map<String, dynamic>> _changedFiles = [];
  
  // 保存 patches 信息用于获取 commitId
  List<Map<String, dynamic>> _patchSets = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 优先使用从列表传递的 patchSetId
      // fromPatchSetId = 目标分支版本 (target), toPatchSetId = 源分支版本 (source)
      String? fromPatchSetId = widget.targetPatchSetBizId;
      String? toPatchSetId = widget.sourcePatchSetBizId;
      
      debugPrint('From widget - fromPatchSetId: $fromPatchSetId, toPatchSetId: $toPatchSetId');
      
      // 如果没有传递 patchSetId，调用 patches 接口获取
      if (fromPatchSetId == null || toPatchSetId == null) {
        final patchSets = await widget.codeup.getMrPatchSets(widget.projectId, widget.mrId);
        if (patchSets == null || patchSets.isEmpty) {
          setState(() {
            _errorMessage = '获取版本列表失败';
            _isLoading = false;
          });
          return;
        }

        // 保存 patchSets 用于后续获取 commitId
        _patchSets = patchSets;
        debugPrint('PatchSets response: $patchSets');

        // 根据 relatedMergeItemType 区分源分支和目标分支
        // MERGE_SOURCE = 源分支 (toPatchSetId), MERGE_TARGET = 目标分支 (fromPatchSetId)
        for (final patch in patchSets) {
          final patchSetBizId = patch['patchSetBizId']?.toString();
          final relatedType = patch['relatedMergeItemType']?.toString();
          
          if (patchSetBizId == null || relatedType == null) continue;
          
          if (relatedType == 'MERGE_TARGET') {
            fromPatchSetId ??= patchSetBizId; // 目标分支
          } else if (relatedType == 'MERGE_SOURCE') {
            toPatchSetId ??= patchSetBizId; // 源分支
          }
        }
        
        debugPrint('From patches API - from (target): $fromPatchSetId, to (source): $toPatchSetId');
      }

      if (fromPatchSetId == null || toPatchSetId == null) {
        debugPrint('Error: fromPatchSetId=$fromPatchSetId, toPatchSetId=$toPatchSetId');
        setState(() {
          _errorMessage = '无法获取版本信息 (目标分支: ${fromPatchSetId ?? "缺失"}, 源分支: ${toPatchSetId ?? "缺失"})';
          _isLoading = false;
        });
        return;
      }
      
      debugPrint('Using - fromPatchSetId (target): $fromPatchSetId, toPatchSetId (source): $toPatchSetId');

      // 2. 获取变更文件树
      final changeTree = await widget.codeup.getMrChangeTree(
        widget.projectId,
        widget.mrId,
        fromPatchSetId,
        toPatchSetId,
      );

      if (changeTree == null) {
        setState(() {
          _errorMessage = '获取变更文件列表失败';
          _isLoading = false;
        });
        return;
      }

      _changeTree = changeTree;

      // 解析变更文件列表
      final changedTreeItems = changeTree['changedTreeItems'] as List<dynamic>?;
      if (changedTreeItems != null) {
        _changedFiles = changedTreeItems.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 获取文件状态标签
  Widget _buildFileStatusTag(Map<String, dynamic> file) {
    final isNew = file['newFile'] == true;
    final isDeleted = file['deletedFile'] == true;
    final isRenamed = file['renamedFile'] == true;
    final isBinary = file['isBinary'] == true;

    String label;
    Color color;

    if (isNew) {
      label = '新增';
      color = Colors.green;
    } else if (isDeleted) {
      label = '删除';
      color = Colors.red;
    } else if (isRenamed) {
      label = '重命名';
      color = Colors.orange;
    } else if (isBinary) {
      label = '二进制';
      color = Colors.grey;
    } else {
      label = '修改';
      color = Colors.blue;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha((0.3 * 255).toInt())),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// 获取统计信息
  Widget _buildStats() {
    if (_changeTree == null) return SizedBox.shrink();

    final count = _changeTree!['count'] ?? 0;
    final totalAddLines = _changeTree!['totalAddLines'] ?? 0;
    final totalDelLines = _changeTree!['totalDelLines'] ?? 0;

    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('文件数', '$count', Colors.blue),
          _buildStatItem('新增行', '+$totalAddLines', Colors.green),
          _buildStatItem('删除行', '-$totalDelLines', Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('文件变更', style: TextStyle(fontSize: 16)),
            Text(
              widget.mrTitle,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_changedFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无文件变更'),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildStats(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              itemCount: _changedFiles.length,
              itemBuilder: (context, index) {
                final file = _changedFiles[index];
                return _buildFileItem(file);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file) {
    final newPath = file['newPath'] ?? '';
    final oldPath = file['oldPath'] ?? '';
    final addLines = file['addLines'] ?? 0;
    final delLines = file['delLines'] ?? 0;
    final isBinary = file['isBinary'] == true;

    // 获取文件名和路径
    final fileName = newPath.isNotEmpty ? newPath.split('/').last : oldPath.split('/').last;
    final dirPath = newPath.isNotEmpty
        ? newPath.substring(0, newPath.length - fileName.length).replaceAll(RegExp(r'/$'), '')
        : oldPath.substring(0, oldPath.length - fileName.length).replaceAll(RegExp(r'/$'), '');

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        dense: true,
        leading: _buildFileStatusTag(file),
        title: Row(
          children: [
            Expanded(
              child: Text(
                fileName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dirPath.isNotEmpty)
              Text(
                dirPath,
                style: TextStyle(fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            SizedBox(height: 4),
            if (!isBinary)
              Row(
                children: [
                  if (addLines > 0)
                    Text(
                      '+$addLines',
                      style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  if (addLines > 0 && delLines > 0) SizedBox(width: 8),
                  if (delLines > 0)
                    Text(
                      '-$delLines',
                      style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          // 跳转到文件 diff 页面
          _openFileDiff(file);
        },
      ),
    );
  }

  /// 打开文件 diff 页面
  void _openFileDiff(Map<String, dynamic> file) {
    final newPath = file['newPath'] ?? '';
    final oldPath = file['oldPath'] ?? '';
    final isNew = file['newFile'] == true;
    final isDeleted = file['deletedFile'] == true;
    final isBinary = file['isBinary'] == true;
    
    // 从 patchSets 中获取 commitId
    // MERGE_TARGET (目标分支) = 旧版本, MERGE_SOURCE (源分支) = 新版本
    String? fromCommitId; // 目标分支 commit
    String? toCommitId;   // 源分支 commit
    
    for (final patch in _patchSets) {
      final commitId = patch['commitId']?.toString();
      final relatedType = patch['relatedMergeItemType']?.toString();
      
      if (commitId == null || relatedType == null) continue;
      
      if (relatedType == 'MERGE_TARGET') {
        fromCommitId = commitId;
      } else if (relatedType == 'MERGE_SOURCE') {
        toCommitId = commitId;
      }
    }
    
    debugPrint('Opening file diff - fromCommitId: $fromCommitId, toCommitId: $toCommitId');

    context.push(
      '/codeup/project/mr_file_diff',
      extra: {
        'codeup': widget.codeup,
        'projectId': widget.projectId,
        'mrId': widget.mrId,
        'mrTitle': widget.mrTitle,
        'filePath': newPath.isNotEmpty ? newPath : oldPath,
        'fromCommitId': fromCommitId,
        'toCommitId': toCommitId,
        'isNew': isNew,
        'isDeleted': isDeleted,
        'isBinary': isBinary,
      },
    );
  }

  void _showFileDetail(Map<String, dynamic> file) {
    final newPath = file['newPath'] ?? '';
    final oldPath = file['oldPath'] ?? '';
    final isNew = file['newFile'] == true;
    final isDeleted = file['deletedFile'] == true;
    final isRenamed = file['renamedFile'] == true;
    final isBinary = file['isBinary'] == true;
    final addLines = file['addLines'] ?? 0;
    final delLines = file['delLines'] ?? 0;
    final newObjectId = file['newObjectId'] ?? '';
    final oldObjectId = file['oldObjectId'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text('文件详情', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              _buildDetailItem('当前路径', newPath),
              if (isRenamed || oldPath != newPath) _buildDetailItem('原路径', oldPath),
              _buildDetailItem('状态', _getStatusText(file)),
              if (!isBinary) ...[
                _buildDetailItem('新增行数', '+$addLines'),
                _buildDetailItem('删除行数', '-$delLines'),
              ],
              if (isBinary) _buildDetailItem('文件类型', '二进制文件'),
              if (newObjectId.isNotEmpty) _buildDetailItem('新对象 ID', newObjectId.substring(0, newObjectId.length > 8 ? 8 : newObjectId.length)),
              if (oldObjectId.isNotEmpty) _buildDetailItem('旧对象 ID', oldObjectId.substring(0, oldObjectId.length > 8 ? 8 : oldObjectId.length)),
              SizedBox(height: 16),
              if (!isBinary)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      context.pop();
                      _openFileDiff(file);
                    },
                    icon: Icon(Icons.code),
                    label: Text('查看 Diff'),
                  ),
                ),
              if (!isBinary) SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.pop();
                    _openInCodeUp();
                  },
                  icon: Icon(Icons.open_in_browser),
                  label: Text('在 CodeUp 中查看'),
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text('关闭'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: SelectableText(value, style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _getStatusText(Map<String, dynamic> file) {
    if (file['newFile'] == true) return '新增文件';
    if (file['deletedFile'] == true) return '删除文件';
    if (file['renamedFile'] == true) return '重命名文件';
    if (file['isBinary'] == true) return '二进制文件';
    return '修改文件';
  }

  void _openInCodeUp() {
    // 构建 CodeUp MR 详情页 URL
    final mrUrl = _mrDetail?['webUrl'] ?? _mrDetail?['detailUrl'];
    if (mrUrl != null) {
      // 使用 url_launcher 或其他方式打开网页
      // 这里简单显示提示，实际项目中可以使用 url_launcher
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('提示'),
          content: Text('请在浏览器中打开以下链接查看详情：\n\n$mrUrl'),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text('确定'),
            ),
          ],
        ),
      );
    }
  }
}
