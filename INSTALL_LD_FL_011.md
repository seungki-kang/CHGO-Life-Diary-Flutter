# LD-FL-011 문항 입력 간소화 및 사용성 개선

## 반영 내용

- 3번 기록을 두 칸으로 간소화
  - 어떤 상황에서 하나님 나라를 발견하였는가?
  - 고백·선포·선언하며 누렸는가?
- 4번 기록을 두 칸으로 간소화
  - 누구와 어떤 일이 있었는가?
  - 하나님의 사랑과 긍휼로 바라보았는가?
- 4번 체크 항목을 판단·저항·긍휼의 세 항목으로 정리
- 5번 감사 고백에서 쉼표를 입력하지 않아도 통과
- 6번 다음 감사 기록으로 넘어가면 첫 번째 입력칸에 자동 포커스
- 기존 3번·4번의 분리 저장 데이터는 두 칸에 합쳐 표시하고 Canonical 필드는 유지

## 설치 및 검증

```powershell
cd D:\CHGO-VibeCodeing\CHGO-Life-Diary-Flutter

$zip = "$env:USERPROFILE\Downloads\CHGO-Life-Diary-Flutter_LD-FL-011_Update_1.0.zip"
$temp = Join-Path $env:TEMP "chgo_ld_fl_011"

if (Test-Path $temp) { Remove-Item $temp -Recurse -Force }
Expand-Archive -Path $zip -DestinationPath $temp -Force
Copy-Item "$temp\*" "." -Recurse -Force
Remove-Item $temp -Recurse -Force

D:\flutter\bin\dart.bat format `
  lib\presentation\questions\question_3_page.dart `
  lib\presentation\questions\question_4_page.dart `
  lib\presentation\questions\question_5_page.dart `
  lib\presentation\questions\question_6_page.dart

D:\flutter\bin\flutter.bat analyze --no-fatal-infos
$analyzeCode = $LASTEXITCODE
Write-Host "ANALYZE EXIT CODE: $analyzeCode"

D:\flutter\bin\flutter.bat test
$testCode = $LASTEXITCODE
Write-Host "TEST EXIT CODE: $testCode"

git status --short
```
