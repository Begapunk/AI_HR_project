<template>
  <teleport to="body">
    <!-- Backdrop -->
    <transition name="rpd-fade">
      <div v-if="modelValue" class="rpd-overlay" @click="$emit('update:modelValue', false)" />
    </transition>

    <!-- Drawer panel -->
    <transition name="rpd-slide">
      <div v-if="modelValue" class="rpd-drawer">

        <!-- Header -->
        <div class="rpd-hd">
          <div class="rpd-hd-left">
            <p class="rpd-filename">{{ candidate?.raw_filename }}</p>
            <h3 class="rpd-cname">{{ candidate?.name || candidate?.raw_filename }}</h3>
            <div class="rpd-meta">
              <span v-if="candidate?.overall_score != null" class="rpd-score">{{ candidate.overall_score }}%</span>
              <span v-if="candidate?.tier" class="rpd-tier" :class="`rtier-${candidate.tier}`">{{ tierLabel }}</span>
              <span v-if="candidate?.low_quality" class="rpd-lowq-tag">⚠ {{ locale === 'zh' ? '识别不佳' : 'Low Extract' }}</span>
            </div>
          </div>
          <div class="rpd-hd-right">
            <button class="rpd-export-btn" @click="exportPDF" :disabled="exporting || !file">
              <template v-if="!exporting">📥 {{ locale === 'zh' ? '导出 PDF' : 'Export PDF' }}</template>
              <template v-else>
                <span class="rpd-spinner-sm"></span>
                {{ locale === 'zh' ? '转码中…' : 'Converting…' }}
              </template>
            </button>
            <button class="rpd-close-btn" @click="$emit('update:modelValue', false)">×</button>
          </div>
        </div>

        <!-- Body -->
        <div class="rpd-body">

          <!-- No file in memory -->
          <div v-if="!file" class="rpd-nofile">
            <div class="rpd-nofile-ico">📄</div>
            <p class="rpd-nofile-title">{{ locale === 'zh' ? '原始文件不可用' : 'File Unavailable' }}</p>
            <p class="rpd-nofile-hint">{{ locale === 'zh' ? '页面刷新后内存已清除，请重新上传' : 'File cleared after page refresh. Please re-upload.' }}</p>
          </div>

          <!-- PDF → iframe native render -->
          <iframe v-else-if="isPDF" class="rpd-iframe" :src="blobUrl" />

          <!-- Image → img tag -->
          <div v-else-if="isImage" class="rpd-img-wrap">
            <img :src="blobUrl" class="rpd-img" alt="resume preview" />
          </div>

          <!-- Word / TXT / other → mammoth HTML -->
          <div v-else class="rpd-html-outer">
            <div v-if="converting" class="rpd-converting">
              <div class="rpd-spinner"></div>
              <span>{{ locale === 'zh' ? '正在渲染文档…' : 'Rendering document…' }}</span>
            </div>
            <div v-else ref="htmlRef" class="rpd-html-content" v-html="htmlContent" />
          </div>

        </div>
      </div>
    </transition>
  </teleport>
</template>

<script setup>
import { ref, computed, watch, onUnmounted } from 'vue'
import { useI18n } from 'vue-i18n'

const props = defineProps({
  modelValue: Boolean,
  candidate: Object,
  file: Object,
})
const emit = defineEmits(['update:modelValue'])
const { locale } = useI18n()

const blobUrl  = ref('')
const htmlContent = ref('')
const htmlRef  = ref(null)
const converting = ref(false)
const exporting  = ref(false)

const isPDF = computed(() =>
  props.file?.type === 'application/pdf' ||
  /\.pdf$/i.test(props.file?.name || '')
)
const isImage = computed(() =>
  /^image\//.test(props.file?.type || '') ||
  /\.(jpe?g|png|gif|webp|bmp)$/i.test(props.file?.name || '')
)

const tierLabel = computed(() => {
  const zh = { strong_recommend: '🥇 强推', consider: '💡 可考虑', not_recommend: '暂不推荐', rejected: '🚫' }
  const en = { strong_recommend: '🥇 Top', consider: '💡 Consider', not_recommend: 'Not Rec.', rejected: '🚫' }
  return (locale.value === 'zh' ? zh : en)[props.candidate?.tier] || ''
})

function cleanup() {
  if (blobUrl.value) { URL.revokeObjectURL(blobUrl.value); blobUrl.value = '' }
  htmlContent.value = ''
}

watch(
  [() => props.modelValue, () => props.file],
  async ([open, f]) => {
    cleanup()
    if (!open || !f) return

    blobUrl.value = URL.createObjectURL(f)

    if (isPDF.value || isImage.value) return

    // Word / TXT / MD → convert to HTML
    converting.value = true
    try {
      const isDoc = /\.docx?$/i.test(f.name)
      if (isDoc) {
        const mammoth = (await import('mammoth')).default
        const buf = await f.arrayBuffer()
        const result = await mammoth.convertToHtml({ arrayBuffer: buf })
        htmlContent.value = result.value
      } else {
        const text = await f.text()
        const escaped = text.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
        htmlContent.value = `<pre class="rpd-pre">${escaped}</pre>`
      }
    } catch (e) {
      htmlContent.value = `<p style="color:#f87171">渲染失败: ${e.message}</p>`
    } finally {
      converting.value = false
    }
  },
  { immediate: false }
)

async function exportPDF() {
  if (!props.file || exporting.value) return
  const base = (props.candidate?.name || props.candidate?.raw_filename || 'resume').replace(/\.[^.]+$/, '')
  const filename = `${base}_简历.pdf`

  if (isPDF.value) {
    const a = document.createElement('a')
    a.href = blobUrl.value
    a.download = filename
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    return
  }

  exporting.value = true
  try {
    const el = htmlRef.value
    if (!el) return
    const { default: html2pdf } = await import('html2pdf.js')
    await html2pdf()
      .set({
        margin: [12, 14, 12, 14],
        filename,
        html2canvas: { scale: 2, useCORS: true, backgroundColor: '#ffffff' },
        jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' },
      })
      .from(el)
      .save()
  } finally {
    exporting.value = false
  }
}

onUnmounted(cleanup)
</script>

<style scoped>
/* ── Overlay ── */
.rpd-overlay {
  position: fixed; inset: 0;
  background: rgba(0, 0, 0, .55);
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
  z-index: 1000;
}

/* ── Drawer panel ── */
.rpd-drawer {
  position: fixed; top: 0; right: 0; bottom: 0;
  width: clamp(340px, 46vw, 800px);
  z-index: 1001;
  background: #0d0d1f;
  border-left: 1px solid rgba(255,255,255,.08);
  display: flex; flex-direction: column;
  box-shadow: -16px 0 64px rgba(0,0,0,.6);
}

/* ── Transitions ── */
.rpd-fade-enter-active, .rpd-fade-leave-active { transition: opacity .25s ease; }
.rpd-fade-enter-from, .rpd-fade-leave-to { opacity: 0; }

.rpd-slide-enter-active, .rpd-slide-leave-active { transition: transform .3s cubic-bezier(.22,.68,0,1.2); }
.rpd-slide-enter-from, .rpd-slide-leave-to { transform: translateX(100%); }

/* ── Header ── */
.rpd-hd {
  display: flex; align-items: flex-start; justify-content: space-between; gap: 12px;
  padding: 20px 20px 16px;
  border-bottom: 1px solid rgba(255,255,255,.07);
  flex-shrink: 0;
  background: rgba(255,255,255,.02);
}
.rpd-hd-left { flex: 1; min-width: 0; }
.rpd-filename { font-size: .72rem; color: #475569; margin: 0 0 4px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.rpd-cname { font-size: 1.05rem; font-weight: 700; color: #e2e8f0; margin: 0 0 8px; line-height: 1.3; }
.rpd-meta { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.rpd-score { font-size: .85rem; font-weight: 700; color: #818cf8; background: rgba(129,140,248,.12); padding: 2px 8px; border-radius: 20px; }
.rpd-tier { font-size: .78rem; padding: 2px 8px; border-radius: 20px; }
.rtier-strong_recommend { background: rgba(52,211,153,.1); color: #34d399; }
.rtier-consider { background: rgba(251,191,36,.1); color: #fbbf24; }
.rtier-not_recommend, .rtier-rejected { background: rgba(248,113,113,.1); color: #f87171; }
.rpd-lowq-tag { font-size: .72rem; color: #fb923c; background: rgba(251,146,60,.1); padding: 2px 8px; border-radius: 20px; }

.rpd-hd-right { display: flex; align-items: center; gap: 8px; flex-shrink: 0; }

.rpd-export-btn {
  display: flex; align-items: center; gap: 6px;
  padding: 7px 14px; border-radius: 8px; border: 1px solid rgba(129,140,248,.35);
  background: rgba(129,140,248,.1); color: #818cf8;
  font-size: .82rem; font-weight: 600; cursor: pointer;
  transition: all .2s;
  white-space: nowrap;
}
.rpd-export-btn:hover:not(:disabled) { background: rgba(129,140,248,.2); border-color: rgba(129,140,248,.6); }
.rpd-export-btn:disabled { opacity: .5; cursor: not-allowed; }

.rpd-close-btn {
  width: 32px; height: 32px; border-radius: 8px; border: 1px solid rgba(255,255,255,.1);
  background: rgba(255,255,255,.05); color: #94a3b8;
  font-size: 1.2rem; cursor: pointer; display: flex; align-items: center; justify-content: center;
  transition: all .15s; flex-shrink: 0;
}
.rpd-close-btn:hover { background: rgba(248,113,113,.15); color: #f87171; border-color: rgba(248,113,113,.3); }

/* ── Body ── */
.rpd-body { flex: 1; overflow: hidden; display: flex; flex-direction: column; }

/* No file */
.rpd-nofile {
  flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center;
  color: #475569; gap: 8px;
}
.rpd-nofile-ico { font-size: 3rem; }
.rpd-nofile-title { font-size: 1rem; color: #64748b; margin: 0; }
.rpd-nofile-hint { font-size: .8rem; color: #334155; margin: 0; text-align: center; max-width: 240px; }

/* PDF iframe */
.rpd-iframe { width: 100%; flex: 1; border: none; background: #fff; }

/* Image */
.rpd-img-wrap { flex: 1; overflow: auto; display: flex; align-items: flex-start; justify-content: center; padding: 20px; background: #07071a; }
.rpd-img { max-width: 100%; border-radius: 8px; box-shadow: 0 4px 24px rgba(0,0,0,.5); }

/* HTML content (Word/TXT) */
.rpd-html-outer { flex: 1; overflow-y: auto; background: #ffffff; }

.rpd-converting {
  display: flex; align-items: center; justify-content: center; gap: 10px;
  height: 100%; color: #94a3b8; font-size: .9rem;
}

.rpd-html-content {
  padding: 32px 40px;
  color: #1e293b;
  font-family: 'Georgia', 'Times New Roman', serif;
  font-size: 14px; line-height: 1.8;
  max-width: 760px; margin: 0 auto;
}
.rpd-html-content :deep(h1), .rpd-html-content :deep(h2), .rpd-html-content :deep(h3) {
  color: #0f172a; margin-top: 1.4em; margin-bottom: .5em;
}
.rpd-html-content :deep(table) { border-collapse: collapse; width: 100%; margin: 1em 0; }
.rpd-html-content :deep(td), .rpd-html-content :deep(th) { border: 1px solid #e2e8f0; padding: 6px 10px; }
.rpd-html-content :deep(strong) { color: #0f172a; }
.rpd-pre { white-space: pre-wrap; word-break: break-word; font-family: 'Menlo', monospace; font-size: 13px; }

/* Spinners */
.rpd-spinner {
  width: 20px; height: 20px; border-radius: 50%;
  border: 2px solid rgba(129,140,248,.2);
  border-top-color: #818cf8;
  animation: rpd-spin .7s linear infinite;
}
.rpd-spinner-sm {
  display: inline-block; width: 12px; height: 12px; border-radius: 50%;
  border: 2px solid rgba(129,140,248,.2);
  border-top-color: #818cf8;
  animation: rpd-spin .7s linear infinite;
}
@keyframes rpd-spin { to { transform: rotate(360deg); } }
</style>
