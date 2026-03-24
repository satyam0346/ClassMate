import 'package:flutter/material.dart';

/// ClassMate color palette.
/// All colors are defined here as const values.
/// Use AppColors throughout the app — never use hard-coded hex values.
abstract class AppColors {
  // ── Primary ─────────────────────────────────────────────
  static const Color primary       = Color(0xFF1A1A5E); // Deep Indigo
  static const Color primaryLight  = Color(0xFF2E2E8F);
  static const Color primaryDark   = Color(0xFF10103F);

  // ── Accent ──────────────────────────────────────────────
  static const Color accent        = Color(0xFF00D4FF); // Soft Cyan
  static const Color accentLight   = Color(0xFF66E5FF);
  static const Color accentDark    = Color(0xFF009FBF);

  // ── Surfaces ────────────────────────────────────────────
  static const Color surfaceLight  = Color(0xFFFFFFFF);
  static const Color surfaceDark   = Color(0xFF121212);
  static const Color cardLight     = Color(0xFFF8F9FF);
  static const Color cardDark      = Color(0xFF1E1E2E);

  // ── Background ──────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF0F2FF);
  static const Color backgroundDark  = Color(0xFF0D0D1A);

  // ── Semantic ────────────────────────────────────────────
  static const Color error         = Color(0xFFFF4444);
  static const Color success       = Color(0xFF00C853);
  static const Color warning       = Color(0xFFFFAA00);
  static const Color info          = Color(0xFF2196F3);

  // ── Priority colors ─────────────────────────────────────
  static const Color priorityHigh   = Color(0xFFFF4444);
  static const Color priorityMedium = Color(0xFFFFAA00);
  static const Color priorityLow    = Color(0xFF00C853);

  // ── Text ────────────────────────────────────────────────
  static const Color textPrimaryLight   = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark    = Color(0xFFF0F2FF);
  static const Color textSecondaryDark  = Color(0xFF9CA3AF);

  // ── Divider ─────────────────────────────────────────────
  static const Color dividerLight = Color(0xFFE5E7EB);
  static const Color dividerDark  = Color(0xFF374151);

  // ── Gradient stops ──────────────────────────────────────
  static const List<Color> heroGradient = [
    Color(0xFF1A1A5E),
    Color(0xFF2E2E8F),
  ];
  static const List<Color> accentGradient = [
    Color(0xFF00D4FF),
    Color(0xFF0099CC),
  ];
  static const List<Color> cardGradient = [
    Color(0xFF1A1A5E),
    Color(0xFF00D4FF),
  ];
}
