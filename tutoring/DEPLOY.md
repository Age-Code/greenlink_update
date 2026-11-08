# Tugether(tutoring) 학교 서버 배포

「학교 서버 배포 가이드 (맥북 → winserver → Cloudflare)」를 이 프로젝트 값으로 채운 버전입니다.
명령은 그대로 복사해 붙여넣으면 됩니다.

| 항목 | 값 |
|---|---|
| 서비스 이름 | `tutoring` |
| 서버 포트 | `8086` (8083 crabcycle, 8085 greenlink 사용 중) |
| 공개 주소 | `tutoring.likepigs.shop` |
| 앱 내부 포트 | `80` (nginx) |
| 코드 위치 | `Age-Code/greenlink_update` 저장소의 `tutoring/` 폴더 |

## 이 앱이 다른 서비스와 다른 점

- Flutter **웹 앱**이고 서버(DB, 로그인)는 **Firebase**(`tugether-a3dea`)가 맡습니다.
  학교 서버는 빌드된 정적 파일만 nginx로 내보내므로 **`.env`와 DB가 필요 없습니다** (2단계의 scp 생략).
- 실행 중 메모리는 약 5MB(상한 64MB)입니다. 다만 **첫 빌드**에는 Flutter SDK를 받아 컴파일하느라
  몇 분과 메모리 2GB 안팎, 디스크 3GB 정도가 듭니다.
- 배포 파일: `Dockerfile`, `docker-compose.prod.yml`, `.dockerignore`, `deploy/nginx.conf`

## 0. (한 번만) Firebase에 주소 등록

Google 로그인을 하려면 Firebase가 새 주소를 허용해야 합니다. 안 하면 `unauthorized-domain` 오류가 납니다.
Firebase 프로젝트 소유자가 다음을 해야 합니다.

Firebase Console → `tugether-a3dea` → Authentication → Settings → **Authorized domains** → Add domain → `tutoring.likepigs.shop`

## 1~2단계 · 서버에 코드 받기

`ssh winserver` 로 접속한 뒤 `wsl` 을 입력하고, 서버 WSL에서 아래를 실행합니다.

```bash
ss -ltn | grep -q ':8086 ' && echo "8086 사용 중! 다른 포트를 골라야 함" || echo "8086 비어 있음"
cd ~/projects
git clone -b claude/magical-bell-3bmk3s git@github.com:Age-Code/greenlink_update.git tutoring-src
ls ~/projects/tutoring-src/tutoring
```

`Permission denied (publickey)` 가 나오면 가이드 2단계대로 Deploy key를 만듭니다. 이름은 `deploy_tutoring`, Host는 `github-tutoring` 으로 하고, 저장소 `Age-Code/greenlink_update` 에 등록합니다. 그다음 아래처럼 받습니다.
`git clone -b claude/magical-bell-3bmk3s git@github-tutoring:Age-Code/greenlink_update.git tutoring-src`

> 브랜치가 main에 합쳐지면 `cd ~/projects/tutoring-src && git checkout main && git pull` 로 바꿔 둡니다.

## 3단계 · 빌드하고 실행

```bash
cd ~/projects/tutoring-src/tutoring
docker compose -p tutoring -f docker-compose.prod.yml up -d --build
docker compose -p tutoring -f docker-compose.prod.yml ps
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8086/
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8086/login
```

둘 다 `200` 이면 정상입니다. `000` 이면 `docker compose -p tutoring -f docker-compose.prod.yml logs --tail 100` 으로 확인합니다.
`-p tutoring` 은 폴더 이름과 관계없이 compose 프로젝트 이름을 `tutoring` 으로 고정합니다.

## 4단계 · 재부팅 때 자동 시작

```bash
sudo cp /usr/local/bin/wsl-boot.sh /usr/local/bin/wsl-boot.sh.bak
sudo sed -i '/^sleep infinity/i cd /home/geung/projects/tutoring-src/tutoring \&\& docker compose -p tutoring -f docker-compose.prod.yml up -d' /usr/local/bin/wsl-boot.sh
cat /usr/local/bin/wsl-boot.sh
```

새 줄이 `sleep infinity` 바로 위에 있고, `sleep infinity` 가 마지막 줄이면 됩니다.

## 5단계 · Cloudflare 주소 등록과 터널 규칙

가이드 5단계 블록을 **첫 줄만 아래로 바꿔서** 그대로 실행합니다.

```bash
APP=tutoring; PORT=8086
```

## 6단계 · 터널 재시작

가이드 6단계를 그대로 실행합니다. 이 프로젝트 때문에 바꿀 값은 없습니다.

## 7단계 · 외부에서 확인 (맥 터미널)

```bash
curl -I https://tutoring.likepigs.shop
```

`200` 이 나오면 브라우저로 열어 로그인까지 해 봅니다.

## 이후 · 코드 업데이트

이 저장소에 push한 뒤 맥에서 실행합니다.

```bash
ssh -o ClearAllForwardings=yes winserver "wsl -d Ubuntu -u geung -- bash -lc 'cd ~/projects/tutoring-src && git pull && cd tutoring && docker compose -p tutoring -f docker-compose.prod.yml up -d --build && docker image prune -f'"
```

빌드 캐시(Flutter SDK 등)가 디스크를 많이 차지하면 `docker builder prune -f` 로 정리합니다.
원본 저장소(`jonghyekim/tutoring`)가 바뀌어도 여기에 자동으로 반영되지는 않습니다. 새 코드를 이 `tutoring/` 폴더에 덮어쓰고 push해야 합니다.

## 서버 닫기

```bash
cd ~/projects/tutoring-src/tutoring && docker compose -p tutoring -f docker-compose.prod.yml down --rmi local
cd ~ && rm -rf ~/projects/tutoring-src
sudo sed -i "/\/projects\/tutoring-src\//d" /usr/local/bin/wsl-boot.sh
```

Cloudflare 설정은 가이드의 「서버 닫기」 뒷부분에서 `APP=tutoring` 으로 지웁니다. 그다음 6단계로 터널을 재시작하고, 대시보드에서 DNS 레코드를 지웁니다.

## 문제 해결

| 증상 | 원인 | 해결 |
|---|---|---|
| 흰 화면만 나옴 | Firebase 초기화 실패 | 브라우저 개발자도구 Console 확인. 네트워크가 `gstatic.com` 을 막는지 확인 |
| Google 로그인 `unauthorized-domain` | Firebase에 주소 미등록 | 0단계 |
| 새 버전이 안 보임 | 브라우저 캐시 | 강력 새로고침(Cmd+Shift+R). `index.html` 등은 캐시하지 않도록 설정돼 있음 |
| 빌드 중 `Killed` / Exit 137 | 빌드 메모리 부족 | 다른 컨테이너가 많이 쓰는지 `docker stats` 확인 후 다시 빌드 |
| 502 / 530 / 404 | 터널 문제 | 가이드 7단계 표 참고 (포트 8086) |
