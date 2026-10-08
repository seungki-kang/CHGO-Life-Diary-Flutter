# LD-FL-016 적용 안내

## 변경 내용

- 4번 추가 옛사람 처리에서 `100% 내 안에 있음` 확인란을 제거했습니다.
- 새롭게 발견한 옛사람을 하나 이상 선택하면 바로 `추가 2번으로 처리하기`가 가능합니다.
- 6번 요약 화면에서 뒤로가면 새 4번째 감사를 만들지 않고 마지막 감사의 수정 화면으로 이동합니다.
- 4번째 이후 감사는 `감사를 더 기록합니다` 또는 `감사 추가하기`를 직접 선택한 경우에만 시작합니다.
- 1~7번 첫 화면의 뒤로가기는 확인창 없이 현재 입력을 자동 저장한 뒤 이동합니다.
- 뒤로가기 화살표를 한 번, 두 번, 세 번 또는 그 이상 눌러도 이미 기록한 내용은 삭제되지 않습니다.
- 각 화살표 입력마다 현재 내용을 자동 저장하고 바로 앞 단계로 이동해 기존 내용을 확인·수정할 수 있습니다.
- 2번의 완료 화면에서는 마지막 고백부터 앞쪽 고백까지 차례로 돌아가 확인·수정할 수 있습니다.
- 6번의 감사 수정 화면에서도 세 번째, 두 번째, 첫 번째 기록 순서로 돌아가 확인·수정할 수 있습니다.
- 시작 화면의 책 아이콘을 JesusLife 보라색 로고로 교체하고 앱 포인트 색상을 로고 색상에 맞췄습니다.

## 적용

PowerShell에서 프로젝트 폴더로 이동한 뒤, 압축을 푼 폴더의 경로만 `$update`에 지정합니다.

```powershell
cd D:\CHGO-VibeCodeing\CHGO-Life-Diary-Flutter
$update = "압축을_푼_LD-FL-016_폴더"
Copy-Item "$update\lib\*" ".\lib" -Recurse -Force
Copy-Item "$update\test\*" ".\test" -Recurse -Force
Copy-Item "$update\assets\*" ".\assets" -Recurse -Force
Copy-Item "$update\pubspec.yaml" ".\pubspec.yaml" -Force
Copy-Item "$update\INSTALL_LD_FL_016.md" ".\INSTALL_LD_FL_016.md" -Force
```

## 검증

```powershell
D:\flutter\bin\dart.bat format .\lib .\test
D:\flutter\bin\flutter.bat pub get
D:\flutter\bin\flutter.bat analyze --no-fatal-infos
$analyzeCode = $LASTEXITCODE
D:\flutter\bin\flutter.bat test
$testCode = $LASTEXITCODE
Write-Host "ANALYZE EXIT CODE: $analyzeCode"
Write-Host "TEST EXIT CODE: $testCode"
git status --short
```

두 EXIT CODE가 모두 `0`이면 스테이징합니다.

```powershell
git add INSTALL_LD_FL_016.md pubspec.yaml assets/branding/jesuslife_logo_light.jpg lib/app/life_diary_app_shell.dart lib/presentation/questions/question_1_page.dart lib/presentation/questions/question_2_page.dart lib/presentation/questions/question_4_page.dart lib/presentation/questions/question_6_page.dart test/widget_test.dart
git status
```

## 화면 확인

실행 중인 Flutter 프로세스가 있으면 `q`로 종료한 다음 Android 에뮬레이터에서 다시 실행합니다.

```powershell
D:\flutter\bin\flutter.bat run -d emulator-5554
```

확인 항목:

1. 시작 화면에 흰 배경의 보라색 `J.` 로고가 표시됩니다.
2. 4번에서 추가 옛사람 하나를 선택하면 별도 100% 확인 없이 처리 버튼이 활성화됩니다.
3. 감사 3개 기록 후 요약 화면에서 뒤로가면 `감사 3번째 수정`이 표시되고 `감사 4번째`가 자동으로 나오지 않습니다.
4. 뒤로가기 화살표를 반복해서 눌러도 기존 기록이 유지되고 한 단계씩 앞의 기록을 확인할 수 있습니다.
5. 첫 단계에서 뒤로가면 확인창 없이 자동 저장 후 이전 화면으로 이동합니다.
