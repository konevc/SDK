import React, { useState, useRef, useCallback } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, FlatList,
  StyleSheet, ActivityIndicator, Linking, KeyboardAvoidingView,
  Platform, SafeAreaView,
} from 'react-native';

/* ── Types ── */
export interface KoneSDKConfig {
  apiKey: string;
  siteUrl?: string;
  greeting?: string;
  accentColor?: string;
  quickChips?: { label: string; question: string }[];
}

interface Message {
  id: string;
  role: 'ai' | 'user';
  text: string;
}

const DEFAULT_CHIPS = [
  { label: '👟 Cheap shoes UK',    question: 'Where can I buy cheap shoes in the UK?' },
  { label: '🤖 Top AI tools',       question: 'Recommend top AI tools for 2025' },
  { label: '💰 Best deals today',   question: 'What are the best online deals today?' },
  { label: '✈️ Cheap travel',       question: 'What are cheap travel destinations right now?' },
];

const API_ENDPOINT = 'https://go.kone.vc/mcp/chat';

/* ── API call ── */
async function sendToKone(
  apiKey: string,
  siteUrl: string,
  prompt: string,
  responseId: string | null,
): Promise<{ message: string; response_id: string }> {
  const payload: Record<string, string> = { prompt, url: siteUrl, api_key: apiKey };
  if (responseId) payload.response_id = responseId;

  const res = await fetch(API_ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const data = await res.json();
  return {
    message: data.message || data.response || data.text || data.content || JSON.stringify(data),
    response_id: data.response_id ? String(data.response_id) : '',
  };
}

/* ── Main component ── */
export function KoneSpecialOffers({
  apiKey,
  siteUrl = 'https://kone.vc',
  greeting = "Hi! 👋 I'm your free personal AI assistant.\n\nI can help you find the best deals, offers, and recommendations.\n\nTap a quick question or ask anything!",
  accentColor = '#5b6ef5',
  quickChips = DEFAULT_CHIPS,
}: KoneSDKConfig) {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [screen, setScreen] = useState<'landing' | 'chat'>('landing');
  const responseIdRef = useRef<string | null>(null);
  const listRef = useRef<FlatList>(null);

  const addMessage = useCallback((role: 'ai' | 'user', text: string) => {
    setMessages(prev => [...prev, { id: Date.now().toString() + role, role, text }]);
    setTimeout(() => listRef.current?.scrollToEnd({ animated: true }), 80);
  }, []);

  const openChat = useCallback((initialQuestion?: string) => {
    setScreen('chat');
    if (messages.length === 0) {
      addMessage('ai', greeting);
    }
    if (initialQuestion) {
      setTimeout(() => doSend(initialQuestion), 200);
    }
  }, [messages.length, greeting]);

  const doSend = useCallback(async (text: string) => {
    if (loading || !text.trim()) return;
    const prompt = text.trim();
    setInput('');
    addMessage('user', prompt);
    setLoading(true);
    try {
      const result = await sendToKone(apiKey, siteUrl, prompt, responseIdRef.current);
      if (result.response_id) responseIdRef.current = result.response_id;
      addMessage('ai', result.message);
    } catch (e: any) {
      addMessage('ai', `⚠️ Something went wrong: ${e.message}`);
    } finally {
      setLoading(false);
    }
  }, [loading, apiKey, siteUrl, addMessage]);

  const handleSend = () => doSend(input);

  const styles = makeStyles(accentColor);

  /* ── Landing screen ── */
  if (screen === 'landing') {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.landingHeader}>
          <View style={styles.statusRow}>
            <View style={styles.statusDot} />
            <Text style={styles.headerTitle}>AI Assistant</Text>
          </View>
          <View style={styles.freeBadge}>
            <Text style={styles.freeBadgeText}>Free · No signup</Text>
          </View>
        </View>

        <View style={styles.hero}>
          <View style={[styles.heroIcon, { backgroundColor: accentColor }]}>
            <Text style={styles.heroIconText}>AI</Text>
          </View>
          <Text style={styles.heroTitle}>Your free personal{'\n'}AI assistant</Text>
          <Text style={styles.heroSub}>Find deals, offers & recommendations</Text>
        </View>

        <Text style={styles.sectionLabel}>QUICK QUESTIONS</Text>

        <View style={styles.chipsContainer}>
          {quickChips.map((chip, i) => (
            <TouchableOpacity
              key={i}
              style={styles.chip}
              onPress={() => openChat(chip.question)}
              activeOpacity={0.7}
            >
              <Text style={styles.chipText}>{chip.label}</Text>
            </TouchableOpacity>
          ))}
        </View>

        <View style={styles.ctaArea}>
          <TouchableOpacity
            style={[styles.ctaButton, { backgroundColor: accentColor }]}
            onPress={() => openChat()}
            activeOpacity={0.85}
          >
            <Text style={styles.ctaButtonText}>💬  Ask your own question</Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => Linking.openURL('https://kone.vc/apps.html')}
            activeOpacity={0.7}
          >
            <Text style={styles.koneLink}>More AI agents ↗</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  /* ── Chat screen ── */
  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 20}
      >
        {/* Chat header */}
        <View style={styles.chatHeader}>
          <TouchableOpacity onPress={() => setScreen('landing')} style={styles.backBtn}>
            <Text style={styles.backBtnText}>‹</Text>
          </TouchableOpacity>
          <View style={[styles.chatAv, { backgroundColor: accentColor }]}>
            <Text style={styles.chatAvText}>AI</Text>
          </View>
          <View style={{ flex: 1 }}>
            <Text style={styles.chatHeaderName}>Your free personal AI assistant</Text>
            <View style={styles.onlineRow}>
              <View style={styles.statusDotSm} />
              <Text style={styles.onlineText}>online</Text>
            </View>
          </View>
        </View>

        {/* Messages */}
        <FlatList
          ref={listRef}
          data={messages}
          keyExtractor={m => m.id}
          style={styles.messagesList}
          contentContainerStyle={{ paddingVertical: 12, paddingHorizontal: 12 }}
          renderItem={({ item }) => (
            <View style={[styles.msgRow, item.role === 'user' && styles.msgRowUser]}>
              {item.role === 'ai' && (
                <View style={[styles.msgAv, { backgroundColor: accentColor }]}>
                  <Text style={styles.msgAvText}>AI</Text>
                </View>
              )}
              <View style={[
                styles.msgBubble,
                item.role === 'user' ? [styles.msgBubbleUser, { backgroundColor: accentColor }] : styles.msgBubbleAi,
              ]}>
                <Text style={[styles.msgText, item.role === 'user' && styles.msgTextUser]}>
                  {item.text}
                </Text>
              </View>
            </View>
          )}
          ListFooterComponent={loading ? (
            <View style={styles.typingRow}>
              <View style={[styles.msgAv, { backgroundColor: accentColor }]}>
                <Text style={styles.msgAvText}>AI</Text>
              </View>
              <View style={styles.typingBubble}>
                <ActivityIndicator size="small" color={accentColor} />
              </View>
            </View>
          ) : null}
        />

        {/* Input */}
        <View style={styles.inputRow}>
          <TextInput
            style={styles.input}
            value={input}
            onChangeText={setInput}
            placeholder="Ask me anything…"
            placeholderTextColor="#55535f"
            multiline
            maxLength={512}
            onSubmitEditing={handleSend}
            blurOnSubmit={false}
          />
          <TouchableOpacity
            style={[styles.sendBtn, { backgroundColor: accentColor }, loading && styles.sendBtnDisabled]}
            onPress={handleSend}
            disabled={loading}
            activeOpacity={0.8}
          >
            <Text style={styles.sendBtnText}>↑</Text>
          </TouchableOpacity>
        </View>

        <TouchableOpacity
          onPress={() => Linking.openURL('https://kone.vc/apps.html')}
          activeOpacity={0.7}
        >
          <Text style={styles.koneLink}>More AI agents ↗</Text>
        </TouchableOpacity>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

/* ── Styles factory ── */
function makeStyles(accent: string) {
  return StyleSheet.create({
    container: { flex: 1, backgroundColor: '#0d0d10' },

    // Landing
    landingHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: '#28282f' },
    statusRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
    statusDot: { width: 8, height: 8, borderRadius: 4, backgroundColor: '#3ecf72' },
    headerTitle: { fontSize: 14, fontWeight: '600', color: '#eeedf2' },
    freeBadge: { backgroundColor: '#1c1c22', borderWidth: 1, borderColor: '#333340', borderRadius: 20, paddingHorizontal: 10, paddingVertical: 3 },
    freeBadgeText: { fontSize: 11, color: '#55535f' },

    hero: { alignItems: 'center', paddingVertical: 28, paddingHorizontal: 20 },
    heroIcon: { width: 56, height: 56, borderRadius: 16, alignItems: 'center', justifyContent: 'center', marginBottom: 14 },
    heroIconText: { color: '#fff', fontSize: 16, fontWeight: '800' },
    heroTitle: { fontSize: 20, fontWeight: '700', color: '#eeedf2', textAlign: 'center', letterSpacing: -0.5, marginBottom: 8 },
    heroSub: { fontSize: 12, color: '#55535f', textAlign: 'center' },

    sectionLabel: { fontSize: 10, fontWeight: '700', color: '#55535f', letterSpacing: 1, paddingHorizontal: 16, marginBottom: 10 },

    chipsContainer: { paddingHorizontal: 14, gap: 6, marginBottom: 4 },
    chip: { backgroundColor: '#1c1c22', borderWidth: 1, borderColor: '#333340', borderRadius: 12, paddingVertical: 11, paddingHorizontal: 14, marginBottom: 6 },
    chipText: { color: '#9896a8', fontSize: 13 },

    ctaArea: { paddingHorizontal: 16, paddingTop: 8, paddingBottom: 16, gap: 10 },
    ctaButton: { borderRadius: 12, paddingVertical: 14, alignItems: 'center' },
    ctaButtonText: { color: '#fff', fontWeight: '600', fontSize: 14 },

    koneLink: { textAlign: 'center', fontSize: 11, color: '#55535f', paddingVertical: 8 },

    // Chat
    chatHeader: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 12, paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: '#28282f', backgroundColor: '#141418', gap: 8 },
    backBtn: { width: 32, height: 32, alignItems: 'center', justifyContent: 'center' },
    backBtnText: { fontSize: 24, color: '#9896a8', lineHeight: 28 },
    chatAv: { width: 32, height: 32, borderRadius: 8, alignItems: 'center', justifyContent: 'center' },
    chatAvText: { color: '#fff', fontSize: 10, fontWeight: '800' },
    chatHeaderName: { fontSize: 13, fontWeight: '600', color: '#eeedf2' },
    onlineRow: { flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 2 },
    statusDotSm: { width: 5, height: 5, borderRadius: 3, backgroundColor: '#3ecf72' },
    onlineText: { fontSize: 10, color: '#55535f' },

    messagesList: { flex: 1, backgroundColor: '#0d0d10' },
    msgRow: { flexDirection: 'row', alignItems: 'flex-end', marginBottom: 8, gap: 8 },
    msgRowUser: { flexDirection: 'row-reverse' },
    msgAv: { width: 24, height: 24, borderRadius: 6, alignItems: 'center', justifyContent: 'center', marginBottom: 2 },
    msgAvText: { color: '#fff', fontSize: 8, fontWeight: '800' },
    msgBubble: { maxWidth: '78%', borderRadius: 12, paddingVertical: 8, paddingHorizontal: 12 },
    msgBubbleAi: { backgroundColor: '#1c1c22' },
    msgBubbleUser: { borderRadius: 12 },
    msgText: { fontSize: 13, color: '#eeedf2', lineHeight: 19 },
    msgTextUser: { color: '#fff' },

    typingRow: { flexDirection: 'row', alignItems: 'center', gap: 8, paddingHorizontal: 12, marginBottom: 8 },
    typingBubble: { backgroundColor: '#1c1c22', borderRadius: 12, paddingVertical: 10, paddingHorizontal: 16 },

    inputRow: { flexDirection: 'row', alignItems: 'flex-end', paddingHorizontal: 12, paddingVertical: 8, borderTopWidth: 1, borderTopColor: '#28282f', backgroundColor: '#141418', gap: 8 },
    input: { flex: 1, backgroundColor: '#1c1c22', borderWidth: 1, borderColor: '#333340', borderRadius: 10, paddingHorizontal: 12, paddingVertical: 9, color: '#eeedf2', fontSize: 13, maxHeight: 100 },
    sendBtn: { width: 36, height: 36, borderRadius: 10, alignItems: 'center', justifyContent: 'center' },
    sendBtnDisabled: { opacity: 0.35 },
    sendBtnText: { color: '#fff', fontSize: 18, fontWeight: '700' },
  });
}
