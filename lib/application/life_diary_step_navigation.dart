int previousQuestion3Stage({
  required int stage,
  required bool noKingdomEnjoyment,
}) {
  if (stage <= 0) return 0;
  if (stage == 1) return 0;
  if (stage == 2) return 1;
  if (stage == 3) return noKingdomEnjoyment ? 0 : 2;
  return 3;
}

int previousQuestion4Stage({
  required int stage,
  required bool noRecord,
  required bool hasAdditionalConfessions,
}) {
  if (stage <= 0) return 0;
  if (stage == 1 || stage == 2) return 0;
  if (stage == 3) return 1;
  if (stage == 4) return 3;
  if (noRecord) return 2;
  return hasAdditionalConfessions ? 4 : 1;
}

int previousQuestion5Stage({required int stage, required String? selection}) {
  if (stage <= 0) return 0;
  if (stage == 1 || stage == 3) return 0;
  if (stage == 2) return selection == 'both' ? 1 : 0;
  if (selection == 'daily') return 1;
  if (selection == 'word' || selection == 'both') return 2;
  return 3;
}

int previousQuestion6Stage(int stage) {
  if (stage <= 0) return 0;
  return stage - 1;
}

int previousQuestion7Stage(int stage) {
  if (stage <= 0) return 0;
  return stage - 1;
}
