import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../shared/models/persona.dart';
import '../theme/design_tokens.dart';

/// AppStore — LocalStorage adapter.
/// Nguồn chân lý duy nhất cho state local của In-Sight.
/// Tương đương với Store object trong web app (insight_store).
class AppStore extends ChangeNotifier {
  static const _quotaKey = 'insight_quota';
  static const _themeKey = 'insight_theme';
  static const _personaKey = 'insight_persona';
  static const _sessionsKey = 'insight_sessions';
  static const _onboardedKey = 'insight_onboarded';
  static const _anonUserIdKey = 'insight_anon_user_id';

  late SharedPreferences _prefs;
  bool _initialized = false;

  // ─────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────
  QuotaStatus _quota = QuotaStatus.defaultFree();
  bool _isDarkMode = false;
  Persona _currentPersona = Persona.lay;
  List<JourneySession> _sessions = [];
  bool _hasOnboarded = false;
  String _anonUserId = '';

  // ─────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────
  bool get initialized => _initialized;
  QuotaStatus get quota => _quota;
  bool get isDarkMode => _isDarkMode;
  Persona get currentPersona => _currentPersona;
  List<JourneySession> get sessions =>
      List.unmodifiable(_sessions.reversed.toList());
  bool get hasOnboarded => _hasOnboarded;
  /// Anonymous device ID — generated once per install, never contains PII.
  /// Used as X-Anon-User-Id header for server-side quota tracking.
  String get anonUserId => _anonUserId;

  // ─────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadQuota();
    _loadTheme();
    _loadPersona();
    _loadSessions();
    _hasOnboarded = _prefs.getBool(_onboardedKey) ?? false;
    await _loadOrCreateAnonUserId();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadOrCreateAnonUserId() async {
    var id = _prefs.getString(_anonUserIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await _prefs.setString(_anonUserIdKey, id);
    }
    _anonUserId = id;
  }

  // ─────────────────────────────────────────
  // QUOTA
  // ─────────────────────────────────────────
  void _loadQuota() {
    final raw = _prefs.getString(_quotaKey);
    if (raw == null) {
      _quota = QuotaStatus.defaultFree();
      return;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _quota = QuotaStatus.fromJson(json);
      // Daily reset check
      final today = _todayStr();
      if (_quota.quotaDate != today) {
        _quota = QuotaStatus.defaultFree();
        _saveQuota();
      }
    } catch (_) {
      _quota = QuotaStatus.defaultFree();
    }
  }

  void _saveQuota() {
    _prefs.setString(_quotaKey, jsonEncode(_quota.toJson()));
  }

  /// Consume 1 token — returns false if quota empty
  bool consumeToken() {
    if (_quota.isEmpty && !_quota.isPremium) return false;
    if (_quota.isPremium) return true; // unlimited

    _quota = QuotaStatus(
      tokensRemaining: _quota.tokensRemaining - 1,
      tokensGranted: _quota.tokensGranted,
      adGrants: _quota.adGrants,
      isPremium: _quota.isPremium,
      resetsAt: _quota.resetsAt,
      quotaDate: _quota.quotaDate,
    );
    _saveQuota();
    notifyListeners();
    return true;
  }

  /// Grant ad reward tokens (+10)
  void grantAdReward() {
    _quota = QuotaStatus(
      tokensRemaining: _quota.tokensRemaining + DesignTokens.quotaAdReward,
      tokensGranted: _quota.tokensGranted + DesignTokens.quotaAdReward,
      adGrants: _quota.adGrants + 1,
      isPremium: _quota.isPremium,
      resetsAt: _quota.resetsAt,
      quotaDate: _quota.quotaDate,
    );
    _saveQuota();
    notifyListeners();
  }

  /// Sync quota from server response (GET /quota)
  void syncQuotaFromServer(Map<String, dynamic> serverData) {
    _quota = QuotaStatus.fromJson(serverData);
    _saveQuota();
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // THEME
  // ─────────────────────────────────────────
  void _loadTheme() {
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    _prefs.setBool(_themeKey, value);
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // PERSONA
  // ─────────────────────────────────────────
  void _loadPersona() {
    final id = _prefs.getString(_personaKey) ?? 'lay';
    _currentPersona = Persona.fromId(id);
  }

  void setPersona(Persona persona) {
    _currentPersona = persona;
    _prefs.setString(_personaKey, persona.id);
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // SESSIONS (Journey)
  // ─────────────────────────────────────────
  void _loadSessions() {
    final raw = _prefs.getString(_sessionsKey);
    if (raw == null) {
      _sessions = [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _sessions = list
          .map((e) => _sessionFromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _sessions = [];
    }
  }

  void _saveSessions() {
    _prefs.setString(
        _sessionsKey, jsonEncode(_sessions.map(_sessionToJson).toList()));
  }

  void addSession(JourneySession session) {
    _sessions.add(session);
    _saveSessions();
    notifyListeners();
  }

  void updateSession(JourneySession updated) {
    final idx = _sessions.indexWhere((s) => s.id == updated.id);
    if (idx >= 0) {
      _sessions[idx] = updated;
      _saveSessions();
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────
  // CASCADE WIPE — xoá toàn bộ dữ liệu
  // ─────────────────────────────────────────
  Future<void> cascadeWipe() async {
    await _prefs.clear();
    _quota = QuotaStatus.defaultFree();
    _isDarkMode = false;
    _currentPersona = Persona.lay;
    _sessions = [];
    _hasOnboarded = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // ONBOARDING
  // ─────────────────────────────────────────
  void markOnboarded() {
    _hasOnboarded = true;
    _prefs.setBool(_onboardedKey, true);
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────
  String _todayStr() {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _sessionToJson(JourneySession s) => {
        'id': s.id,
        'persona': s.persona.id,
        'date': s.date.millisecondsSinceEpoch,
        'messages': s.messages.map((m) => m.toJson()).toList(),
        'mood': s.mood?.name,
        'summary': s.summary,
      };

  JourneySession _sessionFromJson(Map<String, dynamic> json) {
    return JourneySession(
      id: json['id'] as String,
      persona: Persona.fromId(json['persona'] as String),
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      messages: (json['messages'] as List<dynamic>)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      mood: json['mood'] != null
          ? MoodTag.values.firstWhere(
              (t) => t.name == json['mood'],
              orElse: () => MoodTag.calm,
            )
          : null,
      summary: json['summary'] as String?,
    );
  }
}
