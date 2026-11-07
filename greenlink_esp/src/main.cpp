#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <math.h>

// =====================================================
// 1. Wi-Fi 및 서버 설정
// =====================================================
//
// Wi-Fi 자격 정보, 서버 주소, 장치 키는 소스에 두지 않는다.
// secrets.ini의 build_flags로 주입하며, 없으면 빌드 단계에서 실패한다.
// 보드마다 Backend에 등록된 DEVICE_KEY로 빌드한다.
// 자세한 내용은 secrets.ini.example 참고.

#ifndef GREENLINK_WIFI_SSID
#error "GREENLINK_WIFI_SSID 빌드 플래그가 필요합니다. secrets.ini를 확인하세요."
#endif

#ifndef GREENLINK_WIFI_PASSWORD
#error "GREENLINK_WIFI_PASSWORD 빌드 플래그가 필요합니다. secrets.ini를 확인하세요."
#endif

#ifndef GREENLINK_SERVER_URL
#error "GREENLINK_SERVER_URL 빌드 플래그가 필요합니다. secrets.ini를 확인하세요."
#endif

#ifndef GREENLINK_DEVICE_KEY
#error "GREENLINK_DEVICE_KEY 빌드 플래그가 필요합니다. secrets.ini를 확인하세요."
#endif

const char* WIFI_SSID = GREENLINK_WIFI_SSID;
const char* WIFI_PASSWORD = GREENLINK_WIFI_PASSWORD;

const char* SERVER_URL = GREENLINK_SERVER_URL;
const char* DEVICE_KEY = GREENLINK_DEVICE_KEY;


// =====================================================
// 3. 핀 설정
// =====================================================

const int SOIL_SENSOR_PIN = 34;


// =====================================================
// 4. 센서 보정값 설정
// =====================================================
//
// 토양수분센서는 보통:
// raw 값이 클수록 건조
// raw 값이 작을수록 습함
//
// 계산식:
// percent = (DRY_RAW - raw) / (DRY_RAW - WET_RAW) * 100
//
// 주의:
// 공기 중 raw 값은 센서 정상 확인용이고,
// 실제 계산에는 "마른 흙 raw"와 "충분히 젖은 흙 raw"를 사용한다.
//
// 기존 센서 기준 측정값 (참고용):
// 공기 중: 2783, 2781
// 마른 흙: 2213, 2224
// 젖은 흙: 1711, 1710
// 물 더 줌: 1438, 1461
//
// 실제 DB에 최근 들어온 raw 값이 1420~1423이었으므로,
// WET_RAW = 1710으로 두면 현재 raw가 WET_RAW보다 작아져서
// percent가 100%로 계속 잘리는 문제가 생긴다.
//
// 그래서 현재 운영 기준에서는 충분히 젖은 상태를 1400 근처로 잡는다.
//
// 보정값은 센서마다 다르므로 소스에 고정하지 않고 secrets.ini의 build_flags로 주입한다.
// 보드를 바꿔 빌드할 때 소스를 수정할 필요가 없다.

#ifndef GREENLINK_DRY_RAW
#error "GREENLINK_DRY_RAW 빌드 플래그가 필요합니다. secrets.ini를 확인하세요."
#endif

#ifndef GREENLINK_WET_RAW
#error "GREENLINK_WET_RAW 빌드 플래그가 필요합니다. secrets.ini를 확인하세요."
#endif

const int DRY_RAW = GREENLINK_DRY_RAW;
const int WET_RAW = GREENLINK_WET_RAW;

// 센서 이탈/고장 판정 — 이 범위를 벗어난 raw는 서버로 보내지 않는다.
// 흙에서 빠진 센서는 공기 중 값(DRY_RAW보다 훨씬 큼)을 내므로 0%로 clamp해 보내면
// 백엔드 자동 급수가 반복될 수 있다. 기본값은 DRY_RAW에서 보정 구간 한 폭만큼 더 건조한 값.
#ifdef GREENLINK_SENSOR_FAULT_RAW
const int SENSOR_FAULT_RAW = GREENLINK_SENSOR_FAULT_RAW;
#else
const int SENSOR_FAULT_RAW = GREENLINK_DRY_RAW + (GREENLINK_DRY_RAW - GREENLINK_WET_RAW);
#endif

// ADC 양 끝값 — 단선(0 근처) 또는 포화(4095 근처)
const int ADC_MIN_VALID_RAW = 50;
const int ADC_MAX_VALID_RAW = 4045;


// =====================================================
// 5. 측정 및 전송 설정
// =====================================================

const int SAMPLE_COUNT = 10;

// 테스트용: 10초마다 전송
//const unsigned long SEND_INTERVAL_MS = 10UL * 1000UL;

// 실제 운영용: 10분마다 전송
const unsigned long SEND_INTERVAL_MS = 10UL * 60UL * 1000UL;

unsigned long lastSendTime = 0;


// =====================================================
// 6. 함수 선언
// =====================================================

void connectWiFi();
void ensureWiFiConnected();

int readSoilRaw();
double convertRawToPercent(int raw);
bool isSensorReadingValid(int raw);

String createJsonBody(int soilRaw, double soilPercent);
bool sendSoilMoistureData(int soilRaw, double soilPercent);

void measureAndSend();


// =====================================================
// 7. setup
// =====================================================

void setup() {
    Serial.begin(115200);
    delay(1000);

    Serial.println();
    Serial.println("====================================");
    Serial.println("GreenLink ESP32 Soil Moisture 시작");
    Serial.println("====================================");

    Serial.print("SOIL_SENSOR_PIN: ");
    Serial.println(SOIL_SENSOR_PIN);

    Serial.print("DRY_RAW: ");
    Serial.println(DRY_RAW);

    Serial.print("WET_RAW: ");
    Serial.println(WET_RAW);

    if (DRY_RAW <= WET_RAW) {
        Serial.println("[ERROR] DRY_RAW는 WET_RAW보다 커야 합니다.");
        Serial.println("[ERROR] 보정값을 다시 확인하세요.");
    }

    analogReadResolution(12);
    analogSetPinAttenuation(SOIL_SENSOR_PIN, ADC_11db);

    connectWiFi();

    measureAndSend();

    lastSendTime = millis();
}


// =====================================================
// 8. loop
// =====================================================

void loop() {
    unsigned long currentTime = millis();

    if (currentTime - lastSendTime >= SEND_INTERVAL_MS) {
        measureAndSend();
        lastSendTime = currentTime;
    }

    delay(1000);
}


// =====================================================
// 9. 토양수분 raw 값 읽기
// =====================================================

int readSoilRaw() {
    long sum = 0;

    Serial.println();
    Serial.println("[RAW 샘플 측정 시작]");

    for (int i = 0; i < SAMPLE_COUNT; i++) {
        int value = analogRead(SOIL_SENSOR_PIN);

        Serial.print("sample ");
        Serial.print(i + 1);
        Serial.print(": ");
        Serial.println(value);

        sum += value;
        delay(50);
    }

    int average = (int)(sum / SAMPLE_COUNT);

    Serial.print("[RAW 평균] ");
    Serial.println(average);

    return average;
}


// =====================================================
// 10. raw 값을 percent로 변환
// =====================================================

double convertRawToPercent(int raw) {
    if (DRY_RAW == WET_RAW) {
        Serial.println("[ERROR] DRY_RAW와 WET_RAW가 같습니다. 보정값을 다시 확인하세요.");
        return 0.0;
    }

    double percent = ((double)(DRY_RAW - raw) / (double)(DRY_RAW - WET_RAW)) * 100.0;

    if (raw > DRY_RAW) {
        Serial.println("[WARN] raw가 DRY_RAW보다 큽니다. 0%로 보정합니다.");
    }

    if (raw < WET_RAW) {
        Serial.println("[WARN] raw가 WET_RAW보다 작습니다. 100%로 보정합니다.");
    }

    if (percent < 0.0) {
        percent = 0.0;
    }

    if (percent > 100.0) {
        percent = 100.0;
    }

    return round(percent * 10.0) / 10.0;
}


// 센서 값 유효성 — 보정값 오류, ADC 양 끝값, 공기 중 값이면 false
bool isSensorReadingValid(int raw) {
    if (DRY_RAW <= WET_RAW) {
        Serial.println("[ERROR] DRY_RAW <= WET_RAW 보정값 오류");
        return false;
    }

    if (raw < ADC_MIN_VALID_RAW || raw > ADC_MAX_VALID_RAW) {
        Serial.print("[ERROR] ADC 범위 이상값: ");
        Serial.println(raw);
        return false;
    }

    if (raw > SENSOR_FAULT_RAW) {
        Serial.print("[ERROR] 센서가 흙에서 빠졌거나 접촉 불량으로 보입니다. raw=");
        Serial.print(raw);
        Serial.print(", SENSOR_FAULT_RAW=");
        Serial.println(SENSOR_FAULT_RAW);
        return false;
    }

    return true;
}


// =====================================================
// 11. JSON Body 생성
// =====================================================

String createJsonBody(int soilRaw, double soilPercent) {
    String jsonBody = "{";
    jsonBody += "\"soilMoistureRaw\":";
    jsonBody += soilRaw;
    jsonBody += ",";
    jsonBody += "\"soilMoisturePercent\":";
    jsonBody += String(soilPercent, 1);
    jsonBody += "}";

    return jsonBody;
}


// =====================================================
// 12. Spring Boot 서버로 데이터 전송
// =====================================================

bool sendSoilMoistureData(int soilRaw, double soilPercent) {
    ensureWiFiConnected();

    HTTPClient http;
    WiFiClient plainClient;
    WiFiClientSecure secureClient;

    http.setTimeout(5000);

    // 운영 서버는 Cloudflare 터널 HTTPS(https://greenlink.likepigs.shop)다.
    // ESP32에 루트 인증서를 넣고 갱신하기 어려워 인증서 검증은 생략한다(암호화는 유지).
    // 장치 키가 헤더로 가므로 http:// 주소는 학교 내부망 점검용으로만 쓴다.
    bool beginOk;
    if (String(SERVER_URL).startsWith("https://")) {
        secureClient.setInsecure();
        beginOk = http.begin(secureClient, SERVER_URL);
    } else {
        beginOk = http.begin(plainClient, SERVER_URL);
    }

    if (!beginOk) {
        Serial.println("[서버 전송 실패] SERVER_URL을 해석할 수 없습니다. secrets.ini를 확인하세요.");
        return false;
    }

    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-DEVICE-KEY", DEVICE_KEY);

    String jsonBody = createJsonBody(soilRaw, soilPercent);

    Serial.println();
    Serial.println("====================================");
    Serial.println("[서버 전송 시작]");
    Serial.print("SERVER_URL: ");
    Serial.println(SERVER_URL);
    Serial.println("[전송 JSON]");
    Serial.println(jsonBody);
    Serial.println("====================================");

    int httpResponseCode = http.POST(jsonBody);

    if (httpResponseCode > 0) {
        String responseBody = http.getString();

        Serial.print("HTTP Code: ");
        Serial.println(httpResponseCode);

        Serial.print("Response: ");
        Serial.println(responseBody);

        http.end();

        if (httpResponseCode >= 200 && httpResponseCode < 300) {
            Serial.println("[서버 전송 성공]");
            return true;
        }

        Serial.println("[서버 전송 실패]");
        return false;
    }

    Serial.print("HTTP Error: ");
    Serial.println(http.errorToString(httpResponseCode));

    http.end();

    return false;
}


// =====================================================
// 13. 측정 후 서버 전송
// =====================================================

void measureAndSend() {
    int raw = readSoilRaw();

    if (!isSensorReadingValid(raw)) {
        Serial.println("[전송 생략] 센서 이탈 또는 고장으로 판단되어 이번 측정값을 보내지 않습니다.");
        return;
    }

    double percent = convertRawToPercent(raw);

    Serial.println();
    Serial.println("====================================");
    Serial.println("[측정 결과]");

    Serial.print("DRY_RAW: ");
    Serial.println(DRY_RAW);

    Serial.print("WET_RAW: ");
    Serial.println(WET_RAW);

    Serial.print("soilMoistureRaw: ");
    Serial.println(raw);

    Serial.print("soilMoisturePercent: ");
    Serial.print(percent, 1);
    Serial.println("%");

    if (raw > DRY_RAW) {
        Serial.println("[판단] 기준상 매우 건조 또는 공기 중/접촉 불량 가능성");
    } else if (raw < WET_RAW) {
        Serial.println("[판단] 기준상 매우 젖음 또는 과습 가능성");
    } else {
        Serial.println("[판단] dryRaw와 wetRaw 사이 정상 범위");
    }

    Serial.println("====================================");

    sendSoilMoistureData(raw, percent);
}


// =====================================================
// 14. Wi-Fi 연결
// =====================================================

void connectWiFi() {
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    Serial.println();
    Serial.println("====================================");
    Serial.println("[Wi-Fi 연결 시도]");
    Serial.print("SSID: ");
    Serial.println(WIFI_SSID);
    Serial.println("====================================");

    int retryCount = 0;

    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");

        retryCount++;

        if (retryCount >= 60) {
            Serial.println();
            Serial.println("[Wi-Fi 연결 실패] ESP32를 재시작합니다.");
            ESP.restart();
        }
    }

    Serial.println();
    Serial.print("[Wi-Fi 연결 성공] IP: ");
    Serial.println(WiFi.localIP());
}


// =====================================================
// 15. Wi-Fi 연결 상태 확인
// =====================================================

void ensureWiFiConnected() {
    if (WiFi.status() == WL_CONNECTED) {
        return;
    }

    Serial.println("[Wi-Fi 끊김] 재연결 시도");
    connectWiFi();
}