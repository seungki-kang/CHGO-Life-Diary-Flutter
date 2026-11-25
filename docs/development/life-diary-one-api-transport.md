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

# 개발 전용 One API 전송 어댑터

2026-11-09. 기존 준비 문서를 보완한다. 실제 앱 조립·활성화는 하지 않았다.
`LifeDiaryOneApiAuthClient`와 `LifeDiaryIoAuthTransport`를 추가했다.
기존 컨트롤러, 콜백 검사, 기본 비활성 debug opt-in은 변경하지 않았다.
일기 저장·업로드·DB·소유자 변경 경로에 의존하지 않는다.
전용 client ID는 필수 주입 값이며 기본값이나 실제 등록 값은 없다.

## API 코드로 확인한 계약

아래 경로는 모두 `D:/CHGO-VibeCodeing/JesusLife-One-API-ld-login` 기준이다.

| 항목 | 코드 근거 | 구현 |
| --- | --- | --- |
| 고정 로컬 prefix, app, return URI | `app/core/life_diary_login.py:15-18` | localhost 8000, life_diary, 기존 컨트롤러 URI |
| POST login-transactions | `app/core/life_diary_login.py:70-79`, `app/core/mobile_routes.py:24-26` | app_id/client_id/return_uri/challenge, 200, UUID transaction 및 authorize_url 검사 |
| authorize URL | `app/core/life_diary_login.py:77-86` | 고정 scheme/host/port/path, userInfo·fragment 없음, 단일 43자 state |
| POST session-exchange | `app/core/life_diary_login.py:146-155`, `app/core/mobile_routes.py:29-33` | 같은 결합 값 + transaction/code/verifier, 200 |
| 교환 응답 | `app/core/life_diary_login.py:154-155`, `app/core/core_store.py:42-43,146` | 43자 opaque credential, Bearer, UUID sub, 미래 Unix 초 정수 expires_at |
| GET session | `app/core/life_diary_login.py:128-160` | Authorization Bearer, 200, UUID sub와 app_id=life_diary 검사 |
| POST logout | `app/core/life_diary_login.py:162-169` | Authorization Bearer, 빈 204 응답 |

교환 응답에는 app_id가 없다. 임의로 추가 요구하지 않고 기존 컨트롤러의 후속
session 조회에서 앱과 계정을 확인한다. credential은 JWT로 해석하지 않는다.
알 수 없는 응답 필드를 계약 위반으로 가정하지 않으며 필수 필드를 검증한다.
실제 IO는 리디렉션·재시도 없이 한 번만 전송하고 제한 시간과 응답 크기를 제한한다.
오류에는 응답 원문이나 토큰을 포함하지 않는다. 교환 결과가 불확실하면 기존
컨트롤러가 이미 소비한 콜백을 재사용하지 못하며 새 로그인부터 시작해야 한다.

## 미결 / AUTHOR_REVIEW_REQUIRED

- 복귀 URI는 여전히 후보: API `docs/life-diary-android-login-draft.md:58-59`.
  Android manifest 등록, cold start/onNewIntent 전달과 실제 활성화는 검토 대기.
- 전용 개발 client/runtime 등록: `app/core/life_diary_login.py:22-30,45-59`.
  코드는 실제 client ID를 제공하지 않고 기본 enabled=False다.
- 실제 Auth0 client/profile, audience, callback 허용 목록과 scope는 미확인:
  API `docs/life-diary-android-login-draft.md:63-69`.
  API·Auth0·DB 설정 및 live login은 수행하지 않았다.

## 검증

추가 테스트는 fake HTTP transport만 사용한다. 네 경로·본문·헤더, Unix 초 변환,
잘못된 JSON/필수 필드/타입/만료/토큰 종류, 앱 불일치, 실패 상태·리디렉션,
불확실한 교환 후 콜백 재사용 차단 및 기본 비활성을 다룬다.

```powershell
flutter test --no-pub --coverage test/application/life_diary_dev_login_test.dart test/application/life_diary_one_api_auth_client_test.dart
flutter test --no-pub --coverage --dart-define=LIFE_DIARY_DEV_LOGIN=true test/application/life_diary_dev_login_test.dart test/application/life_diary_one_api_auth_client_test.dart
flutter analyze --no-pub
```

- NOT_RUN: 기본 테스트와 flutter analyze는 출력 없이 대기하여 중단했다.
  SDK snapshot 직접 실행으로 opt-in 테스트 및 analyze를 재시도했지만
  `D:/flutter/bin/cache/lockfile` 접근 거부로 모두 도구 시작 실패(종료 1).
- 정적 분석 참고: SDK dart.exe로 추가한 두 파일을 분석하면 `No issues found!`.
  이후 telemetry 파일 접근 거부로 종료 1이므로 명령 전체 PASS로 표시하지 않는다.
- 포맷은 적용됐다. 포맷 명령도 같은 telemetry 문제로 종료 1.
- PASS: git diff --check 및 신규 파일 공백 검사.
- NOT_RUN: pub get(의존성 변경 없음), 전체 테스트·빌드·저장 계약 validator
  (로그인 전송만 변경), 실기기·복구·실제 서버 로그인(요청 범위 밖).
- 새 브랜치 생성은 .git 쓰기 제한으로 실패했다. 기존 작업 브랜치
  `docs/ld-agent-guidance-20261101`, HEAD `05996c7be8af429df901afb62a0ee758b075ea2d` 유지.
  기존 변경·미추적 파일 보존. commit/push/merge 없음.

롤백은 이번에 추가한 어댑터·테스트·이 문서 세 파일만 제거하면 된다.
