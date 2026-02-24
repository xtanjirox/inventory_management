import '../models/user_profile.dart';

class PlanLimits {
  // ── Normal plan limits ─────────────────────────────────────────────────────
  static const int normalMaxProducts = 50;
  static const bool normalCloudSync = false;

  // ── Pro plan limits ────────────────────────────────────────────────────────
  static const int proMaxProducts = -1; // unlimited
  static const bool proCloudSync = true;

  // ── Helpers ────────────────────────────────────────────────────────────────

  static bool canAddProduct(AppPlan plan, int currentProductCount) {
    if (plan == AppPlan.pro) return true;
    return currentProductCount < normalMaxProducts;
  }

  static int? maxProducts(AppPlan plan) {
    if (plan == AppPlan.pro) return null; // unlimited
    return normalMaxProducts;
  }

  static bool canUseCloudSync(AppPlan plan) => plan == AppPlan.pro;

  static String getPlanName(AppPlan plan) =>
      plan == AppPlan.pro ? 'Pro' : 'Normal';

  static String getProductLimitText(AppPlan plan) {
    if (plan == AppPlan.pro) return 'Unlimited products';
    return '$normalMaxProducts products max';
  }

  static String getCloudSyncText(AppPlan plan) {
    if (plan == AppPlan.pro) return 'Cloud sync available';
    return 'No cloud sync';
  }

  static List<_PlanFeature> getFeatures(AppPlan plan) {
    final isPro = plan == AppPlan.pro;
    return [
      _PlanFeature('Products', getProductLimitText(plan), isPro || false),
      _PlanFeature('Cloud Sync', getCloudSyncText(plan), isPro),
      _PlanFeature('Advanced Stats', isPro ? 'Full analytics' : 'Basic stats', isPro),
      _PlanFeature('Data Export', isPro ? 'CSV & PDF export' : 'Not available', isPro),
      _PlanFeature('Priority Support', isPro ? 'Included' : 'Not included', isPro),
    ];
  }
}

class _PlanFeature {
  final String title;
  final String description;
  final bool enabled;

  const _PlanFeature(this.title, this.description, this.enabled);
}
