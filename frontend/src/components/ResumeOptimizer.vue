<template>
  <div class="ro" ref="root" @mousemove="onMouse">
    <!-- BG -->
    <div class="cursor-glow" ref="cursorGlow"></div>
    <canvas ref="canvas" class="bg-canvas"></canvas>
    <div class="aurora" aria-hidden="true">
      <div class="ab ab1"></div><div class="ab ab2"></div><div class="ab ab3"></div>
    </div>

    <!-- Nav -->
    <nav class="ro-nav">
      <button class="back-btn" @click="$emit('close')">
        <span class="back-ico">←</span>返回
      </button>
      <div class="nav-brand">🧠 AI 简历深度优化</div>
      <div class="step-ind">
        <span class="si" :class="{active: stepNum===1, done: stepNum>1}">① 输入</span>
        <span class="si-arrow">›</span>
        <span class="si" :class="{active: stepNum===2, done: stepNum>2}">② 事实确认</span>
        <span class="si-arrow">›</span>
        <span class="si" :class="{active: stepNum===3}">③ 双屏工作台</span>
      </div>
    </nav>

    <!-- ── STEP 1: Input / Analyzing ── -->
    <div v-if="stepNum === 1" class="ro-body">
      <div v-if="step === 'analyzing'" class="analyzing-center">
        <div class="brain-ico">🧠</div>
        <div class="analyzing-title">AI 正在深度分析差距…</div>
        <div class="analyzing-sub">{{ analysisStatus }}</div>
        <div class="progress-dots"><span></span><span></span><span></span></div>
      </div>

      <template v-else>
        <header class="ro-hero ai-in" style="--d:0s">
          <div class="hero-tag"><span class="tag-dot"></span>AI 驱动 · 拒绝瞎编 · 双屏协同</div>
          <h1 class="ro-h1">
            <span class="h1-plain">简历</span>&nbsp;<span class="h1-grad">深度优化</span><br>
            <span class="h1-plain">工作台</span>
          </h1>
          <p class="ro-sub">上传简历 + 粘贴 JD → AI 先做差距分析，再追问你的真实经历 → 双屏协同编辑 → 一键导出</p>
        </header>

        <transition name="err-fade">
          <div v-if="err" class="err-box">⚠ {{ err }}</div>
        </transition>

        <div class="panels ai-in" style="--d:.14s">
          <!-- Left: Upload -->
          <div class="panel" ref="panelL" @mousemove="e=>tilt(e,panelL)" @mouseleave="e=>resetTilt(panelL)">
            <div class="panel-glow"></div>
            <div class="panel-hd">
              <div class="panel-ico">📄</div>
              <div>
                <div class="panel-title">我的简历</div>
                <div class="panel-hint">PDF · Word · TXT · MD · 图片</div>
              </div>
            </div>
            <label class="drop-zone" :class="{'has-file': rFile}">
              <input type="file"
                accept=".pdf,.doc,.docx,.txt,.md,.jpg,.jpeg,.png,application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document,image/*"
                @change="pickFile" hidden />
              <template v-if="!rFile">
                <span class="dz-cloud">☁</span>
                <span class="dz-main">点击上传简历文件</span>
                <span class="dz-sub">PDF · Word · TXT · MD · 图片</span>
              </template>
              <template v-else>
                <span class="dz-check">✓</span>
                <span class="dz-name">{{ rFile.name }}</span>
                <span class="dz-sub">点击重新选择</span>
              </template>
            </label>
          </div>

          <!-- Right: JD -->
          <div class="panel" ref="panelR" @mousemove="e=>tilt(e,panelR)" @mouseleave="e=>resetTilt(panelR)">
            <div class="panel-glow"></div>
            <div class="panel-hd">
              <div class="panel-ico">📋</div>
              <div>
                <div class="panel-title">目标职位 JD</div>
                <div class="panel-hint">从任意招聘平台复制</div>
              </div>
            </div>
            <div class="ta-wrap" :class="{focused: jdFocus}">
              <textarea class="glass-ta" v-model="jdText"
                placeholder="将职位描述粘贴到这里…&#10;&#10;可从 BOSS 直聘、猎聘、招聘官网等复制完整 JD"
                @focus="jdFocus=true" @blur="jdFocus=false" />
            </div>
            <div class="ta-bar">
              <span :class="['char-cnt',{warn:jdText.length>2800}]">{{ jdText.length }} / 3000</span>
              <button v-if="jdText" class="clear-btn" @click="jdText=''">清空</button>
            </div>
          </div>
        </div>

        <div class="cta-row ai-in" style="--d:.28s">
          <button class="cta-btn" :disabled="!canRun" @click="startAnalysis">
            <span class="cta-ico">🧠</span>
            <span>开始 AI 深度分析</span>
            <span class="btn-shine"></span>
          </button>
          <p v-if="!canRun" class="req-note">请上传简历并粘贴 JD（各至少 20 字）</p>
        </div>
      </template>
    </div>

    <!-- ── STEP 2: Questioning ── -->
    <div v-else-if="step === 'questioning'" class="ro-body">
      <!-- Score card -->
      <div class="score-section ai-in" style="--d:0s">
        <div class="score-wrap">
          <svg class="score-svg" viewBox="0 0 100 100">
            <circle cx="50" cy="50" r="42" class="track"/>
            <circle cx="50" cy="50" r="42" class="fill"
              :style="{ stroke: scoreColor, strokeDasharray: `${2*Math.PI*42}`, strokeDashoffset: scoreOffset }" />
          </svg>
          <div class="score-inner">
            <span class="score-num" :style="{color: scoreColor}">{{ analysis.score }}</span>
            <span class="score-label">/ 100</span>
          </div>
        </div>
        <div class="score-info">
          <div class="score-title">AI 综合评估</div>
          <p class="score-summary">{{ analysis.summary }}</p>
          <div class="gaps-row">
            <span v-for="g in analysis.gaps" :key="g.skill"
              class="gap-chip" :class="`sev-${g.severity}`">
              {{ g.skill }}
              <span class="gap-sev">{{ g.severity === 'high' ? '高' : g.severity === 'medium' ? '中' : '低' }}</span>
            </span>
          </div>
        </div>
      </div>

      <!-- Q&A -->
      <div v-if="analysis.questions.length" class="qa-section ai-in" style="--d:.1s">
        <div class="qa-header">
          <span class="qa-ico">🤔</span>
          <div>
            <div class="qa-title">AI 教练追问</div>
            <div class="qa-sub">以下差距需要进一步确认，请如实作答 — AI 只会使用你亲口确认的经历</div>
          </div>
        </div>
        <div v-for="(q, i) in analysis.questions" :key="q.id" class="qa-card"
          :class="{skipped: skipped.has(q.id)}">
          <div class="qa-num">Q{{ i+1 }}</div>
          <div class="qa-body">
            <div class="qa-q">{{ q.question }}</div>
            <div class="qa-skill-tag">涉及技能：{{ q.gap_skill }}</div>
            <textarea v-if="!skipped.has(q.id)"
              class="qa-ta" v-model="answers[q.id]"
              :placeholder="`请描述你在 ${q.gap_skill} 方面的真实经历…`"
              rows="3" />
            <div v-else class="skip-badge">已跳过 — AI 将注明暂无此经验</div>
            <div class="qa-actions">
              <button v-if="!skipped.has(q.id)" class="skip-btn" @click="skip(q.id)">无此经验，跳过</button>
              <button v-else class="unskip-btn" @click="unskip(q.id)">撤销跳过</button>
            </div>
          </div>
        </div>
      </div>

      <div v-else class="no-qa ai-in" style="--d:.1s">
        <span class="no-qa-ico">🎯</span>
        <div>匹配度很高，无需补充追问，可直接进入工作台优化简历！</div>
      </div>

      <div class="cta-row ai-in" style="--d:.22s">
        <button class="cta-btn" :disabled="!canSubmit" @click="goWorkspace">
          <span>进入双屏协同工作台 →</span>
          <span class="btn-shine"></span>
        </button>
        <button class="ghost-btn" @click="step='input'; err=''">← 重新上传</button>
      </div>
    </div>

    <!-- ── STEP 3: Workspace ── -->
    <div v-else class="workspace">
      <!-- Toolbar -->
      <div class="ws-toolbar">
        <button class="tb-btn" @click="step='questioning'">← 返回确认</button>
        <div class="tb-status">
          <template v-if="optimizing">
            <span class="hot-ring"></span>
            <span style="color:#fb923c">AI 正在生成简历…</span>
          </template>
          <template v-else>
            <span style="color:#34d399">✓ 生成完成 — 右侧可直接编辑</span>
          </template>
        </div>
        <div class="tb-exports">
          <button class="tb-btn tb-export" :disabled="optimizing" @click="exportPdf">
            📥 导出 PDF
          </button>
          <button class="tb-btn tb-export tb-word" :disabled="optimizing" @click="exportWord">
            📝 导出 Word
          </button>
        </div>
      </div>

      <!-- Split screen -->
      <div class="ws-split">
        <!-- Left: Original -->
        <div class="ws-left">
          <div class="ws-hd">原始简历 <span class="ws-hd-sub">只读</span></div>
          <div class="ws-preview">
            <div v-if="!previewReady" class="preview-loading">
              <span class="spin-ring"></span> 加载预览中…
            </div>
            <iframe v-else-if="previewType==='pdf'" :src="previewUrl" class="preview-iframe" />
            <img v-else-if="previewType==='image'" :src="previewUrl" class="preview-img" />
            <div v-else-if="previewType==='html'" class="docx-preview" v-html="previewHtml" />
            <pre v-else class="txt-preview">{{ previewText }}</pre>
          </div>
        </div>

        <!-- Divider -->
        <div class="ws-divider"></div>

        <!-- Right: AI output / WangEditor -->
        <div class="ws-right">
          <div class="ws-hd">
            AI 优化版
            <span v-if="optimizing" class="live-badge"><span class="live-dot"></span>LIVE</span>
            <span v-else class="edit-badge">编辑模式</span>
          </div>

          <!-- Streaming preview -->
          <div v-show="optimizing" ref="streamEl" class="stream-wrap">
            <div class="stream-content" v-html="safeStreamHtml"></div>
            <span class="cursor-blink">▌</span>
          </div>

          <!-- WangEditor (always rendered, shown when done) -->
          <div v-show="!optimizing" class="editor-outer">
            <Toolbar class="we-toolbar" :editor="editorRef" :defaultConfig="toolbarConfig" mode="default" />
            <Editor
              class="we-editor"
              v-model="editorHtml"
              :defaultConfig="editorConfig"
              mode="default"
              @onCreated="handleCreated"
            />
          </div>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount, nextTick, shallowRef } from 'vue'
import { useI18n } from 'vue-i18n'
import DOMPurify from 'dompurify'
import '@wangeditor/editor/dist/css/style.css'
import { Editor, Toolbar } from '@wangeditor/editor-for-vue'

defineEmits(['close'])

const API_BASE = import.meta.env.DEV ? '' : 'https://offer-catcher-api.onrender.com'
const { locale } = useI18n()

// ── DOM refs ──────────────────────────────────────────────────
const root       = ref(null)
const canvas     = ref(null)
const cursorGlow = ref(null)
const panelL     = ref(null)
const panelR     = ref(null)
const streamEl   = ref(null)

// ── State ─────────────────────────────────────────────────────
const step          = ref('input')   // input | analyzing | questioning | workspace
const rFile         = ref(null)
const jdText        = ref('')
const jdFocus       = ref(false)
const err           = ref('')
const analysisStatus = ref('')
const analysis      = ref({ score: 0, summary: '', gaps: [], questions: [] })
const answers       = ref({})
const skipped       = ref(new Set())

// Preview
const previewReady  = ref(false)
const previewType   = ref('text')  // pdf | image | html | text
const previewUrl    = ref('')
const previewHtml   = ref('')
const previewText   = ref('')

// Workspace / streaming
const optimizing    = ref(true)
const streamedHtml  = ref('')

// WangEditor
const editorRef     = shallowRef()
const editorHtml    = ref('')
const toolbarConfig = {}
const editorConfig  = { placeholder: 'AI 优化后的简历将在这里显示…', scroll: false }

const ALLOWED = new Set(['pdf','docx','doc','txt','md','jpg','jpeg','png','gif','webp'])

const stepNum = computed(() => {
  if (step.value === 'input' || step.value === 'analyzing') return 1
  if (step.value === 'questioning') return 2
  return 3
})
const canRun = computed(() => rFile.value && jdText.value.trim().length >= 20)
const canSubmit = computed(() => {
  const qs = analysis.value.questions || []
  if (!qs.length) return true
  return qs.every(q => skipped.value.has(q.id) || (answers.value[q.id] || '').trim())
})
const scoreColor = computed(() => {
  const s = analysis.value.score
  if (s >= 80) return '#10b981'
  if (s >= 60) return '#f59e0b'
  return '#ef4444'
})
const scoreOffset = computed(() => {
  const c = 2 * Math.PI * 42
  return c * (1 - (analysis.value.score || 0) / 100)
})
const safeStreamHtml = computed(() =>
  DOMPurify.sanitize(streamedHtml.value, { USE_PROFILES: { html: true } })
)

// ── File picker ───────────────────────────────────────────────
function pickFile(e) {
  const f = e.target.files?.[0]; if (!f) return
  const ext = f.name.split('.').pop().toLowerCase()
  if (ALLOWED.has(ext)) { rFile.value = f; err.value = '' }
  else err.value = '不支持的文件格式'
}

// ── Step 1 → Step 2: Gap analysis ────────────────────────────
async function startAnalysis() {
  if (!canRun.value) return
  step.value = 'analyzing'
  err.value = ''
  analysisStatus.value = '正在解析简历并分析与 JD 的差距…'
  try {
    const fd = new FormData()
    fd.append('file', rFile.value)
    fd.append('jd_text', jdText.value.slice(0, 3000))
    const resp = await fetch(`${API_BASE}/api/resume-gap-analyze`, {
      method: 'POST',
      headers: { 'Accept-Language': 'zh-CN' },
      body: fd,
    })
    if (!resp.ok) {
      const e = await resp.json().catch(() => ({}))
      throw new Error(e.detail || `HTTP ${resp.status}`)
    }
    const data = await resp.json()
    analysis.value = {
      score: data.score ?? 60,
      summary: data.summary ?? '',
      gaps: data.gaps ?? [],
      questions: data.questions ?? [],
    }
    // Init answers
    const init = {}
    for (const q of analysis.value.questions) init[q.id] = ''
    answers.value = init
    skipped.value = new Set()
    step.value = 'questioning'
  } catch (e) {
    err.value = e.message
    step.value = 'input'
  }
}

// ── Skip / unskip ─────────────────────────────────────────────
function skip(qId) {
  skipped.value = new Set([...skipped.value, qId])
  answers.value[qId] = ''
}
function unskip(qId) {
  const s = new Set(skipped.value); s.delete(qId)
  skipped.value = s
}

// ── Step 2 → Step 3: Go workspace ────────────────────────────
async function goWorkspace() {
  if (!canSubmit.value) return
  step.value = 'workspace'
  optimizing.value = true
  streamedHtml.value = ''
  previewReady.value = false
  preparePreview(rFile.value)   // fire-and-forget (fast, local)
  await streamOptimize()
}

// ── Prepare original file preview (browser-side) ─────────────
async function preparePreview(file) {
  const ext = file.name.split('.').pop().toLowerCase()
  if (ext === 'pdf') {
    previewType.value = 'pdf'
    previewUrl.value = URL.createObjectURL(file)
    previewReady.value = true
  } else if (['jpg','jpeg','png','gif','webp'].includes(ext)) {
    previewType.value = 'image'
    previewUrl.value = URL.createObjectURL(file)
    previewReady.value = true
  } else if (['doc','docx'].includes(ext)) {
    previewType.value = 'html'
    try {
      const ab = await file.arrayBuffer()
      const mammoth = (await import('mammoth')).default
      const result  = await mammoth.convertToHtml({ arrayBuffer: ab })
      previewHtml.value = DOMPurify.sanitize(result.value, { USE_PROFILES: { html: true } })
    } catch { previewHtml.value = '<p style="color:#64748b">Word 预览失败，请参考原件。</p>' }
    previewReady.value = true
  } else {
    previewType.value = 'text'
    previewText.value = await file.text().catch(() => '（读取失败）')
    previewReady.value = true
  }
}

// ── Stream optimized HTML ─────────────────────────────────────
async function streamOptimize() {
  try {
    const fd = new FormData()
    fd.append('file', rFile.value)
    fd.append('jd_text', jdText.value.slice(0, 3000))
    fd.append('questions_json', JSON.stringify(analysis.value.questions))
    fd.append('answers_json', JSON.stringify(answers.value))

    const resp = await fetch(`${API_BASE}/api/resume-optimize-final`, {
      method: 'POST',
      headers: { 'Accept-Language': 'zh-CN' },
      body: fd,
    })
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`)

    const reader = resp.body.getReader()
    const dec    = new TextDecoder()
    let buf = ''
    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      buf += dec.decode(value, { stream: true })
      const lines = buf.split('\n'); buf = lines.pop() || ''
      for (const line of lines) {
        if (!line.startsWith('data: ')) continue
        const obj = JSON.parse(line.slice(6))
        if (obj.type === 'chunk') {
          streamedHtml.value += obj.text
          await nextTick()
          if (streamEl.value) streamEl.value.scrollTop = streamEl.value.scrollHeight
        } else if (obj.type === 'done') {
          optimizing.value = false
        } else if (obj.type === 'error') {
          throw new Error(obj.message)
        }
      }
    }
    optimizing.value = false
  } catch (e) {
    err.value = e.message
    optimizing.value = false
  }
}

// ── WangEditor ────────────────────────────────────────────────
function handleCreated(editor) { editorRef.value = editor }

watch(optimizing, async (val) => {
  if (!val && editorRef.value) {
    await nextTick()
    editorRef.value.setHtml(streamedHtml.value || '<p>（未生成内容，请重试）</p>')
  }
})

// ── Export: PDF ───────────────────────────────────────────────
async function exportPdf() {
  if (optimizing.value || !editorRef.value) return
  const html = editorRef.value.getHtml()
  const html2pdf = (await import('html2pdf.js')).default
  const wrap = document.createElement('div')
  wrap.style.cssText = 'font-family:Arial,sans-serif;font-size:12pt;color:#000;background:#fff;padding:20px;max-width:800px;'
  wrap.innerHTML = DOMPurify.sanitize(html, { USE_PROFILES: { html: true } })
  document.body.appendChild(wrap)
  await html2pdf().from(wrap).set({
    margin: 10,
    filename: `resume-optimized-${Date.now()}.pdf`,
    image: { type: 'jpeg', quality: 0.98 },
    html2canvas: { scale: 2, useCORS: true, backgroundColor: '#ffffff' },
    jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' },
  }).save()
  document.body.removeChild(wrap)
}

// ── Export: Word (.doc) ───────────────────────────────────────
function exportWord() {
  if (optimizing.value || !editorRef.value) return
  const html = editorRef.value.getHtml()
  const doc = `<html xmlns:o='urn:schemas-microsoft-com:office:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='http://www.w3.org/TR/REC-html40'><head><meta charset='utf-8'><style>body{font-family:Arial;font-size:12pt;color:#000;}h1{font-size:18pt;}h2{font-size:14pt;border-bottom:1px solid #ccc;}ul{margin:4pt 0;padding-left:18pt;}li{margin:2pt 0;}</style></head><body>${html}</body></html>`
  const blob = new Blob(['﻿', doc], { type: 'application/msword' })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = `resume-optimized-${Date.now()}.doc`
  a.click()
  URL.revokeObjectURL(a.href)
}

// ── Canvas + cursor ───────────────────────────────────────────
let mx=0,my=0,cgx=0,cgy=0,rafCursor=0
function onMouse(e) { mx=e.clientX; my=e.clientY }
function animCursor() {
  cgx+=(mx-cgx)*0.09; cgy+=(my-cgy)*0.09
  if (cursorGlow.value) cursorGlow.value.style.transform=`translate(${cgx-200}px,${cgy-200}px)`
  rafCursor=requestAnimationFrame(animCursor)
}
function tilt(e,elRef) {
  const el=elRef?.value??elRef; if(!el) return
  const r=el.getBoundingClientRect()
  const x=(e.clientX-r.left)/r.width-.5, y=(e.clientY-r.top)/r.height-.5
  el.style.transform=`perspective(800px) rotateX(${-y*7}deg) rotateY(${x*7}deg) scale(1.02) translateZ(6px)`
  el.style.transition='transform .08s linear'
}
function resetTilt(elRef) {
  const el=elRef?.value??elRef; if(!el) return
  el.style.transform=''; el.style.transition='transform .55s cubic-bezier(0.22,1,0.36,1)'
}
let ctx2d,pts=[],rafCanvas=0
const N=55,MAX_D=120
function initCanvas() {
  const c=canvas.value; if(!c) return
  c.width=window.innerWidth; c.height=window.innerHeight
  ctx2d=c.getContext('2d')
  pts=Array.from({length:N},()=>({x:Math.random()*c.width,y:Math.random()*c.height,vx:(Math.random()-.5)*.35,vy:(Math.random()-.5)*.35,r:Math.random()*1.3+.4}))
}
function drawCanvas() {
  const c=canvas.value; if(!c||!ctx2d) return
  ctx2d.clearRect(0,0,c.width,c.height)
  for (const p of pts) {
    p.x+=p.vx; p.y+=p.vy
    if(p.x<0||p.x>c.width)p.vx*=-1
    if(p.y<0||p.y>c.height)p.vy*=-1
    ctx2d.beginPath(); ctx2d.arc(p.x,p.y,p.r,0,Math.PI*2)
    ctx2d.fillStyle='rgba(139,92,246,.5)'; ctx2d.fill()
  }
  for(let i=0;i<pts.length;i++) for(let j=i+1;j<pts.length;j++) {
    const dx=pts[i].x-pts[j].x,dy=pts[i].y-pts[j].y,d=Math.sqrt(dx*dx+dy*dy)
    if(d<MAX_D){ctx2d.beginPath();ctx2d.moveTo(pts[i].x,pts[i].y);ctx2d.lineTo(pts[j].x,pts[j].y);ctx2d.strokeStyle=`rgba(139,92,246,${.1*(1-d/MAX_D)})`;ctx2d.lineWidth=.7;ctx2d.stroke()}
  }
  rafCanvas=requestAnimationFrame(drawCanvas)
}
function onResize() { if(canvas.value){canvas.value.width=window.innerWidth;canvas.value.height=window.innerHeight} }
onMounted(()=>{initCanvas();drawCanvas();animCursor();window.addEventListener('resize',onResize)})
onBeforeUnmount(()=>{
  cancelAnimationFrame(rafCanvas); cancelAnimationFrame(rafCursor)
  window.removeEventListener('resize',onResize)
  if(previewUrl.value) URL.revokeObjectURL(previewUrl.value)
  editorRef.value?.destroy()
})
</script>

<style scoped>
.ro {
  position:fixed; inset:0; z-index:50;
  background:#060510; color:#e2e8f0;
  font-family:-apple-system,'SF Pro Text','Inter','Helvetica Neue',sans-serif;
  -webkit-font-smoothing:antialiased;
  overflow-y:auto; overflow-x:hidden;
}
.bg-canvas { position:fixed; inset:0; z-index:0; pointer-events:none; }
.aurora { position:fixed; inset:0; z-index:0; pointer-events:none; overflow:hidden; }
.ab { position:absolute; border-radius:50%; filter:blur(88px); opacity:.1; animation:ab-float 9s ease-in-out infinite; }
.ab1 { width:680px;height:680px;background:#6366f1;top:-220px;left:-160px; }
.ab2 { width:520px;height:520px;background:#8b5cf6;top:40%;right:-180px;animation-delay:-3.5s; }
.ab3 { width:440px;height:440px;background:#06b6d4;bottom:8%;left:18%;animation-delay:-6s; }
@keyframes ab-float{0%,100%{transform:translateY(0)scale(1)}50%{transform:translateY(-36px)scale(1.04)}}
.cursor-glow{position:fixed;top:0;left:0;width:400px;height:400px;border-radius:50%;background:radial-gradient(circle,rgba(99,102,241,.15)0%,transparent 70%);pointer-events:none;z-index:1;will-change:transform}

/* Nav */
.ro-nav{position:sticky;top:0;z-index:100;display:flex;align-items:center;justify-content:space-between;padding:0 24px;height:56px;background:rgba(6,5,16,.8);backdrop-filter:blur(24px);border-bottom:1px solid rgba(255,255,255,.06)}
.back-btn{display:flex;align-items:center;gap:6px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);color:#94a3b8;border-radius:980px;padding:6px 14px;font-size:.78rem;font-weight:600;cursor:pointer;transition:all .4s cubic-bezier(0.22,1,0.36,1)}
.back-btn:hover{background:rgba(255,255,255,.11);color:#f1f5f9;transform:translateX(-2px)}
.back-ico{transition:transform .35s cubic-bezier(0.22,1,0.36,1)}
.back-btn:hover .back-ico{transform:translateX(-3px)}
.nav-brand{font-weight:700;font-size:.9rem;color:#f1f5f9}
.step-ind{display:flex;align-items:center;gap:6px;font-size:.72rem}
.si{color:#334155;font-weight:600;transition:color .3s}
.si.active{color:#818cf8}
.si.done{color:#34d399}
.si-arrow{color:#1e293b}

/* Body */
.ro-body{position:relative;z-index:10;max-width:1100px;margin:0 auto;padding:52px 24px 100px}

/* Hero */
.ro-hero{text-align:center;margin-bottom:40px}
.hero-tag{display:inline-flex;align-items:center;gap:8px;font-size:.72rem;font-weight:700;letter-spacing:.07em;text-transform:uppercase;color:#818cf8;background:rgba(99,102,241,.1);border:1px solid rgba(99,102,241,.25);padding:5px 15px;border-radius:20px;margin-bottom:24px}
.tag-dot{width:6px;height:6px;border-radius:50%;background:#818cf8;animation:pulse 2s ease-in-out infinite}
@keyframes pulse{0%,100%{opacity:1;transform:scale(1)}50%{opacity:.4;transform:scale(.75)}}
.ro-h1{font-size:clamp(2rem,5.5vw,3.6rem);font-weight:800;line-height:1.1;letter-spacing:-.04em;margin:0 0 16px}
.h1-plain{color:#f1f5f9}
.h1-grad{display:inline-block;background:linear-gradient(135deg,#818cf8 0%,#c084fc 50%,#67e8f9 100%);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;animation:grad 6s ease-in-out infinite alternate;background-size:200% 200%}
@keyframes grad{from{background-position:0% 50%}to{background-position:100% 50%}}
.ro-sub{font-size:clamp(.85rem,2vw,.95rem);color:#64748b;max-width:620px;margin:0 auto;line-height:1.75}

/* Error */
.err-box{max-width:860px;margin:0 auto 20px;background:rgba(254,202,202,.08);border:1px solid rgba(252,165,165,.25);border-radius:14px;padding:12px 18px;color:#fca5a5;font-size:.85rem}
.err-fade-enter-active,.err-fade-leave-active{transition:opacity .35s,transform .35s}
.err-fade-enter-from,.err-fade-leave-to{opacity:0;transform:translateY(-8px)}

/* Panels */
.panels{display:grid;grid-template-columns:1fr 1fr;gap:22px;align-items:start}
@media(max-width:700px){.panels{grid-template-columns:1fr}}
.panel{position:relative;background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.07);border-radius:22px;padding:24px 22px 20px;overflow:hidden;transition:transform .55s cubic-bezier(0.22,1,0.36,1),box-shadow .55s;will-change:transform}
.panel:hover{box-shadow:0 16px 48px rgba(99,102,241,.14),0 0 0 1px rgba(99,102,241,.2)}
.panel-glow{position:absolute;inset:-1px;border-radius:23px;z-index:0;background:transparent;transition:background .45s;pointer-events:none}
.panel:hover .panel-glow{background:linear-gradient(135deg,rgba(99,102,241,.22),rgba(139,92,246,.14),rgba(6,182,212,.16))}
.panel-hd{display:flex;align-items:flex-start;gap:12px;margin-bottom:16px;position:relative;z-index:1}
.panel-ico{font-size:1.4rem;background:rgba(99,102,241,.12);border:1px solid rgba(99,102,241,.22);width:40px;height:40px;border-radius:12px;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.panel-title{font-size:.9rem;font-weight:700;color:#f1f5f9;letter-spacing:-.01em}
.panel-hint{font-size:.72rem;color:#64748b;margin-top:2px}

/* Drop zone */
.drop-zone{display:block;border:1.5px dashed rgba(99,102,241,.3);border-radius:18px;background:rgba(99,102,241,.04);padding:32px 24px;text-align:center;cursor:pointer;transition:all .45s cubic-bezier(0.22,1,0.36,1);position:relative;z-index:1}
.drop-zone:hover{border-color:rgba(99,102,241,.6);background:rgba(99,102,241,.1);transform:scale(1.015) translateY(-2px)}
.drop-zone.has-file{border-style:solid;border-color:rgba(52,211,153,.4);background:rgba(52,211,153,.05)}
.dz-cloud{display:block;font-size:2rem;margin-bottom:8px;color:#818cf8;opacity:.7}
.dz-check{display:block;font-size:2rem;margin-bottom:8px;color:#34d399}
.dz-main,.dz-name{display:block;font-size:.88rem;font-weight:600;color:#cbd5e1;word-break:break-all}
.dz-sub{display:block;font-size:.72rem;color:#475569;margin-top:5px}

/* Textarea */
.ta-wrap{border:1.5px solid rgba(255,255,255,.08);border-radius:16px;overflow:hidden;max-height:340px;transition:border-color .35s,box-shadow .35s;position:relative;z-index:1}
.ta-wrap.focused{border-color:rgba(99,102,241,.5);box-shadow:0 0 0 3px rgba(99,102,241,.12)}
.glass-ta{display:block;width:100%;height:280px;min-height:120px;max-height:320px;overflow-y:auto;background:rgba(255,255,255,.03);color:#e2e8f0;border:none;outline:none;resize:none;padding:15px 16px;font-size:.86rem;line-height:1.75;font-family:inherit}
.glass-ta::placeholder{color:#334155}
.ta-bar{display:flex;align-items:center;justify-content:space-between;padding:7px 14px;border-top:1px solid rgba(255,255,255,.05);background:rgba(255,255,255,.02);position:relative;z-index:1}
.char-cnt{font-size:.68rem;color:#475569}
.char-cnt.warn{color:#f87171}
.clear-btn{font-size:.7rem;font-weight:600;color:#475569;background:none;border:none;cursor:pointer;padding:2px 8px;border-radius:8px;transition:background .25s,color .25s}
.clear-btn:hover{background:rgba(255,255,255,.08);color:#94a3b8}

/* CTA */
.cta-row{display:flex;flex-direction:column;align-items:center;gap:14px;margin-top:32px}
.cta-btn{position:relative;overflow:hidden;display:flex;align-items:center;gap:10px;padding:14px 40px;border:none;border-radius:14px;background:linear-gradient(135deg,#6366f1,#8b5cf6);font-size:.95rem;font-weight:700;color:#fff;letter-spacing:-.01em;cursor:pointer;box-shadow:0 4px 22px rgba(99,102,241,.38);transition:transform .45s cubic-bezier(0.22,1,0.36,1),box-shadow .45s;will-change:transform}
.cta-btn:disabled{opacity:.45;cursor:not-allowed;transform:none!important;box-shadow:none!important}
.cta-btn:not(:disabled):hover{transform:scale(1.03) translateY(-2px);box-shadow:0 8px 32px rgba(99,102,241,.52),0 0 0 3px rgba(99,102,241,.18)}
.cta-btn:not(:disabled):active{transform:scale(.97);transition-duration:.1s}
.cta-ico{font-size:1.1rem}
.btn-shine{position:absolute;inset:0;background:linear-gradient(110deg,transparent 30%,rgba(255,255,255,.2) 50%,transparent 70%);transform:translateX(-100%);transition:transform 0s}
.cta-btn:not(:disabled):hover .btn-shine{transform:translateX(100%);transition:transform .5s ease}
.req-note{font-size:.74rem;color:#475569;text-align:center}
.ghost-btn{background:transparent;border:1px solid rgba(255,255,255,.1);border-radius:12px;padding:9px 24px;font-size:.82rem;font-weight:600;color:#64748b;cursor:pointer;transition:all .4s cubic-bezier(0.22,1,0.36,1)}
.ghost-btn:hover{border-color:rgba(255,255,255,.22);color:#94a3b8;background:rgba(255,255,255,.04)}

/* Analyzing */
.analyzing-center{display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:60vh;gap:16px;text-align:center}
.brain-ico{font-size:3rem;animation:brain-pulse 1.5s ease-in-out infinite alternate}
@keyframes brain-pulse{from{transform:scale(1)}to{transform:scale(1.15)}}
.analyzing-title{font-size:1.2rem;font-weight:700;color:#f1f5f9}
.analyzing-sub{font-size:.85rem;color:#64748b}
.progress-dots{display:flex;gap:8px}
.progress-dots span{width:8px;height:8px;border-radius:50%;background:#818cf8;animation:dot-bounce .9s ease-in-out infinite}
.progress-dots span:nth-child(2){animation-delay:.2s}
.progress-dots span:nth-child(3){animation-delay:.4s}
@keyframes dot-bounce{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}

/* Score section */
.score-section{display:flex;gap:28px;align-items:flex-start;background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.07);border-radius:20px;padding:24px;margin-bottom:24px}
.score-wrap{position:relative;width:110px;height:110px;flex-shrink:0}
.score-svg{transform:rotate(-90deg);width:110px;height:110px}
.track{fill:none;stroke:rgba(255,255,255,.07);stroke-width:9}
.fill{fill:none;stroke-width:9;stroke-linecap:round;transition:stroke-dashoffset 1.2s cubic-bezier(0.22,1,0.36,1)}
.score-inner{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center}
.score-num{font-size:1.9rem;font-weight:800;line-height:1}
.score-label{font-size:.7rem;color:#64748b}
.score-info{flex:1}
.score-title{font-size:.75rem;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.05em;margin-bottom:8px}
.score-summary{font-size:.88rem;color:#cbd5e1;line-height:1.7;margin:0 0 14px}
.gaps-row{display:flex;flex-wrap:wrap;gap:8px}
.gap-chip{display:inline-flex;align-items:center;gap:6px;padding:4px 12px;border-radius:20px;font-size:.75rem;font-weight:600}
.gap-chip.sev-high{background:rgba(239,68,68,.12);border:1px solid rgba(239,68,68,.3);color:#fca5a5}
.gap-chip.sev-medium{background:rgba(245,158,11,.12);border:1px solid rgba(245,158,11,.3);color:#fcd34d}
.gap-chip.sev-low{background:rgba(99,102,241,.12);border:1px solid rgba(99,102,241,.3);color:#a5b4fc}
.gap-sev{opacity:.7;font-size:.65rem}

/* Q&A */
.qa-section{display:flex;flex-direction:column;gap:16px;margin-bottom:28px}
.qa-header{display:flex;align-items:flex-start;gap:14px;padding:18px;background:rgba(99,102,241,.06);border:1px solid rgba(99,102,241,.15);border-radius:16px}
.qa-ico{font-size:1.4rem}
.qa-title{font-size:.92rem;font-weight:700;color:#c7d2fe;margin-bottom:4px}
.qa-sub{font-size:.78rem;color:#64748b;line-height:1.6}
.qa-card{display:flex;gap:14px;background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.07);border-radius:16px;padding:18px;transition:all .35s}
.qa-card.skipped{opacity:.5;border-color:rgba(255,255,255,.04)}
.qa-num{width:28px;height:28px;border-radius:50%;background:rgba(99,102,241,.2);border:1px solid rgba(99,102,241,.35);color:#a5b4fc;font-size:.78rem;font-weight:700;display:flex;align-items:center;justify-content:center;flex-shrink:0;margin-top:2px}
.qa-body{flex:1}
.qa-q{font-size:.88rem;color:#e2e8f0;line-height:1.65;margin-bottom:8px}
.qa-skill-tag{display:inline-block;font-size:.7rem;color:#64748b;background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:8px;padding:2px 10px;margin-bottom:10px}
.qa-ta{width:100%;background:rgba(255,255,255,.04);border:1.5px solid rgba(255,255,255,.08);border-radius:12px;color:#e2e8f0;font-size:.84rem;line-height:1.65;padding:10px 14px;outline:none;resize:vertical;font-family:inherit;transition:border-color .3s,box-shadow .3s}
.qa-ta:focus{border-color:rgba(99,102,241,.5);box-shadow:0 0 0 3px rgba(99,102,241,.1)}
.qa-ta::placeholder{color:#334155}
.qa-actions{margin-top:10px}
.skip-btn{font-size:.75rem;color:#475569;background:none;border:1px solid rgba(255,255,255,.08);border-radius:8px;padding:5px 12px;cursor:pointer;transition:all .25s}
.skip-btn:hover{background:rgba(255,255,255,.06);color:#94a3b8}
.unskip-btn{font-size:.75rem;color:#818cf8;background:none;border:1px solid rgba(99,102,241,.3);border-radius:8px;padding:5px 12px;cursor:pointer;transition:all .25s}
.unskip-btn:hover{background:rgba(99,102,241,.1)}
.skip-badge{font-size:.8rem;color:#475569;background:rgba(255,255,255,.03);border-radius:8px;padding:8px 14px;text-align:center}

.no-qa{display:flex;align-items:center;gap:14px;background:rgba(52,211,153,.06);border:1px solid rgba(52,211,153,.2);border-radius:16px;padding:20px 24px;font-size:.9rem;color:#6ee7b7;margin-bottom:24px}
.no-qa-ico{font-size:1.5rem}

/* Workspace */
.workspace{position:relative;z-index:10;display:flex;flex-direction:column;height:calc(100vh - 56px)}
.ws-toolbar{display:flex;align-items:center;justify-content:space-between;padding:10px 20px;gap:12px;background:rgba(6,5,16,.88);border-bottom:1px solid rgba(255,255,255,.07);flex-shrink:0}
.tb-btn{background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);color:#94a3b8;border-radius:10px;padding:7px 14px;font-size:.78rem;font-weight:600;cursor:pointer;transition:all .3s cubic-bezier(0.22,1,0.36,1)}
.tb-btn:hover:not(:disabled){background:rgba(255,255,255,.11);color:#f1f5f9}
.tb-btn:disabled{opacity:.35;cursor:not-allowed}
.tb-status{font-size:.82rem;display:flex;align-items:center;gap:8px}
.tb-exports{display:flex;gap:8px}
.tb-export{border-color:rgba(99,102,241,.3);color:#a5b4fc}
.tb-export:hover:not(:disabled){background:rgba(99,102,241,.1)!important;border-color:rgba(99,102,241,.5)!important;color:#c7d2fe!important}
.tb-word{border-color:rgba(52,211,153,.3);color:#6ee7b7}
.tb-word:hover:not(:disabled){background:rgba(52,211,153,.08)!important;border-color:rgba(52,211,153,.5)!important;color:#a7f3d0!important}
.hot-ring{width:10px;height:10px;border-radius:50%;flex-shrink:0;border:2px solid rgba(251,146,60,.3);border-top-color:#fb923c;animation:spin .6s linear infinite}
@keyframes spin{to{transform:rotate(360deg)}}

.ws-split{flex:1;display:flex;overflow:hidden;min-height:0}
.ws-left,.ws-right{flex:1;display:flex;flex-direction:column;overflow:hidden;min-width:0}
.ws-divider{width:1px;background:rgba(255,255,255,.07);flex-shrink:0}
.ws-hd{padding:10px 16px;font-size:.75rem;font-weight:700;color:#475569;border-bottom:1px solid rgba(255,255,255,.05);flex-shrink:0;display:flex;align-items:center;gap:8px;text-transform:uppercase;letter-spacing:.04em}
.ws-hd-sub{font-size:.65rem;color:#334155}
.live-badge{display:inline-flex;align-items:center;gap:5px;background:rgba(239,68,68,.12);border:1px solid rgba(239,68,68,.3);color:#fca5a5;border-radius:20px;padding:2px 8px;font-size:.65rem;font-weight:700;letter-spacing:.04em}
.live-dot{width:5px;height:5px;border-radius:50%;background:#f87171;animation:pulse 1s ease-in-out infinite}
.edit-badge{background:rgba(52,211,153,.1);border:1px solid rgba(52,211,153,.25);color:#6ee7b7;border-radius:20px;padding:2px 8px;font-size:.65rem;font-weight:700}

/* Left preview */
.ws-preview{flex:1;overflow:auto;background:rgba(255,255,255,.015)}
.preview-loading{display:flex;align-items:center;gap:10px;padding:40px 24px;color:#475569;font-size:.85rem}
.preview-iframe{width:100%;height:100%;border:none;background:#fff}
.preview-img{max-width:100%;height:auto;display:block;margin:0 auto;padding:16px}
.docx-preview{padding:24px 28px;font-size:.87rem;line-height:1.75;color:#cbd5e1}
:deep(.docx-preview h1){font-size:1.4rem;color:#f1f5f9;margin:16px 0 8px}
:deep(.docx-preview h2){font-size:1.1rem;color:#c7d2fe;margin:12px 0 6px;border-bottom:1px solid rgba(99,102,241,.2);padding-bottom:4px}
:deep(.docx-preview h3){font-size:.95rem;color:#a5b4fc;margin:10px 0 4px}
:deep(.docx-preview p,:deep(.docx-preview li)){color:#94a3b8;margin:3px 0}
:deep(.docx-preview ul){padding-left:20px}
:deep(.docx-preview strong){color:#e2e8f0}
.txt-preview{padding:20px;font-family:'SF Mono','Fira Code',monospace;font-size:.8rem;color:#94a3b8;white-space:pre-wrap;word-break:break-word;line-height:1.7}

/* Streaming */
.stream-wrap{flex:1;overflow-y:auto;padding:24px 28px;position:relative}
.stream-content{font-size:.88rem;line-height:1.8;color:#cbd5e1}
:deep(.stream-content h1){font-size:1.4rem;color:#f1f5f9;margin:16px 0 8px}
:deep(.stream-content h2){font-size:1.1rem;color:#c7d2fe;margin:12px 0 6px;border-bottom:1px solid rgba(99,102,241,.2);padding-bottom:4px}
:deep(.stream-content h3){font-size:.95rem;color:#a5b4fc;margin:10px 0 4px}
:deep(.stream-content p,:deep(.stream-content li)){color:#94a3b8;margin:3px 0}
:deep(.stream-content ul){padding-left:20px}
:deep(.stream-content strong){color:#e2e8f0}
.cursor-blink{display:inline-block;color:#818cf8;animation:blink .85s step-end infinite;font-size:1rem;vertical-align:middle}
@keyframes blink{0%,100%{opacity:1}50%{opacity:0}}

/* WangEditor container */
.editor-outer{flex:1;display:flex;flex-direction:column;overflow:hidden;min-height:0}
.we-toolbar{flex-shrink:0}
.we-editor{flex:1;overflow-y:auto}

/* WangEditor dark theme overrides */
:deep(.w-e-toolbar){background:rgba(255,255,255,.04)!important;border-bottom:1px solid rgba(255,255,255,.08)!important;border-top:none!important;border-left:none!important;border-right:none!important}
:deep(.w-e-bar-item button){color:#94a3b8!important}
:deep(.w-e-bar-item button:hover){background:rgba(255,255,255,.08)!important;color:#e2e8f0!important}
:deep(.w-e-bar-item-group .w-e-bar-item-group-title){color:#475569!important}
:deep(.w-e-text-container){background:rgba(255,255,255,.02)!important;color:#e2e8f0!important;border:none!important}
:deep([data-slate-editor]){color:#e2e8f0!important;font-family:-apple-system,'SF Pro Text','Inter',sans-serif!important;font-size:.88rem!important;line-height:1.8!important;padding:16px 24px!important}
:deep([data-slate-editor] h1){font-size:1.4rem;color:#f1f5f9;margin:16px 0 8px}
:deep([data-slate-editor] h2){font-size:1.1rem;color:#c7d2fe;border-bottom:1px solid rgba(99,102,241,.2);padding-bottom:4px;margin:12px 0 6px}
:deep([data-slate-editor] h3){font-size:.95rem;color:#a5b4fc;margin:10px 0 4px}
:deep([data-slate-editor] p){color:#94a3b8;margin:3px 0}
:deep([data-slate-editor] li){color:#94a3b8}
:deep([data-slate-editor] strong){color:#e2e8f0}
:deep(.w-e-text-placeholder){color:#334155!important}
:deep(.w-e-drop-panel){background:#1e1b2e!important;border:1px solid rgba(255,255,255,.1)!important;color:#e2e8f0!important}
:deep(.w-e-select-list){background:#1e1b2e!important;border:1px solid rgba(255,255,255,.1)!important}
:deep(.w-e-select-list li:hover){background:rgba(99,102,241,.2)!important}

/* Spin + entrance */
.spin-ring{display:inline-block;width:14px;height:14px;flex-shrink:0;border:2px solid rgba(165,180,252,.3);border-top-color:#818cf8;border-radius:50%;animation:spin .7s linear infinite}
.ai-in{opacity:0;transform:translateY(24px);animation:fadeUp .9s cubic-bezier(0.22,1,0.36,1) both;animation-delay:var(--d,0s)}
@keyframes fadeUp{to{opacity:1;transform:translateY(0)}}
</style>
