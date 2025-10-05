import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';
import '../models/calculators.dart';
import '../models/preferences.dart';

class StorageService {
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keySessions = 'sessions';
  static const String _keyActiveSessionId = 'active_session_id';
  static const String _keyPayouts = 'payouts';
  static const String _keyChipCalcs = 'chip_calcs';
  static const String _keyTipCalcs = 'tip_calcs';
  static const String _keyPreferences = 'preferences';

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  Future<void> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
  }

  // Sessions
  Future<List<Session>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keySessions);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Session.fromJson(json)).toList();
  }

  Future<void> saveSessions(List<Session> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_keySessions, jsonString);
  }

  Future<Session?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? activeId = prefs.getString(_keyActiveSessionId);
    if (activeId == null) return null;

    final sessions = await getSessions();
    try {
      return sessions.firstWhere((s) => s.id == activeId);
    } catch (e) {
      return null;
    }
  }

  Future<void> setActiveSession(String? sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    if (sessionId == null) {
      await prefs.remove(_keyActiveSessionId);
    } else {
      await prefs.setString(_keyActiveSessionId, sessionId);
    }
  }

  Future<void> saveSession(Session session) async {
    final sessions = await getSessions();
    final index = sessions.indexWhere((s) => s.id == session.id);
    
    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.add(session);
    }
    
    await saveSessions(sessions);
  }

  Future<void> deleteSession(String sessionId) async {
    final sessions = await getSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    await saveSessions(sessions);
  }

  // Payouts
  Future<List<PayoutSaved>> getPayouts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyPayouts);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => PayoutSaved.fromJson(json)).toList();
  }

  Future<void> savePayout(PayoutSaved payout) async {
    final payouts = await getPayouts();
    payouts.add(payout);
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(payouts.map((p) => p.toJson()).toList());
    await prefs.setString(_keyPayouts, jsonString);
  }

  // Chip Calcs
  Future<List<ChipCalcSaved>> getChipCalcs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyChipCalcs);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => ChipCalcSaved.fromJson(json)).toList();
  }

  Future<void> saveChipCalc(ChipCalcSaved chipCalc) async {
    final chipCalcs = await getChipCalcs();
    chipCalcs.add(chipCalc);
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(chipCalcs.map((c) => c.toJson()).toList());
    await prefs.setString(_keyChipCalcs, jsonString);
  }

  // Tip Calcs
  Future<List<TipCalcSaved>> getTipCalcs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyTipCalcs);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => TipCalcSaved.fromJson(json)).toList();
  }

  Future<void> saveTipCalc(TipCalcSaved tipCalc) async {
    final tipCalcs = await getTipCalcs();
    tipCalcs.add(tipCalc);
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(tipCalcs.map((t) => t.toJson()).toList());
    await prefs.setString(_keyTipCalcs, jsonString);
  }

  // Preferences
  Future<Preferences> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyPreferences);
    if (jsonString == null) return Preferences();
    
    return Preferences.fromJson(json.decode(jsonString));
  }

  Future<void> savePreferences(Preferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(preferences.toJson());
    await prefs.setString(_keyPreferences, jsonString);
  }

  // Clear all data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool(_keyFirstLaunch, false); // Keep onboarding completed
  }
}
