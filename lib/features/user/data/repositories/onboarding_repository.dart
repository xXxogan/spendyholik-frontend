abstract interface class OnboardingRepository {
  Future<bool> isSeen();

  Future<void> markSeen();
}
