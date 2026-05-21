import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/models/persona.dart';

/// API Client — implements API_Contract.md v1.0.0
/// Base URL configurable via environment / build flavor.
class ApiClient {
  static const _baseUrlDev = 'http://localhost:8787/api/v1';
  static const _baseUrlProd = 'https://api.insight.app/api/v1';

  final String baseUrl;
  final String appKey;
  final String anonUserId;

  ApiClient({
    required this.appKey,
    required this.anonUserId,
    bool isProduction = false,
  }) : baseUrl = isProduction ? _baseUrlProd : _baseUrlDev;

  Map<String, String> get _headers => {
        'X-App-Key': appKey,
        'X-Anon-User-Id': anonUserId,
        'Content-Type': 'application/json',
      };

  // ─────────────────────────────────────────
  // POST /chat/{persona} — SSE Streaming
  // ─────────────────────────────────────────
  Stream<ChatStreamEvent> sendChatMessage({
    required Persona persona,
    required String message,
    required String sessionId,
    required List<Map<String, String>> history,
  }) async* {
    final uri = Uri.parse('$baseUrl/chat/${persona.id}');
    final body = jsonEncode({
      'message': message,
      'session_id': sessionId,
      'history': history,
      'client_ts': DateTime.now().millisecondsSinceEpoch,
    });

    final request = http.Request('POST', uri);
    request.headers.addAll(_headers);
    request.headers['Accept'] = 'text/event-stream';
    request.body = body;

    try {
      final response = await request.send();

      if (response.statusCode != 200) {
        final errBody = await response.stream.bytesToString();
        final errJson = jsonDecode(errBody) as Map<String, dynamic>;
        throw ApiException.fromJson(errJson, response.statusCode);
      }

      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // keep incomplete line

        String? eventType;
        String? dataLine;

        for (final line in lines) {
          if (line.startsWith('event: ')) {
            eventType = line.substring(7).trim();
          } else if (line.startsWith('data: ')) {
            dataLine = line.substring(6).trim();
          } else if (line.isEmpty && eventType != null && dataLine != null) {
            final data = jsonDecode(dataLine) as Map<String, dynamic>;
            yield ChatStreamEvent(type: eventType, data: data);
            eventType = null;
            dataLine = null;
          }
        }
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        code: 'E099',
        message: 'Mạng lỗi: $e',
        httpStatus: 0,
      );
    }
  }

  // ─────────────────────────────────────────
  // GET /quota
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> getQuota() async {
    final uri = Uri.parse('$baseUrl/quota');
    final response = await http.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  // ─────────────────────────────────────────
  // POST /quota/reward
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> grantAdReward(String ssvToken) async {
    final uri = Uri.parse('$baseUrl/quota/reward');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'ad_network': 'admob',
        'ssv_token': ssvToken,
      }),
    );
    return _handleResponse(response);
  }

  // ─────────────────────────────────────────
  // POST /ai/reflection/{persona}
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> generateReflection({
    required Persona persona,
    required String milestoneType,
    required String sessionId,
  }) async {
    final uri = Uri.parse('$baseUrl/ai/reflection/${persona.id}');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'milestone_type': milestoneType,
        'session_id': sessionId,
        'client_ts': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    return _handleResponse(response);
  }

  // ─────────────────────────────────────────
  // DELETE /ai/memory — Cascade Wipe step 1
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> purgeMemory() async {
    final uri = Uri.parse('$baseUrl/ai/memory');
    final response = await http.delete(uri, headers: _headers);
    return _handleResponse(response);
  }

  // ─────────────────────────────────────────
  // GET /health
  // ─────────────────────────────────────────
  Future<bool> healthCheck() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────
  // HELPER
  // ─────────────────────────────────────────
  Map<String, dynamic> _handleResponse(http.Response response) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (json['data'] as Map<String, dynamic>?) ?? json;
    }
    throw ApiException.fromJson(json, response.statusCode);
  }
}

// ─────────────────────────────────────────
// SSE Event model
// ─────────────────────────────────────────
class ChatStreamEvent {
  final String type; // 'chunk' | 'done'
  final Map<String, dynamic> data;

  const ChatStreamEvent({required this.type, required this.data});

  bool get isChunk => type == 'chunk';
  bool get isDone => type == 'done';

  String? get delta => data['delta'] as String?;
  int? get quotaRemaining => data['quota_remaining'] as int?;
  String? get finishReason => data['finish_reason'] as String?;
}

// ─────────────────────────────────────────
// API Exception
// ─────────────────────────────────────────
class ApiException implements Exception {
  final String code;
  final String message;
  final int httpStatus;
  final String? traceId;

  const ApiException({
    required this.code,
    required this.message,
    required this.httpStatus,
    this.traceId,
  });

  factory ApiException.fromJson(Map<String, dynamic> json, int httpStatus) {
    final err = json['error'] as Map<String, dynamic>? ?? json;
    return ApiException(
      code: err['code'] as String? ?? 'E099',
      message: err['message'] as String? ?? 'Lỗi không xác định',
      httpStatus: httpStatus,
      traceId: err['trace_id'] as String?,
    );
  }

  bool get isQuotaEmpty => code == 'E003';
  bool get isRateLimited => code == 'E004';
  bool get isServiceUnavailable => code == 'E005';

  @override
  String toString() => 'ApiException($code): $message';
}
