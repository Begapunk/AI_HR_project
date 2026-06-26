<template>
  <div v-if="hasAnyTags" class="tcp">
    <button class="tcp-hd" @click="open = !open" :aria-expanded="open">
      <span class="tcp-title">
        <span class="tcp-ico">🎯</span>
        核心能力图谱
        <span class="tcp-counts">
          <span class="cnt cnt-good">✓ {{ matchedTags.length }}</span>
          <span class="cnt cnt-miss">⚠ {{ missingTags.length }}</span>
          <span v-if="bonusTags.length" class="cnt cnt-bonus">＋ {{ bonusTags.length }}</span>
        </span>
      </span>
      <span class="tcp-caret" :class="{ rotated: open }">›</span>
    </button>

    <Transition name="tcp-slide">
      <div v-if="open" class="tcp-body">
        <div v-if="matchedTags.length" class="tcp-row">
          <span class="row-lbl lbl-good">命中</span>
          <div class="tcp-chips">
            <span v-for="t in matchedTags" :key="t" class="chip chip-good">{{ t }}</span>
          </div>
        </div>
        <div v-if="missingTags.length" class="tcp-row">
          <span class="row-lbl lbl-miss">缺失</span>
          <div class="tcp-chips">
            <span v-for="t in missingTags" :key="t" class="chip chip-miss">{{ t }}</span>
          </div>
        </div>
        <div v-if="bonusTags.length" class="tcp-row">
          <span class="row-lbl lbl-bonus">加分</span>
          <div class="tcp-chips">
            <span v-for="t in bonusTags" :key="t" class="chip chip-bonus">{{ t }}</span>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  matchedTags: { type: Array, default: () => [] },
  missingTags:  { type: Array, default: () => [] },
  bonusTags:    { type: Array, default: () => [] },
})

const open = ref(true)
const hasAnyTags = computed(() =>
  props.matchedTags.length + props.missingTags.length + props.bonusTags.length > 0
)
</script>

<style scoped>
/* ── Container ── */
.tcp {
  margin: 0 0 10px;
  border: 1px solid rgba(255,255,255,.07);
  border-radius: 12px;
  background: rgba(15,15,30,.55);
  backdrop-filter: blur(10px);
  overflow: hidden;
}

/* ── Header toggle ── */
.tcp-hd {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  background: none;
  border: none;
  cursor: pointer;
  color: #e2e8f0;
  user-select: none;
}
.tcp-hd:hover { background: rgba(255,255,255,.04); }

.tcp-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: .8rem;
  font-weight: 600;
  letter-spacing: .04em;
}
.tcp-ico { font-size: .9rem; }

.tcp-counts { display: flex; gap: 6px; }
.cnt {
  font-size: .68rem;
  font-weight: 700;
  padding: 1px 7px;
  border-radius: 99px;
  letter-spacing: .03em;
}
.cnt-good { background: rgba(16,185,129,.18); color: #34d399; }
.cnt-miss { background: rgba(239,68,68,.18);  color: #f87171; }
.cnt-bonus{ background: rgba(139,92,246,.18); color: #a78bfa; }

.tcp-caret {
  font-size: 1.1rem; color: #64748b;
  transition: transform .25s ease;
  display: inline-block;
}
.tcp-caret.rotated { transform: rotate(90deg); }

/* ── Slide transition ── */
.tcp-slide-enter-active, .tcp-slide-leave-active {
  transition: all .22s ease;
  overflow: hidden;
}
.tcp-slide-enter-from, .tcp-slide-leave-to {
  max-height: 0; opacity: 0; padding-top: 0; padding-bottom: 0;
}
.tcp-slide-enter-to, .tcp-slide-leave-from { max-height: 200px; opacity: 1; }

/* ── Body ── */
.tcp-body {
  padding: 4px 16px 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.tcp-row { display: flex; align-items: flex-start; gap: 10px; }

.row-lbl {
  flex-shrink: 0;
  font-size: .65rem;
  font-weight: 700;
  letter-spacing: .06em;
  padding: 3px 8px;
  border-radius: 6px;
  margin-top: 2px;
}
.lbl-good { background: rgba(16,185,129,.15); color: #34d399; }
.lbl-miss  { background: rgba(239,68,68,.15);  color: #f87171; }
.lbl-bonus { background: rgba(139,92,246,.15); color: #a78bfa; }

/* ── Chips ── */
.tcp-chips { display: flex; flex-wrap: wrap; gap: 6px; }

.chip {
  display: inline-flex;
  align-items: center;
  font-size: .72rem;
  font-weight: 600;
  padding: 3px 10px;
  border-radius: 99px;
  letter-spacing: .02em;
  border: 1px solid transparent;
  transition: transform .15s, box-shadow .15s;
  cursor: default;
}
.chip:hover { transform: translateY(-1px); }

/* matched — glowing green */
.chip-good {
  background: rgba(16,185,129,.12);
  border-color: rgba(16,185,129,.35);
  color: #6ee7b7;
  box-shadow: 0 0 8px rgba(16,185,129,.15);
}
.chip-good:hover { box-shadow: 0 0 14px rgba(16,185,129,.35); }

/* missing — warning orange-red */
.chip-miss {
  background: rgba(239,68,68,.1);
  border-color: rgba(239,68,68,.35);
  color: #fca5a5;
  animation: pulse-miss 2.5s ease infinite;
}
.chip-miss:hover { box-shadow: 0 0 14px rgba(239,68,68,.3); animation: none; }

/* bonus — subdued purple */
.chip-bonus {
  background: rgba(139,92,246,.1);
  border-color: rgba(139,92,246,.3);
  color: #c4b5fd;
}
.chip-bonus:hover { box-shadow: 0 0 14px rgba(139,92,246,.25); }

/* subtle pulse on missing chips to draw attention */
@keyframes pulse-miss {
  0%,100% { box-shadow: 0 0 4px rgba(239,68,68,.2); }
  50%      { box-shadow: 0 0 12px rgba(239,68,68,.45); }
}
</style>
