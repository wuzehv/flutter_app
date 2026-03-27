import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/models/codeup.dart';

/// 文件 Diff 查看页面
class CodeUpMrFileDiff extends StatefulWidget {
  final CodeUpModel codeup;
  final int projectId;
  final int mrId;
  final String mrTitle;
  final String filePath;
  final String? fromCommitId;  // 目标分支 commit (旧版本)
  final String? toCommitId;    // 源分支 commit (新版本)
  final bool isNew;
  final bool isDeleted;
  final bool isBinary;

  const CodeUpMrFileDiff({
    super.key,
    required this.codeup,
    required this.projectId,
    required this.mrId,
    required this.mrTitle,
    required this.filePath,
    this.fromCommitId,
    this.toCommitId,
    this.isNew = false,
    this.isDeleted = false,
    this.isBinary = false,
  });

  @override
  State<CodeUpMrFileDiff> createState() => _CodeUpMrFileDiffState();
}

class _CodeUpMrFileDiffState extends State<CodeUpMrFileDiff> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _diffContent;
  List<DiffLine> _diffLines = [];

  @override
  void initState() {
    super.initState();
    _loadDiff();
  }

  Future<void> _loadDiff() async {
    if (widget.isBinary) {
      setState(() {
        _isLoading = false;
        _errorMessage = '二进制文件无法显示 diff';
      });
      return;
    }

    // 获取 commit IDs
    final fromId = widget.fromCommitId;
    final toId = widget.toCommitId;

    if (fromId == null || toId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '无法获取 commit 信息 (from: $fromId, to: $toId)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 调用 compareCommits API 获取 diff
      // from = 目标分支 commit (旧), to = 源分支 commit (新)
      final from = fromId;
      final to = toId;

      final result = await widget.codeup.compareCommits(
        widget.projectId,
        from,
        to,
      );

      if (result == null) {
        setState(() {
          _errorMessage = '获取 diff 失败';
          _isLoading = false;
        });
        return;
      }

      // 从返回的 diffs 中找到当前文件
      final diffs = result['diffs'] as List<dynamic>?;
      debugPrint('Compare result - diffs count: ${diffs?.length ?? 0}');
      debugPrint('Looking for file: ${widget.filePath}');
      
      if (diffs == null || diffs.isEmpty) {
        setState(() {
          _errorMessage = '没有找到文件差异 (commits: $from..$to)';
          _isLoading = false;
        });
        return;
      }

      // 查找匹配的文件
      Map<String, dynamic>? fileDiff;
      for (var diff in diffs) {
        final newPath = diff['newPath'] as String?;
        final oldPath = diff['oldPath'] as String?;
        debugPrint('Checking diff - newPath: $newPath, oldPath: $oldPath');
        if (newPath == widget.filePath || oldPath == widget.filePath) {
          fileDiff = diff as Map<String, dynamic>;
          break;
        }
      }

      if (fileDiff == null) {
        // 列出所有可用的文件路径
        final availablePaths = diffs.map((d) => '${d['oldPath']} -> ${d['newPath']}').join(', ');
        setState(() {
          _errorMessage = '未找到该文件的 diff 信息\n查找: ${widget.filePath}\n可用: $availablePaths';
          _isLoading = false;
        });
        return;
      }

      _diffContent = fileDiff['diff'] as String?;
      if (_diffContent != null && _diffContent!.isNotEmpty) {
        _diffLines = _parseDiff(_diffContent!);
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

  /// 解析 diff 内容为行列表
  List<DiffLine> _parseDiff(String diff) {
    final lines = <DiffLine>[];
    final rawLines = diff.split('\n');
    int oldLineNum = 0;
    int newLineNum = 0;
    bool inHunk = false;

    for (var line in rawLines) {
      // 解析 hunk header: @@ -start,count +start,count @@
      if (line.startsWith('@@')) {
        final match = RegExp(r'@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@').firstMatch(line);
        if (match != null) {
          oldLineNum = int.parse(match.group(1)!);
          newLineNum = int.parse(match.group(3)!);
          inHunk = true;
        }
        lines.add(DiffLine(
          type: DiffLineType.header,
          content: line,
          oldLineNum: null,
          newLineNum: null,
        ));
        continue;
      }

      if (!inHunk) {
        // 文件头信息
        lines.add(DiffLine(
          type: DiffLineType.header,
          content: line,
          oldLineNum: null,
          newLineNum: null,
        ));
        continue;
      }

      // 解析 diff 行
      if (line.isEmpty) {
        lines.add(DiffLine(
          type: DiffLineType.context,
          content: '',
          oldLineNum: oldLineNum++,
          newLineNum: newLineNum++,
        ));
      } else if (line.startsWith('+')) {
        lines.add(DiffLine(
          type: DiffLineType.add,
          content: line.substring(1),
          oldLineNum: null,
          newLineNum: newLineNum++,
        ));
      } else if (line.startsWith('-')) {
        lines.add(DiffLine(
          type: DiffLineType.delete,
          content: line.substring(1),
          oldLineNum: oldLineNum++,
          newLineNum: null,
        ));
      } else if (line.startsWith('\\')) {
        // "\ No newline at end of file"
        lines.add(DiffLine(
          type: DiffLineType.header,
          content: line,
          oldLineNum: null,
          newLineNum: null,
        ));
      } else {
        // 上下文行（以空格开头或无前缀）
        lines.add(DiffLine(
          type: DiffLineType.context,
          content: line.startsWith(' ') ? line.substring(1) : line,
          oldLineNum: oldLineNum++,
          newLineNum: newLineNum++,
        ));
      }
    }

    return lines;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('文件差异', style: TextStyle(fontSize: 16)),
            Text(
              widget.filePath.split('/').last,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDiff,
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
              onPressed: _loadDiff,
              child: Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_diffLines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.code, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无 diff 内容'),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFileHeader(),
        Expanded(
          child: _buildDiffView(),
        ),
      ],
    );
  }

  Widget _buildFileHeader() {
    return Container(
      padding: EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.filePath,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    if (widget.isNew)
                      _buildBadge('新增', Colors.green),
                    if (widget.isDeleted)
                      _buildBadge('删除', Colors.red),
                    if (!widget.isNew && !widget.isDeleted)
                      _buildBadge('修改', Colors.blue),
                    if (widget.isBinary)
                      _buildBadge('二进制', Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha((0.3 * 255).toInt())),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDiffView() {
    return ListView.builder(
      itemCount: _diffLines.length,
      itemBuilder: (context, index) {
        final line = _diffLines[index];
        return _buildDiffLine(line);
      },
    );
  }

  Widget _buildDiffLine(DiffLine line) {
    Color backgroundColor;
    Color textColor = Colors.black87;
    Color indicatorColor;
    
    switch (line.type) {
      case DiffLineType.add:
        backgroundColor = const Color(0xFFE8F5E9); // 更明显的浅绿色
        indicatorColor = Colors.green;
        break;
      case DiffLineType.delete:
        backgroundColor = const Color(0xFFFFEBEE); // 更明显的浅红色
        indicatorColor = Colors.red;
        break;
      case DiffLineType.header:
        backgroundColor = const Color(0xFFE3F2FD); // 更明显的浅蓝色
        indicatorColor = Colors.blue;
        textColor = Colors.blue.shade800;
        break;
      case DiffLineType.context:
      default:
        backgroundColor = const Color(0xFFFFFFFF); // 明确纯白色
        indicatorColor = Colors.grey.shade300; // 灰色指示条
    }

    return Container(
      color: backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左边彩色指示条
          Container(
            width: 3,
            height: 24,
            color: indicatorColor,
          ),
          // 旧版本行号
          Container(
            width: 50,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
              color: Colors.grey.shade50,
            ),
            child: Text(
              line.oldLineNum?.toString() ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.right,
            ),
          ),
          // 新版本行号
          Container(
            width: 50,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
              color: Colors.grey.shade50,
            ),
            child: Text(
              line.newLineNum?.toString() ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.right,
            ),
          ),
          // 代码内容
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: SelectableText(
                line.content,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Diff 行类型
enum DiffLineType {
  header,   // 文件头或 hunk 头
  context,  // 上下文（未变更）
  add,      // 新增
  delete,   // 删除
}

/// Diff 行数据
class DiffLine {
  final DiffLineType type;
  final String content;
  final int? oldLineNum;
  final int? newLineNum;

  DiffLine({
    required this.type,
    required this.content,
    this.oldLineNum,
    this.newLineNum,
  });
}
