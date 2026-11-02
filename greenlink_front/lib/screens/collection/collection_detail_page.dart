// 도감 상세 화면 — 수확 기록과 상태 조회

import 'package:flutter/material.dart';
import '../../models/collection_models.dart';
import '../../services/collection_service.dart';
import '../../core/widgets/greenlink_card.dart';

// CollectionDetailPage — 화면 위젯
class CollectionDetailPage extends StatefulWidget {
  final int plantId;

  const CollectionDetailPage({Key? key, required this.plantId}) : super(key: key);

  // State 객체 생성
  @override
  _CollectionDetailPageState createState() => _CollectionDetailPageState();
}

// _CollectionDetailPageState — 화면 상태와 이벤트 처리
class _CollectionDetailPageState extends State<CollectionDetailPage> {
  final CollectionService _collectionService = CollectionService();
  CollectionDetail? _detail;
  bool _isLoading = true;

  // 초기 상태 설정
  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  // 데이터 로드 — API 호출 후 상태 반영
  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    final res = await _collectionService.getCollectionDetail(widget.plantId);
    if (res.success && res.data != null) {
      if (!mounted) return;
      setState(() {
        _detail = res.data;
        _isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 날짜 문자열 포맷 — 파싱 실패 시 원문 반환
  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_detail?.name ?? "식물 상세"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
              ? _buildErrorState(theme)
              : _buildContent(theme),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildContent(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(theme),
          const SizedBox(height: 24),
          _buildStatusCard(theme),
          const SizedBox(height: 32),
          Text(
            "함께한 기록",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRecordsSection(theme),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildHeaderCard(ThemeData theme) {
    return GreenlinkCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _detail!.collected ? theme.scaffoldBackgroundColor : theme.disabledColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Opacity(
              opacity: _detail!.collected ? 1.0 : 0.4,
              child: _detail!.imageUrl != null
                  ? Image.network(_detail!.imageUrl!, fit: BoxFit.contain)
                  : Icon(Icons.local_florist, size: 80, color: theme.primaryColor),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _detail!.category,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.primaryColorDark),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _detail!.name,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (_detail!.description != null) ...[
            const SizedBox(height: 12),
            Text(
              _detail!.description!,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildStatusCard(ThemeData theme) {
    if (_detail!.collected) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(Icons.star, color: theme.colorScheme.secondary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("도감에 기록된 식물이에요", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("총 ${_detail!.harvestCount}번 수확했어요", style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.disabledColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(Icons.help_outline, color: theme.disabledColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("아직 이 식물과 함께한 기록이 없어요", style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("씨앗을 얻어 키워보세요", style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor)),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  // 화면 섹션 렌더링
  Widget _buildRecordsSection(ThemeData theme) {
    if (!_detail!.collected || _detail!.harvestedPlants.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.disabledColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(Icons.photo_album, size: 60, color: theme.disabledColor.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              "아직 함께한 기록이 없어요",
              style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor),
            ),
            const SizedBox(height: 8),
            Text(
              "이 식물을 키우고 수확하면 여기에 기록돼요",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _detail!.harvestedPlants.map((plant) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GreenlinkCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: plant.imageUrl != null
                      ? Image.network(plant.imageUrl!, fit: BoxFit.cover)
                      : Icon(Icons.eco, color: theme.primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plant.nickname, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("심은 날 ${_formatDate(plant.plantedAt)}", style: TextStyle(fontSize: 12, color: theme.disabledColor)),
                      Text("수확한 날 ${_formatDate(plant.harvestedAt)}", style: TextStyle(fontSize: 12, color: theme.disabledColor)),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: theme.colorScheme.secondary, size: 24),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Text(
        "데이터를 불러올 수 없습니다.",
        style: TextStyle(color: theme.disabledColor),
      ),
    );
  }
}
