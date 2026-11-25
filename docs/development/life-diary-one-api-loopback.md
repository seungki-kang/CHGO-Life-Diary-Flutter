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

# One API debug 로그인

기본 fixture 경로는 그대로 유지한다. 실제 개발 서버 선택은 debug 빌드에서 두 플래그를
명시하고 생명일기 전용 공개 Client ID를 전달한다. Client Secret은 서버에만 둔다.
일기 저장·업로드는 변경하지 않으며 인증 세션은 메모리에만 보관한다.

```powershell
Set-Location 'D:\CHGO-VibeCodeing\CHGO-Life-Diary-Flutter'
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
& $adb devices -l
$device = '<Android 기기 ID>'
& $adb -s $device reverse tcp:8000 tcp:8000
$clientId = '<생명일기 전용 공개 Client ID>'
& 'D:\flutter\bin\flutter.bat' run --no-pub --debug -d $device -t lib/main_dev_auth.dart --dart-define=LIFE_DIARY_DEV_LOGIN=true --dart-define=LIFE_DIARY_ONE_API_LOGIN=true "--dart-define=LIFE_DIARY_AUTH0_CLIENT_ID=$clientId"
```

Client ID는 One API의 LD_AUTH0_CLIENT_ID와 같아야 한다. issuer, audience, Client Secret,
DB 암호와 키는 Flutter 설정이 아니다. fixture 서버를 동시에 시작하지 않는다.
One API는 localhost authorize URL과 HTTPS Auth0 callback URL을 분리하는 개발 relay 버전이어야 한다.
HTTPS 콜백만 ngrok으로 공개하며, callback은 60초 일회용 식별자로 loopback 완료 경로에 복귀한다.
완료에는 시작 브라우저 쿠키가 필요하다. 새 브라우저나 프로세스 재시작 후에는 다시 시작한다.
개발 서버는 단일 프로세스이며 relay는 재시작 시 폐기된다.

실제 로그인·기기 브라우저 왕복·ngrok 정책 변경은 이번 오프라인 검증에 포함하지 않는다.
