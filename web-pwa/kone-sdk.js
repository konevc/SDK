/*!
 * KoneSDK Web/PWA v1.0.0
 * Drop-in Special Offers tab for web apps and PWAs
 * Usage: see README.md
 */

(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined'
    ? module.exports = factory()
    : typeof define === 'function' && define.amd
      ? define(factory)
      : (global.KoneSDK = factory());
}(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';

  const API_ENDPOINT = 'https://go.kone.vc/mcp/chat';
  const KONE_APPS    = 'https://kone.vc/apps.html';

  const DEFAULT_CHIPS = [
    { label: '👟 Cheap shoes UK',   question: 'Where can I buy cheap shoes in the UK?' },
    { label: '🤖 Top AI tools',     question: 'Recommend top AI tools for 2025' },
    { label: '💰 Best deals today', question: 'What are the best online deals today?' },
    { label: '✈️ Cheap travel',    question: 'What are cheap travel destinations right now?' },
  ];

  // ── Styles ──────────────────────────────────────────────────────────────

  const CSS = `
    .kone-root {
      --acc:   #5b6ef5;
      --acc2:  #7b8fff;
      --bg:    #0d0d10;
      --s1:    #141418;
      --s2:    #1c1c22;
      --s3:    #252528;
      --bd:    #28282f;
      --bd2:   #333340;
      --tx:    #eeedf2;
      --tx2:   #9896a8;
      --tx3:   #55535f;
      --green: #3ecf72;
      font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
      font-size: 14px;
      color: var(--tx);
      background: var(--bg);
      height: 100%;
      display: flex;
      flex-direction: column;
      overflow: hidden;
      -webkit-font-smoothing: antialiased;
    }
    .kone-root * { box-sizing: border-box; margin: 0; padding: 0; }

    /* ─ Header ─ */
    .kone-hdr {
      display: flex; align-items: center; justify-content: space-between;
      padding: 13px 16px; border-bottom: 1px solid var(--bd); flex-shrink: 0;
    }
    .kone-hdr-left { display: flex; align-items: center; gap: 9px; }
    .kone-pulse { position:relative; width:10px; height:10px; flex-shrink:0; }
    .kone-pulse-dot { width:10px; height:10px; background:var(--green); border-radius:50%; position:absolute; inset:0; }
    .kone-pulse-ring { position:absolute; inset:-3px; border-radius:50%; background:rgba(62,207,114,.22); animation:koneRing 2.5s ease-out infinite; }
    @keyframes koneRing { 0%{transform:scale(.5);opacity:1} 100%{transform:scale(2.2);opacity:0} }
    .kone-hdr-title { font-size:14px; font-weight:600; color:var(--tx); }
    .kone-badge { font-size:11px; color:var(--tx3); background:var(--s2); border:1px solid var(--bd2); padding:3px 9px; border-radius:20px; }

    /* ─ Hero ─ */
    .kone-hero {
      display:flex; flex-direction:column; align-items:center; text-align:center;
      padding:28px 20px 18px;
      background: radial-gradient(ellipse 220px 140px at 50% 0%, rgba(91,110,245,.07) 0%, transparent 70%);
      flex-shrink: 0;
    }
    .kone-hero-icon {
      width:56px; height:56px; background:var(--acc); border-radius:14px;
      display:flex; align-items:center; justify-content:center; color:#fff;
      font-size:16px; font-weight:800; margin-bottom:14px;
      box-shadow:0 4px 20px rgba(91,110,245,.4);
      animation: koneFloat 4s ease-in-out infinite;
    }
    @keyframes koneFloat { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-5px)} }
    .kone-hero-title { font-size:20px; font-weight:700; line-height:1.25; letter-spacing:-.02em; margin-bottom:9px; }
    .kone-hero-sub { font-size:12px; color:var(--tx3); line-height:1.5; }

    /* ─ Section label ─ */
    .kone-section-lbl { font-size:10px; font-weight:700; color:var(--tx3); letter-spacing:.1em; text-transform:uppercase; padding:0 16px 10px; flex-shrink:0; }

    /* ─ Chips ─ */
    .kone-chips { display:flex; flex-direction:column; gap:7px; padding:0 16px; flex:1; overflow:hidden; }
    .kone-chip {
      background:var(--s2); border:1px solid var(--bd); color:var(--tx2);
      font-size:13px; padding:11px 14px; border-radius:10px; cursor:pointer;
      display:flex; align-items:center; gap:10px; font-family:inherit; text-align:left;
      transition:background .13s, border-color .13s, color .13s, transform .1s;
    }
    .kone-chip:hover { background:var(--s3); border-color:var(--acc); color:var(--tx); transform:translateX(2px); }
    .kone-chip-icon { font-size:16px; flex-shrink:0; line-height:1; }

    /* ─ CTA area ─ */
    .kone-cta { padding:14px 16px 14px; flex-shrink:0; display:flex; flex-direction:column; gap:9px; }
    .kone-cta-btn {
      padding:13px 18px; background:var(--acc); border:none; border-radius:10px;
      color:#fff; font-family:inherit; font-size:14px; font-weight:600; cursor:pointer;
      display:flex; align-items:center; justify-content:center; gap:8px;
      box-shadow:0 4px 16px rgba(91,110,245,.35); transition:opacity .13s;
    }
    .kone-cta-btn:hover { opacity:.88; }

    /* ─ Footer link ─ */
    .kone-footer-link {
      display:block; text-align:center; font-size:11px; color:var(--tx3);
      text-decoration:none; padding:6px 0 8px; flex-shrink:0; transition:color .13s;
    }
    .kone-footer-link:hover { color:var(--acc2); }

    /* ─ Chat header ─ */
    .kone-chat-hdr {
      display:flex; align-items:center; gap:9px; padding:11px 13px;
      border-bottom:1px solid var(--bd); background:var(--s1); flex-shrink:0;
    }
    .kone-back-btn {
      background:none; border:none; color:var(--tx2); cursor:pointer;
      width:28px; height:28px; border-radius:6px; display:flex; align-items:center; justify-content:center;
      font-size:18px; transition:background .13s, color .13s; flex-shrink:0;
    }
    .kone-back-btn:hover { background:var(--s2); color:var(--tx); }
    .kone-chat-av {
      width:30px; height:30px; background:var(--acc); border-radius:7px;
      display:flex; align-items:center; justify-content:center;
      font-size:10px; font-weight:800; color:#fff; flex-shrink:0;
    }
    .kone-chat-hdr-info { flex:1; display:flex; flex-direction:column; gap:2px; }
    .kone-chat-hdr-name { font-size:13px; font-weight:600; color:var(--tx); line-height:1; }
    .kone-chat-hdr-status { font-size:10px; color:var(--tx3); display:flex; align-items:center; gap:4px; line-height:1; }
    .kone-sdot { width:5px; height:5px; background:var(--green); border-radius:50%; animation:koneBlink 3s ease-in-out infinite; }
    @keyframes koneBlink { 0%,80%,100%{opacity:1} 40%{opacity:.3} }

    /* ─ Messages ─ */
    .kone-msgs {
      flex:1; overflow-y:auto; padding:13px 13px 8px;
      display:flex; flex-direction:column; gap:8px; scroll-behavior:smooth;
    }
    .kone-msgs::-webkit-scrollbar { width:3px; }
    .kone-msgs::-webkit-scrollbar-thumb { background:var(--bd2); border-radius:3px; }
    .kone-msg { display:flex; gap:8px; align-items:flex-start; animation:koneUp .18s ease both; }
    @keyframes koneUp { from{opacity:0;transform:translateY(5px)} to{opacity:1;transform:translateY(0)} }
    .kone-msg-av {
      width:24px; height:24px; border-radius:6px; flex-shrink:0;
      display:flex; align-items:center; justify-content:center; font-size:9px; font-weight:800; margin-top:2px;
    }
    .kone-msg-av.a { background:var(--acc); color:#fff; }
    .kone-msg-av.u { background:var(--s3); color:var(--tx2); border:1px solid var(--bd2); }
    .kone-msg-body { flex:1; min-width:0; }
    .kone-msg-name { font-size:10px; font-weight:700; color:var(--tx3); margin-bottom:3px; text-transform:uppercase; letter-spacing:.04em; }
    .kone-msg-text { font-size:13px; line-height:1.65; color:var(--tx); white-space:pre-wrap; word-break:break-word; }
    .kone-msg-text a { color:var(--acc2); text-decoration:none; }
    .kone-msg-text strong { font-weight:600; color:#fff; }

    /* ─ Typing ─ */
    .kone-typing { display:flex; gap:4px; padding:4px 0; align-items:center; }
    .kone-tdot { width:5px; height:5px; background:var(--tx3); border-radius:50%; animation:konePulse 1.3s ease-in-out infinite; }
    .kone-tdot:nth-child(2){animation-delay:.18s} .kone-tdot:nth-child(3){animation-delay:.36s}
    @keyframes konePulse { 0%,80%,100%{opacity:.2;transform:scale(.75)} 40%{opacity:1;transform:scale(1)} }

    /* ─ Input ─ */
    .kone-input-row {
      display:flex; align-items:flex-end; gap:7px; padding:8px 12px 10px;
      border-top:1px solid var(--bd); background:var(--s1); flex-shrink:0;
    }
    .kone-inp {
      flex:1; background:var(--s2); border:1px solid var(--bd2); border-radius:10px;
      padding:10px 13px; color:var(--tx); font-family:inherit; font-size:13px; line-height:1.4;
      resize:none; outline:none; min-height:40px; max-height:100px; overflow-y:auto;
      transition:border-color .13s;
    }
    .kone-inp::placeholder { color:var(--tx3); }
    .kone-inp:focus { border-color:var(--acc); }
    .kone-send-btn {
      width:36px; height:36px; background:var(--acc); border:none; border-radius:9px;
      cursor:pointer; display:flex; align-items:center; justify-content:center;
      color:#fff; flex-shrink:0; font-size:18px; transition:opacity .13s;
    }
    .kone-send-btn:hover { opacity:.85; }
    .kone-send-btn:active { transform:scale(.92); }
    .kone-send-btn:disabled { opacity:.3; cursor:not-allowed; }

    /* ─ Screen switching ─ */
    .kone-screen { display:none; flex-direction:column; flex:1; min-height:0; }
    .kone-screen.active { display:flex; }
  `;

  // ── SDK class ────────────────────────────────────────────────────────────

  class KoneSpecialOffers {
    constructor(options = {}) {
      if (!options.apiKey) throw new Error('[KoneSDK] apiKey is required');
      this.apiKey     = options.apiKey;
      this.siteUrl    = options.siteUrl    || 'https://kone.vc';
      this.greeting   = options.greeting   || "Hi! 👋 I'm your free personal AI assistant.\n\nI can help you find the best deals, offers and recommendations.\n\nTap a quick question or ask anything!";
      this.accentColor = options.accentColor || '#5b6ef5';
      this.quickChips = options.quickChips || DEFAULT_CHIPS;

      this._responseId = null;
      this._isLoading  = false;
      this._greeted    = false;
      this._root       = null;
    }

    // ── mount(containerEl) ──────────────────────────────────────────────
    mount(container) {
      if (typeof container === 'string') container = document.querySelector(container);
      if (!container) throw new Error('[KoneSDK] container not found');

      // Inject CSS once
      if (!document.getElementById('kone-sdk-styles')) {
        const style = document.createElement('style');
        style.id = 'kone-sdk-styles';
        const accentCSS = CSS.replace(/var\(--acc\)/g, this.accentColor);
        style.textContent = accentCSS;
        document.head.appendChild(style);
      }

      container.innerHTML = this._buildHTML();
      this._root = container.querySelector('.kone-root');
      this._bindEvents();
      return this;
    }

    // ── HTML template ──────────────────────────────────────────────────
    _buildHTML() {
      const chipsHTML = this.quickChips.map(c => `
        <button class="kone-chip" data-q="${this._esc(c.question)}">
          <span class="kone-chip-icon">${c.label.split(' ')[0]}</span>
          <span>${this._esc(c.label.replace(/^\S+\s/, ''))}</span>
        </button>`).join('');

      return `
      <div class="kone-root">

        <!-- LANDING -->
        <div class="kone-screen active" id="kone-land">
          <div class="kone-hdr">
            <div class="kone-hdr-left">
              <span class="kone-pulse"><span class="kone-pulse-dot"></span><span class="kone-pulse-ring"></span></span>
              <span class="kone-hdr-title">AI Assistant</span>
            </div>
            <span class="kone-badge">Free · No signup</span>
          </div>
          <div class="kone-hero">
            <div class="kone-hero-icon" style="background:${this.accentColor}">AI</div>
            <h2 class="kone-hero-title">Your free personal<br>AI assistant</h2>
            <p class="kone-hero-sub">Cooking · Tech · Travel · Health · Finance · and more</p>
          </div>
          <div class="kone-section-lbl">Try asking</div>
          <div class="kone-chips">${chipsHTML}</div>
          <div class="kone-cta">
            <button class="kone-cta-btn" id="kone-open-btn" style="background:${this.accentColor}">
              💬&nbsp; Ask your own question
            </button>
            <a class="kone-footer-link" href="${KONE_APPS}" target="_blank" rel="noopener">More AI agents ↗</a>
          </div>
        </div>

        <!-- CHAT -->
        <div class="kone-screen" id="kone-chat">
          <div class="kone-chat-hdr">
            <button class="kone-back-btn" id="kone-back">‹</button>
            <div class="kone-chat-av" style="background:${this.accentColor}">AI</div>
            <div class="kone-chat-hdr-info">
              <span class="kone-chat-hdr-name">Your free personal AI assistant</span>
              <span class="kone-chat-hdr-status"><span class="kone-sdot"></span>online</span>
            </div>
          </div>
          <div class="kone-msgs" id="kone-msgs"></div>
          <div class="kone-input-row">
            <textarea id="kone-inp" class="kone-inp" placeholder="Ask me anything…" rows="1" maxlength="512"></textarea>
            <button id="kone-send" class="kone-send-btn" style="background:${this.accentColor}">↑</button>
          </div>
          <a class="kone-footer-link" href="${KONE_APPS}" target="_blank" rel="noopener">More AI agents ↗</a>
        </div>

      </div>`;
    }

    // ── Events ──────────────────────────────────────────────────────────
    _bindEvents() {
      const r = this._root;
      r.querySelector('#kone-open-btn').addEventListener('click', () => this._showChat());
      r.querySelector('#kone-back').addEventListener('click', () => this._showLand());
      r.querySelectorAll('.kone-chip').forEach(c =>
        c.addEventListener('click', () => {
          this._showChat();
          setTimeout(() => this._doSend(c.dataset.q), 160);
        })
      );
      const inp  = r.querySelector('#kone-inp');
      const send = r.querySelector('#kone-send');
      send.addEventListener('click', () => this._sendFromInput());
      inp.addEventListener('input', function() {
        this.style.height = 'auto';
        this.style.height = Math.min(this.scrollHeight, 100) + 'px';
      });
      inp.addEventListener('keydown', e => {
        if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); this._sendFromInput(); }
      });
    }

    _sendFromInput() {
      const inp = this._root.querySelector('#kone-inp');
      const text = inp.value.trim();
      if (!text) return;
      inp.value = '';
      inp.style.height = 'auto';
      this._doSend(text);
    }

    _showChat() {
      this._root.querySelector('#kone-land').classList.remove('active');
      this._root.querySelector('#kone-chat').classList.add('active');
      if (!this._greeted) {
        this._greeted = true;
        this._appendMsg('a', this.greeting);
      }
      setTimeout(() => this._root.querySelector('#kone-inp').focus(), 80);
    }

    _showLand() {
      this._root.querySelector('#kone-chat').classList.remove('active');
      this._root.querySelector('#kone-land').classList.add('active');
    }

    // ── API ──────────────────────────────────────────────────────────────
    async _doSend(prompt) {
      if (this._isLoading) return;
      this._isLoading = true;
      const sendBtn = this._root.querySelector('#kone-send');
      sendBtn.disabled = true;

      if (!this._root.querySelector('#kone-chat').classList.contains('active')) this._showChat();
      this._appendMsg('u', prompt);
      const typingEl = this._showTyping();

      const payload = { url: this.siteUrl, prompt, api_key: this.apiKey };
      if (this._responseId) payload.response_id = this._responseId;

      try {
        const res = await fetch(API_ENDPOINT, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });
        this._removeTyping(typingEl);
        if (!res.ok) {
          this._appendMsg('a', `⚠️ Error ${res.status}. Please try again.`);
        } else {
          const data = await res.json().catch(() => null);
          if (data && typeof data === 'object') {
            if (data.response_id) this._responseId = String(data.response_id);
            this._appendMsg('a', data.message || data.response || data.text || data.content || JSON.stringify(data));
          }
        }
      } catch (err) {
        this._removeTyping(typingEl);
        this._appendMsg('a', `⚠️ Connection error.\n${err.message}`);
      }
      this._isLoading = false;
      sendBtn.disabled = false;
      this._root.querySelector('#kone-inp').focus();
    }

    // ── DOM helpers ──────────────────────────────────────────────────────
    _appendMsg(role, text) {
      const isA = role === 'a';
      const msgs = this._root.querySelector('#kone-msgs');
      const row = document.createElement('div');
      row.className = 'kone-msg';
      row.innerHTML = `
        <div class="kone-msg-av ${role}" style="${isA ? `background:${this.accentColor}` : ''}">${isA ? 'AI' : 'U'}</div>
        <div class="kone-msg-body">
          <div class="kone-msg-name">${isA ? 'AI Assistant' : 'You'}</div>
          <div class="kone-msg-text">${isA ? this._fmt(text) : this._esc(text)}</div>
        </div>`;
      msgs.appendChild(row);
      msgs.scrollTop = msgs.scrollHeight;
    }

    _showTyping() {
      const msgs = this._root.querySelector('#kone-msgs');
      const row = document.createElement('div');
      row.className = 'kone-msg'; row.id = 'kone-typing';
      row.innerHTML = `
        <div class="kone-msg-av a" style="background:${this.accentColor}">AI</div>
        <div class="kone-msg-body">
          <div class="kone-msg-name">AI Assistant</div>
          <div class="kone-typing"><div class="kone-tdot"></div><div class="kone-tdot"></div><div class="kone-tdot"></div></div>
        </div>`;
      msgs.appendChild(row);
      msgs.scrollTop = msgs.scrollHeight;
      return row;
    }

    _removeTyping(el) { if (el && el.parentNode) el.parentNode.removeChild(el); }

    _esc(s) {
      return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
    }

    _fmt(s) {
      let o = this._esc(s);
      o = o.replace(/\[([^\]]+)\]\((https?:\/\/[^)]+)\)/g,'<a href="$2" target="_blank" rel="noopener">$1</a>');
      o = o.replace(/\*\*(.*?)\*\*/g,'<strong>$1</strong>');
      o = o.replace(/^[-*] (.+)$/gm,'<span style="display:flex;gap:6px"><span style="color:var(--acc2);flex-shrink:0">–</span><span>$1</span></span>');
      o = o.replace(/\n/g,'<br>');
      return o;
    }
  }

  return { KoneSpecialOffers };
}));
