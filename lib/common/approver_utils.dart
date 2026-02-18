/// 审核人工具类
class ApproverUtils {
  /// 将领导置顶排序
  /// [approvers] 待排序的审核人列表
  /// [leaders] 领导名单列表
  /// 返回排序后的审核人列表，领导在前，普通员工在后
  static List<String> sortApproversWithLeadersFirst(List<String> approvers, List<String> leaders) {
    // 如果没有配置领导，则按字母顺序排序
    if (leaders.isEmpty) {
      final sortedApprovers = List<String>.from(approvers);
      sortedApprovers.sort();
      return sortedApprovers;
    }

    // 分离领导和普通员工
    final leaderApprovers = <String>[];
    final regularApprovers = <String>[];

    for (String approver in approvers) {
      if (leaders.contains(approver)) {
        leaderApprovers.add(approver);
      } else {
        regularApprovers.add(approver);
      }
    }

    // 领导按预定义顺序排列，普通员工按字母顺序排列
    leaderApprovers.sort((a, b) => leaders.indexOf(a).compareTo(leaders.indexOf(b)));
    regularApprovers.sort();

    // 合并结果：领导在前，普通员工在后
    return [...leaderApprovers, ...regularApprovers];
  }

  /// 检查是否为领导
  /// [approver] 审核人姓名
  /// [leaders] 领导名单列表
  static bool isLeader(String approver, List<String> leaders) {
    return leaders.contains(approver);
  }

  /// 获取领导列表（默认配置）
  static const List<String> DEFAULT_LEADERS = ['张俊兴'];
}