import '../../shared/models/persona.dart';

/// PersonaEngine — local AI response simulator.
/// Dùng trong dev/offline mode. Production thay bằng ApiClient.sendChatMessage().
///
/// Implement đúng behavior từ Bio_Lay.md, Bio_Mentor.md, Bio_Soul.md.
class PersonaEngine {
  // ─────────────────────────────────────────
  // SMART TOPIC SUGGESTIONS — 3 chip/persona
  // ─────────────────────────────────────────
  static List<String> topicSuggestions(Persona persona) {
    switch (persona) {
      case Persona.lay:
        return [
          'kể tớ nghe drama hôm nay đi 👀',
          'tớ cần được roast thẳng thắn 😂',
          'ôi trời mệt quá cậu ơi...',
        ];
      case Persona.mentor:
        return [
          'Tôi đang thiếu động lực làm việc',
          'Làm sao để quản lý cảm xúc tốt hơn?',
          'Tôi cần một framework để giải quyết vấn đề này',
        ];
      case Persona.soul:
        return [
          'Tôi cảm thấy trống rỗng và không biết tại sao',
          'Gần đây tôi hay suy nghĩ nhiều về bản thân',
          'Tôi muốn được lắng nghe mà không bị phán xét',
        ];
    }
  }

  // ─────────────────────────────────────────
  // RESPONSE GENERATION
  // ─────────────────────────────────────────
  static List<String> generateResponse(Persona persona, String userMessage) {
    switch (persona) {
      case Persona.lay:
        return _layResponse(userMessage);
      case Persona.mentor:
        return _mentorResponse(userMessage);
      case Persona.soul:
        return _soulResponse(userMessage);
    }
  }

  // ─────────────────────────────────────────
  // LẦY — Gen-Z bestie, 3 bubbles, no-caps
  // Bio_Lay.md: roast nhẹ, đồng cảm thật, slang
  // ─────────────────────────────────────────
  static List<String> _layResponse(String msg) {
    final lower = msg.toLowerCase();

    if (_contains(lower, ['mệt', 'mệt mỏi', 'exhausted'])) {
      return [
        'ôi trời ơi cậu lại mệt rồi á 😩',
        'thôi kể tớ nghe đi, hôm nay xảy ra chuyện gì vậy??',
        'tớ ở đây nghe nha, không judge đâu promise 🫶',
      ];
    }

    if (_contains(lower, ['buồn', 'sad', 'khóc', 'chán'])) {
      return [
        'ủa sao buồn vậy cưng ơi 🥺',
        'kể tớ nghe điiiiiii tớ đang rảnh nè',
        'không phải một mình đâu nha, tớ đây rồi 💕',
      ];
    }

    if (_contains(lower, ['drama', 'drama hôm nay', 'chuyện'])) {
      return [
        'DRAMA?? 👀 tớ đang nghe đây kể nhanh lên!!',
        'ôi trời ơi cái này nghe có vẻ căng ghê',
        'thôi kể từ đầu đi, tớ muốn biết hết 🍿',
      ];
    }

    if (_contains(lower, ['roast', 'thẳng thắn', 'sự thật'])) {
      return [
        'oke fine cậu muốn nghe thật thì tớ nói thật nha 😂',
        'tớ thấy cậu đang overthink quá rồi đó, relax đi bạn ơi',
        'nhưng mà seriously cậu đang làm tốt hơn cậu nghĩ đó 💪',
      ];
    }

    if (_contains(lower, ['yêu', 'crush', 'thích', 'người ấy'])) {
      return [
        'ỐI TRỜI ƠI có chuyện tình cảm rồi?? 👀',
        'kể điiiii tớ đang tò mò lắm rồi đây',
        'à mà cậu thấy sao, tim đập nhanh chưa 💓',
      ];
    }

    if (_contains(lower, ['công việc', 'sếp', 'deadline', 'áp lực'])) {
      return [
        'ôi deadline nữa á 😭 cậu ổn không vậy',
        'thôi hít thở đi rồi kể tớ nghe xem chuyện gì',
        'cậu không phải một mình chiến đâu, tớ đây 💪',
      ];
    }

    // Default
    return [
      'ừm... tớ đang nghe nè cậu ơi 👂',
      'kể thêm đi, tớ muốn hiểu hơn chút',
      'cậu đang cảm thấy thế nào thật ra? 🤍',
    ];
  }

  // ─────────────────────────────────────────
  // MENTOR — Stoic, frameworks, structured
  // Bio_Mentor.md: empathy + framework + action
  // ─────────────────────────────────────────
  static List<String> _mentorResponse(String msg) {
    final lower = msg.toLowerCase();

    if (_contains(lower, ['động lực', 'motivation', 'lười', 'không muốn'])) {
      return [
        'Tôi hiểu cảm giác thiếu động lực — đây là trạng thái rất bình thường và có giải pháp.\n\n'
            'Theo nghiên cứu của BJ Fogg về Tiny Habits: **động lực không phải điểm khởi đầu, hành động mới là**.\n\n'
            '**Framework 2 phút**: Xác định một hành động nhỏ nhất bạn có thể làm ngay bây giờ. '
            'Ví dụ: không phải "làm xong dự án" mà là "mở file dự án ra".\n\n'
            'Bạn đang bị mắc kẹt ở bước nào cụ thể?',
      ];
    }

    if (_contains(lower, ['cảm xúc', 'kiểm soát', 'tức giận', 'lo lắng', 'anxiety'])) {
      return [
        'Quản lý cảm xúc là một kỹ năng — và như mọi kỹ năng, nó có thể luyện tập được.\n\n'
            '**Mô hình ABC của Cognitive Behavioral Therapy**:\n'
            '• **A** (Antecedent) — Sự kiện kích hoạt là gì?\n'
            '• **B** (Belief) — Bạn đang diễn giải nó như thế nào?\n'
            '• **C** (Consequence) — Cảm xúc và hành vi bạn phản ứng ra sao?\n\n'
            'Thay đổi **B** sẽ thay đổi **C**. Hãy kể cho tôi nghe về sự kiện kích hoạt gần đây nhất của bạn.',
      ];
    }

    if (_contains(lower, ['quyết định', 'lựa chọn', 'không biết', 'khó'])) {
      return [
        'Đây là framework tôi hay dùng cho những quyết định khó:\n\n'
            '**Ma trận Eisenhower + Regret Minimization**:\n'
            '1. Liệt kê tất cả lựa chọn\n'
            '2. Hỏi: "10 năm sau, tôi có hối hận vì đã **không** chọn X không?"\n'
            '3. Phân loại: Khẩn cấp vs. Quan trọng\n\n'
            'Bạn đang phải đưa ra quyết định về điều gì? Tôi muốn giúp bạn phân tích cụ thể hơn.',
      ];
    }

    if (_contains(lower, ['mệt', 'burnout', 'kiệt sức'])) {
      return [
        'Burnout là tín hiệu của cơ thể và tâm trí — không phải điểm yếu, mà là dữ liệu quan trọng.\n\n'
            '**Chẩn đoán Burnout (Maslach)**: Ba chiều cần kiểm tra:\n'
            '• Kiệt sức cảm xúc (emotional exhaustion)\n'
            '• Cynicism / mất kết nối với công việc\n'
            '• Giảm hiệu suất cá nhân\n\n'
            'Bạn đang ở mức nào trên thang 1-10 cho mỗi chiều? Từ đó tôi có thể gợi ý recovery plan phù hợp.',
      ];
    }

    // Default
    return [
      'Tôi đang lắng nghe bạn.\n\n'
          'Để tôi có thể hỗ trợ tốt nhất, hãy kể thêm về:\n'
          '• Tình huống cụ thể bạn đang đối mặt là gì?\n'
          '• Bạn đã thử những cách nào rồi?\n'
          '• Kết quả mong muốn của bạn là gì?\n\n'
          'Mọi thứ đều có giải pháp — chúng ta sẽ tìm ra cùng nhau.',
    ];
  }

  // ─────────────────────────────────────────
  // SOUL — Reflective listening, token limiter
  // Bio_Soul.md: mirror + presence + depth
  // Output tối đa 30% độ dài input (token limiter)
  // ─────────────────────────────────────────
  static List<String> _soulResponse(String msg) {
    final lower = msg.toLowerCase();
    // Token limiter: output ≤ 30% input length (chars as proxy)
    // Soul không roast, không advice, chỉ lắng nghe và phản chiếu

    if (_contains(lower, ['trống rỗng', 'empty', 'void', 'không biết tại sao'])) {
      return [_limitTokens(
        msg,
        'Cảm giác trống rỗng mà không có lý do rõ ràng... '
        'Tôi ở đây với bạn trong khoảnh khắc này.',
      )];
    }

    if (_contains(lower, ['bản thân', 'identity', 'tôi là ai', 'suy nghĩ nhiều'])) {
      return [_limitTokens(
        msg,
        'Những câu hỏi về bản thân thường nảy sinh khi chúng ta đang ở một giai đoạn quan trọng. '
        'Bạn muốn chia sẻ những suy nghĩ đó không?',
      )];
    }

    if (_contains(lower, ['lắng nghe', 'phán xét', 'hiểu', 'không ai'])) {
      return [_limitTokens(
        msg,
        'Tôi ở đây. Không phán xét. Chỉ lắng nghe. '
        'Bạn có thể kể thêm không?',
      )];
    }

    if (_contains(lower, ['mất', 'đau', 'grief', 'khóc'])) {
      return [_limitTokens(
        msg,
        'Nỗi đau bạn đang cảm thấy là thật. '
        'Tôi không cần nói gì thêm — chỉ muốn bạn biết tôi đang ở đây.',
      )];
    }

    // Default Soul response
    return [_limitTokens(
      msg,
      'Tôi cảm nhận được điều bạn đang chia sẻ. '
      'Kể thêm cho tôi nghe nhé — tôi muốn hiểu hơn về bạn.',
    )];
  }

  // ─────────────────────────────────────────
  // SOUL TOKEN LIMITER — output ≤ 30% input
  // ─────────────────────────────────────────
  static String _limitTokens(String input, String output) {
    final maxLen = (input.length * 0.3).floor().clamp(20, 200);
    if (output.length <= maxLen) return output;
    // Truncate gracefully at word boundary
    final truncated = output.substring(0, maxLen);
    final lastSpace = truncated.lastIndexOf(' ');
    return lastSpace > 0 ? '${truncated.substring(0, lastSpace)}...' : '$truncated...';
  }

  // ─────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────
  static bool _contains(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  // SOS detection — trigger keywords
  static bool detectSOS(String text) {
    const sosKeywords = [
      'tự tử', 'muốn chết', 'không muốn sống',
      'tự làm đau', 'suicide', 'kill myself',
      'kết thúc tất cả', 'không còn ý nghĩa',
    ];
    final lower = text.toLowerCase();
    return sosKeywords.any((k) => lower.contains(k));
  }

  // SOS response — luôn override persona
  static String sosResponse() {
    return '💙 Tôi nghe bạn. Cảm xúc này rất nặng nề.\n\n'
        'Xin hãy liên hệ đường dây hỗ trợ sức khỏe tâm thần:\n'
        '**Đường dây 1800 599 920** (miễn phí, 24/7)\n\n'
        'Bạn không một mình. Tôi ở đây cùng bạn.';
  }
}
