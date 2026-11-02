// 센서 기록 카드 — 토양 수분/온도/습도/조도 추이 그래프 (외부 차트 패키지 없이 CustomPainter)

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/network/api_response.dart';
import '../../../models/iot_models.dart';
import '../../../services/iot_service.dart';
import '../../../theme/app_theme.dart';

enum _Metric {
  soil('토양 수분', '%', Color(0xFF3A8FC8)),
  temperature('온도', '°C', Color(0xFFE07A3F)),
  humidity('습도', '%', Color(0xFF3F7480)),
  light('조도', 'lx', Color(0xFFB8860B));

  final String label;
  final String unit;
  final Color color;

  const _Metric(this.label, this.unit, this.color);
}

class SensorHistoryCard extends StatefulWidget {
  final int userPlantId;

  // 값이 바뀌면 기록을 다시 불러온다 (부모 화면 새로고침 연동)
  final int refreshToken;

  // 기록 조회 함수 — 테스트에서 주입, 기본은 IotService
  final Future<ApiResponse<SensorHistory>> Function(int userPlantId, int hours)?
  loader;

  const SensorHistoryCard({
    super.key,
    required this.userPlantId,
    this.refreshToken = 0,
    this.loader,
  });

  @override
  State<SensorHistoryCard> createState() => _SensorHistoryCardState();
}

class _SensorHistoryCardState extends State<SensorHistoryCard> {
  final IotService _iotService = IotService();

  _Metric _metric = _Metric.soil;
  int _hours = 24;
  SensorHistory? _history;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SensorHistoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken ||
        oldWidget.userPlantId != widget.userPlantId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = widget.loader != null
        ? await widget.loader!(widget.userPlantId, _hours)
        : await _iotService.getSensorHistory(widget.userPlantId, hours: _hours);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _history = res.data;
      } else {
        _error = res.message.isNotEmpty ? res.message : '센서 기록을 불러오지 못했어요.';
      }
    });
  }

  List<SensorPoint> get _points {
    final history = _history;
    if (history == null) return const [];
    return switch (_metric) {
      _Metric.soil => history.soilMoisture,
      _Metric.temperature => history.temperature,
      _Metric.humidity => history.humidity,
      _Metric.light => history.light,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.show_chart_rounded,
                size: 18,
                color: AppColors.primaryStrong,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '센서 기록',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              _PeriodToggle(
                hours: _hours,
                onChanged: (hours) {
                  if (hours == _hours) return;
                  setState(() => _hours = hours);
                  _load();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _Metric.values.map((metric) {
                final selected = metric == _metric;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(metric.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _metric = metric),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.onPrimary : AppColors.bodyMuted,
                    ),
                    selectedColor: AppColors.primarySoft,
                    backgroundColor: AppColors.surfacePearl,
                    side: BorderSide(
                      color: selected ? AppColors.primaryFocus : AppColors.hairline,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 180, child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _history == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_error != null && _history == null) {
      return Center(
        child: TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(_error!),
        ),
      );
    }

    final points = _points;
    if (points.length < 2) {
      return Center(
        child: Text(
          '최근 ${_hours == 24 ? '24시간' : '7일'} 동안 ${_metric.label} 기록이 부족해요.',
          style: const TextStyle(fontSize: 13, color: AppColors.bodyMuted),
        ),
      );
    }

    final values = points.map((p) => p.value);
    final latest = points.last.value;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${_format(latest)}${_metric.unit}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _metric.color,
                ),
              ),
              TextSpan(
                text: '  최저 ${_format(minValue)} · 최고 ${_format(maxValue)}',
                style: const TextStyle(fontSize: 12, color: AppColors.bodySoft),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _LineChartPainter(points: points, color: _metric.color),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_timeLabel(points.first.time), style: _axisStyle),
            Text(_timeLabel(points.last.time), style: _axisStyle),
          ],
        ),
      ],
    );
  }

  static const _axisStyle = TextStyle(fontSize: 11, color: AppColors.bodySoft);

  String _format(double value) => _metric == _Metric.light
      ? value.round().toString()
      : value.toStringAsFixed(1);

  String _timeLabel(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return _hours == 24 ? '$hh:$mm' : '${time.month}/${time.day} $hh:$mm';
  }
}

class _PeriodToggle extends StatelessWidget {
  final int hours;
  final ValueChanged<int> onChanged;

  const _PeriodToggle({required this.hours, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget option(int value, String label) {
      final selected = hours == value;
      return GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceCard : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.ink : AppColors.bodyMuted,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfacePearl,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [option(24, '24시간'), option(168, '7일')],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<SensorPoint> points;
  final Color color;

  _LineChartPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final start = points.first.time.millisecondsSinceEpoch.toDouble();
    final end = points.last.time.millisecondsSinceEpoch.toDouble();
    final span = math.max(end - start, 1.0);

    var minValue = points.map((p) => p.value).reduce(math.min);
    var maxValue = points.map((p) => p.value).reduce(math.max);
    if (maxValue - minValue < 1) {
      minValue -= 0.5;
      maxValue += 0.5;
    }
    final range = maxValue - minValue;

    // 마지막 점 표시가 잘리지 않도록 좌우·상하 여백
    const inset = 4.0;
    final plotWidth = size.width - inset * 2;
    final plotHeight = size.height - inset * 2;

    Offset toOffset(SensorPoint p) => Offset(
      inset + (p.time.millisecondsSinceEpoch - start) / span * plotWidth,
      inset + plotHeight - (p.value - minValue) / range * plotHeight,
    );

    final grid = Paint()
      ..color = AppColors.hairline
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final line = Path();
    final fill = Path()..moveTo(toOffset(points.first).dx, size.height);
    for (var i = 0; i < points.length; i++) {
      final o = toOffset(points[i]);
      if (i == 0) {
        line.moveTo(o.dx, o.dy);
      } else {
        line.lineTo(o.dx, o.dy);
      }
      fill.lineTo(o.dx, o.dy);
    }
    fill
      ..lineTo(toOffset(points.last).dx, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(toOffset(points.last), 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
