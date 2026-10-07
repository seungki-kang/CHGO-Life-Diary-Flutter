# LD-FL-009 Life Diary acceptance runbook

Contract source: `JL-LD-003 Flutter MVP Implementation Backlog 1.0` and
`LIFE_DIARY_MVP_ACCEPTANCE_1.0.csv`.

## Automated gate

Run from the Flutter repository root:

```powershell
D:\flutter\bin\flutter.bat analyze --no-fatal-infos
D:\flutter\bin\flutter.bat test
```

The gate passes only when both commands return exit code 0. LD-007 through
LD-009 are covered by `test/acceptance/life_diary_privacy_acceptance_test.dart`.
Existing domain, repository, application, presentation, and widget tests cover
the remaining contract behavior.

## Android emulator gate

1. Start the Android emulator.
2. Run `D:\flutter\bin\flutter.bat devices` and record the device ID.
3. Run `D:\flutter\bin\flutter.bat run -d <device-id>`.
4. Verify Q1-Q7 free navigation, exit-save confirmation, draft resume,
   completion, history, reopen, delete, restore, and season/session display.
5. Close and reopen the app and verify that an unfinished draft survives.

## Physical Android device gate

1. Enable developer options and USB debugging on one test device.
2. Confirm it with `D:\flutter\bin\flutter.bat devices`.
3. Run `D:\flutter\bin\flutter.bat run -d <device-id>`.
4. Repeat the emulator checks and record Android version, device model, date,
   tester, and result.

## Privacy evidence

- Owner raw text remains local and owner-only by default.
- Pastor and coach roles do not grant raw access.
- A share grant records recipient, scope, purpose, grant time, and expiry.
- Summary consent does not imply raw-entry consent.
- Growth-event export contains Canonical IDs and counts, never Q1-Q7 raw text.

## Completion record

LD-FL-009 is complete only after automated tests, one Android emulator, and one
physical Android device all pass. Do not mark a device gate passed without
running it on that device.
