// 식물 이미지 URL 선택 유틸리티

// 홈 카드 이미지 URL 결정 — AI 이미지 우선
String? getHomePlantImageUrl({
  required String? aiImageUrl,
  required String? originalImageUrl,
}) {
  if (aiImageUrl != null && aiImageUrl.isNotEmpty) return aiImageUrl;
  if (originalImageUrl != null && originalImageUrl.isNotEmpty) {
    return originalImageUrl;
  }
  return null;
}

// 식물 상세 이미지 URL 결정 — 원본 이미지 우선
String? getDetailPlantImageUrl({
  required String? aiImageUrl,
  required String? originalImageUrl,
}) {
  if (originalImageUrl != null && originalImageUrl.isNotEmpty) {
    return originalImageUrl;
  }
  if (aiImageUrl != null && aiImageUrl.isNotEmpty) return aiImageUrl;
  return null;
}
