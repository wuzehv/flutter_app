import 'package:flutter/material.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:provider/provider.dart';
import 'package:jenkins_app/models/jenkins.dart';

// 公共的待审核项目组件
class PendingApprovalItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const PendingApprovalItem({
    Key? key,
    required this.item,
    required this.onReject,
    required this.onApprove,
  }) : super(key: key);

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
          trailing: Text(
            '${item['show_time'] ?? ''}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          subtitle: Text('${item['real_project'] ?? '未知项目'} by ${item['creator'] ?? '未知提交者'}'),
          leading: Icon(Icons.pending_actions, color: Colors.orange),
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
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          spacing: 8,
                          children: [
                            Text('${p['name']}:', style: TextStyle(fontWeight: FontWeight.w500)),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(p['value']?.toString() ?? '', softWrap: true,),
                            ),
                          ],
                        ),
                      );
                    }).toList() ?? [],
                  ),
                  SizedBox(height: 12),
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

// 公共的构建历史项目组件
class BuildHistoryItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onViewLog;
  final VoidCallback onRebuild;

  const BuildHistoryItem({
    Key? key,
    required this.item,
    required this.onViewLog,
    required this.onRebuild,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late Widget icon;
    if (item['result'] == 'SUCCESS') {
      icon = Icon(Icons.check_circle, color: Colors.green);
    } else if (item['result'] == 'FAILURE') {
      icon = Icon(Icons.cancel, color: Colors.red);
    } else {
      icon = SizedBox(height: 17, width: 17, child: CircularProgressIndicator(color: Colors.blue));
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: icon,
          title: Text(item['title'] ?? 'Unknown Title', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(item['time'] ?? 'Unknown Time', style: TextStyle(color: Colors.grey, fontSize: 13.5)),
          childrenPadding: EdgeInsets.all(0),
          children: [
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('构建详情:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('ID: ${item['id']}'),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onRebuild,
                          icon: Icon(Icons.play_arrow, color: Colors.white),
                          label: Text('立即构建', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onViewLog,
                          icon: Icon(Icons.description, color: Colors.white),
                          label: Text('查看日志', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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