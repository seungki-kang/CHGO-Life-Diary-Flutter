# 생명일기 개발 운영 지침

이 저장소는 `main + 작업 브랜치 + PR + CI` 방식을 사용합니다. 전통적인 Git Flow 전체를 도입하지 않으며 현재 `develop`, `release/*`, `hotfix/*` 브랜치는 상시 운영하지 않습니다.

## 브랜치

| 작업 | 이름 예시 |
| --- | --- |
| 기능 추가 | `feature/backup-restore` |
| 오류 수정 | `fix/draft-restore` |
| 동작을 유지하는 구조 개선 | `refactor/question-pages` |
| 문서 변경 | `docs/life-diary-branch-workflow` |
| 개발 환경·CI 설정 | `chore/ci-maintenance` |

한 브랜치와 PR은 하나의 목적을 가집니다. `main`에 직접 push하거나 강제 push하지 않습니다. 정상적인 수정은 기존 작업 브랜치에 새 커밋으로 추가합니다.

## 1. 작업 시작

VS Code PowerShell에서:

```powershell
Set-Location 'D:\CHGO-VibeCodeing\CHGO-Life-Diary-Flutter'
git status --short --branch
```

추적 파일에 수정이 있으면 먼저 해당 작업을 정리합니다. 미추적 오류 로그나 문서를 무조건 삭제하거나 커밋하지 않습니다.

```powershell
git switch main
git pull --ff-only origin main
git switch -c feature/backup-restore
```

마지막 브랜치 이름은 실제 작업에 맞게 변경합니다. 명령이 실패하면 원인을 확인한 뒤 다음 단계로 진행합니다.

## 2. 구현 및 검증

기존 저장소 인터페이스와 DI를 활용합니다. 정본 문구, Canonical ID, 문항 순서와 완료 기준은 승인된 요구 없이 바꾸지 않습니다. 저장 필드·DB 변경은 기존 기록과 임시저장의 호환성 및 마이그레이션을 검토합니다. 사람의 영적 상태를 점수로 판정하는 기능은 추가하지 않습니다.

동작을 수정할 때 관련 회귀 테스트를 추가·수정합니다. 문서만 바꾸는 경우에는 문서 링크와 변경 내용을 확인하며 불필요한 기능 테스트를 새로 만들지 않습니다.

Dart 또는 저장 계약을 변경했다면 해당 검사를 실행합니다.

```powershell
flutter pub get
flutter analyze
flutter test --coverage
python tools/contract/validate_life_diary_contract.py
```

Python 계약 검사에 필요한 jsonschema가 없으면 `python -m pip install jsonschema==4.26.0`을 먼저 실행합니다. 미실행 검사는 PR에 미실행으로 기록합니다. SQLite FFI 테스트 통과는 Android/iOS 실기기·강제 종료·재시작 검증을 대신하지 않습니다.

## 3. 커밋 및 PR

```powershell
git diff
# 실제 변경 파일만 각각 지정합니다. 아래는 예시입니다.
git add lib/application/example.dart test/application/example_test.dart
git diff --cached --check
git diff --cached
git commit -m "Fix draft restoration after navigation"
git push -u origin feature/backup-restore
```

예시 경로와 메시지는 실제 작업에 맞게 바꾸세요. `git add .`로 개인 기록·오류 로그·로컬 설정을 일괄 포함하지 마세요. PR은 base `main`, compare 작업 브랜치로 생성하고 템플릿을 작성합니다.

필수 상태 검사는 `Analyze, test and validate contracts` (GitHub Actions)입니다. 실패 또는 대기 상태에서는 병합하지 않습니다. 최신 main 반영이 필요하면 아래처럼 기존 작업 브랜치에서 병합한 후 충돌을 해결하고 관련 검사를 다시 실행합니다.

```powershell
git fetch origin
git merge origin/main
# 충돌 해결과 검증 완료 후
git push
```

## 4. 병합과 정리

PR 변경 내용과 CI 성공을 확인한 뒤 GitHub에서 병합합니다. 실제 기기 검증이 필요한 변경은 그 결과도 기록합니다.

```powershell
git switch main
git pull --ff-only origin main
git status --short --branch
```

병합된 작업 브랜치는 필요하면 삭제합니다. GitHub에서 원격 브랜치를 삭제해도 main의 병합 내용은 유지됩니다. 로컬 브랜치는 merge 방식으로 병합된 경우 `git branch -d 브랜치이름`으로 정리할 수 있습니다. Squash/Rebase 병합으로 삭제가 거부되면 강제 삭제 대신 이력부터 확인하세요.

## main 보호 규칙

규칙 이름은 `main-ci-protection`, 대상은 `main`, 상태는 Active입니다. 우회 목록은 비웁니다. PR 필수·승인 0명·필수 CI·최신 main 반영·삭제 제한·강제 push 차단으로 운영합니다. 실제 적용 여부는 GitHub 저장소 설정이 기준이며 이 문서만으로 설정이 변경되지는 않습니다.

## 배포 시작 이후

실제 배포 시 `pubspec.yaml` 버전과 변경 내역을 맞추고, 검증된 배포 커밋에 `vX.Y.Z` 태그를 붙입니다. 버전과 태그는 배포를 결정할 때 지정하며 이번 운영 지침 도입으로 새 릴리스를 만들지 않습니다. 배포 버전의 긴급 수정과 다음 버전 개발을 동시에 유지해야 할 때 release/hotfix 브랜치 도입을 별도 결정합니다.
