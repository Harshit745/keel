import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Keel';

  // New Color Palette
  static const Color bgColor = Color(0xFF080808);
  static const Color cardColor = Color(0xFF0D0D0D);
  static const Color card2Color = Color(0xFF131313);
  static const Color accentColor = Color(0xFFF0FF00);
  static const Color tealColor = Color(0xFF00E5FF);
  static const Color successColor = Color(0xFF00FF88);
  static const Color dangerColor = Color(0xFFFF4444);

  // Hive Box Names
  static const String buildLogsBox = 'build_logs';
  static const String selfLogsBox = 'self_logs';
  static const String ideasBox = 'ideas_vault';
  static const String onboardingCompletedKey = 'is_onboarded';
  static const String userNameKey = 'user_name';
  static const String userGoalKey = 'user_goal';
  static const String userDailyBudgetKey = 'user_daily_budget';
  static const String userAgeKey = 'user_age';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const int targetSleep = 8;
  static const int targetSteps = 10000;
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String revenueCatApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
  );

  static const String geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';
}
