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
| `docker-compose.prod.yml` | `app`(Spring Boot, 768MB 상한) + `db`(MySQL 8, 512MB 상한, healthcheck 후 app 시작) |
| `.env.example` | `.env` 템플릿. 실제 `.env`는 커밋하지 않음 |

DB는 컨테이너 내부(`db:3306`)에서만 쓰고 포트를 열지 않습니다. 앱은 `127.0.0.1:8085`에만 열려 Cloudflare 터널로만 공개됩니다. 빈 DB로 처음 뜰 때 기본 식물·가입 지급 아이템과 최초 관리자(`.env`에 지정 시)가 자동 생성됩니다.

## 1. 맥북: `.env` 만들기

```bash
cp .env.example .env
# 값 채우기 — 비밀값은 openssl rand 로 생성
```

필수: `DB_PASSWORD`, `DB_ROOT_PASSWORD`, `JWT_SECRET`, `GREENLINK_AI_WORKER_SECRET`, `S3_BUCKET`, `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, OAuth client 값. 학교 서버에는 AWS IAM role이 없으므로 `greenlink/userplant/` prefix에 `s3:PutObject`만 허용한 IAM 사용자 키를 씁니다.

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

## 다른 구성요소가 새 주소를 쓰도록 바꾸기

| 구성요소 | 설정 | 값 |
| --- | --- | --- |
| Flutter 앱 | 빌드 시 `--dart-define=GREENLINK_API_BASE_URL=https://greenlink.likepigs.shop/api` (기본값은 예전 주소) | API base URL |
| Raspberry Pi | `greenlink.env`의 `GREENLINK_BASE_URL` | `https://greenlink.likepigs.shop` |
| ESP32 | `secrets.ini`의 `GREENLINK_SERVER_URL` | `https://greenlink.likepigs.shop/api/iot/esp/soil-moisture` (HTTPS 인증서 검증은 실기기 확인 필요) |
| AI Worker | `.env`의 `BACKEND_BASE_URL` | `https://greenlink.likepigs.shop` |

## 코드 업데이트

```bash
ssh -o ClearAllForwardings=yes winserver "wsl -d Ubuntu -u geung -- bash -lc 'cd ~/projects/greenlink && git pull && docker compose -f docker-compose.prod.yml up -d --build && docker image prune -f'"
```

## 메모리 예산

app 768MB + db 512MB = 최대 약 1.3GB. WSL 여유(약 4.6GB) 안에 들어갑니다. AI Worker(rembg 모델 포함)는 1GB 이상 쓰므로 같은 서버에 올릴지는 따로 판단합니다.
