// no external imports needed

/// Chart product metadata for NAIPS graphical charts
class ChartItem {
  final String code; // e.g., 81210
  final String name; // e.g., SIGMET AUSTRALIA ALL LEVELS
  final DateTime validFromUtc;
  final DateTime? validTillUtc; // null for PERM entries
  final String category; // e.g., MSL_ANALYSIS, MSL_PROGNOSIS, SIGWX_HIGH, SIGWX_MID, SIGMET, SATPIC, GP_WINDS
  final String? level; // e.g., High, Mid, A050, A100, F185, F340
  final String? cycleZ; // e.g., 0000/0600/1200/1800
  final Uri? loResUrl;
  final Uri? hiResUrl;
  final Uri? pdfUrl;
  final String source; // typically 'naips'

  const ChartItem({
    required this.code,
    required this.name,
    required this.validFromUtc,
    required this.validTillUtc,
    required this.category,
    this.level,
    this.cycleZ,
    this.loResUrl,
    this.hiResUrl,
    this.pdfUrl,
    this.source = 'naips',
  });

  bool get isCurrentlyValid {
    final now = DateTime.now().toUtc();
    final till = validTillUtc;
    if (till == null) return true; // treat PERM as always valid
    return now.isAfter(validFromUtc) && !now.isAfter(till);
  }

  Duration? get timeRemaining {
    final till = validTillUtc;
    if (till == null) return null;
    final now = DateTime.now().toUtc();
    if (now.isAfter(till)) return Duration.zero;
    return till.difference(now);
  }
}


