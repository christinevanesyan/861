class BetInfo {
  final String odds;
  final double houseEdgePct;
  final String tip;

  BetInfo({
    required this.odds,
    required this.houseEdgePct,
    required this.tip,
  });
}

class OddsData {
  static final Map<String, Map<String, BetInfo>> data = {
    'Blackjack': {
      'Even Money (1:1)': BetInfo(
        odds: '1:1',
        houseEdgePct: 0.5,
        tip: 'Basic even-money payout.',
      ),
      'Blackjack (3:2)': BetInfo(
        odds: '3:2',
        houseEdgePct: 0.5,
        tip: 'Varies by rules; use for natural 21.',
      ),
      'Insurance (2:1)': BetInfo(
        odds: '2:1',
        houseEdgePct: 7.5,
        tip: 'Generally negative EV.',
      ),
    },
    'Roulette': {
      'Straight (35:1)': BetInfo(
        odds: '35:1',
        houseEdgePct: 2.7,
        tip: 'Single number bet.',
      ),
      'Split (17:1)': BetInfo(
        odds: '17:1',
        houseEdgePct: 2.7,
        tip: 'Two numbers.',
      ),
      'Red/Black (1:1)': BetInfo(
        odds: '1:1',
        houseEdgePct: 2.7,
        tip: 'Even-money outside bet.',
      ),
    },
    'Baccarat': {
      'Player (1:1)': BetInfo(
        odds: '1:1',
        houseEdgePct: 1.24,
        tip: 'Player hand wins.',
      ),
      'Banker (1:1, 5% commission)': BetInfo(
        odds: '0.95:1',
        houseEdgePct: 1.06,
        tip: 'Best odds, commission applies.',
      ),
      'Tie (8:1)': BetInfo(
        odds: '8:1',
        houseEdgePct: 14.4,
        tip: 'High variance, poor odds.',
      ),
    },
    'Craps': {
      'Pass Line (1:1)': BetInfo(
        odds: '1:1',
        houseEdgePct: 1.41,
        tip: 'Core craps bet.',
      ),
      "Don't Pass (1:1)": BetInfo(
        odds: '1:1',
        houseEdgePct: 1.36,
        tip: 'Against the shooter.',
      ),
      'Field (1:1 or 2:1 on 2/12)': BetInfo(
        odds: 'varies',
        houseEdgePct: 5.5,
        tip: 'Check table rules.',
      ),
    },
  };

  static List<String> get games => data.keys.toList();

  static List<String> getBetTypes(String game) {
    return data[game]?.keys.toList() ?? [];
  }

  static BetInfo? getBetInfo(String game, String betType) {
    return data[game]?[betType];
  }

  static double calculatePayout(String odds, double amount) {
    if (odds == 'varies') return amount; // Return input for variable odds
    
    try {
      final parts = odds.split(':');
      if (parts.length != 2) return amount;
      
      final numerator = double.parse(parts[0]);
      final denominator = double.parse(parts[1]);
      
      return amount * (numerator / denominator);
    } catch (e) {
      return amount;
    }
  }
}
