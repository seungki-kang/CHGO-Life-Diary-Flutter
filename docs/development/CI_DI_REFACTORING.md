# 생명일기 CI · DI · 리팩토링

## 이번 변경

- 임시저장의 순차 처리와 최대 3회 재시도를 `LifeDiaryDraftPersistence`로 분리했습니다.
- 저장 함수, 대기 함수, 재시도 알림을 생성자로 주입합니다.
- 저장 요청 시 JSON 스냅샷을 만들어 대기 중인 중첩 목록 변경이 저장 내용에 영향을 주지 않도록 합니다.
- 개별 저장 Future는 실패를 전달하고, settled는 성공 보장이 아닌 대기열 종료만 의미합니다.
- 화면의 기존 저장 오류 로그와 이동 동작은 유지합니다. 저장 실패 시 화면에 알리고 이동을 막는 UX는 이번 범위에 포함되지 않습니다.
- 완료 기록 저장소 변수는 기존 LifeDiaryRepository 인터페이스에 의존합니다.
- 정본 문구, 문항 완료 기준, SQLite 스키마와 직렬화 필드는 변경하지 않습니다.

## 테스트

새 테스트는 느린 저장의 순서, 중첩 스냅샷 보존, 일시적 실패의 재시도, 영구 실패 후 다음 저장 복구를 확인합니다. 기존 SQLite FFI 테스트에도 주입한 저장 함수로 마지막 체크포인트를 복원하고 같은 날짜에 한 건만 남는 검사를 추가했습니다.

기존 완료 검증 테스트는 3번 하나님 나라 문항의 완료 단계와 6번 감사 문항의 서로 다른 완성 기록 3개 이상 조건을 각각 검사합니다. 이번 변경은 해당 기준을 바꾸지 않습니다.

## CI 및 PR

`.github/workflows/flutter-ci.yml`은 main push, PR, 수동 실행에서 Flutter 3.47.7로 정적 분석, 전체 테스트와 coverage, Python 계약 검증을 실행합니다. Python jsonschema는 4.26.0으로 고정합니다. APK 빌드와 Android/iOS 실기기 검사는 포함되지 않습니다.

GitHub 설정에서 main 보호 규칙 또는 ruleset을 만들고 CI가 한 번 실행된 다음 `Analyze, test and validate contracts`를 필수 상태 검사로 선택하세요. PR 생성만으로 병합이 차단되지는 않습니다. 이 설정은 저장소 관리자 권한이 필요하며 이번 파일 변경만으로 활성화되지 않습니다.

## 검증 상태

- Python 계약 검증: PASS (13개 검사).
- git diff --check: PASS.
- Dart 변경 파일 포맷: 실행 완료. 패키지 준비 전이라 flutter_lints 경로 해석 경고가 있었습니다.
- flutter analyze / flutter test: NOT_RUN. Flutter SDK 초기화 중 메타데이터 주소 접근이 감지되어 자동 승인 검토가 실행을 차단했습니다.
- GitHub Actions 실제 실행: 미확인.
- 실제 Android/iOS, 강제 종료·재시작, APK 빌드: NOT_RUN.

## 로컬 확인

```powershell
flutter pub get
flutter analyze
flutter test --coverage
python -m pip install jsonschema==4.26.0
python tools/contract/validate_life_diary_contract.py
```

검사 실패 시 main에 병합하지 말고 작업 브랜치에서 수정하세요.
