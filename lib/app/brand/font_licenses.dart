import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Registra no [LicenseRegistry] as licenças (SIL OFL 1.1) das fontes
/// embutidas, para que apareçam em "Licenças de código aberto".
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (name, path) in const [
      ('Plus Jakarta Sans', 'assets/fonts/plus_jakarta_sans/OFL.txt'),
      ('JetBrains Mono', 'assets/fonts/jetbrains_mono/OFL.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([name], await rootBundle.loadString(path));
    }
  });
}
