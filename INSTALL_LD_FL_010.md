# LD-FL-010 설치 및 확인

이 업데이트는 다음 두 가지를 반영합니다.

1. 생명일기 완성 후 처음 화면으로 돌아가 같은 날에도 새 일기를 작성할 수 있습니다.
2. 6번 감사 기록을 `누구에게`와 `무엇을 또는 왜`의 두 입력칸으로 단순화합니다.

기존 기록의 `what`/`why` 데이터는 화면에서 합쳐 보여 주며, Canonical 필드는 삭제하지 않아 이전 데이터와 호환됩니다. 새 기록 ID에는 시즌과 회차가 포함되므로 같은 날짜의 여러 기록이 서로 덮어쓰지 않습니다.

## PowerShell 설치

ZIP 파일을 Windows 다운로드 폴더에 저장한 뒤 프로젝트 터미널에서 아래 명령을 한꺼번에 실행합니다.

```powershell
cd D:\CHGO-VibeCodeing\CHGO-Life-Diary-Flutter

$zip = "$env:USERPROFILE\Downloads\CHGO-Life-Diary-Flutter_LD-FL-010_Update_1.0.zip"
$temp = Join-Path $env:TEMP "chgo_ld_fl_010"

if (Test-Path $temp) { Remove-Item $temp -Recurse -Force }
Expand-Archive -Path $zip -DestinationPath $temp -Force
Copy-Item "$temp\*" "." -Recurse -Force
Remove-Item $temp -Recurse -Force

D:\flutter\bin\dart.bat format lib test
D:\flutter\bin\flutter.bat analyze --no-fatal-infos
Write-Host "ANALYZE EXIT CODE: $LASTEXITCODE"
D:\flutter\bin\flutter.bat test
Write-Host "TEST EXIT CODE: $LASTEXITCODE"
git status
```

두 종료 코드가 모두 `0`이면 다음 명령으로 저장합니다.

```powershell
git add `
  lib/app/life_diary_app_shell.dart `
  lib/application/life_diary_progress.dart `
  lib/data/life_diary_entry_factory.dart `
  lib/presentation/questions/question_6_page.dart `
  lib/presentation/questions/question_7_page.dart `
  test/application/life_diary_progress_test.dart `
  test/data/life_diary_entry_factory_test.dart

git commit -m "Allow repeat daily entries and simplify gratitude LD-FL-010"
git push origin main
git status
git log -1 --oneline
```

## 수동 확인

1. 생명일기 한 건을 최종 완성합니다.
2. `처음으로 돌아가 새 생명일기 쓰기` 버튼을 누릅니다.
3. 같은 날짜를 선택해 다음 회차로 새 생명일기를 시작할 수 있는지 확인합니다.
4. 6번 감사 기록에 입력칸이 두 개만 표시되는지 확인합니다.
5. 이전에 저장한 감사 기록의 `무엇을`과 `왜` 내용이 함께 표시되는지 확인합니다.
