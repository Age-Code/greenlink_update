# GreenLink Backend 배포 (맥북 → winserver → Cloudflare)

학교 서버 배포 가이드(맥북 → winserver WSL Docker → Cloudflare 터널) 형식에 맞춘 GreenLink 백엔드 배포 절차입니다. 이 저장소는 모노레포라서 compose 파일은 **저장소 루트**에, Dockerfile은 `greenlink_back/`에 있습니다.

## 정한 값

| 항목 | 값 | 비고 |
| --- | --- | --- |
| 서비스 이름 | `greenlink` | 서버 폴더 `~/projects/greenlink`, compose 프로젝트 이름 |
| 서버 포트 | `8085` | `.env`의 `GREENLINK_PORT`로 변경 가능. 8081, 8082, 8084~8099 중 미사용 |
| 공개 주소 | `greenlink.likepigs.shop` | 사용 중 이름(win-ssh, win-api, crabcycle, mc, ssh, stock, mac)과 겹치지 않음 |
| 앱 내부 포트 | `8080` | Spring Boot |

## 저장소에 있는 배포 파일

| 파일 | 역할 |
| --- | --- |
| `greenlink_back/Dockerfile` | Java 17로 `bootJar` 빌드 후 JRE 이미지로 실행 |
| `greenlink_back/.dockerignore` | 빌드 산출물, 키 파일 제외 |
| `docker-compose.prod.yml` | `app`(Spring Boot, 768MB 상한, 사진 볼륨 `images`) + `db`(MySQL 8, 512MB 상한, healthcheck 후 app 시작) |
| `.env.example` | `.env` 템플릿. 실제 `.env`는 커밋하지 않음 |

DB는 컨테이너 내부(`db:3306`)에서만 쓰고 포트를 열지 않습니다. 앱은 `127.0.0.1:8085`에만 열려 Cloudflare 터널로만 공개됩니다. 빈 DB로 처음 뜰 때 기본 식물·가입 지급 아이템과 최초 관리자(`.env`에 지정 시)가 자동 생성됩니다.

## 1. 맥북: `.env` 만들기

```bash
cp .env.example .env
# 값 채우기 — 비밀값은 openssl rand 로 생성
```

필수: `DB_PASSWORD`, `DB_ROOT_PASSWORD`, `JWT_SECRET`, OAuth client 값. 식물 사진은 Docker 볼륨(`images`, 컨테이너 `/data/images`)에 저장되며 `GREENLINK_IMAGE_RETENTION_DAYS`(기본 30일)가 지난 사진은 매일 04시에 정리됩니다(식물별 최신 사진은 유지).

(선택) 맥에서 미리 확인:

```bash
docker compose -f docker-compose.prod.yml up --build
curl -I http://localhost:8085/api/plants
docker compose -f docker-compose.prod.yml down
```

## 2. 서버에 코드와 `.env` 올리기

```bash
scp .env winserver:greenlink.env
ssh winserver
```

```bash
wsl
cd ~/projects
git clone git@github.com:Age-Code/greenlink_update.git greenlink
mv /mnt/c/Users/user/greenlink.env ~/projects/greenlink/.env
chmod 600 ~/projects/greenlink/.env
```

비공개 저장소라 `Permission denied (publickey)`가 나오면 학교 서버 가이드의 Deploy key 절차(`deploy_greenlink`, `Host github-greenlink`)를 따른 뒤 `git clone git@github-greenlink:Age-Code/greenlink_update.git greenlink`로 받습니다.

## 3. 빌드하고 실행

```bash
cd ~/projects/greenlink
docker compose -f docker-compose.prod.yml up -d --build
docker compose -f docker-compose.prod.yml logs -f --tail 100 app   # "Started GreenlinkApplication" 확인 후 Ctrl+C
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8085/api/plants   # 200이면 정상
```

## 4. 재부팅 자동 시작

```bash
sudo cp /usr/local/bin/wsl-boot.sh /usr/local/bin/wsl-boot.sh.bak
sudo sed -i '/^sleep infinity/i cd /home/geung/projects/greenlink \&\& docker compose -f docker-compose.prod.yml up -d' /usr/local/bin/wsl-boot.sh
cat /usr/local/bin/wsl-boot.sh
```

## 5~6. Cloudflare 주소 등록과 터널 재시작

학교 서버 가이드 5·6단계를 `APP=greenlink; PORT=8085`로 실행합니다. 백엔드는 Cloudflare가 HTTPS를 처리하고 `X-Forwarded-*` 헤더를 넘기므로 `server.forward-headers-strategy: framework`로 리다이렉트가 `https://greenlink.likepigs.shop`으로 만들어집니다.

## 7. 외부 확인

```bash
curl -I https://greenlink.likepigs.shop/api/plants
```

관리자 페이지: `https://greenlink.likepigs.shop/admin/login` — 최초 관리자로 로그인을 확인한 뒤 `.env`에서 `GREENLINK_BOOTSTRAP_ADMIN_*` 두 줄을 지우고 `docker compose -f docker-compose.prod.yml up -d --force-recreate`.

## 장치 연결 (재배기 1대 = 식물 1개)

순서가 중요합니다. 백엔드에 식물이 있어야 장치를 그 식물에 연결할 수 있습니다.

1. **앱에서 식물 심기**: 앱(기본 API 주소가 `https://greenlink.likepigs.shop/api`)으로 실제 사용할 계정에 가입하고, 지급된 바질 씨앗을 심습니다. 식물 상세 화면 또는 관리자 대시보드에서 `userPlantId`를 확인합니다.
2. **백엔드에 장치 등록 + 설정 파일 생성** (맥, 저장소 루트):
   ```bash
   python3 scripts/setup_iot.py --user-plant-id <userPlantId>
   ```
   - 관리자 계정은 루트 `.env`의 `GREENLINK_BOOTSTRAP_ADMIN_*`를 읽습니다(이미 지웠다면 `GREENLINK_ADMIN_EMAIL`/`GREENLINK_ADMIN_PASSWORD` 환경변수로 전달).
   - 재배 공간 `greenlink-grower-1`, 장치 `greenlink-pi`·`greenlink-esp`, 펌프 채널(GPIO 22)을 만들고 장치 키를 무작위로 생성합니다. 여러 번 실행해도 중복 등록하지 않습니다.
   - 생성 파일(커밋 금지): `greenlink_pi/greenlink.env`, `greenlink_esp/secrets.ini`.
3. **Raspberry Pi**: `greenlink_pi/greenlink.env`를 Pi의 `/home/greenlink/greenlink/greenlink.env`로 복사하고 서비스(`greenlink-command`, `greenlink-stream`)를 재시작합니다. 서비스 파일은 `greenlink_pi/systemd/`에 있습니다. cron은 `greenlink_pi/crontab.example`대로 등록합니다(센서 10분마다, **썸네일 캡처 매일 09:00**). 배선과 Pi 초기 설정(부팅 시 릴레이 OFF 고정 포함)은 [HARDWARE_WIRING.md](./HARDWARE_WIRING.md)를 따릅니다.
4. **ESP32**: `greenlink_esp/secrets.ini`에 Wi-Fi와 실측 보정값(DRY/WET_RAW)을 채운 뒤 `pio run -t upload`.
5. **카메라 스트림**: 예전 `camera.likepigs.shop` 터널은 없습니다. 앱 기본값은 `https://greenlink-camera.likepigs.shop`이므로, Pi에 cloudflared 터널을 만들고 이 주소를 `http://localhost:8000`으로 연결합니다(다른 주소를 쓰면 앱 빌드 시 `--dart-define=GREENLINK_STREAM_BASE_URL=...`). 인증 없는 영상이라 공개 범위는 Cloudflare Access 등으로 제한하는 것을 권장합니다.

## 수확 후 다시 심을 때

앱에서 식물을 수확한 뒤 같은 계정으로 새 씨앗을 심으면, Backend가 그 재배기(ESP 토양 센서·펌프 채널·사진 대상·자동화 설정)를 새 식물로 자동으로 옮깁니다. 장치 키나 Pi·ESP 설정 파일은 다시 만들지 않아도 됩니다. 다른 식물로 수동으로 옮기려면 `python3 scripts/setup_iot.py --user-plant-id <새 userPlantId>`를 실행합니다(내부적으로 `POST /api/iot/grow-spaces/{id}/replant` 호출).

## 구성요소별 서버 주소

| 구성요소 | 설정 | 값 |
| --- | --- | --- |
| Flutter 앱 | 기본값 (`--dart-define=GREENLINK_API_BASE_URL`로 변경 가능) | `https://greenlink.likepigs.shop/api` |
| Raspberry Pi | `greenlink.env`의 `GREENLINK_BASE_URL` | `https://greenlink.likepigs.shop` |
| ESP32 | `secrets.ini`의 `GREENLINK_SERVER_URL` | `https://greenlink.likepigs.shop/api/iot/esp/soil-moisture` (HTTPS 인증서 검증은 실기기 확인 필요) |

## 코드 업데이트

```bash
ssh -o ClearAllForwardings=yes winserver "wsl -d Ubuntu -u geung -- bash -lc 'cd ~/projects/greenlink && git pull && docker compose -f docker-compose.prod.yml up -d --build && docker image prune -f'"
```

## 메모리 예산

app 768MB + db 512MB = 최대 약 1.3GB. WSL 여유(약 4.6GB) 안에 들어갑니다. 사진은 하루 1장(수백 KB)이라 30일 보관 시 디스크 사용량은 수십 MB 수준입니다.
