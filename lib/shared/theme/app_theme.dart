import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/theme/app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: AppColors.brandLight,
            onPrimary: Colors.white,
            primaryContainer: AppColors.primarySoftDark,
            onPrimaryContainer: AppColors.brandLight,
            secondary: AppColors.brandCyan,
            onSecondary: Colors.white,
            error: AppColors.error,
            onError: Colors.white,
            surface: AppColors.surfaceDark,
            onSurface: AppColors.textPrimaryDark,
            surfaceContainerHighest: AppColors.surfaceVariantDark,
            outline: AppColors.borderDark,
            outlineVariant: AppColors.borderSubtleDark,
          )
        : const ColorScheme.light(
            primary: AppColors.brand,
            onPrimary: Colors.white,
            primaryContainer: AppColors.primarySoft,
            onPrimaryContainer: AppColors.brandDark,
            secondary: AppColors.brandCyan,
            onSecondary: Colors.white,
            error: AppColors.error,
            onError: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
            surfaceContainerHighest: AppColors.surfaceStrong,
            outline: AppColors.border,
            outlineVariant: AppColors.borderStrong,
          );

    final bg = isDark ? AppColors.midnight : AppColors.background;
    final cardBg = isDark ? AppColors.surfaceElevatedDark : AppColors.surface;
    final cardBorder = isDark ? AppColors.borderDark : AppColors.border;
    final inputFill = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final systemOverlay = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        systemOverlayStyle: systemOverlay,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: textPrimary),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        color: cardBg,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cardBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cardBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brandLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cardBorder, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textDisabled,
          disabledForegroundColor: AppColors.textTertiary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppTextStyles.buttonMedium,
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.brandLight : AppColors.brand,
          disabledForegroundColor: AppColors.textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: cardBorder, width: 1.5),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.brandLight : AppColors.brand,
          disabledForegroundColor: AppColors.textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textDisabled,
          disabledForegroundColor: AppColors.textTertiary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppTextStyles.buttonMedium,
          elevation: 0,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: cardBorder,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: textPrimary),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceElevatedDark : AppColors.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
        actionTextColor: AppColors.brandLight,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
        deleteIconColor: textSecondary,
        disabledColor: AppColors.textDisabled,
        selectedColor: isDark ? AppColors.brandLight : AppColors.brand,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: AppTextStyles.labelMedium.copyWith(color: textSecondary),
        brightness: brightness,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      dividerTheme: DividerThemeData(color: cardBorder, space: 1, thickness: 1),

      iconTheme: IconThemeData(color: textPrimary, size: 24),
      primaryIconTheme: const IconThemeData(color: AppColors.brandLight, size: 24),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: textSecondary,
        textColor: textPrimary,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.brand,
        linearTrackColor: inputFill,
        circularTrackColor: inputFill,
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brand;
          return textSecondary;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brand;
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brand;
          return inputFill;
        }),
      ),

      // Keep defined for fallback use — main nav uses custom glass pill
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(color: AppColors.brandLight);
          }
          return AppTextStyles.labelSmall.copyWith(color: textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.brandLight);
          }
          return IconThemeData(color: textSecondary);
        }),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.brand,
        unselectedLabelColor: textSecondary,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelLarge,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.brand, width: 2),
        ),
      ),
    );
  }
}
