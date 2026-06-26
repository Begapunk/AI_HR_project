<template>
  <Teleport to="body">
    <div
      class="fc-root"
      :style="{ left: `${pos.x}px`, top: `${pos.y}px` }"
      ref="ballRef"
    >
      <!-- ── Ball ── -->
      <div
        class="fc-ball"
        :class="{ pulsing: loading, has_unread: hasUnread && !open }"
        @click="toggleOpen"
        @mousedown.stop
        title="AI 简历教练"
      >
        <span class="fc-avatar">{{ avatarIcon }}</span>
        <span v-if="hasUnread && !open" class="fc-badge">{{ unreadCount }}</span>
        <span v-if="loading" class="fc-loading-ring"></span>
      </div>

      <!-- ── Panel ── -->
      <Transition name="fc-panel">
        <div v-if="open" class="fc-panel" @mousedown.stop>
          <!-- Header -->
          <div class="fc-head">
            <span class="fc-head-title">{{ phaseLabel }}</span>
            <button class="fc-close" @click="open = false">✕</button>
          </div>

          <!-- Messages -->
          <div class="fc-msgs" ref="msgsEl">
            <div
              v-for="m in messages"
              :key="m.id"
              :class="['fc-msg', `fc-msg--${m.role}`, { streaming: m.streaming }]"
            >
              <span class="fc-msg-avatar">{{ m.role === 'ai' ? '🧠' : '👤' }}</span>
              <div class="fc-bubble" v-html="renderText(m.text)"></div>
            </div>
            <div v-if="loading" class="fc-msg fc-msg--ai">
              <span class="fc-msg-avatar">🧠</span>
              <div class="fc-bubble fc-thinking">
                <span></span><span></span><span></span>
              </div>
            </div>
          </div>

          <!-- Input area -->
          <div class="fc-foot">
            <template v-if="phase === 'questioning'">
              <div class="fc-input-wrap" :class="{ focused: taFocus }">
                <textarea
                  ref="taRef"
                  v-model="draft"
                  class="fc-ta"
                  :placeholder="inputPlaceholder"
                  :maxlength="500"
                  rows="2"
                  @focus="taFocus = true"
                  @blur="taFocus = false"
                  @keydown.enter.exact.prevent="sendDraft"
                  @keydown.enter.shift.exact.prevent="draft += '\n'"
                />
                <button class="fc-send-btn" :disabled="!draft.trim()" @click="sendDraft">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
                </button>
              </div>
              <div class="fc-hint">Enter 发送 · Shift+Enter 换行 · 最多 500 字</div>
            </template>
            <template v-else-if="phase === 'ready'">
              <button class="fc-gen-btn" @click="$emit('confirm')">
                <span>🚀 开始生成优化简历</span>
                <span class="fc-gen-shine"></span>
              </button>
            </template>
            <template v-else-if="phase === 'generating'">
              <div class="fc-generating-hint">
                <span class="fc-gen-ring"></span>
                AI 正在写入简历…右侧实时更新
              </div>
            </template>
            <template v-else-if="phase === 'done'">
              <div class="fc-done-hint">✓ 简历生成完成，右侧可直接编辑</div>
            </template>
          </div>
        </div>
      </Transition>
    </div>
  </Teleport>
</template>

<script setup>
import { ref, computed, watch, nextTick } from 'vue'
import { useDraggable, useWindowSize } from '@vueuse/core'
import DOMPurify from 'dompurify'

const props = defineProps({
  messages:  { type: Array,  default: () => [] },
  phase:     { type: String, default: 'idle' },    // idle | analyzing | questioning | ready | generating | done
  loading:   { type: Boolean, default: false },
})
const emit = defineEmits(['send', 'confirm'])

// ── Draggable ──────────────────────────────────────────────────────────
const ballRef = ref(null)
const { width: ww, height: wh } = useWindowSize()
const { x, y, isDragging } = useDraggable(ballRef, {
  initialValue: { x: Math.max(ww.value - 100, 40), y: Math.max(wh.value - 160, 40) },
})
// Clamp to viewport
const pos = computed(() => ({
  x: Math.min(Math.max(x.value, 8), ww.value  - 72),
  y: Math.min(Math.max(y.value, 8), wh.value  - 72),
}))

// ── State ──────────────────────────────────────────────────────────────
const open      = ref(false)
const draft     = ref('')
const taFocus   = ref(false)
const msgsEl    = ref(null)
const taRef     = ref(null)

const seenCount = ref(0)
const hasUnread = computed(() => props.messages.length > seenCount.value)
const unreadCount = computed(() => props.messages.filter(m => m.role === 'ai').length - seenCount.value)

const avatarIcon = computed(() => {
  if (props.phase === 'generating') return '✍️'
  if (props.phase === 'done')       return '✅'
  if (props.phase === 'analyzing')  return '🔍'
  return '🧠'
})

const phaseLabel = computed(() => {
  const map = {
    idle:        'AI 简历教练',
    analyzing:   '正在分析差距…',
    questioning: '事实追问',
    ready:       '确认生成',
    generating:  'AI 热写中…',
    done:        '编辑模式',
  }
  return map[props.phase] || 'AI 简历教练'
})

const inputPlaceholder = computed(() => '输入你的回答… (Enter 发送，Shift+Enter 换行)')

// ── Open / close ───────────────────────────────────────────────────────
function toggleOpen() {
  if (isDragging.value) return
  open.value = !open.value
  if (open.value) {
    seenCount.value = props.messages.filter(m => m.role === 'ai').length
    nextTick(() => scrollToBottom())
  }
}

// Auto-open when questioning phase starts
watch(() => props.phase, (val) => {
  if (val === 'questioning') open.value = true
})

// Scroll to bottom when new messages arrive
watch(() => props.messages.length, async () => {
  await nextTick()
  scrollToBottom()
  if (open.value) seenCount.value = props.messages.filter(m => m.role === 'ai').length
})

function scrollToBottom() {
  if (msgsEl.value) msgsEl.value.scrollTop = msgsEl.value.scrollHeight
}

// ── Send ───────────────────────────────────────────────────────────────
function sendDraft() {
  const text = draft.value.trim().slice(0, 500)
  if (!text) return
  emit('send', text)
  draft.value = ''
  nextTick(() => taRef.value?.focus())
}

// ── Render markdown-lite (no external dep) ────────────────────────────
function renderText(text) {
  const escaped = text
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/`(.+?)`/g, '<code>$1</code>')
    .replace(/\n/g, '<br>')
  return DOMPurify.sanitize(escaped, { ALLOWED_TAGS: ['strong', 'em', 'code', 'br'], ALLOWED_ATTR: [] })
}
</script>

<style scoped>
.fc-root {
  position: fixed;
  z-index: 9999;
  user-select: none;
  width: 64px;
  height: 64px;
}

/* ── Ball ── */
.fc-ball {
  width: 64px; height: 64px;
  border-radius: 50%;
  background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 50%, #0891b2 100%);
  box-shadow: 0 4px 20px rgba(99,102,241,.5), 0 0 0 0 rgba(99,102,241,.3);
  display: flex; align-items: center; justify-content: center;
  cursor: grab; position: relative;
  transition: transform .35s cubic-bezier(0.22,1,0.36,1), box-shadow .35s;
}
.fc-ball:active { cursor: grabbing; }
.fc-ball:hover  { transform: scale(1.1); box-shadow: 0 8px 28px rgba(99,102,241,.65); }

.fc-ball.pulsing {
  animation: ball-pulse 1.4s ease-in-out infinite;
}
@keyframes ball-pulse {
  0%,100% { box-shadow: 0 4px 20px rgba(99,102,241,.5), 0 0 0 0 rgba(99,102,241,.4); }
  50%      { box-shadow: 0 4px 20px rgba(99,102,241,.5), 0 0 0 16px rgba(99,102,241,0); }
}
.fc-ball.has_unread {
  animation: ball-bounce .8s cubic-bezier(0.34,1.56,.64,1) infinite alternate;
}
@keyframes ball-bounce {
  from { transform: translateY(0); }
  to   { transform: translateY(-7px); }
}

.fc-avatar { font-size: 1.6rem; line-height: 1; }
.fc-badge {
  position: absolute; top: -4px; right: -4px;
  width: 20px; height: 20px; border-radius: 50%;
  background: #ef4444; border: 2px solid #060510;
  font-size: .62rem; font-weight: 700; color: #fff;
  display: flex; align-items: center; justify-content: center;
}
.fc-loading-ring {
  position: absolute; inset: -4px; border-radius: 50%;
  border: 2.5px solid transparent;
  border-top-color: #a5b4fc;
  animation: spin .8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }

/* ── Panel ── */
.fc-panel {
  position: absolute;
  bottom: 74px; right: 0;
  width: 320px;
  background: rgba(8, 8, 22, .98);
  border: 1px solid rgba(99,102,241,.3);
  border-radius: 22px;
  box-shadow: 0 16px 56px rgba(0,0,0,.65), 0 0 0 1px rgba(99,102,241,.18);
  display: flex; flex-direction: column;
  overflow: hidden;
  backdrop-filter: blur(20px);
  max-height: 520px;
}
/* Reposition panel if ball is in left half of screen */
@media (max-width: 440px) { .fc-panel { right: auto; left: 0; } }

.fc-panel-enter-active { transition: opacity .35s, transform .4s cubic-bezier(0.22,1,0.36,1); }
.fc-panel-leave-active { transition: opacity .2s, transform .25s cubic-bezier(0.55,0,1,.45); }
.fc-panel-enter-from   { opacity: 0; transform: scale(.88) translateY(16px); }
.fc-panel-leave-to     { opacity: 0; transform: scale(.92) translateY(10px); }

.fc-head {
  display: flex; align-items: center; justify-content: space-between;
  padding: 14px 16px 10px;
  border-bottom: 1px solid rgba(255,255,255,.06);
  flex-shrink: 0;
}
.fc-head-title { font-size: .82rem; font-weight: 700; color: #c7d2fe; letter-spacing: .02em; }
.fc-close {
  width: 24px; height: 24px; border-radius: 50%;
  background: rgba(255,255,255,.07); border: none;
  color: #64748b; font-size: .8rem; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  transition: all .25s;
}
.fc-close:hover { background: rgba(255,255,255,.14); color: #f1f5f9; }

/* Messages */
.fc-msgs {
  flex: 1; overflow-y: auto; padding: 12px 12px 8px;
  display: flex; flex-direction: column; gap: 10px;
  scroll-behavior: smooth;
  min-height: 0;
}
.fc-msgs::-webkit-scrollbar { width: 4px; }
.fc-msgs::-webkit-scrollbar-thumb { background: rgba(255,255,255,.1); border-radius: 2px; }

.fc-msg {
  display: flex; align-items: flex-end; gap: 7px;
}
.fc-msg--user { flex-direction: row-reverse; }

.fc-msg-avatar {
  font-size: .95rem;
  width: 26px; height: 26px;
  background: rgba(255,255,255,.05); border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.fc-msg--user .fc-msg-avatar { background: rgba(99,102,241,.2); }

.fc-bubble {
  max-width: 220px;
  padding: 8px 12px;
  border-radius: 16px;
  font-size: .8rem; line-height: 1.65; color: #e2e8f0;
  word-break: break-word;
}
.fc-msg--ai  .fc-bubble { background: rgba(99,102,241,.16); border: 1px solid rgba(99,102,241,.22); border-bottom-left-radius: 4px; }
.fc-msg--user .fc-bubble { background: rgba(52,211,153,.14); border: 1px solid rgba(52,211,153,.25); border-bottom-right-radius: 4px; color: #a7f3d0; }

.fc-bubble :deep(strong) { color: #f1f5f9; font-weight: 700; }
.fc-bubble :deep(code)   { background: rgba(255,255,255,.1); border-radius: 4px; padding: 1px 5px; font-family: monospace; font-size: .78rem; }

/* Thinking dots */
.fc-thinking {
  display: flex; gap: 5px; align-items: center; padding: 10px 14px;
}
.fc-thinking span {
  width: 6px; height: 6px; border-radius: 50%; background: #818cf8;
  animation: dot-pop .9s ease-in-out infinite;
}
.fc-thinking span:nth-child(2) { animation-delay: .18s; }
.fc-thinking span:nth-child(3) { animation-delay: .36s; }
@keyframes dot-pop { 0%,100%{transform:scale(1);opacity:.5} 50%{transform:scale(1.45);opacity:1} }

/* Foot */
.fc-foot {
  flex-shrink: 0;
  border-top: 1px solid rgba(255,255,255,.06);
  padding: 10px 12px;
}
.fc-input-wrap {
  display: flex; gap: 6px; align-items: flex-end;
  border: 1.5px solid rgba(255,255,255,.09);
  border-radius: 14px; background: rgba(255,255,255,.04);
  padding: 7px 8px 7px 12px;
  transition: border-color .3s, box-shadow .3s;
}
.fc-input-wrap.focused {
  border-color: rgba(99,102,241,.5);
  box-shadow: 0 0 0 3px rgba(99,102,241,.1);
}
.fc-ta {
  flex: 1; background: none; border: none; outline: none; resize: none;
  font-size: .8rem; color: #e2e8f0; line-height: 1.55; font-family: inherit;
  min-height: 36px; max-height: 110px;
}
.fc-ta::placeholder { color: #334155; }
.fc-send-btn {
  width: 30px; height: 30px; border-radius: 50%;
  background: linear-gradient(135deg,#4f46e5,#7c3aed);
  border: none; color: #fff; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0; transition: transform .3s, opacity .3s;
}
.fc-send-btn:disabled { opacity: .35; cursor: not-allowed; }
.fc-send-btn:not(:disabled):hover { transform: scale(1.1); }
.fc-hint { font-size: .64rem; color: #334155; margin-top: 5px; text-align: right; }

/* Generate button */
.fc-gen-btn {
  position: relative; overflow: hidden;
  width: 100%; padding: 11px 0;
  background: linear-gradient(135deg,#10b981,#059669);
  border: none; border-radius: 12px;
  font-size: .86rem; font-weight: 700; color: #fff; cursor: pointer;
  box-shadow: 0 4px 16px rgba(16,185,129,.35);
  transition: transform .35s cubic-bezier(0.22,1,0.36,1), box-shadow .35s;
}
.fc-gen-btn:hover { transform: scale(1.03) translateY(-1px); box-shadow: 0 8px 24px rgba(16,185,129,.5); }
.fc-gen-shine {
  position: absolute; inset: 0;
  background: linear-gradient(110deg,transparent 30%,rgba(255,255,255,.25) 50%,transparent 70%);
  transform: translateX(-100%);
}
.fc-gen-btn:hover .fc-gen-shine { transform: translateX(100%); transition: transform .5s ease; }

.fc-generating-hint, .fc-done-hint {
  display: flex; align-items: center; gap: 8px;
  font-size: .78rem; color: #64748b; text-align: center; justify-content: center;
  padding: 4px 0;
}
.fc-done-hint { color: #34d399; }
.fc-gen-ring {
  width: 14px; height: 14px; flex-shrink: 0;
  border: 2px solid rgba(251,146,60,.3); border-top-color: #fb923c;
  border-radius: 50%; animation: spin .6s linear infinite;
}
</style>
