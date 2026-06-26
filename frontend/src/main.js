import { createApp } from 'vue'
import App from './App.vue'
import { i18n } from './i18n.js'

// ECharts global registration (tree-shaken) — must run before any VChart mount
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { ScatterChart } from 'echarts/charts'
import { GridComponent, TooltipComponent, MarkAreaComponent, MarkLineComponent } from 'echarts/components'
use([CanvasRenderer, ScatterChart, GridComponent, TooltipComponent, MarkAreaComponent, MarkLineComponent])

createApp(App).use(i18n).mount('#app')
