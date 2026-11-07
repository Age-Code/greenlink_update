// 사용자 식물 상세 화면 — 성장 정보, IoT, 자동화 진입

import 'package:flutter/material.dart';
import '../../models/user_plant_models.dart';
import '../../models/iot_models.dart';
import '../../services/user_plant_service.dart';
import '../../services/iot_service.dart';
import '../../core/utils/plant_image_utils.dart';
import '../../core/widgets/greenlink_card.dart';
import '../../core/widgets/greenlink_button.dart';
import '../../theme/app_theme.dart';
import '../../widgets/soil_moisture_sufficient_banner.dart';
import '../../widgets/water_shortage_banner.dart';
import '../iot/iot_status_page.dart';
import 'automation_section.dart';

// UserPlantDetailPage — 화면 위젯
class UserPlantDetailPage extends StatefulWidget {
  final int userPlantId;

  const UserPlantDetailPage({Key? key, required this.userPlantId}) : super(key: key);

  // State 객체 생성
  @override
  _UserPlantDetailPageState createState() => _UserPlantDetailPageState();
}

// _UserPlantDetailPageState — 화면 상태와 이벤트 처리
class _UserPlantDetailPageState extends State<UserPlantDetailPage> {
  final UserPlantService _plantService = UserPlantService();
  final IotService _iotService = IotService();

  UserPlantDetail? _plant;
  bool _isLoading = true;
  bool _isHarvesting = false;

  PlantImageData? _latestImageData;
  IotLatestStatus? _latestStatus;
  String? _capturedAt;

  // 초기 상태 설정
  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  // 데이터 로드 — API 호출 후 상태 반영
  Future<void> _loadDetail() async {
    // 처음에만 전체 로딩 화면을 쓴다. 이름 변경 후 다시 불러올 때 화면 전체(자동화 섹션 포함)를
    // 갈아끼우면 저장하지 않은 입력이 사라지고 API를 다시 호출하므로 기존 화면을 유지한다.
    if (_plant == null) {
      setState(() => _isLoading = true);
    }
    final res = await _plantService.getUserPlantDetail(widget.userPlantId);
    if (!mounted) return;

    if (res.success && res.data != null) {
      setState(() { _plant = res.data; _isLoading = false; });
      _loadLatestImage();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 데이터 로드 — API 호출 후 상태 반영
  Future<void> _loadLatestImage() async {
    try {
      final res = await _iotService.getLatestStatus(widget.userPlantId);
      if (!mounted) return;
      final latest = res.data;
      final img = latest?.latestImage;
      if (res.success && latest != null) {
        setState(() {
          _latestStatus = latest;
          _latestImageData = img;
          _capturedAt = img?.capturedAt;
        });
      }
    } catch (e) {
      debugPrint('[UserPlantDetailPage] ⚠️ 최신 이미지 로드 실패: $e');
    }
  }

  // 수확 처리 — 성공 시 상태 갱신
  Future<void> _harvestPlant() async {
    if (_plant == null || _isHarvesting) return;
    setState(() => _isHarvesting = true);
    final res = await _plantService.harvestUserPlant(_plant!.userPlantId);
    if (!mounted) return;
    setState(() => _isHarvesting = false);

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('식물 수확이 완료되었습니다.')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 사용자 안내 UI 표시 — 시트는 입력값만 반환하고, API 호출/스낵바는 페이지 context로 처리
  Future<void> _showEditNameBottomSheet() async {
    if (_plant == null) return;
    final currentName = _plant!.nickname;
    final newName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditNameSheet(initialName: currentName),
    );
    if (!mounted || _plant == null) return;
    if (newName == null || newName.isEmpty || newName == currentName) return;
    final res = await _plantService.updateUserPlantNickname(_plant!.userPlantId, newName);
    if (!mounted) return;
    if (res.success) {
      _loadDetail();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 날짜 문자열 포맷 — 파싱 실패 시 원문 반환
  String _formatDate(String? isoString) {
    if (isoString == null) return '-';
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    } catch (_) { return isoString; }
  }

  // 표시용 문자열 포맷
  String _formatDateTimeStr(String? isoString) {
    if (isoString == null) return '-';
    try {
      final dt = DateTime.parse(isoString);
      final pad = (int n) => n.toString().padLeft(2, '0');
      return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} ${pad(dt.hour)}:${pad(dt.minute)}';
    } catch (_) { return isoString; }
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('식물 상세')),
        body: const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryStrong))),
      );
    }

    if (_plant == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('식물 상세')),
        body: const Center(child: Text('데이터를 불러오지 못했습니다.', style: TextStyle(color: AppColors.bodyMuted))),
      );
    }

    String statusMsg = '';
    if (_plant!.status == 'GROWING') statusMsg = '조금씩 자라고 있어요 🌱';
    else if (_plant!.status == 'HARVESTABLE') statusMsg = '이제 수확할 수 있어요 🌿';
    else if (_plant!.status == 'HARVESTED') statusMsg = '도감에 기록됐어요 📖';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(_plant!.nickname),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: _showEditNameBottomSheet,
            tooltip: '이름 수정',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_latestStatus?.isWaterShortage == true &&
                      _latestStatus?.soilMoisturePercent != null) ...[
                    WaterShortageBanner(
                      plantName: _plant?.nickname,
                      soilMoisturePercent: _latestStatus!.soilMoisturePercent!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_latestStatus?.isTooWet == true &&
                      _latestStatus?.soilMoisturePercent != null) ...[
                    SoilMoistureSufficientBanner(
                      soilMoisturePercent: _latestStatus!.soilMoisturePercent!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildMainCard(statusMsg),
                  const SizedBox(height: 32),
                  _buildSectionTitle('성장 정보'),
                  const SizedBox(height: 12),
                  _buildGrowthInfoCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('장착 화분'),
                  const SizedBox(height: 12),
                  _buildPotCard(),
                  const SizedBox(height: 24),
                  _buildIotCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('자동화 관리'),
                  const SizedBox(height: 12),
                  AutomationSection(userPlantId: widget.userPlantId),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          if (_plant!.status != 'HARVESTED') _buildBottomAction(),
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink));
  }

  // 썸네일 라벨 — 캡처 사진이면 촬영 날짜, 아니면 기본 이미지
  String _capturedLabel() {
    final captured = DateTime.tryParse(_latestImageData?.capturedAt ?? '');
    if (_latestImageData?.imageUrl == null || captured == null) return '기본 이미지';
    return '${captured.month}월 ${captured.day}일 촬영';
  }

  // 화면 섹션 렌더링
  Widget _buildMainCard(String statusMsg) {
    final displayUrl = getPlantThumbnailUrl(
      capturedImageUrl: _latestImageData?.imageUrl,
      fallbackImageUrl: _plant!.imageUrl,
    );

    return GreenlinkCard(
      borderRadius: 24,
      padding: EdgeInsets.zero,
      color: AppColors.canvasSoft,
      child: Column(
        children: [
          // Image area
          Container(
            width: double.infinity,
            height: 240,
            decoration: const BoxDecoration(
              color: AppColors.canvasSoft,
              borderRadius: BorderRadius.vertical(top: Radius.circular(23)),
            ),
            child: Stack(
              children: [
                Center(
                  child: displayUrl != null
                      ? Image.network(
                          displayUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.eco_rounded, size: 80, color: AppColors.primaryStrong),
                        )
                      : const Icon(Icons.eco_rounded, size: 80, color: AppColors.primaryStrong),
                ),
                // Image type label
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.canvas.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: Text(
                      _capturedLabel(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.bodyMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(23)),
              border: Border(top: BorderSide(color: AppColors.hairline)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_plant!.nickname, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.3)),
                          const SizedBox(height: 2),
                          Text(_plant!.plantName, style: const TextStyle(fontSize: 14, color: AppColors.bodyMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _plant!.status == 'HARVESTABLE' ? AppColors.primarySoft : AppColors.canvasGreenTint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusMsg,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _plant!.status == 'HARVESTABLE' ? AppColors.primaryStrong : AppColors.bodyMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_capturedAt != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '최근 촬영: ${_formatDateTimeStr(_capturedAt)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.bodySoft),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildGrowthInfoCard() {
    return GreenlinkCard(
      child: Column(
        children: [
          _InfoRow(label: '식물 종류', value: _plant!.plantName),
          const _Hairline(),
          _InfoRow(label: '함께한 지', value: '${_plant!.daysAfterPlanting ?? 0}일째'),
          const _Hairline(),
          _InfoRow(label: '심은 날짜', value: _formatDate(_plant!.plantedAt)),
          if (_plant!.status == 'HARVESTED') ...[
            const _Hairline(),
            _InfoRow(label: '수확 날짜', value: _formatDate(_plant!.harvestedAt)),
          ] else if (_plant!.remainingDays != null && _plant!.remainingDays! > 0) ...[
            const _Hairline(),
            _InfoRow(label: '수확까지', value: '${_plant!.remainingDays}일 남음', valueColor: AppColors.primaryStrong),
          ],
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildPotCard() {
    if (_plant!.equippedPot == null) {
      return GreenlinkCard(
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.canvasGreenTint, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.inventory_2_outlined, color: AppColors.bodyMuted, size: 22),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('장착한 화분이 없어요', style: TextStyle(fontSize: 15, color: AppColors.ink, fontWeight: FontWeight.w500)),
                  SizedBox(height: 2),
                  Text('인벤토리에서 화분을 장착해보세요', style: TextStyle(fontSize: 13, color: AppColors.bodyMuted)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final pot = _plant!.equippedPot!;
    return GreenlinkCard(
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: AppColors.canvasGreenTint, borderRadius: BorderRadius.circular(14)),
            child: pot.imageUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(pot.imageUrl!, fit: BoxFit.contain))
                : const Icon(Icons.inventory_2_rounded, color: AppColors.primaryStrong, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(20)),
                  child: const Text('장착 중', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primaryStrong)),
                ),
                const SizedBox(height: 6),
                Text(pot.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildIotCard() {
    return GreenlinkCard(
      color: AppColors.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.primaryOnDark.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.sensors_rounded, color: AppColors.primaryOnDark, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('IoT 모니터링', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.bodyOnDark)),
                    SizedBox(height: 2),
                    Text('온도·습도·조도·토양수분 및 실시간 제어', style: TextStyle(fontSize: 13, color: AppColors.bodyMutedOnDark)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => IotStatusPage(userPlantId: widget.userPlantId, plantName: _plant?.nickname ?? '식물')),
                );
                // IoT 화면에서 물을 주거나 새로고침했을 수 있으므로 배너·썸네일을 다시 불러온다.
                if (mounted) _loadLatestImage();
              },
              icon: const Icon(Icons.monitor_heart_outlined, size: 18),
              label: const Text('IoT 상태 보기', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOnDark.withValues(alpha: 0.15),
                foregroundColor: AppColors.primaryOnDark,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildBottomAction() {
    final isHarvestable = _plant!.status == 'HARVESTABLE';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: GreenlinkButton(
        text: isHarvestable ? '수확하기' : '아직 더 자라야 해요',
        isLoading: _isHarvesting,
        type: isHarvestable ? ButtonType.primary : ButtonType.disabled,
        onPressed: isHarvestable && !_isHarvesting ? _harvestPlant : null,
      ),
    );
  }
}

// _InfoRow — 내부 위젯
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: AppColors.bodyMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// _Hairline — 내부 위젯
class _Hairline extends StatelessWidget {
  const _Hairline();
  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.hairline);
  }
}

// _EditNameSheet — 이름 수정 바텀시트 (입력 컨트롤러 수명 관리)
class _EditNameSheet extends StatefulWidget {
  final String initialName;

  const _EditNameSheet({required this.initialName});

  // State 객체 생성
  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

// _EditNameSheetState — 화면 상태와 이벤트 처리
class _EditNameSheetState extends State<_EditNameSheet> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialName);

  // 리소스 정리
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('이름 수정하기', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 6),
          const Text('식물 친구에게 새로운 이름을 지어주세요', style: TextStyle(fontSize: 14, color: AppColors.bodyMuted)),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(fontSize: 16, color: AppColors.ink),
            decoration: const InputDecoration(hintText: '새로운 이름'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _nameController.text.trim()),
                  child: const Text('저장'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
