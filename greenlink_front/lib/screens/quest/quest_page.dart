// 퀘스트 화면 — 퀘스트 조회, 필터, 보상 수령

import 'package:flutter/material.dart';
import '../../models/quest_models.dart';
import '../../services/quest_service.dart';
import '../../core/widgets/greenlink_card.dart';
import '../../theme/app_theme.dart';
import '../../widgets/quest_detail_bottom_sheet.dart';
import '../attend/attend_page.dart';
import '../main_page.dart';

// QuestPage — 화면 위젯
class QuestPage extends StatefulWidget {
  const QuestPage({Key? key}) : super(key: key);

  // State 객체 생성
  @override
  QuestPageState createState() => QuestPageState();
}

// QuestPageState — 퀘스트 화면 — 퀘스트 조회, 필터, 보상 수령
class QuestPageState extends State<QuestPage> {
  final QuestService _questService = QuestService();

  List<UserQuestSummary>? _allQuests;
  List<UserQuestSummary>? _filteredQuests;
  bool _isLoading = true;
  // 보상 수령 요청 중인 퀘스트 ID — 중복 요청 방지
  final Set<int> _receivingQuestIds = {};

  String _selectedStatus = 'ALL';
  String _selectedQuestType = 'ALL';

  final Map<String, String> _statusFilters = {
    'ALL': '전체',
    'IN_PROGRESS': '진행 중',
    'ACHIEVABLE': '보상 가능',
    'COMPLETED': '완료',
    'EXPIRED': '만료',
  };

  final Map<String, String> _typeFilters = {
    'ALL': '전체',
    'DAILY': '일일',
    'WEEKLY': '주간',
    'MONTHLY': '월간',
    'ACHIEVEMENT': '업적',
  };

  // 초기 상태 설정
  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  // 화면 데이터 새로고침
  void refresh() {
    debugPrint('[QuestPage] 🔄 refresh quests');
    _loadQuests();
  }

  // 데이터 로드 — API 호출 후 상태 반영
  Future<void> _loadQuests() async {
    setState(() => _isLoading = true);
    final res = await _questService.getUserQuests();
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() {
        _allQuests = res.data;
        _applyFilters();
        _isLoading = false;
      });
    } else {
      setState(() { _allQuests = []; _filteredQuests = []; _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 필터 적용 — 현재 선택값 기준으로 목록 갱신
  void _applyFilters() {
    if (_allQuests == null) return;
    _filteredQuests = _allQuests!.where((q) {
      bool passStatus = _selectedStatus == 'ALL' || q.status == _selectedStatus;
      bool passType = _selectedQuestType == 'ALL' || q.questType == _selectedQuestType;
      return passStatus && passType;
    }).toList();
  }

  // 퀘스트 상태 필터 변경
  void _onStatusChanged(String status) => setState(() { _selectedStatus = status; _applyFilters(); });
  // 퀘스트 타입 필터 변경
  void _onTypeChanged(String type) => setState(() { _selectedQuestType = type; _applyFilters(); });

  // 보상 수령 처리
  Future<void> _receiveReward(UserQuestSummary quest) async {
    if (_receivingQuestIds.contains(quest.userQuestId)) return;
    setState(() => _receivingQuestIds.add(quest.userQuestId));
    final res = await _questService.receiveReward(quest.userQuestId);
    if (!mounted) return;
    setState(() => _receivingQuestIds.remove(quest.userQuestId));
    if (res.success && res.data != null) {
      await _loadQuests();
      if (!mounted) return;
      _showRewardSuccessDialog(res.data!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 사용자 안내 UI 표시
  void _showRewardSuccessDialog(QuestRewardResponse rewardData) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.redeem_rounded, size: 32, color: AppColors.primaryStrong),
              ),
              const SizedBox(height: 20),
              const Text('보상을 받았어요', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 6),
              const Text('작은 약속을 지켜서 선물을 받았어요', style: TextStyle(fontSize: 14, color: AppColors.bodyMuted)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.canvasGreenTint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                      child: rewardData.reward.itemName.contains('영양제')
                          ? const Icon(Icons.water_drop_rounded, color: AppColors.primaryStrong, size: 22)
                          : const Icon(Icons.eco_rounded, color: AppColors.primaryStrong, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '${rewardData.reward.itemName} ${rewardData.reward.quantity}개가 인벤토리에 들어왔어요',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('확인'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // 다이얼로그 닫은 뒤 기존 MainPage의 인벤토리 탭으로 전환 (새 MainPage push 금지)
                        Navigator.pop(dialogContext);
                        MainPage.switchTab(1);
                      },
                      child: const Text('인벤토리'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 사용자 안내 UI 표시
  Future<void> _showDetailBottomSheet(UserQuestSummary quest) async {
    // 바텀시트에서 보상 수령 성공 시 보상 정보를 결과로 받아 이 화면의 context로 다이얼로그 표시
    final reward = await showModalBottomSheet<QuestRewardResponse>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: QuestDetailBottomSheet(userQuestId: quest.userQuestId, onRewardReceived: _loadQuests),
      ),
    );
    if (!mounted || reward == null) return;
    _showRewardSuccessDialog(reward);
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('퀘스트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, size: 22),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => AttendPage(onAttended: _loadQuests)));
              if (mounted) _loadQuests();
            },
            tooltip: '출석',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              '식물 친구와 함께하는 작은 약속이에요',
              style: TextStyle(fontSize: 15, color: AppColors.bodyMuted),
            ),
          ),
          const SizedBox(height: 16),
          if (!_isLoading && _allQuests != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSummaryCard(),
            ),
            const SizedBox(height: 16),
          ],
          _buildFilters(),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryStrong)))
                : _filteredQuests == null || _filteredQuests!.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _filteredQuests!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildQuestCard(_filteredQuests![index]),
                      ),
          ),
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildSummaryCard() {
    final int inProgress = _allQuests!.where((q) => q.status == 'IN_PROGRESS').length;
    final int achievable = _allQuests!.where((q) => q.status == 'ACHIEVABLE').length;
    final int completed = _allQuests!.where((q) => q.status == 'COMPLETED').length;

    return GreenlinkCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(label: '진행 중', count: inProgress),
          Container(width: 1, height: 36, color: AppColors.hairline),
          _SummaryItem(label: '받을 보상', count: achievable, isHighlight: achievable > 0),
          Container(width: 1, height: 36, color: AppColors.hairline),
          _SummaryItem(label: '완료', count: completed),
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildFilters() {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: _statusFilters.entries.map((e) {
              final isSelected = _selectedStatus == e.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(e.value),
                  selected: isSelected,
                  onSelected: (_) => _onStatusChanged(e.key),
                  selectedColor: AppColors.primarySoft,
                  backgroundColor: AppColors.canvas,
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.hairline),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: isSelected ? AppColors.primaryStrong : AppColors.bodyMuted,
                  ),
                  shape: const StadiumBorder(),
                  checkmarkColor: AppColors.primaryStrong,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: _typeFilters.entries.map((e) {
              final isSelected = _selectedQuestType == e.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(e.value),
                  selected: isSelected,
                  onSelected: (_) => _onTypeChanged(e.key),
                  selectedColor: AppColors.canvasGreenTint,
                  backgroundColor: AppColors.canvas,
                  side: BorderSide(color: isSelected ? AppColors.primaryFocus : AppColors.hairline),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSelected ? AppColors.ink : AppColors.bodySoft,
                  ),
                  shape: const StadiumBorder(),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 화면 섹션 렌더링
  Widget _buildQuestCard(UserQuestSummary quest) {
    final bool isExpired = quest.status == 'EXPIRED';
    final bool isAchievable = quest.status == 'ACHIEVABLE';
    final bool isCompleted = quest.status == 'COMPLETED';

    double progressRate = quest.targetValue == 0 ? 0 : quest.progressValue / quest.targetValue;
    if (progressRate > 1.0) progressRate = 1.0;

    return GestureDetector(
      onTap: () => _showDetailBottomSheet(quest),
      child: Opacity(
        opacity: isExpired ? 0.55 : 1.0,
        child: GreenlinkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TypeBadge(type: quest.questType),
                  _StatusBadge(status: quest.status),
                ],
              ),
              const SizedBox(height: 14),
              Text(quest.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text(
                _statusMessage(quest.status),
                style: const TextStyle(fontSize: 13, color: AppColors.bodyMuted),
              ),
              const SizedBox(height: 16),
              // Progress
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressRate,
                        backgroundColor: AppColors.primarySoft,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isAchievable ? AppColors.primaryStrong : AppColors.primary,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${quest.progressValue}/${quest.targetValue}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                  ),
                ],
              ),
              if (isAchievable) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _receivingQuestIds.contains(quest.userQuestId) ? null : () => _receiveReward(quest),
                    child: Text(
                      _receivingQuestIds.contains(quest.userQuestId) ? '받는 중...' : '보상 받기',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
              if (isCompleted) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.bodyMuted,
                      side: const BorderSide(color: AppColors.hairline),
                    ),
                    child: const Text('보상 받음'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 상태 표시값 변환
  String _statusMessage(String status) {
    switch (status) {
      case 'IN_PROGRESS': return '조금만 더 해볼까요?';
      case 'ACHIEVABLE': return '보상을 받을 수 있어요';
      case 'COMPLETED': return '이미 보상을 받았어요';
      case 'EXPIRED': return '이번 약속은 지나갔어요';
      default: return '';
    }
  }

  // 화면 섹션 렌더링
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.canvasGreenTint, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.check_circle_outline_rounded, size: 40, color: AppColors.bodyMuted),
            ),
            const SizedBox(height: 24),
            const Text('아직 퀘스트가 없어요', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 8),
            const Text('식물을 돌보면 새로운 약속이 생겨요', style: TextStyle(fontSize: 14, color: AppColors.bodyMuted, height: 1.5)),
          ],
        ),
      ),
    );
  }
}


// _SummaryItem — 내부 위젯
class _SummaryItem extends StatelessWidget {
  final String label;
  final int count;
  final bool isHighlight;

  const _SummaryItem({required this.label, required this.count, this.isHighlight = false});

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count개',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isHighlight ? AppColors.primaryStrong : AppColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.bodyMuted)),
      ],
    );
  }
}

// _TypeBadge — 내부 위젯
class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  String get _label {
    switch (type) {
      case 'DAILY': return '오늘의 약속';
      case 'WEEKLY': return '이번 주 약속';
      case 'MONTHLY': return '이번 달 약속';
      case 'ACHIEVEMENT': return '도전 기록';
      default: return type;
    }
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.canvasGreenTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(_label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.bodyMuted)),
    );
  }
}

// _StatusBadge — 내부 위젯
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case 'IN_PROGRESS':
        bg = AppColors.primarySoft;
        fg = AppColors.primaryStrong;
        text = '진행 중';
        break;
      case 'ACHIEVABLE':
        bg = const Color(0xFFFFF4D8);
        fg = const Color(0xFF8A6500);
        text = '보상 가능';
        break;
      case 'COMPLETED':
        bg = const Color(0xFFF0F0EE);
        fg = AppColors.bodyMuted;
        text = '완료';
        break;
      case 'EXPIRED':
        bg = AppColors.dangerBg;
        fg = AppColors.dangerText;
        text = '만료';
        break;
      default:
        bg = const Color(0xFFF0F0EE);
        fg = AppColors.bodyMuted;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}
