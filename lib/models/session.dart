import 'package:uuid/uuid.dart';

class Session {
  final String id;
  final String casino;
  final String game;
  final double buyIn;
  final double? lossLimit;
  final double? winTarget;
  final String? note;
  final DateTime startedAt;
  DateTime? endedAt;
  double? cashOut;
  final List<SessionEvent> events;

  Session({
    String? id,
    required this.casino,
    required this.game,
    required this.buyIn,
    this.lossLimit,
    this.winTarget,
    this.note,
    DateTime? startedAt,
    this.endedAt,
    this.cashOut,
    List<SessionEvent>? events,
  })  : id = id ?? const Uuid().v4(),
        startedAt = startedAt ?? DateTime.now(),
        events = events ?? [];

  double get currentBalance {
    double balance = buyIn;
    for (var event in events) {
      if (event.type == SessionEventType.buyin && event.amount != null) {
        balance += event.amount!;
      }
    }
    if (cashOut != null) {
      balance = cashOut!;
    }
    return balance;
  }

  double get totalBuyIn {
    double total = buyIn;
    for (var event in events) {
      if (event.type == SessionEventType.buyin && event.amount != null) {
        total += event.amount!;
      }
    }
    return total;
  }

  double get winLoss {
    if (cashOut == null) return 0;
    return cashOut! - totalBuyIn;
  }

  double get roi {
    if (totalBuyIn == 0) return 0;
    return (winLoss / totalBuyIn) * 100;
  }

  Duration? get duration {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'casino': casino,
      'game': game,
      'buyIn': buyIn,
      'lossLimit': lossLimit,
      'winTarget': winTarget,
      'note': note,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'cashOut': cashOut,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      casino: json['casino'] as String,
      game: json['game'] as String,
      buyIn: (json['buyIn'] as num).toDouble(),
      lossLimit: json['lossLimit'] != null ? (json['lossLimit'] as num).toDouble() : null,
      winTarget: json['winTarget'] != null ? (json['winTarget'] as num).toDouble() : null,
      note: json['note'] as String?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
      cashOut: json['cashOut'] != null ? (json['cashOut'] as num).toDouble() : null,
      events: (json['events'] as List?)?.map((e) => SessionEvent.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

enum SessionEventType { buyin, note, cashout, calcSaved }

class SessionEvent {
  final String id;
  final SessionEventType type;
  final double? amount;
  final String? text;
  final CalcRef? calcRef;
  final DateTime ts;

  SessionEvent({
    String? id,
    required this.type,
    this.amount,
    this.text,
    this.calcRef,
    DateTime? ts,
  })  : id = id ?? const Uuid().v4(),
        ts = ts ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'text': text,
      'calcRef': calcRef?.toJson(),
      'ts': ts.toIso8601String(),
    };
  }

  factory SessionEvent.fromJson(Map<String, dynamic> json) {
    return SessionEvent(
      id: json['id'] as String,
      type: SessionEventType.values.firstWhere((e) => e.name == json['type']),
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      text: json['text'] as String?,
      calcRef: json['calcRef'] != null ? CalcRef.fromJson(json['calcRef'] as Map<String, dynamic>) : null,
      ts: DateTime.parse(json['ts'] as String),
    );
  }
}

class CalcRef {
  final String kind;
  final String id;

  CalcRef({required this.kind, required this.id});

  Map<String, dynamic> toJson() => {'kind': kind, 'id': id};

  factory CalcRef.fromJson(Map<String, dynamic> json) {
    return CalcRef(
      kind: json['kind'] as String,
      id: json['id'] as String,
    );
  }
}
