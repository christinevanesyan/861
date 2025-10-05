class Preferences {
  final String currency;
  final List<double> chipDenoms;
  final int? breakReminderMinutes;
  final double? defaultLossLimit;
  final double? defaultWinTarget;
  final String theme; // 'light', 'dark', 'system'

  Preferences({
    this.currency = 'USD',
    List<double>? chipDenoms,
    this.breakReminderMinutes,
    this.defaultLossLimit,
    this.defaultWinTarget,
    this.theme = 'dark',
  }) : chipDenoms = chipDenoms ?? [1, 5, 25, 100, 500, 1000];

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'chipDenoms': chipDenoms,
      'breakReminderMinutes': breakReminderMinutes,
      'defaultLossLimit': defaultLossLimit,
      'defaultWinTarget': defaultWinTarget,
      'theme': theme,
    };
  }

  factory Preferences.fromJson(Map<String, dynamic> json) {
    return Preferences(
      currency: json['currency'] as String? ?? 'USD',
      chipDenoms: (json['chipDenoms'] as List?)?.map((e) => (e as num).toDouble()).toList(),
      breakReminderMinutes: json['breakReminderMinutes'] as int?,
      defaultLossLimit: json['defaultLossLimit'] != null ? (json['defaultLossLimit'] as num).toDouble() : null,
      defaultWinTarget: json['defaultWinTarget'] != null ? (json['defaultWinTarget'] as num).toDouble() : null,
      theme: json['theme'] as String? ?? 'dark',
    );
  }

  Preferences copyWith({
    String? currency,
    List<double>? chipDenoms,
    int? breakReminderMinutes,
    double? defaultLossLimit,
    double? defaultWinTarget,
    String? theme,
  }) {
    return Preferences(
      currency: currency ?? this.currency,
      chipDenoms: chipDenoms ?? this.chipDenoms,
      breakReminderMinutes: breakReminderMinutes ?? this.breakReminderMinutes,
      defaultLossLimit: defaultLossLimit ?? this.defaultLossLimit,
      defaultWinTarget: defaultWinTarget ?? this.defaultWinTarget,
      theme: theme ?? this.theme,
    );
  }
}
