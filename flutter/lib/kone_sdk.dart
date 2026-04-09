library kone_sdk;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────
//  Config
// ─────────────────────────────────────────
class KoneSDKConfig {
  final String apiKey;
  final String siteUrl;
  final String? greeting;
  final Color accentColor;
  final List<KoneQuickChip> quickChips;

  const KoneSDKConfig({
    required this.apiKey,
    this.siteUrl = 'https://kone.vc',
    this.greeting,
    this.accentColor = const Color(0xFF5B6EF5),
    this.quickChips = _defaultChips,
  });
}

class KoneQuickChip {
  final String label;
  final String question;
  const KoneQuickChip({required this.label, required this.question});
}

const _defaultChips = [
  KoneQuickChip(label: '👟 Cheap shoes UK',  question: 'Where can I buy cheap shoes in the UK?'),
  KoneQuickChip(label: '🤖 Top AI tools',    question: 'Recommend top AI tools for 2025'),
  KoneQuickChip(label: '💰 Best deals today', question: 'What are the best online deals today?'),
  KoneQuickChip(label: '✈️ Cheap travel',    question: 'What are cheap travel destinations right now?'),
];

// ─────────────────────────────────────────
//  Message model
// ─────────────────────────────────────────
class _Message {
  final String id;
  final bool isAi;
  final String text;
  _Message({required this.isAi, required this.text})
      : id = DateTime.now().millisecondsSinceEpoch.toString() + (isAi ? 'a' : 'u');
}

// ─────────────────────────────────────────
//  Main widget
// ─────────────────────────────────────────
class KoneSpecialOffers extends StatefulWidget {
  final KoneSDKConfig config;
  const KoneSpecialOffers({super.key, required this.config});

  @override
  State<KoneSpecialOffers> createState() => _KoneSpecialOffersState();
}

class _KoneSpecialOffersState extends State<KoneSpecialOffers> {
  static const _apiEndpoint = 'https://go.kone.vc/mcp/chat';

  final _messages = <_Message>[];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = false;
  bool _chatScreen = false;
  String? _responseId;

  KoneSDKConfig get cfg => widget.config;

  String get _greeting =>
      cfg.greeting ??
      "Hi! 👋 I'm your free personal AI assistant.\n\n"
      "I can help you find the best deals, offers and recommendations.\n\n"
      "Tap a quick question or ask anything!";

  // ── API ──
  Future<void> _send(String prompt) async {
    if (_loading || prompt.trim().isEmpty) return;

    setState(() {
      _messages.add(_Message(isAi: false, text: prompt.trim()));
      _loading = true;
    });
    _scrollToBottom();

    final body = <String, String>{
      'prompt': prompt.trim(),
      'url': cfg.siteUrl,
      'api_key': cfg.apiKey,
      if (_responseId != null) 'response_id': _responseId!,
    };

    try {
      final res = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['response_id'] != null) _responseId = data['response_id'].toString();
      final msg = data['message'] ?? data['response'] ?? data['text'] ?? data['content'] ?? jsonEncode(data);
      setState(() => _messages.add(_Message(isAi: true, text: msg.toString())));
    } catch (e) {
      setState(() => _messages.add(_Message(isAi: true, text: '⚠️ Error: $e')));
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _openChat([String? initialQ]) {
    setState(() => _chatScreen = true);
    if (_messages.isEmpty) {
      _messages.add(_Message(isAi: true, text: _greeting));
    }
    if (initialQ != null) {
      Future.delayed(const Duration(milliseconds: 200), () => _send(initialQ));
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _send(text);
  }

  // ─────────────────
  // BUILD
  // ─────────────────
  @override
  Widget build(BuildContext context) {
    return _chatScreen ? _buildChat() : _buildLanding();
  }

  // ── Landing ──
  Widget _buildLanding() {
    final accent = cfg.accentColor;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D10),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildLandingHeader(accent),
            // Hero
            _buildHero(accent),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text('QUICK QUESTIONS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: Color(0xFF55535f), letterSpacing: 1.2)),
            ),
            // Chips
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  ...cfg.quickChips.map((c) => _buildChip(c, accent)),
                  const SizedBox(height: 12),
                  // CTA
                  GestureDetector(
                    onTap: () => _openChat(),
                    child: Container(
                      decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: const Text('💬  Ask your own question',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _koneFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandingHeader(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF28282F)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF3ECF72), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            const Text('AI Assistant', style: TextStyle(color: Color(0xFFEEEDF2), fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFF1C1C22), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF333340))),
            child: const Text('Free · No signup', style: TextStyle(color: Color(0xFF55535F), fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      alignment: Alignment.center,
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 4))]),
          alignment: Alignment.center,
          child: const Text('AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        const SizedBox(height: 14),
        const Text('Your free personal\nAI assistant',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFEEEDF2), fontSize: 20, fontWeight: FontWeight.w700, height: 1.3)),
        const SizedBox(height: 8),
        const Text('Find deals, offers & recommendations',
            style: TextStyle(color: Color(0xFF55535F), fontSize: 12)),
      ]),
    );
  }

  Widget _buildChip(KoneQuickChip chip, Color accent) {
    return GestureDetector(
      onTap: () => _openChat(chip.question),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333340)),
        ),
        child: Text(chip.label, style: const TextStyle(color: Color(0xFF9896A8), fontSize: 13)),
      ),
    );
  }

  // ── Chat ──
  Widget _buildChat() {
    final accent = cfg.accentColor;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D10),
      body: SafeArea(
        child: Column(
          children: [
            _buildChatHeader(accent),
            Expanded(child: _buildMessagesList(accent)),
            if (_loading) _buildTypingIndicator(accent),
            _buildInputRow(accent),
            _koneFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
          color: Color(0xFF141418), border: Border(bottom: BorderSide(color: Color(0xFF28282F)))),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF9896A8), size: 18),
          onPressed: () => setState(() => _chatScreen = false),
        ),
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your free personal AI assistant',
                style: TextStyle(color: Color(0xFFEEEDF2), fontSize: 13, fontWeight: FontWeight.w600)),
            Row(children: [
              Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF3ECF72), shape: BoxShape.circle)),
              const SizedBox(width: 4),
              const Text('online', style: TextStyle(color: Color(0xFF55535F), fontSize: 10)),
            ]),
          ],
        )),
      ]),
    );
  }

  Widget _buildMessagesList(Color accent) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final m = _messages[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: m.isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (m.isAi) ...[
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(6)),
                  alignment: Alignment.center,
                  child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: m.isAi ? const Color(0xFF1C1C22) : accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(m.text, style: const TextStyle(color: Color(0xFFEEEDF2), fontSize: 13, height: 1.5)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(6)),
          alignment: Alignment.center,
          child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF1C1C22), borderRadius: BorderRadius.circular(12)),
          child: SizedBox(width: 32, height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: accent)),
        ),
      ]),
    );
  }

  Widget _buildInputRow(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
          color: Color(0xFF141418), border: Border(top: BorderSide(color: Color(0xFF28282F)))),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _textController,
            style: const TextStyle(color: Color(0xFFEEEDF2), fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Ask me anything…',
              hintStyle: const TextStyle(color: Color(0xFF55535F)),
              filled: true, fillColor: const Color(0xFF1C1C22),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF333340))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF333340))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: accent)),
            ),
            maxLines: null, maxLength: 512, buildCounter: (_,{__,___,____}) => null,
            onSubmitted: (_) => _handleSend(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _loading ? null : _handleSend,
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: _loading ? accent.withOpacity(0.35) : accent, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: const Text('↑', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _koneFooter() {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse('https://kone.vc/apps.html')),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('More AI agents ↗', textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF55535F), fontSize: 11)),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
