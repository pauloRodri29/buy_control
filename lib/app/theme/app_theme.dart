import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_semantic_colors.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Tema único do app, construído sobre o sistema nativo do Flutter
/// (Material 3): [ColorScheme] explícito para claro/escuro, [TextTheme]
/// como escala tipográfica e o tema de cada componente configurado aqui.
///
/// Telas e widgets não definem cores/estilos próprios: leem do tema via
/// `context.colors`, `context.text` e `context.semantic` (ver
/// `theme_context.dart`). Para mudar o visual de um componente em todo o
/// app, ajuste o tema correspondente abaixo.
class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = build(Brightness.light);
  static final ThemeData darkTheme = build(Brightness.dark);

  // Paleta da marca. Só este arquivo conhece valores de cor.
  static const _green = Color(0xFF4CAF50);

  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _green,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDCEFDD),
    onPrimaryContainer: Color(0xFF1B5E20),
    secondary: Color(0xFF1C1C1C),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE0E0E0),
    onSecondaryContainer: Color(0xFF1C1C1E),
    tertiary: Color(0xFF2E7D32),
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFE5484D),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFCE9E9),
    onErrorContainer: Color(0xFF8C1D21),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1C1C1E),
    onSurfaceVariant: Color(0xFF6B6B70),
    surfaceDim: Color(0xFFEDEDEF),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F7F8),
    surfaceContainer: Color(0xFFF2F2F4),
    surfaceContainerHigh: Color(0xFFEFEFF2),
    surfaceContainerHighest: Color(0xFFEFEFF2),
    outline: Color(0xFFDDDDE1),
    outlineVariant: Color(0xFFDDDDE1),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1C1C1E),
    onInverseSurface: Color(0xFFEDEDED),
    inversePrimary: Color(0xFF81C784),
    surfaceTint: Colors.transparent,
  );

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _green,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF1E3A20),
    onPrimaryContainer: Color(0xFFB9E4BB),
    secondary: Color(0xFF2C2C2C),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF333333),
    onSecondaryContainer: Color(0xFFEDEDED),
    tertiary: Color(0xFF81C784),
    onTertiary: Color(0xFF0D2E10),
    error: Color(0xFFE5484D),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF3A1F20),
    onErrorContainer: Color(0xFFFFB4B6),
    surface: Color(0xFF1C1C1E),
    onSurface: Color(0xFFEDEDED),
    onSurfaceVariant: Color(0xFFA5A5A8),
    surfaceDim: Color(0xFF121212),
    surfaceBright: Color(0xFF2C2C2E),
    surfaceContainerLowest: Color(0xFF121212),
    surfaceContainerLow: Color(0xFF1A1A1C),
    surfaceContainer: Color(0xFF1F1F21),
    surfaceContainerHigh: Color(0xFF262628),
    surfaceContainerHighest: Color(0xFF262628),
    outline: Color(0xFF3A3A3C),
    outlineVariant: Color(0xFF3A3A3C),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFEDEDED),
    onInverseSurface: Color(0xFF1C1C1E),
    inversePrimary: Color(0xFF2E7D32),
    surfaceTint: Colors.transparent,
  );

  /// Fundo das telas (um tom abaixo de [ColorScheme.surface], que é o
  /// fundo de cards e sheets).
  static Color _background(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark ? scheme.surfaceContainerLowest : scheme.surfaceContainerLow;

  /// Escala tipográfica do app. Os tamanhos seguem a escala que o app já
  /// usava; as cores vêm do [ColorScheme].
  static TextTheme _textTheme(ColorScheme scheme) {
    final onSurface = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;
    return TextTheme(
      displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: onSurface),
      displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: onSurface),
      displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: onSurface),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: onSurface),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
      titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: onSurface),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: onSurface),
      bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: muted),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
      labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: muted),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: muted),
    );
  }

  static ThemeData build(Brightness brightness) {
    final scheme = brightness == Brightness.dark ? darkScheme : lightScheme;
    final semantic = brightness == Brightness.dark ? AppSemanticColors.dark : AppSemanticColors.light;
    final text = _textTheme(scheme);
    final background = _background(scheme);

    final fieldBorder = OutlineInputBorder(
      borderRadius: AppRadius.borderMd,
      borderSide: BorderSide(color: scheme.outline),
    );
    final buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.borderMd);
    const buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14);
    const buttonMinSize = Size(64, 52);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: background,
      canvasColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      splashFactory: InkRipple.splashFactory,
      extensions: [semantic],

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: const CircleBorder(),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.5),
          disabledForegroundColor: scheme.onPrimary,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: buttonShape,
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(borderSide: BorderSide(color: scheme.primary, width: 2)),
        errorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: scheme.error)),
        focusedErrorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: scheme.error, width: 2)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primary,
        disabledColor: scheme.surfaceContainerHighest,
        labelStyle: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        showCheckmark: false,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        dragHandleSize: const Size(40, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        closeIconColor: scheme.onInverseSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        textStyle: text.bodyLarge,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurface,
        textColor: scheme.onSurface,
        selectedColor: scheme.primary,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
        leadingAndTrailingTextStyle: text.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),

      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
        circularTrackColor: Colors.transparent,
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(buttonShape),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? scheme.primary : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? scheme.onPrimary : scheme.onSurface,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.3),
        selectionHandleColor: scheme.primary,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: AppRadius.borderSm),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
    );
  }
}
