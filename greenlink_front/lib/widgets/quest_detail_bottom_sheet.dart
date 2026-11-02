// 퀘스트 상세 바텀시트 — 상세 조회와 보상 수령

import 'package:flutter/material.dart';
import '../models/quest_models.dart';
import '../services/quest_service.dart';
import '../theme/app_theme.dart';

// QuestDetailBottomSheet — 퀘스트 상세 바텀시트 — 상세 조회와 보상 수령
class QuestDetailBottomSheet extends StatefulWidget {
  final int userQuestId;
  final VoidCallback onRewardReceived;

  const QuestDetailBottomSheet({
    Key? key,
    required this.userQuestId,
    required this.onRewardReceived,
  }) : super(key: key);

  // State 객체 생성
  @override
  _QuestDetailBottomSheetState createState() => _QuestDetailBottomSheetState();
}

// _QuestDetailBottomSheetState — 화면 상태와 이벤트 처리
class _QuestDetailBottomSheetState extends State<QuestDetailBottomSheet> {
  final QuestService _questService = QuestService();
  UserQuestDetail? _detail;
  bool _isLoading = true;
  bool _isReceiving = false;

  // 초기 상태 설정
  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  // 데이터 로드 — API 호출 후 상태 반영
  Future<void> _loadDetail() async {
    final res = await _questService.getUserQuestDetail(widget.userQuestId);
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() { _detail = res.data; _isLoading = false; });
    } else {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 보상 수령 처리
  Future<void> _receiveReward() async {
    if (_isReceiving || _detail == null) return;
    setState(() => _isReceiving = true);
    final res = await _questService.receiveReward(_detail!.userQuestId);
    if (!mounted) return;
    setState(() => _isReceiving = false);
    if (res.success && res.data != null) {
      widget.onRewardReceived();
      // 바텀시트를 닫으며 보상 정보를 반환 — 보상 다이얼로그는 호출한 화면(QuestPage)에서 표시
      Navigator.pop(context, res.data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 날짜 문자열 포맷 — 파싱 실패 시 원문 반환
  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    } catch (_) { return isoString; }
  }

  // 퀘스트 타입 라벨 반환
  String _getTypeName(String type) {
    switch (type) {
      case 'DAILY': return '오늘의 약속';
      case 'WEEKLY': return '이번 주 약속';
      case 'MONTHLY': return '이번 달 약속';
      case 'ACHIEVEMENT': return '도전 기록';
      default: return type;
    }
  }

  // 퀘스트 목표 타입 라벨 반환
  String _getTargetTypeName(String type) {
    switch (type) {
      case 'ATTEND': return '출석';
      case 'WATERING': return '물주기';
      case 'GROW_PLANT': return '식물 키우기';
      case 'HARVEST': return '수확';
      default: return type;
    }
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryStrong))),
      );
    }

    if (_detail == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('데이터를 불러오지 못했습니다.', style: TextStyle(color: AppColors.bodyMuted))),
      );
    }

    double progressRate = _detail!.targetValue == 0 ? 0 : _detail!.progressValue / _detail!.targetValue;
    if (progressRate > 1.0) progressRate = 1.0;

    final isAchievable = _detail!.status == 'ACHIEVABLE';
    final isCompleted = _detail!.status == 'COMPLETED';
    final isExpired = _detail!.status == 'EXPIRED';

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 28),

          // Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TypeBadge(type: _detail!.questType, label: _getTypeName(_detail!.questType)),
              _StatusBadge(status: _detail!.status),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(_detail!.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.3)),
          if (_detail!.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_detail!.description, style: const TextStyle(fontSize: 15, color: AppColors.bodyMuted, height: 1.5)),
          ],
          const SizedBox(height: 24),

          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '목표: ${_getTargetTypeName(_detail!.targetType)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.body),
              ),
              Text(
                '${_detail!.progressValue} / ${_detail!.targetValue}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressRate,
              backgroundColor: AppColors.primarySoft,
              valueColor: AlwaysStoppedAnimation<Color>(
                isAchievable ? AppColors.primaryStrong : AppColors.primary,
              ),
              minHeight: 10,
            ),
          ),

          // Date range
          const SizedBox(height: 16),
          Row(
            children: [
              if (_detail!.startedAt != null)
                Expanded(child: Text('시작: ${_formatDate(_detail!.startedAt)}', style: const TextStyle(fontSize: 13, color: AppColors.bodyMuted))),
              if (_detail!.expiredAt != null)
                Expanded(child: Text('마감: ${_formatDate(_detail!.expiredAt)}', style: const TextStyle(fontSize: 13, color: AppColors.bodyMuted), textAlign: TextAlign.right)),
            ],
          ),
          const SizedBox(height: 28),

          // Reward area
          if (_detail!.rewardItem != null)
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
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                    child: _detail!.rewardItem!.imageUrl != null
                        ? Image.network(_detail!.rewardItem!.imageUrl!)
                        : const Icon(Icons.eco_rounded, color: AppColors.primaryStrong),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('보상', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primaryStrong)),
                        const SizedBox(height: 4),
                        Text(
                          '${_detail!.rewardItem!.name} ${_detail!.rewardQuantity}개',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.canvasSoft, borderRadius: BorderRadius.circular(16)),
              child: const Text('등록된 보상이 없어요', style: TextStyle(color: AppColors.bodyMuted, fontSize: 14), textAlign: TextAlign.center),
            ),
          const SizedBox(height: 28),

          // Action button
          _buildActionButton(isAchievable, isCompleted, isExpired),
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildActionButton(bool isAchievable, bool isCompleted, bool isExpired) {
    if (isAchievable) {
      return SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _isReceiving ? null : _receiveReward,
          child: _isReceiving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
              : const Text('보상 받기', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        ),
      );
    }

    String label = isCompleted ? '이미 받았어요' : isExpired ? '기간이 지났어요' : '아직 진행 중이에요';
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.bodyMuted,
          side: const BorderSide(color: AppColors.hairline),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      ),
    );
  }
}


// _TypeBadge — 내부 위젯
class _TypeBadge extends StatelessWidget {
  final String type;
  final String label;
  const _TypeBadge({required this.type, required this.label});

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.canvasGreenTint, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.bodyMuted)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}
