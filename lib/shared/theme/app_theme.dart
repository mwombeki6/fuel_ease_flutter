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
            primary: AppColors.primaryDarkTheme,
            onPrimary: AppColors.inverseTextDark,
            primaryContainer: AppColors.primaryContainerDark,
            onPrimaryContainer: AppColors.onPrimaryContainerDark,
            secondary: AppColors.accentDarkTheme,
            onSecondary: AppColors.inverseTextDark,
            error: AppColors.errorDark,
            onError: AppColors.inverseTextDark,
            errorContainer: AppColors.errorContainer,
            surface: AppColors.surfaceDark,
            onSurface: AppColors.textPrimaryDark,
            surfaceContainerHighest: AppColors.surfaceDark,
            onSurfaceVariant: AppColors.textSecondaryDark,
            outline: AppColors.borderDark,
            outlineVariant: AppColors.borderStrongDark,
            surfaceTint: AppColors.primaryDarkTheme,
            scrim: AppColors.scrimDark,
          )
        : const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.inverseText,
            primaryContainer: AppColors.primaryContainer,
            onPrimaryContainer: AppColors.onPrimaryContainer,
            secondary: AppColors.accent,
            onSecondary: AppColors.inverseText,
            error: AppColors.error,
            onError: AppColors.inverseText,
            errorContainer: AppColors.errorContainer,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
            surfaceContainerHighest: AppColors.surfaceMuted,
            onSurfaceVariant: AppColors.textSecondary,
            outline: AppColors.border,
            outlineVariant: AppColors.borderStrong,
            surfaceTint: AppColors.primary,
            scrim: AppColors.scrim,
          );

    final cardBorder = isDark ? AppColors.borderDark : AppColors.border;
    final inputFill = isDark
        ? AppColors.surfaceMutedDark.withValues(alpha: 0.8)
        : AppColors.surfaceMuted.withValues(alpha: 0.8);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

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
      scaffoldBackgroundColor: Colors.transparent, // Use transparent for glassmorphism
      canvasColor: Colors.transparent,

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
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        color: Colors.transparent, // Transparent for glassmorphism
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cardBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cardBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cardBorder, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: cardBorder,
          disabledForegroundColor: textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonMedium,
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: cardBorder, width: 1.5),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: cardBorder,
          disabledForegroundColor: textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonMedium,
          elevation: 0,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: Colors.white.withValues(alpha: 0.3),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: textPrimary),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: textSecondary,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.transparent,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        actionTextColor: AppColors.accentLight,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.surfaceMutedDark.withValues(alpha: 0.8)
            : AppColors.surfaceMuted.withValues(alpha: 0.8),
        deleteIconColor: textSecondary,
        disabledColor: cardBorder,
        selectedColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: AppTextStyles.labelMedium.copyWith(color: textSecondary),
        brightness: brightness,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: cardBorder, width: 1),
      ),

      dividerTheme: DividerThemeData(
        color: cardBorder,
        space: 1,
        thickness: 1,
      ),

      iconTheme: IconThemeData(color: textPrimary, size: 24),
      primaryIconTheme: const IconThemeData(
        color: AppColors.primary,
        size: 24,
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: textPrimary),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: textPrimary),
        displaySmall: AppTextStyles.displaySmall.copyWith(color: textPrimary),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: textPrimary),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: textPrimary),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(color: textPrimary),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: textPrimary),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: textPrimary),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: textPrimary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: textPrimary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: textSecondary),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: textPrimary),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: textPrimary),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: textSecondary),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        iconColor: textSecondary,
        textColor: textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Colors.transparent,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: inputFill,
        circularTrackColor: inputFill,
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return textSecondary;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(colorScheme.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: cardBorder, width: 2),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return inputFill;
        }),
        trackOutlineColor: WidgetStatePropertyAll(cardBorder),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(
              color: colorScheme.primary,
            );
          }
          return AppTextStyles.labelSmall.copyWith(color: textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary);
          }
          return IconThemeData(color: textSecondary);
        }),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: textSecondary,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelLarge,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colorScheme.primary, width: 3),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
        dividerColor: Colors.transparent,
      ),

      splashFactory: InkRipple.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }
}