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

# 생명일기 개발 로그인 준비

상태: 부분 구현. 실제 로그인 연결은 **AUTHOR_REVIEW_REQUIRED**.

`lib/application/life_diary_dev_login.dart`는 앱에 연결하지 않은 DI 컨트롤러다.
기본 비활성이고 debug에서 `LIFE_DIARY_DEV_LOGIN=true`일 때만 시작/복귀를 허용한다.
이 플래그만으로 현재 앱에 로그인 버튼이나 네트워크 연결이 생기지는 않는다.
인증 상태는 메모리에만 유지되며 앱 종료 후 다시 로그인한다. 자동 교환 재시도는 없다.
브라우저·클라이언트·PKCE 생성은 주입 지점이며 실제 Android 구현은 아직 없다.
일기·임시저장·소유자 ID·동의·DB와 연결하지 않았고 업로드 기능도 없다.

## 읽기 전용 확인한 계약

원본: `D:/CHGO-VibeCodeing/JesusLife-One-API-ld-login/docs/life-diary-android-login-draft.md`,
`app/core/life_diary_login.py`, `app/core/mobile_routes.py`.

- 로컬 API: `http://127.0.0.1:8000/api/v1/mobile/life-diary`.
- POST `/login-transactions`: `app_id=life_diary`, 전용 `client_id`,
  `return_uri`, S256 `challenge`; 응답 `transaction`, `authorize_url`.
- 외부 브라우저로 `authorize_url`을 연다. Auth0 WebView/직접 토큰 교환은 사용하지 않는다.
- 앱 복귀 후보: `jesuslife-life-diary-poc://auth/complete/android`;
  쿼리는 `transaction`, 일회용 `code`다.
- POST `/session-exchange`: 같은 app/client/return 결합과
  `transaction`, `code`, `verifier`; 응답 `access_token`, `token_type=Bearer`,
  `sub`(내부 account_id), `expires_at`.
- GET `/session`: Bearer credential; 응답 `sub`, `app_id=life_diary`.
- POST `/logout`: Bearer credential; 204, 현재 앱의 해당 세션만 철회.
- 401: 불일치/만료/재사용, 422: 결합 누락, 503: 비활성/구성 오류.
  실패한 일회용 교환은 재사용하지 않고 새 로그인한다.

## 차단 사항과 제안

1. 초안은 복귀 URI를 “후보”로 명시한다. 위 URI를 개발용으로 확정하는 검토가 필요하다.
   승인 후 debug 전용 Android intent-filter에 scheme/host/path를 정확히 등록하고
   cold-start와 onNewIntent를 Flutter 콜백으로 전달하는 어댑터를 추가한다.
   main/release manifest는 변경하지 않는다.
2. 서버는 기본 비활성이고 전용 개발 client_id가 제공되지 않았다. 서버 담당자가
   등록/runtime 연결 및 전용 Auth0 client를 검토해야 한다. 서버 callback은
   `http://127.0.0.1:8000/api/v1/auth/callback/life-diary/android`이며 앱 복귀 URI와 다르다.
   API·Auth0·운영 설정은 이번 변경에서 수정하지 않았다.
3. 승인 후 고정 로컬 API에만 연결하는 HTTP 어댑터, 안전한 난수/S256 PKCE,
   외부 브라우저 실행, debug 전용 로컬 cleartext 허용과 ADB reverse를 준비한다.
   응답 app_id/토큰 종류/만료/형식을 검증하고 credential은 로그나 DB에 넣지 않는다.
4. 마지막으로 개발 로그인 화면을 연결한다. 로그인은 일기 이용 조건이 아니며,
   로컬 기록의 owner를 계정 ID로 바꾸거나 로그아웃 때 기록을 지우지 않는다.
   현재 컨트롤러를 연결 완료로 취급하지 않는다.

롤백: 새 컨트롤러와 테스트를 제거하면 된다. 기존 앱 경로와 저장소는 수정하지 않았다.
ChurchOS 진입은 직접 Android 로그인 검증 이후 별도 후속 작업이다.

## 오프라인 검증 명령

```powershell
flutter test --no-pub --coverage test/application/life_diary_dev_login_test.dart
flutter test --no-pub --coverage --dart-define=LIFE_DIARY_DEV_LOGIN=true test/application/life_diary_dev_login_test.dart
flutter analyze --no-pub lib/application/life_diary_dev_login.dart test/application/life_diary_dev_login_test.dart
```

fake 클라이언트만 사용한다. 테스트의 허용 호출은 start/exchange/session/logout뿐이다.
실기기 브라우저/콜드스타트, 앱 간 계정 일치·로그아웃 격리, 실제 저장 자료 보존,
전체 Android 구간 업로드 0건은 별도 실기기 검증이 필요하다.

## 이번 작업의 실행 결과

- PASS: `git diff --check`; 신규 세 파일도 `git diff --no-index --check`로
  공백 오류가 없음을 확인했다(신규 파일 비교 종료 1은 차이 존재를 뜻함).
- 포맷 적용: SDK의 `dart.exe format`이 두 Dart 파일을 포맷했다.
  명령 종료는 telemetry 파일 접근 거부로 1이므로 정상 종료 PASS로 보고하지 않는다.
- NOT_RUN: 기본 비활성 테스트는 Flutter 시작 과정에서 출력 없이 대기하여 중단했다.
- NOT_RUN: opt-in fake 테스트와 analyze는 SDK 직접 실행으로 시도했으나
  `D:/flutter/bin/cache/lockfile` 접근 거부로 도구 시작이 실패했다(종료 1).
  테스트/분석 결과로 간주하지 않는다. 쓰기 가능한 SDK 환경에서 위 명령을 재실행해야 한다.
- NOT_RUN: `flutter pub get`은 의존성 변경이 없어 생략했다.
  전체 테스트·빌드·계약 validator는 이번 독립 준비 코드 범위에서 실행하지 않았다.
- NOT_RUN: 실제 Auth0/Android/서버 연결 및 복구 실행. API·DB·운영 설정 변경,
  commit/push는 수행하지 않았다. 기존 수정 및 미추적 자료를 보존했다.
