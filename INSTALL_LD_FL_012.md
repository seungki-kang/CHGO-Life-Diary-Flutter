# LD-FL-012 설치 안내

## 수정 내용

- 최종 완성 뒤 이전 질문 화면이 닫히면서 완료된 내용을 다시 초안으로 저장하던 문제를 수정했습니다.
- `처음으로 돌아가 새 생명일기 쓰기`를 누르면 1~7번 입력 상태가 초기화됩니다.
- 같은 날에도 다음 회차의 새 생명일기를 빈 상태로 작성할 수 있습니다.
- 이미 최종 완성한 생명일기 기록은 목록에 그대로 보존됩니다.
- 완료된 화면이 닫히는 동안 임시저장을 차단하는 생명주기 객체와 회귀 테스트를 추가했습니다.

## 설치

ZIP 파일을 다운로드 폴더에 압축 해제한 뒤, 프로젝트 PowerShell에서 실행합니다.

```powershell
cd D:\CHGO-VibeCodeing\CHGO-Life-Diary-Flutter

$update = "$env:USERPROFILE\Downloads\CHGO-Life-Diary-Flutter_LD-FL-012_Update_1.0"

Copy-Item "$update\lib\*" ".\lib" -Recurse -Force
Copy-Item "$update\test\*" ".\test" -Recurse -Force
Copy-Item "$update\INSTALL_LD_FL_012.md" ".\INSTALL_LD_FL_012.md" -Force

D:\flutter\bin\dart.bat format .\lib .\test
D:\flutter\bin\flutter.bat analyze --no-fatal-infos
$analyzeCode = $LASTEXITCODE
D:\flutter\bin\flutter.bat test
$testCode = $LASTEXITCODE

Write-Host "ANALYZE EXIT CODE: $analyzeCode"
Write-Host "TEST EXIT CODE: $testCode"
git status --short
```

두 종료 코드가 모두 `0`이면 검증 성공입니다.

## 화면 확인

1. 기존 생명일기를 7번까지 최종 완성합니다.
2. `처음으로 돌아가 새 생명일기 쓰기`를 누릅니다.
3. 같은 날짜로 다시 시작합니다.
4. 다음 회차 번호가 표시되는지 확인합니다.
5. 1번 질문의 입력란과 선택값이 모두 비어 있는지 확인합니다.
6. 이전 완성 기록이 생명일기 목록에 남아 있는지 확인합니다.
