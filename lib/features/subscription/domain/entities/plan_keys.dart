import 'package:get/get.dart';

/// Recursos com limite de quantidade nos planos.
enum ResourceKey {
  boxes('common.boxes', 'common.box', 'common.boxes'),
  products('common.products', 'common.productLower', 'common.productsLower'),
  categories('subscription.customCategories', 'subscription.category', 'subscription.categories'),
  productTypes('subscription.customProductTypes', 'subscription.productType', 'subscription.productTypes'),
  units('subscription.customUnits', 'subscription.unit', 'subscription.units'),
  planBoards('subscription.openBoards', 'subscription.board', 'subscription.boards'),
  planItemsPerBoard('subscription.itemsPerBoard', 'common.item', 'common.items');

  final String _label;
  final String _singular;
  final String _plural;

  const ResourceKey(this._label, this._singular, this._plural);

  String get label => _label.tr;
  String get singular => _singular.tr;
  String get plural => _plural.tr;
}

/// Módulos que um plano libera ou não.
///
/// [available] = `false` marca os módulos que ainda não existem no app:
/// aparecem nos planos como "Em breve".
enum FeatureKey {
  planning('subscription.planningBoards'),
  backupManual('common.manualBackup'),
  barcodeScanner('subscription.barcodeScanner'),
  dashboardCharts('subscription.homeCharts'),
  discountRules('subscription.discountsSurchargesPerItem'),
  carryOver('subscription.repeatEntryNextCycle'),
  reportsAdvanced('subscription.reportsAdvancedFilters'),
  reportsCompare('subscription.bReportComparison'),
  exportPdf('subscription.exportReportPdf'),
  scaleLabel('subscription.scaleLabelReading'),
  priceHistory('subscription.priceHistory', available: false),
  budgets('subscription.goalsPerBoxCategory', available: false),
  backupAuto('subscription.automaticBackup', available: false),
  cloudSync('subscription.syncAcrossDevices', available: false);

  final String _label;
  final bool available;

  const FeatureKey(this._label, {this.available = true});

  String get label => _label.tr;
}

enum BillingPeriod {
  monthly('subscription.monthly', 'subscription.mo'),
  yearly('subscription.yearly', 'subscription.yr');

  final String _label;
  final String _suffix;

  const BillingPeriod(this._label, this._suffix);

  String get label => _label.tr;
  String get suffix => _suffix.tr;
}
