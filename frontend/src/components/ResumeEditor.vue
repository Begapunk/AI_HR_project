<template>
  <div class="re" ref="root" @mousemove="onMouse">

    <!-- BG -->
    <div class="cursor-glow" ref="cursorGlow"></div>
    <canvas ref="canvas" class="bg-canvas"></canvas>
    <div class="aurora" aria-hidden="true">
      <div class="ab ab1"></div><div class="ab ab2"></div><div class="ab ab3"></div>
    </div>

    <!-- Nav -->
    <nav class="re-nav">
      <button class="back-btn" @click="$emit('close')">
        <span class="back-ico">←</span>{{ locale === 'zh' ? '返回' : 'Back' }}
      </button>
      <div class="nav-brand"><span>🔥</span><span class="brand-word">简历热改写</span></div>
      <div class="nav-right">
        <transition name="badge-fade">
          <span v-if="phase === 'streaming'" class="live-badge">
            <span class="live-dot"></span>LIVE
          </span>
          <span v-else-if="phase === 'done'" class="done-badge">完成 ✓</span>
        </transition>
      </div>
    </nav>

    <!-- ── UPLOAD PHASE ── -->
    <div v-if="phase === 'idle' || phase === 'loading'" class="re-body">
      <header class="re-hero ai-in" style="--d:0s">
        <div class="hero-tag"><span class="tag-dot"></span>{{ locale === 'zh' ? 'AI 驱动 · 一键热改写' : 'AI-Powered · Hot Rewrite' }}</div>
        <h1 class="re-h1">
          <span class="h1-plain">{{ locale === 'zh' ? '简历' : 'Resume' }}&nbsp;</span>
          <span class="h1-hot">{{ locale === 'zh' ? '热改写' : 'Hot Rewrite' }}</span>
        </h1>
        <p class="re-sub">{{ locale === 'zh' ? '上传简历 + 粘贴 JD，AI 直接在你的文档上改，改完即可手动微调' : 'Upload resume + paste JD — AI rewrites your resume inline, then you fine-tune it' }}</p>
      </header>

      <transition name="err-fade">
        <div v-if="err" class="err-box">⚠ {{ err }}</div>
      </transition>

      <div class="panels ai-in" style="--d:.15s">
        <!-- Left: resume upload -->
        <div class="panel" ref="panelL" @mousemove="e=>tilt(e,panelL)" @mouseleave="e=>resetTilt(panelL)">
          <div class="panel-glow"></div>
          <div class="panel-hd">
            <div class="panel-ico">📄</div>
            <div>
              <div class="panel-title">{{ locale === 'zh' ? '我的简历' : 'My Resume' }}</div>
              <div class="panel-hint">PDF · Word · TXT · MD · 图片</div>
            </div>
          </div>
          <label class="drop-zone" :class="{'has-file': rFile}">
            <input type="file"
              accept=".pdf,.doc,.docx,.txt,.md,.jpg,.jpeg,.png,application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document,image/*"
              @change="pickFile" hidden />
            <template v-if="!rFile">
              <span class="dz-cloud">☁</span>
              <span class="dz-main">{{ locale === 'zh' ? '点击上传简历文件' : 'Click to upload resume' }}</span>
              <span class="dz-sub">PDF · Word · TXT · MD · 图片</span>
            </template>
            <template v-else>
              <span class="dz-check">✓</span>
              <span class="dz-main">{{ rFile.name }}</span>
              <span class="dz-sub">{{ locale === 'zh' ? '点击重新选择' : 'Click to reselect' }}</span>
            </template>
          </label>
          <div v-if="rFile" class="file-info">
            <span class="fi-name">{{ rFile.name }}</span>
            <button class="fi-clear" @click.prevent="rFile=null">✕</button>
          </div>
        </div>

        <!-- Right: JD input -->
        <div class="panel" ref="panelR" @mousemove="e=>tilt(e,panelR)" @mouseleave="e=>resetTilt(panelR)">
          <div class="panel-glow"></div>
          <div class="panel-hd">
            <div class="panel-ico">📋</div>
            <div>
              <div class="panel-title">{{ locale === 'zh' ? '目标职位 JD' : 'Target Job Description' }}</div>
              <div class="panel-hint">{{ locale === 'zh' ? '从任意招聘平台复制粘贴' : 'Copy from any job board' }}</div>
            </div>
          </div>
          <div class="ta-wrap" :class="{focused: jdFocus}">
            <textarea class="glass-ta"
              v-model="jdText"
              :placeholder="locale === 'zh'
                ? '将职位描述粘贴到这里…\n\n可从 BOSS 直聘、猎聘、招聘官网等复制完整 JD 内容'
                : 'Paste the full job description here…\n\nCopy from LinkedIn, Indeed, or any career page'"
              @focus="jdFocus=true" @blur="jdFocus=false"
            />
          </div>
          <div class="ta-bar">
            <span :class="['char-cnt', {warn: jdText.length > 2800}]">{{ jdText.length }} / 3000</span>
            <button v-if="jdText" class="clear-btn" @click="jdText=''">{{ locale === 'zh' ? '清空' : 'Clear' }}</button>
          </div>
        </div>
      </div>

      <!-- CTA -->
      <div class="cta-row ai-in" style="--d:.28s">
        <button class="cta-btn" :disabled="!canRun || phase==='loading'" @click="run">
          <span class="cta-fire">🔥</span>
          <span>{{ phase === 'loading'
            ? (locale === 'zh' ? 'AI 改写中…' : 'Rewriting…')
            : (locale === 'zh' ? 'AI 直接改写我的简历' : 'AI Rewrite My Resume') }}</span>
          <span class="btn-shine"></span>
        </button>
        <p v-if="!canRun" class="req-note">{{ locale === 'zh' ? '请上传简历并粘贴 JD（各至少 20 字）' : 'Upload resume and paste JD (20+ chars each)' }}</p>
        <transition name="pill-in">
          <div v-if="phase==='loading'" class="status-pill">
            <span class="spin-ring"></span>{{ statusText }}
          </div>
        </transition>
      </div>
    </div>

    <!-- ── EDITOR PHASE ── -->
    <div v-else class="editor-wrap">
      <!-- Toolbar -->
      <div class="toolbar">
        <div class="tb-left">
          <button class="tb-btn tb-reset" @click="resetAll">↺ {{ locale === 'zh' ? '重新改写' : 'Rewrite Again' }}</button>
        </div>
        <div class="tb-center">
          <span v-if="phase==='streaming'" class="tb-status hot">
            <span class="hot-ring"></span>{{ locale === 'zh' ? 'AI 正在改写…' : 'AI rewriting…' }}
          </span>
          <span v-else class="tb-status done">
            ✓ {{ locale === 'zh' ? '改写完成，可直接编辑' : 'Done — edit freely below' }}
          </span>
        </div>
        <div class="tb-right">
          <button class="tb-btn" @click="copyContent" :title="locale==='zh'?'复制全部':'Copy all'">
            {{ copied ? '✓' : (locale === 'zh' ? '复制' : 'Copy') }}
          </button>
          <button class="tb-btn tb-dl" @click="download" :title="locale==='zh'?'下载为 txt':'Download as txt'">
            ↓ {{ locale === 'zh' ? '下载' : 'Download' }}
          </button>
        </div>
      </div>

      <!-- Hot glow hint -->
      <transition name="hint-fade">
        <div v-if="phase==='streaming'" class="hot-hint">
          🔥 {{ locale === 'zh' ? '实时改写中，完成后可自由编辑' : 'Streaming live — fully editable when done' }}
        </div>
      </transition>

      <!-- Editor area -->
      <div class="editor-outer" :class="{ hot: phase==='streaming', cool: phase==='done' }">
        <textarea
          ref="editorEl"
          class="editor-ta"
          v-model="content"
          :readonly="phase==='streaming'"
          :placeholder="locale==='zh' ? '改写内容将在这里实时显示…' : 'Rewritten resume will appear here…'"
          spellcheck="false"
        />
        <span v-if="phase==='streaming'" class="cursor-blink">▌</span>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useI18n } from 'vue-i18n'

defineEmits(['close'])

const API_BASE = import.meta.env.DEV ? '' : 'https://offer-catcher-api.onrender.com'
const { locale } = useI18n()

// refs
const root       = ref(null)
const canvas     = ref(null)
const cursorGlow = ref(null)
const panelL     = ref(null)
const panelR     = ref(null)
const editorEl   = ref(null)

// state
const rFile     = ref(null)
const jdText    = ref('')
const jdFocus   = ref(false)
const phase     = ref('idle')   // idle | loading | streaming | done
const statusText = ref('')
const content   = ref('')
const err       = ref('')
const copied    = ref(false)

const ALLOWED = new Set(['pdf','docx','doc','txt','md','jpg','jpeg','png'])

const canRun = computed(() =>
  rFile.value && jdText.value.trim().length >= 20
)

function pickFile(e) {
  const f = e.target.files?.[0]
  if (!f) return
  const ext = f.name.split('.').pop().toLowerCase()
  if (ALLOWED.has(ext)) { rFile.value = f; err.value = '' }
  else err.value = locale.value === 'zh' ? '不支持的文件格式' : 'Unsupported file format'
}

async function run() {
  if (!canRun.value) return
  err.value = ''; content.value = ''; phase.value = 'loading'
  statusText.value = locale.value === 'zh' ? '正在解析简历…' : 'Parsing resume…'

  try {
    const fd = new FormData()
    fd.append('file', rFile.value)
    fd.append('jd', jdText.value.slice(0, 3000))

    const resp = await fetch(`${API_BASE}/api/resume-edit`, {
      method: 'POST',
      headers: { 'Accept-Language': locale.value === 'zh' ? 'zh-CN' : 'en-US' },
      body: fd,
    })
    if (!resp.ok) {
      const e = await resp.json().catch(() => ({}))
      throw new Error(e.detail || `HTTP ${resp.status}`)
    }

    const reader = resp.body.getReader()
    const dec = new TextDecoder()
    let buf = ''
    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      buf += dec.decode(value, { stream: true })
      const lines = buf.split('\n'); buf = lines.pop() || ''
      for (const line of lines) {
        if (!line.startsWith('data: ')) continue
        const obj = JSON.parse(line.slice(6))
        if (obj.type === 'status') {
          statusText.value = obj.text
        } else if (obj.type === 'chunk') {
          if (phase.value !== 'streaming') phase.value = 'streaming'
          content.value += obj.text
          await nextTick()
          if (editorEl.value) editorEl.value.scrollTop = editorEl.value.scrollHeight
        } else if (obj.type === 'done') {
          phase.value = 'done'
        } else if (obj.type === 'error') {
          throw new Error(obj.message)
        }
      }
    }
    phase.value = 'done'
  } catch (e) {
    err.value = e.message
    phase.value = 'idle'
  }
}

function resetAll() {
  phase.value = 'idle'; content.value = ''; err.value = ''
}

async function copyContent() {
  await navigator.clipboard.writeText(content.value).catch(() => {})
  copied.value = true
  setTimeout(() => { copied.value = false }, 2000)
}

function download() {
  const blob = new Blob([content.value], { type: 'text/plain;charset=utf-8' })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = `resume-optimized-${Date.now()}.txt`
  a.click()
  URL.revokeObjectURL(a.href)
}

// ── cursor glow ───────────────────────────────────────────────
let mx = 0, my = 0, cgx = 0, cgy = 0, rafCursor = 0
function onMouse(e) { mx = e.clientX; my = e.clientY }
function animCursor() {
  cgx += (mx - cgx) * 0.09; cgy += (my - cgy) * 0.09
  if (cursorGlow.value) cursorGlow.value.style.transform = `translate(${cgx - 200}px,${cgy - 200}px)`
  rafCursor = requestAnimationFrame(animCursor)
}

// ── 3D tilt ───────────────────────────────────────────────────
function tilt(e, elRef) {
  const el = elRef?.value ?? elRef; if (!el) return
  const r = el.getBoundingClientRect()
  const x = (e.clientX - r.left) / r.width - 0.5
  const y = (e.clientY - r.top) / r.height - 0.5
  el.style.transform = `perspective(800px) rotateX(${-y*7}deg) rotateY(${x*7}deg) scale(1.02) translateZ(6px)`
  el.style.transition = 'transform .08s linear'
}
function resetTilt(elRef) {
  const el = elRef?.value ?? elRef; if (!el) return
  el.style.transform = ''; el.style.transition = 'transform .55s cubic-bezier(0.22,1,0.36,1)'
}

// ── canvas ────────────────────────────────────────────────────
let ctx2d, pts = [], rafCanvas = 0
const N = 65, MAX_D = 130
function initCanvas() {
  const c = canvas.value; if (!c) return
  c.width = window.innerWidth; c.height = window.innerHeight
  ctx2d = c.getContext('2d')
  pts = Array.from({ length: N }, () => ({
    x: Math.random() * c.width, y: Math.random() * c.height,
    vx: (Math.random() - 0.5) * 0.38, vy: (Math.random() - 0.5) * 0.38,
    r: Math.random() * 1.4 + 0.5,
  }))
}
function drawCanvas() {
  const c = canvas.value; if (!c || !ctx2d) return
  ctx2d.clearRect(0, 0, c.width, c.height)
  for (const p of pts) {
    p.x += p.vx; p.y += p.vy
    if (p.x < 0 || p.x > c.width) p.vx *= -1
    if (p.y < 0 || p.y > c.height) p.vy *= -1
    ctx2d.beginPath(); ctx2d.arc(p.x, p.y, p.r, 0, Math.PI * 2)
    ctx2d.fillStyle = 'rgba(251,146,60,.55)'; ctx2d.fill()
  }
  for (let i = 0; i < pts.length; i++) {
    for (let j = i + 1; j < pts.length; j++) {
      const dx = pts[i].x - pts[j].x, dy = pts[i].y - pts[j].y
      const d = Math.sqrt(dx*dx + dy*dy)
      if (d < MAX_D) {
        ctx2d.beginPath(); ctx2d.moveTo(pts[i].x, pts[i].y); ctx2d.lineTo(pts[j].x, pts[j].y)
        ctx2d.strokeStyle = `rgba(251,146,60,${.09 * (1 - d / MAX_D)})`
        ctx2d.lineWidth = 0.75; ctx2d.stroke()
      }
    }
  }
  rafCanvas = requestAnimationFrame(drawCanvas)
}
function onResize() {
  if (canvas.value) { canvas.value.width = window.innerWidth; canvas.value.height = window.innerHeight }
}

onMounted(() => { initCanvas(); drawCanvas(); animCursor(); window.addEventListener('resize', onResize) })
onUnmounted(() => { cancelAnimationFrame(rafCanvas); cancelAnimationFrame(rafCursor); window.removeEventListener('resize', onResize) })
</script>

<style scoped>
.re {
  position: fixed; inset: 0; z-index: 50;
  background: #060508;
  color: #e2e8f0;
  font-family: -apple-system, 'SF Pro Text', 'Inter', 'Helvetica Neue', sans-serif;
  -webkit-font-smoothing: antialiased;
  overflow-y: auto; overflow-x: hidden;
}

.bg-canvas { position: fixed; inset: 0; z-index: 0; pointer-events: none; }
.aurora { position: fixed; inset: 0; z-index: 0; pointer-events: none; overflow: hidden; }
.ab { position: absolute; border-radius: 50%; filter: blur(88px); opacity: .1; animation: ab-float 9s ease-in-out infinite; }
.ab1 { width: 680px; height: 680px; background: #ea580c; top: -220px; left: -160px; }
.ab2 { width: 520px; height: 520px; background: #dc2626; top: 40%; right: -180px; animation-delay: -3.5s; }
.ab3 { width: 440px; height: 440px; background: #d97706; bottom: 8%; left: 18%; animation-delay: -6s; }
@keyframes ab-float { 0%,100% { transform: translateY(0) scale(1); } 50% { transform: translateY(-36px) scale(1.04); } }

.cursor-glow {
  position: fixed; top: 0; left: 0; width: 400px; height: 400px; border-radius: 50%;
  background: radial-gradient(circle, rgba(251,146,60,.15) 0%, transparent 70%);
  pointer-events: none; z-index: 1; will-change: transform;
}

/* Nav */
.re-nav {
  position: sticky; top: 0; z-index: 100;
  display: flex; align-items: center; justify-content: space-between;
  padding: 0 28px; height: 56px;
  background: rgba(6,5,8,.8);
  backdrop-filter: saturate(180%) blur(24px);
  border-bottom: 1px solid rgba(255,255,255,.06);
}
.back-btn {
  display: flex; align-items: center; gap: 7px;
  background: rgba(255,255,255,.06); border: 1px solid rgba(255,255,255,.1);
  color: #94a3b8; border-radius: 980px; padding: 6px 16px;
  font-size: .8rem; font-weight: 600; cursor: pointer;
  transition: all .4s cubic-bezier(0.22,1,0.36,1);
}
.back-btn:hover { background: rgba(255,255,255,.11); color: #f1f5f9; transform: translateX(-2px); }
.back-ico { transition: transform .35s cubic-bezier(0.22,1,0.36,1); }
.back-btn:hover .back-ico { transform: translateX(-3px); }
.nav-brand { display: flex; align-items: center; gap: 8px; font-weight: 700; font-size: .9rem; color: #f1f5f9; }
.nav-right { min-width: 90px; display: flex; justify-content: flex-end; }

.live-badge {
  display: inline-flex; align-items: center; gap: 6px;
  background: rgba(239,68,68,.15); border: 1px solid rgba(239,68,68,.35);
  color: #fca5a5; border-radius: 20px; padding: 4px 12px;
  font-size: .72rem; font-weight: 700; letter-spacing: .05em;
}
.live-dot {
  width: 6px; height: 6px; border-radius: 50%; background: #f87171;
  animation: live-pulse 1s ease-in-out infinite;
}
@keyframes live-pulse { 0%,100% { opacity:1; transform:scale(1); } 50% { opacity:.4; transform:scale(.7); } }

.done-badge {
  display: inline-flex; align-items: center;
  background: rgba(52,211,153,.12); border: 1px solid rgba(52,211,153,.3);
  color: #6ee7b7; border-radius: 20px; padding: 4px 12px;
  font-size: .72rem; font-weight: 700;
}
.badge-fade-enter-active, .badge-fade-leave-active { transition: opacity .3s, transform .3s; }
.badge-fade-enter-from, .badge-fade-leave-to { opacity: 0; transform: scale(.85); }

/* Upload body */
.re-body {
  position: relative; z-index: 10;
  max-width: 1100px; margin: 0 auto;
  padding: 56px 24px 100px;
}

.re-hero { text-align: center; margin-bottom: 44px; }
.hero-tag {
  display: inline-flex; align-items: center; gap: 8px;
  font-size: .72rem; font-weight: 700; letter-spacing: .07em; text-transform: uppercase;
  color: #fb923c;
  background: rgba(251,146,60,.1); border: 1px solid rgba(251,146,60,.25);
  padding: 5px 15px; border-radius: 20px; margin-bottom: 24px;
}
.tag-dot { width: 6px; height: 6px; border-radius: 50%; background: #fb923c; animation: live-pulse 2s ease-in-out infinite; }
.re-h1 {
  font-size: clamp(2rem,5.5vw,3.6rem); font-weight: 800; line-height: 1.1; letter-spacing: -.04em; margin: 0 0 18px;
}
.h1-plain { color: #f1f5f9; }
.h1-hot {
  display: inline-block;
  background: linear-gradient(135deg, #f97316 0%, #ef4444 50%, #fb923c 100%);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;
  animation: grad-anim 5s ease-in-out infinite alternate; background-size: 200% 200%;
}
@keyframes grad-anim { from { background-position: 0% 50%; } to { background-position: 100% 50%; } }
.re-sub { font-size: clamp(.85rem,2vw,1rem); color: #94a3b8; max-width: 580px; margin: 0 auto; line-height: 1.7; }

/* Error */
.err-box {
  max-width: 860px; margin: 0 auto 20px;
  background: rgba(254,202,202,.08); border: 1px solid rgba(252,165,165,.25);
  border-radius: 14px; padding: 12px 18px; color: #fca5a5; font-size: .85rem;
}
.err-fade-enter-active,.err-fade-leave-active { transition: opacity .35s,transform .35s; }
.err-fade-enter-from,.err-fade-leave-to { opacity: 0; transform: translateY(-8px); }

/* Panels */
.panels { display: grid; grid-template-columns: 1fr 1fr; gap: 22px; align-items: start; }
@media (max-width: 700px) { .panels { grid-template-columns: 1fr; } }

.panel {
  position: relative;
  background: rgba(255,255,255,.03); border: 1px solid rgba(255,255,255,.07);
  border-radius: 22px; padding: 24px 22px 20px; overflow: hidden;
  transition: transform .55s cubic-bezier(0.22,1,0.36,1),box-shadow .55s; will-change: transform;
}
.panel:hover { box-shadow: 0 16px 48px rgba(251,146,60,.12),0 0 0 1px rgba(251,146,60,.2); }
.panel-glow {
  position: absolute; inset: -1px; border-radius: 23px; z-index: 0;
  background: transparent; transition: background .45s; pointer-events: none;
}
.panel:hover .panel-glow { background: linear-gradient(135deg, rgba(251,146,60,.18), rgba(239,68,68,.1), rgba(217,119,6,.12)); }
.panel-hd { display: flex; align-items: flex-start; gap: 12px; margin-bottom: 16px; position: relative; z-index: 1; }
.panel-ico {
  font-size: 1.4rem; margin-top: 2px;
  background: rgba(251,146,60,.12); border: 1px solid rgba(251,146,60,.22);
  width: 40px; height: 40px; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0;
}
.panel-title { font-size: .9rem; font-weight: 700; color: #f1f5f9; letter-spacing: -.01em; }
.panel-hint  { font-size: .72rem; color: #64748b; margin-top: 2px; }

.drop-zone {
  display: block; border: 1.5px dashed rgba(251,146,60,.3);
  border-radius: 18px; background: rgba(251,146,60,.04);
  padding: 32px 24px; text-align: center; cursor: pointer;
  transition: all .45s cubic-bezier(0.22,1,0.36,1); position: relative; z-index: 1;
}
.drop-zone:hover { border-color: rgba(251,146,60,.6); background: rgba(251,146,60,.09); transform: scale(1.015) translateY(-2px); }
.drop-zone.has-file { border-style: solid; border-color: rgba(52,211,153,.4); background: rgba(52,211,153,.05); }
.dz-cloud { display: block; font-size: 2rem; margin-bottom: 8px; color: #fb923c; opacity: .7; }
.dz-check { display: block; font-size: 2rem; margin-bottom: 8px; color: #34d399; }
.dz-main  { display: block; font-size: .88rem; font-weight: 600; color: #cbd5e1; word-break: break-all; }
.dz-sub   { display: block; font-size: .72rem; color: #475569; margin-top: 5px; }

.file-info {
  display: flex; align-items: center; justify-content: space-between;
  margin-top: 10px; padding: 8px 12px;
  background: rgba(52,211,153,.06); border: 1px solid rgba(52,211,153,.15);
  border-radius: 10px; position: relative; z-index: 1;
}
.fi-name { font-size: .78rem; color: #6ee7b7; word-break: break-all; }
.fi-clear { background: none; border: none; color: #475569; cursor: pointer; font-size: .85rem; padding: 0 4px; transition: color .2s; }
.fi-clear:hover { color: #f87171; }

.ta-wrap {
  border: 1.5px solid rgba(255,255,255,.08); border-radius: 16px; overflow: hidden;
  max-height: 340px; transition: border-color .35s,box-shadow .35s; position: relative; z-index: 1;
}
.ta-wrap.focused { border-color: rgba(251,146,60,.5); box-shadow: 0 0 0 3px rgba(251,146,60,.1); }
.glass-ta {
  display: block; width: 100%; height: 280px; min-height: 120px; max-height: 320px;
  overflow-y: auto; background: rgba(255,255,255,.03); color: #e2e8f0;
  border: none; outline: none; resize: none; padding: 15px 16px;
  font-size: .86rem; line-height: 1.75; font-family: inherit;
}
.glass-ta::placeholder { color: #334155; }
.ta-bar {
  display: flex; align-items: center; justify-content: space-between;
  padding: 7px 14px; border-top: 1px solid rgba(255,255,255,.05);
  background: rgba(255,255,255,.02); position: relative; z-index: 1;
}
.char-cnt { font-size: .68rem; color: #475569; font-variant-numeric: tabular-nums; }
.char-cnt.warn { color: #f87171; }
.clear-btn { font-size: .7rem; font-weight: 600; color: #475569; background: none; border: none; cursor: pointer; padding: 2px 8px; border-radius: 8px; transition: background .25s,color .25s; }
.clear-btn:hover { background: rgba(255,255,255,.08); color: #94a3b8; }

/* CTA */
.cta-row { display: flex; flex-direction: column; align-items: center; gap: 14px; margin-top: 32px; }
.cta-btn {
  position: relative; overflow: hidden;
  display: flex; align-items: center; gap: 10px;
  padding: 15px 40px; border: none; border-radius: 16px;
  background: linear-gradient(135deg, #f97316, #ef4444);
  font-size: 1rem; font-weight: 700; color: #fff; letter-spacing: -.01em;
  cursor: pointer; box-shadow: 0 4px 28px rgba(249,115,22,.4);
  transition: transform .45s cubic-bezier(0.22,1,0.36,1),box-shadow .45s; will-change: transform;
}
.cta-btn:disabled { opacity: .45; cursor: not-allowed; transform: none !important; box-shadow: none !important; }
.cta-btn:not(:disabled):hover { transform: scale(1.04) translateY(-2px); box-shadow: 0 8px 36px rgba(249,115,22,.55),0 0 0 3px rgba(249,115,22,.18); }
.cta-btn:not(:disabled):active { transform: scale(.97); transition-duration: .1s; }
.cta-fire { font-size: 1.2rem; animation: fire-flicker 1.5s ease-in-out infinite alternate; }
@keyframes fire-flicker { from { transform: scale(1) rotate(-3deg); } to { transform: scale(1.15) rotate(3deg); } }
.btn-shine {
  position: absolute; inset: 0;
  background: linear-gradient(110deg,transparent 30%,rgba(255,255,255,.22) 50%,transparent 70%);
  transform: translateX(-100%); transition: transform 0s;
}
.cta-btn:not(:disabled):hover .btn-shine { transform: translateX(100%); transition: transform .5s ease; }
.req-note { font-size: .75rem; color: #475569; text-align: center; }

.status-pill {
  display: flex; align-items: center; gap: 10px;
  padding: 11px 20px; background: rgba(249,115,22,.1); border: 1px solid rgba(249,115,22,.25);
  border-radius: 12px; font-size: .84rem; color: #fdba74;
}
.spin-ring {
  display: inline-block; width: 14px; height: 14px; flex-shrink: 0;
  border: 2px solid rgba(253,186,116,.3); border-top-color: #fb923c;
  border-radius: 50%; animation: spin .7s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
.pill-in-enter-active { transition: opacity .35s,transform .35s cubic-bezier(0.22,1,0.36,1); }
.pill-in-enter-from   { opacity: 0; transform: translateY(8px); }

/* Editor layout */
.editor-wrap {
  position: relative; z-index: 10;
  display: flex; flex-direction: column;
  height: calc(100vh - 56px);
}

.toolbar {
  display: flex; align-items: center; justify-content: space-between;
  padding: 10px 20px; gap: 12px;
  background: rgba(6,5,8,.85);
  border-bottom: 1px solid rgba(255,255,255,.07);
  backdrop-filter: blur(12px);
  flex-shrink: 0;
}
.tb-left, .tb-right { display: flex; gap: 8px; }
.tb-center { flex: 1; text-align: center; }
.tb-btn {
  background: rgba(255,255,255,.06); border: 1px solid rgba(255,255,255,.1);
  color: #94a3b8; border-radius: 10px; padding: 7px 14px;
  font-size: .78rem; font-weight: 600; cursor: pointer;
  transition: all .3s cubic-bezier(0.22,1,0.36,1);
}
.tb-btn:hover { background: rgba(255,255,255,.11); color: #f1f5f9; }
.tb-reset { color: #94a3b8; }
.tb-dl { border-color: rgba(251,146,60,.3); color: #fb923c; }
.tb-dl:hover { background: rgba(251,146,60,.1); border-color: rgba(251,146,60,.5); color: #fdba74; }

.tb-status { font-size: .8rem; font-weight: 600; }
.tb-status.hot { color: #fb923c; display: flex; align-items: center; gap: 8px; justify-content: center; }
.tb-status.done { color: #6ee7b7; }
.hot-ring {
  width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0;
  border: 2px solid rgba(251,146,60,.3); border-top-color: #fb923c;
  animation: spin .6s linear infinite;
}

.hot-hint {
  text-align: center; padding: 7px 20px;
  background: rgba(249,115,22,.07); border-bottom: 1px solid rgba(249,115,22,.15);
  font-size: .78rem; color: #fdba74; flex-shrink: 0;
}
.hint-fade-enter-active,.hint-fade-leave-active { transition: opacity .4s,max-height .4s; max-height: 50px; }
.hint-fade-enter-from,.hint-fade-leave-to { opacity: 0; max-height: 0; }

/* Editor area */
.editor-outer {
  position: relative; flex: 1; display: flex; flex-direction: column;
  margin: 16px 20px; border-radius: 16px; overflow: hidden;
  border: 1.5px solid rgba(255,255,255,.08);
  transition: border-color .5s,box-shadow .5s;
}
.editor-outer.hot {
  border-color: rgba(249,115,22,.5);
  box-shadow: 0 0 0 3px rgba(249,115,22,.1), 0 0 40px rgba(249,115,22,.12);
  animation: hot-pulse 2s ease-in-out infinite;
}
.editor-outer.cool {
  border-color: rgba(52,211,153,.35);
  box-shadow: 0 0 0 3px rgba(52,211,153,.08);
}
@keyframes hot-pulse {
  0%,100% { box-shadow: 0 0 0 3px rgba(249,115,22,.1), 0 0 40px rgba(249,115,22,.12); }
  50%      { box-shadow: 0 0 0 3px rgba(249,115,22,.2), 0 0 60px rgba(249,115,22,.22); }
}

.editor-ta {
  flex: 1; width: 100%; height: 100%;
  background: rgba(255,255,255,.025); color: #e2e8f0;
  border: none; outline: none; resize: none;
  padding: 24px 28px;
  font-size: .92rem; line-height: 1.85;
  font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', 'Consolas', monospace;
  letter-spacing: .01em;
}
.editor-ta::placeholder { color: #334155; }
.editor-ta:not([readonly]) { caret-color: #fb923c; }

.cursor-blink {
  position: absolute; bottom: 24px; right: 28px;
  color: #fb923c; font-size: 1rem;
  animation: blink .85s step-end infinite;
  pointer-events: none;
}
@keyframes blink { 0%,100% { opacity: 1; } 50% { opacity: 0; } }

/* Entrance */
.ai-in {
  opacity: 0; transform: translateY(26px);
  animation: fadeUp .9s cubic-bezier(0.22,1,0.36,1) both;
  animation-delay: var(--d,0s);
}
@keyframes fadeUp { to { opacity: 1; transform: translateY(0); } }
</style>
