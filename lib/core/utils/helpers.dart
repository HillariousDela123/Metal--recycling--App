import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Helper utilities for distance displays, snackbars, and calculations.
class AppHelpers {
  AppHelpers._();

  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primaryGreenDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  static double calculateCo2Saved(String metalType, double weightKg) {
    // Environmental formula: CO2 equivalent saved per kg of recycled metal vs virgin ore
    switch (metalType.toLowerCase()) {
      case 'aluminium':
      case 'aluminum':
        return weightKg * 9.0; // ~9 kg CO2 per kg recycled aluminum
      case 'copper':
        return weightKg * 4.2; // ~4.2 kg CO2 per kg recycled copper
      case 'steel':
        return weightKg * 1.8; // ~1.8 kg CO2 per kg recycled steel
      case 'brass':
        return weightKg * 3.5;
      case 'lead':
        return weightKg * 1.6;
      default:
        return weightKg * 2.0;
    }
  }
}
