// 식물 썸네일 URL 유틸리티 — 매일 카메라 영상에서 캡처한 사진을 앱 썸네일로 사용

import '../network/api_client.dart';

// 서버가 내려주는 사진 경로를 표시용 URL로 변환
// 서버 디스크에 저장한 사진은 "/images/..." 상대 경로로 오므로 API 서버 주소를 붙인다.
String? resolveImageUrl(String? raw, {String? serverOrigin}) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  if (!raw.startsWith('/')) return null;
  return '${serverOrigin ?? ApiClient.serverOrigin}$raw';
}

// 식물 썸네일 결정 — 최근 캡처 사진 우선, 없으면 식물 기본 이미지
String? getPlantThumbnailUrl({
  required String? capturedImageUrl,
  String? fallbackImageUrl,
}) {
  return resolveImageUrl(capturedImageUrl) ?? resolveImageUrl(fallbackImageUrl);
}
