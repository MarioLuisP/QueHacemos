import 'package:flutter/material.dart';
import 'colors.dart';
import 'dimens.dart';

class AppStyles {
  static const titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static final cardDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(AppDimens.borderRadius),
  );

  static const chipLabel = TextStyle(
    fontSize: 14, // Reducido para chips compactos
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );
}