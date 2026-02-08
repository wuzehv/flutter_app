import 'package:flutter/material.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:provider/provider.dart';
import 'package:jenkins_app/models/jenkins.dart';

// 公共的待审核项目组件
class PendingApprovalItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onReject;
  final VoidCallback onApprove;
  final String currentUser;

  const PendingApprovalItem({
    Key? key,
    required this.item,
    required this.onReject,
    required this.onApprove,
    required this.currentUser,
  }) : super(key: key);

  // 构建状态图标
  Widget _buildStatusIcon() {
    final result = item['result'];
    
    if (result == 'SUCCESS') {
      // 成功状态：绿色对勾
      return Icon(Icons.check_circle, color: Colors.green);
    } else if (result == 'ABORTED') {
      // 中止状态：灰色叉号
      return Icon(Icons.cancel, color: Colors.grey);
    } else {
      // 其他状态：圆形动态进度条（作为图标显示）
      return SizedBox(
        height: 24, 
        width: 24, 
        child: CircularProgressIndicator(
          color: Colors.blue,
          strokeWidth: 3,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            children: [
              Text('【${item['country'] ?? ''}】 '),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  (item['branch'] ?? '').toString().length > 25 
                    ? (item['branch'] ?? '').toString().substring(0, 25) + '...'
                    : item['branch'] ?? '',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue[200]!, width: 1),
            ),
            child: Text(
              '${item['show_time'] ?? ''}',
              style: TextStyle(
                fontSize: 11, 
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          subtitle: Text('${item['real_project'] ?? '未知项目'} by ${item['creator'] ?? '未知提交者'}'),
          leading: _buildStatusIcon(),
          childrenPadding: EdgeInsets.all(0),
          children: [
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('构建参数:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (item['build_params'] as List<dynamic>?)?.map((param) {
                      final p = param as Map<String, dynamic>;
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${p['name']}:', style: TextStyle(fontWeight: FontWeight.w500)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p['value']?.toString() ?? '',
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  color: Colors.red,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.red,
                                  decorationThickness: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList() ?? [],
                  ),
                  SizedBox(height: 12),
                  // 条件显示审核按钮：audit_id不为空且当前用户等于approver时显示
                  if ((item['audit_id']?.toString() ?? '').isNotEmpty && 
                      currentUser == (item['approver']?.toString() ?? ''))
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onReject,
                            icon: Icon(Icons.close, color: Colors.white),
                            label: Text('拒绝', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onApprove,
                            icon: Icon(Icons.check, color: Colors.white),
                            label: Text('通过', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}