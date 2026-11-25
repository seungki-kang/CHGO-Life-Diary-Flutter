# 생명일기 작업 지침

- 생명일기는 지저스라이프 교육에서 사용하는 실천 도구다. 교육 참여와 개인 일기 열람 동의는 별개이며, 수강·이수에 따른 기술적 접근 제한은 아직 미결이다. 이를 확정 정책이나 구현 완료로 기록하지 않는다.
- 작업 전 [개발 운영 지침](CONTRIBUTING.md), [상태 구조](docs/architecture/LIFE_DIARY_STATE_ARCHITECTURE.md), [저장·정본 계약 안내](contracts/README.md)를 읽는다. 상태 구조 문서가 미추적이어도 기존 사용자 문서로 보존한다.
- 저장 계약은 [런타임 스키마](contracts/life-diary/life-diary-runtime-schema-v1.json), [Flutter 매핑](contracts/life-diary/life-diary-flutter-mapping-v1.json)을 확인한다. 정본은 [Canonical 등록부](contracts/canonical/JESUSLIFE_CANONICAL_OBJECT_REGISTER_1.0.csv)와 [핀](contracts/canonical/CANONICAL_PIN.json)을 확인한다. 계약 안내에 명시된 ADR 우선순위와 앱 DB의 저장 권위를 따른다. legacy SQL을 현재 DB 정본으로 간주하지 않는다.
- 문항 정본·Canonical ID·문항 순서·완료 기준을 승인된 요구 없이 변경하지 않는다. 저장 성공 전에 완료로 표시하지 않는다. 기존 기록·수정 이력·임시저장을 보존하고, 손상 원본을 빈 기록으로 덮어쓰거나 개발 편의로 DB를 초기화하지 않는다. 민감한 일기 원문·이름·토큰을 로그에 넣지 않는다.
- 작업 전 브랜치·HEAD·작업 트리를 확인한다. 기존 문서 변경과 사용자 변경을 되돌리거나 일괄 스테이징하지 않는다. 작업 브랜치를 사용하고 커밋·push·병합은 별도 지시를 따른다.
- 검증은 CONTRIBUTING의 기존 명령 `flutter pub get`, `flutter analyze`, `flutter test --coverage`, `python tools/contract/validate_life_diary_contract.py` 중 변경에 해당하는 범위로 실행한다. 문서만 변경하면 참조 경로와 diff를 확인하며 전체 기능 테스트·빌드를 일괄 강제하지 않는다. 미실행 검사는 이유와 함께 `NOT_RUN`으로 기록한다. 정적 확인과 실기기·복구 실행 검증을 구분한다.
