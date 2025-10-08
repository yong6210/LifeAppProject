class FirestorePaths {
  FirestorePaths._();

  static String userDoc(String uid) => 'users/$uid';

  static String settingsDoc(String uid) => 'users/$uid';

  static String dailySummaryDoc(String uid, String dateKey) =>
      'users/$uid/daily_summaries/$dateKey';
}
