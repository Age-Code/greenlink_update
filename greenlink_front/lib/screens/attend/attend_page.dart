// 출석 화면 — 월간 출석 조회와 오늘 출석 처리

import 'package:flutter/material.dart';
import '../../models/attend_models.dart';
import '../../services/attend_service.dart';
import '../../core/widgets/greenlink_card.dart';
import '../../theme/app_theme.dart';

// AttendPage — 화면 위젯
class AttendPage extends StatefulWidget {
  final VoidCallback? onAttended;

  const AttendPage({Key? key, this.onAttended}) : super(key: key);

  // State 객체 생성
  @override
  _AttendPageState createState() => _AttendPageState();
}

// _AttendPageState — 화면 상태와 이벤트 처리
class _AttendPageState extends State<AttendPage> {
  final AttendService _attendService = AttendService();

  AttendMonth? _attendData;
  bool _isLoading = true;
  // 출석 요청 중 여부 — 중복 요청 방지
  bool _isAttending = false;

  int _currentYear = DateTime.now().year;
  int _currentMonth = DateTime.now().month;

  // 초기 상태 설정
  @override
  void initState() {
    super.initState();
    _loadAttends();
  }

  // 데이터 로드 — API 호출 후 상태 반영
  Future<void> _loadAttends() async {
    setState(() => _isLoading = true);
    final res = await _attendService.getAttends(year: _currentYear, month: _currentMonth);
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() { _attendData = res.data; _isLoading = false; });
    } else {
      setState(() { _attendData = null; _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 선택값 변경 — 상태 갱신 후 목록 반영
  void _changeMonth(int delta) {
    int newMonth = _currentMonth + delta;
    int newYear = _currentYear;
    if (newMonth < 1) { newMonth = 12; newYear--; }
    else if (newMonth > 12) { newMonth = 1; newYear++; }
    setState(() { _currentYear = newYear; _currentMonth = newMonth; });
    _loadAttends();
  }

  // 오늘 출석 처리 — 성공 시 출석 목록 갱신
  Future<void> _doTodayAttend() async {
    if (_isAttending) return;
    setState(() => _isAttending = true);
    final res = await _attendService.attendToday();
    if (!mounted) return;
    setState(() => _isAttending = false);
    if (res.success && res.data != null) {
      await _loadAttends();
      if (!mounted) return;
      _showSuccessDialog(res.data!.streakDays);
      widget.onAttended?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message), behavior: SnackBarBehavior.floating));
    }
  }

  // 사용자 안내 UI 표시
  void _showSuccessDialog(int streakCount) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(22)),
                child: const Icon(Icons.eco_rounded, size: 36, color: AppColors.primaryStrong),
              ),
              const SizedBox(height: 20),
              const Text('오늘도 만났어요!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 6),
              Text(
                '$streakCount일째 이어지는 만남이에요',
                style: const TextStyle(fontSize: 15, color: AppColors.bodyMuted),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('출석'), centerTitle: false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text('오늘도 식물 친구를 만나러 왔어요', style: TextStyle(fontSize: 15, color: AppColors.bodyMuted)),
          ),
          const SizedBox(height: 20),
          _buildMonthSelector(),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryStrong)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryCards(),
                        const SizedBox(height: 20),
                        _buildCalendarCard(),
                        if (_attendData != null && _attendData!.attends.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              children: [
                                const Text('이번 달에는 아직 만난 날이 없어요', style: TextStyle(color: AppColors.bodyMuted, fontSize: 14), textAlign: TextAlign.center),
                                const SizedBox(height: 4),
                                const Text('오늘 첫 만남을 기록해볼까요?', style: TextStyle(color: AppColors.bodyMuted, fontSize: 14), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
          // CTA Button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: const BoxDecoration(
              color: AppColors.canvas,
              border: Border(top: BorderSide(color: AppColors.hairline)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isLoading || _isAttending) ? null : _doTodayAttend,
                child: const Text('오늘 식물 친구 만나기', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.ink),
          onPressed: () => _changeMonth(-1),
        ),
        const SizedBox(width: 12),
        Text(
          '$_currentYear년 $_currentMonth월',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.3),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  // 화면 섹션 렌더링
  Widget _buildSummaryCards() {
    final int total = _attendData?.totalAttendCount ?? 0;
    final int streak = _attendData?.currentStreakCount ?? 0;

    return Row(
      children: [
        Expanded(
          child: GreenlinkCard(
            child: Column(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.eco_rounded, color: AppColors.primaryStrong, size: 22),
                ),
                const SizedBox(height: 12),
                const Text('이번 달', style: TextStyle(fontSize: 13, color: AppColors.bodyMuted)),
                const SizedBox(height: 4),
                Text('$total번 만났어요', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: GreenlinkCard(
            child: Column(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: const Color(0xFFFFF4D8), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFD4A017), size: 22),
                ),
                const SizedBox(height: 12),
                const Text('연속 만남', style: TextStyle(fontSize: 13, color: AppColors.bodyMuted)),
                const SizedBox(height: 4),
                Text('$streak일째', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 화면 섹션 렌더링
  Widget _buildCalendarCard() {
    return GreenlinkCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _WeekdayLabel(text: '월'),
              _WeekdayLabel(text: '화'),
              _WeekdayLabel(text: '수'),
              _WeekdayLabel(text: '목'),
              _WeekdayLabel(text: '금'),
              _WeekdayLabel(text: '토'),
              _WeekdayLabel(text: '일'),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentYear, _currentMonth, 1);
    final daysInMonth = DateTime(_currentYear, _currentMonth + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday;

    int totalCells = startingWeekday - 1 + daysInMonth;
    int rows = (totalCells / 7).ceil();

    final attendedDateSet = <String>{};
    if (_attendData != null) {
      for (var a in _attendData!.attends) {
        if (a.attendDate.isNotEmpty) attendedDateSet.add(a.attendDate);
      }
    }

    final now = DateTime.now();
    List<Widget> gridRows = [];
    int currentDay = 1;

    for (int i = 0; i < rows; i++) {
      List<Widget> rowChildren = [];
      for (int j = 1; j <= 7; j++) {
        if (i == 0 && j < startingWeekday) {
          rowChildren.add(const Expanded(child: SizedBox()));
        } else if (currentDay <= daysInMonth) {
          final dateKey = '$_currentYear-${_currentMonth.toString().padLeft(2, '0')}-${currentDay.toString().padLeft(2, '0')}';
          final bool isAttended = attendedDateSet.contains(dateKey);
          final bool isToday = _currentYear == now.year && _currentMonth == now.month && currentDay == now.day;
          final bool isFuture = DateTime(_currentYear, _currentMonth, currentDay).isAfter(DateTime(now.year, now.month, now.day));

          rowChildren.add(Expanded(
            child: _DayCell(day: currentDay, isAttended: isAttended, isToday: isToday, isFuture: isFuture),
          ));
          currentDay++;
        } else {
          rowChildren.add(const Expanded(child: SizedBox()));
        }
      }
      gridRows.add(Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: rowChildren));
      if (i < rows - 1) gridRows.add(const SizedBox(height: 14));
    }

    return Column(children: gridRows);
  }
}

// _WeekdayLabel — 내부 위젯
class _WeekdayLabel extends StatelessWidget {
  final String text;
  const _WeekdayLabel({required this.text});

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.bodyMuted),
      textAlign: TextAlign.center,
    );
  }
}

// _DayCell — 내부 위젯
class _DayCell extends StatelessWidget {
  final int day;
  final bool isAttended;
  final bool isToday;
  final bool isFuture;

  const _DayCell({required this.day, required this.isAttended, required this.isToday, required this.isFuture});

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    Color textColor = AppColors.body;
    if (isFuture) textColor = AppColors.bodySoft;
    if (isAttended) textColor = AppColors.primaryStrong;

    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAttended ? AppColors.primary : Colors.transparent,
            border: isToday && !isAttended
                ? Border.all(color: AppColors.primaryFocus, width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            day.toString(),
            style: TextStyle(
              fontSize: 14,
              color: isAttended ? AppColors.onPrimary : textColor,
              fontWeight: isToday || isAttended ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (isAttended)
          const Icon(Icons.eco_rounded, size: 10, color: AppColors.primaryStrong)
        else
          const SizedBox(height: 10),
      ],
    );
  }
}
