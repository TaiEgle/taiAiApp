<template>
  <div class="app-container">
    <!-- Background Decoration -->
    <div class="bg-orbs">
      <div class="orb orb-1"></div>
      <div class="orb orb-2"></div>
      <div class="orb orb-3"></div>
    </div>

    <!-- Header -->
    <header class="app-header">
      <h1 class="app-title">
        <el-icon class="title-icon"><MagicStick /></el-icon>
        AI 图片生成器
      </h1>
      <p class="app-subtitle">Powered by Agnes AI</p>
    </header>

    <!-- Mode Bar -->
    <ModeBar />

    <!-- Main Content -->
    <main class="main-content">
      <!-- Input Area -->
      <section class="card">
        <InputArea
          @generate="onGenerate"
        />
      </section>

      <!-- Result Area -->
      <section class="card">
        <ResultArea
          :loading="loading"
          :error="error"
          :current-result="currentResult"
        />
      </section>

      <!-- History -->
      <HistorySection />
    </main>

    <!-- Config Panel -->
    <ConfigPanel />
  </div>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { useAppStore } from './store'
import ModeBar from './components/ModeBar.vue'
import InputArea from './components/InputArea.vue'
import ResultArea from './components/ResultArea.vue'
import HistorySection from './components/HistorySection.vue'
import ConfigPanel from './components/ConfigPanel.vue'

const store = useAppStore()

const loading = ref(false)
const error = ref('')
const currentResult = ref('')

// Persist config to localStorage
watch(
  () => ({ url: store.apiUrl, key: store.apiKey, fmt: store.responseFormat }),
  (val) => {
    localStorage.setItem('ai-image-config', JSON.stringify(val))
  },
  { deep: true }
)

// Load persisted config on mount
onMounted(() => {
  try {
    const saved = JSON.parse(localStorage.getItem('ai-image-config'))
    if (saved) {
      if (saved.url) store.apiUrl = saved.url
      if (saved.key) store.apiKey = saved.key
      if (saved.fmt) store.responseFormat = saved.fmt
    }
  } catch {}

  // Load history from localStorage
  const hist = localStorage.getItem('ai-image-history')
  if (hist) {
    try { store.history = JSON.parse(hist) } catch {}
  }
})

// Watch history changes for persistence
watch(
  () => store.history,
  (val) => {
    try {
      localStorage.setItem('ai-image-history', JSON.stringify(val.slice(0, 5)))
    } catch {}
  },
  { deep: true }
)

async function onGenerate(data) {
  // Reset
  error.value = ''
  currentResult.value = ''
  loading.value = true

  // Validate API key
  if (!store.apiKey.trim()) {
    error.value = '请先在配置中心（右上角⚙️）填入你的 API Key'
    loading.value = false
    return
  }

  try {
    // Build request body
    const requestBody = {
      model: 'agnes-image-2.1-flash',
      prompt: data.prompt,
      n: 1,
      size: store.selectedSize
    }

    // Build extra_body
    const extraBody = {
      response_format: store.responseFormat === 'b64_json' ? 'b64_json' : 'url'
    }

    // Image-to-image: attach image source
    if (store.mode === 'img2img') {
      if (data.localImage) {
        extraBody.image = [data.localImage]
      } else if (data.imageUrl) {
        extraBody.image = [data.imageUrl]
      }
    }

    requestBody.extra_body = extraBody

    // Send request
    const response = await fetch(store.apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${store.apiKey.trim()}`
      },
      body: JSON.stringify(requestBody)
    })

    if (!response.ok) {
      if (response.status === 401) {
        throw new Error('API Key 无效或已过期，请在配置中心更新')
      }
      if (response.status === 429) {
        throw new Error('请求过于频繁，请稍后再试')
      }
      const errText = await response.text().catch(() => '')
      throw new Error(`请求失败 (${response.status}): ${errText || response.statusText}`)
    }

    const result = await response.json()

    if (!result.data || result.data.length === 0) {
      throw new Error('未获取到图片数据，请检查 API 响应')
    }

    const item = result.data[0]

    // Build display source
    let displaySrc = ''
    if (store.responseFormat === 'b64_json' && item.b64_json) {
      displaySrc = `data:image/png;base64,${item.b64_json}`
    } else if (item.url) {
      displaySrc = item.url
    } else {
      throw new Error('无法解析图片数据，请检查响应格式')
    }

    currentResult.value = displaySrc

    // Add to history
    store.addToHistory({
      prompt: data.prompt,
      displaySrc,
      timestamp: Date.now()
    })

    ElMessage.success('图片生成成功！')
  } catch (err) {
    error.value = err.message || '未知错误，请稍后重试'
    ElMessage.error(error.value)
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.app-container {
  position: relative;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
}

/* Background Orbs */
.bg-orbs {
  position: fixed;
  inset: 0;
  overflow: hidden;
  z-index: 0;
  pointer-events: none;
}

.orb {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  opacity: 0.4;
  animation: float 20s ease-in-out infinite;
}

.orb-1 {
  width: 400px;
  height: 400px;
  background: radial-gradient(circle, #a78bfa, #667eea);
  top: -100px;
  left: -100px;
  animation-delay: 0s;
}

.orb-2 {
  width: 350px;
  height: 350px;
  background: radial-gradient(circle, #f472b6, #ec4899);
  bottom: -80px;
  right: -80px;
  animation-delay: -7s;
}

.orb-3 {
  width: 250px;
  height: 250px;
  background: radial-gradient(circle, #38bdf8, #3b82f6);
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  animation-delay: -14s;
}

@keyframes float {
  0%, 100% { transform: translate(0, 0) scale(1); }
  25% { transform: translate(30px, -30px) scale(1.05); }
  50% { transform: translate(-20px, 20px) scale(0.95); }
  75% { transform: translate(20px, 10px) scale(1.02); }
}

/* Header */
.app-header {
  position: relative;
  z-index: 1;
  text-align: center;
  padding: 48px 20px 24px;
}

.app-title {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  font-size: 32px;
  font-weight: 700;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f472b6 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin: 0;
}

.title-icon {
  font-size: 32px;
}

.app-subtitle {
  font-size: 14px;
  color: #999;
  margin: 6px 0 0;
}

/* Main */
.main-content {
  position: relative;
  z-index: 1;
  width: 100%;
  max-width: 680px;
  padding: 0 16px 40px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card {
  background: rgba(255, 255, 255, 0.55);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border-radius: 20px;
  padding: 20px;
  border: 1px solid rgba(255, 255, 255, 0.5);
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.04);
}

/* Mobile */
@media (max-width: 640px) {
  .app-header {
    padding: 36px 16px 20px;
  }

  .app-title {
    font-size: 26px;
  }

  .main-content {
    padding: 0 12px 32px;
  }

  .card {
    padding: 16px;
    border-radius: 16px;
  }

  .orb {
    filter: blur(60px);
    opacity: 0.3;
  }

  .orb-1 { width: 250px; height: 250px; }
  .orb-2 { width: 200px; height: 200px; }
  .orb-3 { width: 150px; height: 150px; }
}
</style>
