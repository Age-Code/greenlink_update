# Tugether(tutoring) 웹 배포 — Flutter 웹으로 빌드한 뒤 nginx로 서빙
# 백엔드는 Firebase(Auth/Firestore)라서 서버에는 정적 파일만 올라간다.

# 1) 빌드: .fvmrc 에 고정된 Flutter 3.29.3 (공식 릴리스 압축파일을 받아 씀)
FROM debian:bookworm-slim AS build
ARG FLUTTER_VERSION=3.29.3
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C /opt \
 && git config --global --add safe.directory /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}" \
    FLUTTER_SUPPRESS_ANALYTICS=true
RUN flutter config --no-analytics --enable-web >/dev/null && flutter precache --web

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
# --no-web-resources-cdn: 렌더링 엔진(CanvasKit)을 gstatic CDN 대신 우리 서버에서 받게 함
RUN flutter build web --release --no-web-resources-cdn

# 2) 실행: nginx (메모리 수십 MB)
FROM nginx:1.27-alpine
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
