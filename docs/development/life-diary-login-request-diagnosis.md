> **현재 상태 — 2026-11-25**
>
> 홈 개발 로그인과 Android 브라우저 콜백 연결은 구현되어 PR #14로 main에 병합됐습니다.
> 개발 로그인은 기본 비활성이며 debug opt-in입니다.
> `LIFE_DIARY_DEV_LOGIN=true`, `LIFE_DIARY_ONE_API_LOGIN=true`와
> 생명일기 전용 공개 `LIFE_DIARY_AUTH0_CLIENT_ID`를 사용합니다.
> `LIFE_DIARY_PERSIST_LOGIN=true`를 추가하면 Android 보안 저장소를 이용한
> 만료 전 세션 복구를 활성화합니다. PKCE 진행 정보 복구나 자동 세션 갱신은 아닙니다.
>
> 통합본에서 실제 로그인, 로그인 직후 프로세스 재시작 복구, 로그아웃 유지,
> 연결 차단 시 성공 표시 방지와 연결 복원 후 새 인증 없는 복구를 확인했습니다.
> 근거: [세션 복구 검증 기록](../reviews/2026-11-23-persistent-session.md).
> 로그인만으로 일기를 업로드하지 않습니다. 운영 배포·보안 감사 완료를 의미하지 않습니다.
>
> **아래 본문은 당시의 준비·진단 이력입니다.** 당시 NOT_RUN은 당시 결과로 유지합니다.
> 미구현·메모리 전용·검토 대기 설명과 ngrok/relay 구성은 현재 상태 안내로 사용하지 마세요.
> 과거 실행 명령과 일괄 파일 제거 방식의 롤백 명령은 그대로 실행하지 마세요.
> 합성 fixture 문서는 아직 main에 포함되지 않은 `tools/auth` 스크립트에 의존합니다.
> 실제 개발 서버와 fixture는 같은 8000 포트를 사용하므로 동시에 실행하지 않습니다.
> 시험 기기는 `NN_CommonAuth_Test`를 사용하며 기존 기록이 있는 기기의 데이터를 지우지 않습니다.

---

# Login request 진단 (2026-11-10)

- Flutter: `POST http://127.0.0.1:8000/api/v1/mobile/life-diary/login-transactions`.
- JSON 필드: `app_id`, `client_id`, `return_uri`, `challenge`. Accept/Content-Type은 application/json.
- 서버 대조: `JesusLife-One-API-ld-login/app/core/life_diary_login.py`의 `AppStart`, `start`, `command_binding` 및 `mobile_routes.py`의 `Start`와 일치한다. challenge는 43자 base64url, app_id는 life_diary, return_uri는 기존 Android 복귀 URI다. 실제 client_id 등록 일치는 확인하지 않았다.
- 성공 계약: 200 JSON object, UUID transaction, 로컬 authorize URL. 경로·필드·성공 상태의 불일치는 발견하지 못했다.
- 로컬 관측: 필수 필드 없는 `{}` POST는 HTTP 422. 본문을 읽거나 출력하지 않았으며 유효한 로그인 트랜잭션을 만들지 않았다. 호스트 접근 증거이며 에뮬레이터 Flutter 요청 성공의 증거는 아니다.
- Chrome에서 직접 연 콜백의 인증 거부는 로그인 시작 POST의 실패 원인을 증명하지 않는다.

## 재현 및 최소 수정

HTTP 거부·시간 초과·JSON 해석 실패가 동일한 오류로 가려지는 현상을 합성 transport로 재현했다. 전송 어댑터에서 고정 단계명과 HTTP 상태 코드만 전달하도록 수정했다. 응답 본문·원래 예외·인증 자료는 전달하지 않는다. 경로, 등록, 인증 검증, 재시도 정책은 변경하지 않았다. 기존 Content-Length 보완은 보존했다.

실제 앱의 반복 실패 원인은 미확정이다. 서버 401은 binding 불일치, 503은 runtime/등록 조건, 422는 입력 검증 등의 후보이나 실제 앱 관측 없이 확정하지 않는다.

## 검증

- PASS: `flutter test --no-pub --coverage --dart-define=LIFE_DIARY_DEV_LOGIN=true test/application/life_diary_one_api_auth_client_test.dart test/application/life_diary_dev_login_test.dart` — 16 tests.
- PASS: 같은 두 파일의 기본 비활성 모드 — 2 tests, 14 skipped.
- PASS: `git diff --check`.
- NOT_RUN: pub get(의존성 변경 없음), 저장 계약 validator(저장 계약 변경 없음), 전체 테스트·빌드·실기기·복구 실행(이번 전송 진단 범위 밖).
- PASS: 대상 두 파일 `dart analyze` — No issues found, 종료 0. 최초 sandbox 실행은 telemetry 파일 권한 오류로 종료 1이었고 승인된 재실행에서 성공했다.
- NOT_RUN: 전체 `flutter analyze --no-pub`는 출력 없이 대기하여 완료 결과를 확보하지 못했다. PASS로 간주하지 않는다.
- 실제 로그인, ngrok/Auth0 설정 변경, 서버 변경, commit/push/merge 없음. 기존 사용자 변경 보존.
