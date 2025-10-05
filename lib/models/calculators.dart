import 'package:uuid/uuid.dart';

class PayoutSaved {
  final String id;
  final String game;
  final String betType;
  final double amount;
  final String odds;
  final double payout;
  final double houseEdgePct;
  final String? note;
  final DateTime createdAt;

  PayoutSaved({
    String? id,
    required this.game,
    required this.betType,
    required this.amount,
    required this.odds,
    required this.payout,
    required this.houseEdgePct,
    this.note,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game': game,
      'betType': betType,
      'amount': amount,
      'odds': odds,
      'payout': payout,
      'houseEdgePct': houseEdgePct,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PayoutSaved.fromJson(Map<String, dynamic> json) {
    return PayoutSaved(
      id: json['id'] as String,
      game: json['game'] as String,
      betType: json['betType'] as String,
      amount: (json['amount'] as num).toDouble(),
      odds: json['odds'] as String,
      payout: (json['payout'] as num).toDouble(),
      houseEdgePct: (json['houseEdgePct'] as num).toDouble(),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ChipCalcSaved {
  final String id;
  final List<ChipDenom> denoms;
  final double total;
  final String scope; // 'session' or 'global'
  final String? sessionId;
  final String? note;
  final DateTime createdAt;

  ChipCalcSaved({
    String? id,
    required this.denoms,
    required this.total,
    required this.scope,
    this.sessionId,
    this.note,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'denoms': denoms.map((d) => d.toJson()).toList(),
      'total': total,
      'scope': scope,
      'sessionId': sessionId,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChipCalcSaved.fromJson(Map<String, dynamic> json) {
    return ChipCalcSaved(
      id: json['id'] as String,
      denoms: (json['denoms'] as List).map((d) => ChipDenom.fromJson(d as Map<String, dynamic>)).toList(),
      total: (json['total'] as num).toDouble(),
      scope: json['scope'] as String,
      sessionId: json['sessionId'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ChipDenom {
  final double value;
  final int count;

  ChipDenom({required this.value, required this.count});

  Map<String, dynamic> toJson() => {'value': value, 'count': count};

  factory ChipDenom.fromJson(Map<String, dynamic> json) {
    return ChipDenom(
      value: (json['value'] as num).toDouble(),
      count: json['count'] as int,
    );
  }
}

class TipCalcSaved {
  final String id;
  final double base;
  final String mode; // 'percent' or 'fixed'
  final double tipValue;
  final int split;
  final double tipTotal;
  final double perPerson;
  final String? note;
  final DateTime createdAt;

  TipCalcSaved({
    String? id,
    required this.base,
    required this.mode,
    required this.tipValue,
    required this.split,
    required this.tipTotal,
    required this.perPerson,
    this.note,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'base': base,
      'mode': mode,
      'tipValue': tipValue,
      'split': split,
      'tipTotal': tipTotal,
      'perPerson': perPerson,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TipCalcSaved.fromJson(Map<String, dynamic> json) {
    return TipCalcSaved(
      id: json['id'] as String,
      base: (json['base'] as num).toDouble(),
      mode: json['mode'] as String,
      tipValue: (json['tipValue'] as num).toDouble(),
      split: json['split'] as int,
      tipTotal: (json['tipTotal'] as num).toDouble(),
      perPerson: (json['perPerson'] as num).toDouble(),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
