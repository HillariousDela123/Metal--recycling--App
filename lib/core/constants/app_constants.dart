import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App constants including Firestore collection names, metal item metadata, and configuration flags.
class AppConstants {
  AppConstants._();

  // Firestore Collection Names
  static const String usersCollection = 'users';
  static const String servicesCollection = 'services';
  static const String plansCollection = 'plans';
  static const String activitiesCollection = 'activities';

  // Notification Channel
  static const String notificationChannelId = 'metal_recycling_reminders';
  static const String notificationChannelName = 'Recycling Plan Reminders';
  static const String notificationChannelDesc = 'Alerts for scheduled metal drop-offs and recycling events';

  // Metal Categories with descriptive information, icon, and estimated scrap prices ($/kg)
  static const List<MetalCategoryInfo> metalCategories = [
    MetalCategoryInfo(
      id: 'copper',
      name: 'Copper',
      symbol: 'Cu',
      estimatedPricePerKg: 8.50,
      color: AppColors.copper,
      icon: Icons.electrical_services_rounded,
      description: 'Wires, copper pipes, cables, motors, and kitchen cookware. Highly valuable and 100% recyclable.',
      environmentalImpact: 'Saves 85% energy vs mined ore',
    ),
    MetalCategoryInfo(
      id: 'aluminium',
      name: 'Aluminium',
      symbol: 'Al',
      estimatedPricePerKg: 2.10,
      color: AppColors.aluminum,
      icon: Icons.local_drink_rounded,
      description: 'Beverage cans, window frames, car parts, siding, and kitchen utensils.',
      environmentalImpact: 'Saves 95% energy vs raw extraction',
    ),
    MetalCategoryInfo(
      id: 'steel',
      name: 'Steel',
      symbol: 'Fe-C',
      estimatedPricePerKg: 0.65,
      color: AppColors.steel,
      icon: Icons.construction_rounded,
      description: 'Appliances, sheet metal, beams, rebar, car body panels, and structural hardware.',
      environmentalImpact: 'Saves 74% energy vs new steel',
    ),
    MetalCategoryInfo(
      id: 'brass',
      name: 'Brass',
      symbol: 'Cu-Zn',
      estimatedPricePerKg: 5.20,
      color: AppColors.bronze,
      icon: Icons.plumbing_rounded,
      description: 'Valves, plumbing fixtures, door knobs, musical instruments, and decorative trim.',
      environmentalImpact: 'Significant carbon footprint reduction',
    ),
    MetalCategoryInfo(
      id: 'lead',
      name: 'Lead',
      symbol: 'Pb',
      estimatedPricePerKg: 2.30,
      color: Color(0xFF475569),
      icon: Icons.battery_charging_full_rounded,
      description: 'Vehicle car batteries, radiation shields, weights, and roofing flashings.',
      environmentalImpact: 'Prevents toxic ground contamination',
    ),
    MetalCategoryInfo(
      id: 'iron',
      name: 'Cast Iron',
      symbol: 'Fe',
      estimatedPricePerKg: 0.45,
      color: Color(0xFF1E293B),
      icon: Icons.hardware_rounded,
      description: 'Engine blocks, cookware pans, machinery castings, and ornate garden gates.',
      environmentalImpact: 'Diverts heavy tonnage from landfills',
    ),
  ];
}

class MetalCategoryInfo {
  final String id;
  final String name;
  final String symbol;
  final double estimatedPricePerKg;
  final Color color;
  final IconData icon;
  final String description;
  final String environmentalImpact;

  const MetalCategoryInfo({
    required this.id,
    required this.name,
    required this.symbol,
    required this.estimatedPricePerKg,
    required this.color,
    required this.icon,
    required this.description,
    required this.environmentalImpact,
  });
}
