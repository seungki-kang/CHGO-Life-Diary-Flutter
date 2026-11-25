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

# Android debug 합성 인증 검증

2026-11-09. 사용자 지정 범위의 합성 테스트이며 live Auth0 검증이 아니다.
One API/Auth0/DB 설정, 정본, 일기 저장소와 기본 false 로그인 플래그는 변경하지 않는다.

`lib/main_dev_auth.dart`는 기존 로그인 컨트롤러와 HTTP 어댑터를 조합하는 별도
테스트 target이다. 일기 저장 코드를 import하지 않는다. 일반 target은 `lib/main.dart`다.
debug manifest에만 정확한 scheme/host/path를 등록한다. debug Activity는 Dart의
ready 이후 초기 Intent를 한 번 전달하고, 이후 onNewIntent도 같은 validator로 보낸다.
Flutter 기본 deep-link 라우팅은 이 Activity에서 끈다. 재시작으로 transaction이
없어진 경우 교환하지 않고 새 로그인을 요구한다. 세션/PKCE는 저장하지 않는다.
기본 플래그가 꺼져 있으면 채널 초기화와 인증 요청을 하지 않는다.

fixture는 확인한 로컬 API의 binding/PKCE/응답 형식을 재현하며 127.0.0.1:8000에만
bind한다. bind 자체가 원자적 포트 확인이다. 충돌 시 종료하며 기존 프로세스는 건드리지
않는다. Auth0 대신 합성 브라우저 페이지의 명시적 복귀 링크를 사용한다.
`/__synthetic_stats`는 본문/토큰 없이 경로별 횟수만 표시한다. 허용 인증 경로 외
요청은 보수적으로 upload로 집계하고 거절한다.

## PowerShell 재현

쓰기 가능한 SDK 및 사용자 프로필을 가진 일반 PowerShell에서 실행한다.
앱을 제거하거나 데이터를 지우지 않는다. 실행 전 테스트 대상 에뮬레이터가 하나인지 확인한다.

```powershell
Set-Location 'D:\CHGO-VibeCodeing\CHGO-Life-Diary-Flutter'
$python = 'D:\CHGO-VibeCodeing\JesusLife-One-API\.venv\Scripts\python.exe'
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
# fixture는 자체 bind 검사로 포트 충돌 시 실패한다.
$fixture = Start-Process -FilePath $python -ArgumentList 'tools/auth/fake_life_diary_auth.py' -WorkingDirectory (Get-Location).Path -WindowStyle Hidden -PassThru -RedirectStandardOutput "$env:TEMP\ld-auth-fixture.out" -RedirectStandardError "$env:TEMP\ld-auth-fixture.err"
Start-Sleep -Seconds 1
if ($fixture.HasExited) { Get-Content "$env:TEMP\ld-auth-fixture.err"; throw 'Fixture start failed; existing listener left untouched' }
flutter emulators --launch Medium_Phone
# Android 부팅 완료 후 실행
& $adb devices -l
$device = (& $adb -e get-serialno).Trim()
& $adb -s $device reverse tcp:8000 tcp:8000
flutter run --debug -d $device -t lib/main_dev_auth.dart --dart-define=LIFE_DIARY_DEV_LOGIN=true
```

화면의 합성 로그인 → 외부 브라우저 → Return to Life Diary → 합성 로그인 성공을 확인한다.
로그아웃도 실행한다. 별도 PowerShell에서 통계를 조회한다.

```powershell
Invoke-RestMethod 'http://127.0.0.1:8000/__synthetic_stats'
# upload=0 확인. 선택적으로 fixture 자체의 HTTP 회귀 검증:
& $python tools/auth/check_fake_life_diary_auth.py
flutter test --no-pub --coverage test/application/life_diary_dev_login_test.dart test/application/life_diary_one_api_auth_client_test.dart test/application/life_diary_android_callback_test.dart
flutter test --no-pub --coverage --dart-define=LIFE_DIARY_DEV_LOGIN=true test/application/life_diary_dev_login_test.dart test/application/life_diary_one_api_auth_client_test.dart test/application/life_diary_android_callback_test.dart
flutter analyze --no-pub
```

Cold start 확인: 브라우저 복귀 링크를 누르기 전에 아래 명령으로 앱만 종료하고,
기존 브라우저의 복귀 링크를 누른다. 새 로그인 필요 표시와 exchange 횟수 불변을 확인한다.

```powershell
& $adb -s $device shell am force-stop com.example.chgo_life_diary
```

테스트를 마치면 처음 fixture를 시작한 PowerShell에서 그 프로세스만 정리한다.

```powershell
if (-not $fixture.HasExited) { Stop-Process -Id $fixture.Id }
& $adb -s $device reverse --remove tcp:8000
```

## 실제 실행 결과

- PASS: Python fixture loopback HTTP start/authorize/S256 exchange/session/logout,
  재사용 401. 횟수 start=1, authorize=1, exchange=2, session=1, logout=1, upload=0.
- PASS: 두 번째 fixture 시작은 포트 충돌로 종료 1. 기존 fixture 유지 확인.
  작업 후 자신이 시작한 fixture와 대기 중 Flutter 명령을 중단했다.
- PASS: git diff --check. 추가 Dart 두 파일 정적 분석 출력 `No issues found!`.
  단, telemetry 파일 쓰기 거부로 dart analyze 전체 명령 종료는 1이다.
- NOT_RUN: focused Flutter tests 및 flutter analyze. 일반 wrapper는 출력 없이 대기하여
  중단했고, SDK snapshot 직접 실행은 D:/flutter/bin/cache/lockfile 접근 거부로 종료 1.
- NOT_RUN: Medium_Phone 브라우저 왕복 및 Android 빌드. adb가 `\\.android` 생성 권한
  거부로 시작 실패했다. 위 HTTP 결과는 Android Intent 전달의 실행 증거가 아니다.
- NOT_RUN: pub get(의존성 변경 없음), 전체 테스트/저장 계약 validator(저장 변경 없음),
  실기기 복구 및 live Auth0(요청 범위 밖).
- 새 작업 브랜치 생성은 .git 쓰기 거부로 실패했다. 기존 작업 브랜치
  docs/ld-agent-guidance-20261101 및 HEAD 05996c7be8af429df901afb62a0ee758b075ea2d 유지.
  기존 미커밋 변경 보존. 커밋/설치 제거/데이터 초기화 없음.

롤백은 이번에 추가한 target, debug Activity/리소스, fixture/검증 스크립트,
콜백 테스트와 이 문서를 제거하고 debug manifest의 이번 추가 부분만 되돌린다.
