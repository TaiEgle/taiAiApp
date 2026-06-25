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
      <div class="brand">
        <div class="brand-icon">
          <span class="brand-icon-inner">帧</span>
        </div>
        <div class="brand-text">
          <h1 class="brand-name">帧不错</h1>
          <p class="brand-tagline">AI 图像 · 视频生成</p>
        </div>
      </div>
    </header>

    <!-- Top-level Mode Tabs: Image / Video -->
    <div class="top-nav">
      <div class="top-nav-tabs">
        <div
          class="nav-tab"
          :class="{ active: appMode === 'image' }"
          @click="appMode = 'image'"
        >
          <el-icon><Picture /></el-icon>
          <span>图片</span>
        </div>
        <div
          class="nav-tab"
          :class="{ active: appMode === 'video' }"
          @click="appMode = 'video'"
        >
          <el-icon><VideoCamera /></el-icon>
          <span>视频</span>
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <main class="main-content">
      <!-- Image Generation Mode -->
      <template v-if="appMode === 'image'">
        <ModeBar />
        <section class="card">
          <InputArea @generate="onGenerate" />
        </section>
        <section class="card">
          <ResultArea
            :loading="loading"
            :error="error"
            :current-result="currentResult"
          />
        </section>
        <HistorySection />
      </template>

      <!-- Video Generation Mode -->
      <template v-else>
        <VideoModeBar />
        <section class="card">
          <VideoInputArea @generate="onVideoGenerate" />
        </section>
        <section class="card">
          <VideoResultArea
            :polling="videoPolling"
            :progress="videoProgress"
            :status="videoStatus"
            :current-video-url="videoCurrentUrl"
            :error="videoError"
          />
        </section>
        <VideoHistorySection />
      </template>
    </main>

    <!-- Config Panel -->
    <ConfigPanel />
  </div>
</template>

<script setup>
import { ref, watch, onMounted, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { useAppStore } from './store'
import { buildVideoRequestBody } from './utils/videoApi'

// Components
import ModeBar from './components/ModeBar.vue'
import InputArea from './components/InputArea.vue'
import ResultArea from './components/ResultArea.vue'
import HistorySection from './components/HistorySection.vue'
import ConfigPanel from './components/ConfigPanel.vue'
import VideoModeBar from './components/VideoModeBar.vue'
import VideoInputArea from './components/VideoInputArea.vue'
import VideoResultArea from './components/VideoResultArea.vue'
import VideoHistorySection from './components/VideoHistorySection.vue'

const store = useAppStore()

// App mode: 'image' | 'video'
const appMode = computed({
  get: () => store.appMode,
  set: (val) => { store.appMode = val }
})

// ===================== Image Generation =====================
const loading = ref(false)
const error = ref('')
const currentResult = ref('')

// Persist image config
watch(
  () => ({ url: store.apiUrl, key: store.apiKey, fmt: store.responseFormat }),
  (val) => { localStorage.setItem('ai-image-config', JSON.stringify(val)) },
  { deep: true }
)

// ===================== Video Generation =====================
const videoPolling = ref(false)
const videoProgress = ref(0)
const videoStatus = ref('')
const videoCurrentUrl = ref('')
const videoError = ref('')
let videoPollingTimer = null

// Persist video config
watch(
  () => ({ url: store.videoBaseUrl, key: store.apiKey, fmt: store.responseFormat }),
  (val) => { localStorage.setItem('ai-video-config', JSON.stringify(val)) },
  { deep: true }
)

// ===================== Shared: Load on mount =====================
onMounted(() => {
  // Load image config
  try {
    const saved = JSON.parse(localStorage.getItem('ai-image-config'))
    if (saved) {
      if (saved.url) store.apiUrl = saved.url
      if (saved.key) store.apiKey = saved.key
      if (saved.fmt) store.responseFormat = saved.fmt
    }
  } catch {}

  // Load video config
  try {
    const saved = JSON.parse(localStorage.getItem('ai-video-config'))
    if (saved) {
      if (saved.url) store.videoBaseUrl = saved.url
      if (saved.key) store.apiKey = saved.key
      if (saved.fmt) store.responseFormat = saved.fmt
    }
  } catch {}

  // Load image history
  const imgHist = localStorage.getItem('ai-image-history')
  if (imgHist) {
    try { store.history = JSON.parse(imgHist) } catch {}
  }

  // Load video history
  const vidHist = localStorage.getItem('ai-video-history')
  if (vidHist) {
    try { store.videoHistory = JSON.parse(vidHist) } catch {}
  }
})

// Persist image history
watch(
  () => store.history,
  (val) => {
    try { localStorage.setItem('ai-image-history', JSON.stringify(val.slice(0, 5))) } catch {}
  },
  { deep: true }
)

// ===================== Image Generate Handler =====================
async function onGenerate(data) {
  error.value = ''
  currentResult.value = ''
  loading.value = true

  if (!store.apiKey.trim()) {
    error.value = '请先在配置中心（右上角⚙️）填入你的 API Key'
    loading.value = false
    return
  }

  try {
    const requestBody = {
      model: 'agnes-image-2.1-flash',
      prompt: data.prompt,
      n: 1,
      size: store.selectedSize,
      extra_body: {
        response_format: store.responseFormat === 'b64_json' ? 'b64_json' : 'url'
      }
    }

    if (store.mode === 'img2img') {
      if (data.localImage) {
        requestBody.extra_body.image = [data.localImage]
      } else if (data.imageUrl) {
        requestBody.extra_body.image = [data.imageUrl]
      }
    }

    const response = await fetch(store.apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${store.apiKey.trim()}`
      },
      body: JSON.stringify(requestBody)
    })

    if (!response.ok) {
      await handleHttpError(response)
      return
    }

    const result = await response.json()

    if (!result.data || result.data.length === 0) {
      throw new Error('未获取到图片数据，请检查 API 响应')
    }

    const item = result.data[0]
    let displaySrc = ''

    if (store.responseFormat === 'b64_json' && item.b64_json) {
      displaySrc = `data:image/png;base64,${item.b64_json}`
    } else if (item.url) {
      displaySrc = item.url
    } else {
      throw new Error('无法解析图片数据，请检查响应格式')
    }

    currentResult.value = displaySrc
    store.addToHistory({ prompt: data.prompt, displaySrc, timestamp: Date.now() })
    ElMessage.success('图片生成成功！')
  } catch (err) {
    error.value = err.message || '未知错误，请稍后重试'
    ElMessage.error(error.value)
  } finally {
    loading.value = false
  }
}

// ===================== Video Generate Handler =====================
async function onVideoGenerate(data) {
  videoError.value = ''
  videoCurrentUrl.value = ''
  videoProgress.value = 0
  videoStatus.value = '提交中...'
  videoPolling.value = true

  if (!store.apiKey.trim()) {
    videoError.value = '请先在配置中心（右上角⚙️）填入你的 API Key'
    videoPolling.value = false
    return
  }

  try {
    // Build request body
    const body = buildVideoRequestBody(store.videoMode, data, store)

    // Determine video API URL
    const base = store.videoBaseUrl.replace(/\/+$/, '')
    const videoUrl = `${base}/v1/videos`

    const response = await fetch(videoUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${store.apiKey.trim()}`
      },
      body: JSON.stringify(body)
    })

    if (!response.ok) {
      await handleHttpError(response)
      videoPolling.value = false
      return
    }

    const result = await response.json()

    // Extract video_id
    const videoId = result.video_id || result.task_id || result.id
    if (!videoId) {
      throw new Error('未获取到视频任务 ID，请检查 API 响应')
    }

    // Start polling
    startVideoPolling(videoId)
  } catch (err) {
    videoError.value = err.message || '未知错误，请稍后重试'
    videoPolling.value = false
    ElMessage.error(videoError.value)
  }
}

function startVideoPolling(videoId) {
  // Clear any existing timer
  if (videoPollingTimer) clearInterval(videoPollingTimer)

  videoStatus.value = '排队中...'
  videoProgress.value = 0

  videoPollingTimer = setInterval(async () => {
    try {
      const base = store.videoBaseUrl.replace(/\/+$/, '')
      const pollUrl = `${base}/agnesapi?video_id=${videoId}&model_name=agnes-video-v2.0`

      const response = await fetch(pollUrl, {
        headers: {
          'Authorization': `Bearer ${store.apiKey.trim()}`
        }
      })

      if (!response.ok) {
        if (response.status === 401) {
          throw new Error('API Key 无效或已过期')
        }
        throw new Error(`轮询失败 (${response.status})`)
      }

      const data = await response.json()

      // Update progress (clamp 0-100, API may return decimal 0~1 or percentage 0~100)
      if (data.progress !== undefined && data.progress !== null) {
        let p = Math.round(data.progress * 100)
        if (p > 100) p = Math.round(data.progress) // API already returns percentage
        videoProgress.value = Math.min(100, Math.max(0, p))
      }

      // Update status
      if (data.status) {
        const statusMap = {
          queued: '排队中...',
          completed: '已完成！',
          failed: '生成失败'
        }
        if (data.status === 'in_progress') {
          videoStatus.value = `生成中 ${videoProgress.value}%`
        } else {
          videoStatus.value = statusMap[data.status] || data.status
        }
      }

      // Check completion
      if (data.status === 'completed' || data.remixed_from_video_id) {
        stopVideoPolling()
        videoCurrentUrl.value = data.remixed_from_video_id || data.video_url || ''
        videoProgress.value = 100
        videoStatus.value = '已完成！'

        if (!videoCurrentUrl.value) {
          videoError.value = '视频生成完成但未找到视频链接'
          ElMessage.error(videoError.value)
          return
        }

        // Add to history
        const durationLabels = { '3': '~3秒', '5': '~5秒', '10': '~10秒', '18': '~18秒' }
        store.addToVideoHistory({
          prompt: data.prompt || '',
          videoUrl: videoCurrentUrl.value,
          durationLabel: durationLabels[store.videoDuration] || '~5秒',
          timestamp: Date.now()
        })

        ElMessage.success('视频生成成功！')
      }

      // Check failure
      if (data.status === 'failed' || data.error) {
        stopVideoPolling()
        videoError.value = data.error || data.status || '视频生成失败'
        ElMessage.error(videoError.value)
      }
    } catch (err) {
      stopVideoPolling()
      videoError.value = err.message || '轮询出错'
      videoStatus.value = '轮询失败'
      ElMessage.error(videoError.value)
    }
  }, 5000)
}

function stopVideoPolling() {
  if (videoPollingTimer) {
    clearInterval(videoPollingTimer)
    videoPollingTimer = null
  }
  videoPolling.value = false
}

// Cleanup on page unload
window.addEventListener('beforeunload', stopVideoPolling)

// ===================== Shared Helpers =====================
async function handleHttpError(response) {
  if (response.status === 401) {
    throw new Error('API Key 无效或已过期，请在配置中心更新')
  }
  if (response.status === 429) {
    throw new Error('请求过于频繁，请稍后再试')
  }
  const errText = await response.text().catch(() => '')
  throw new Error(`请求失败 (${response.status}): ${errText || response.statusText}`)
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

/* Header / Brand */
.app-header {
  position: relative;
  z-index: 1;
  text-align: center;
  padding: 36px 20px 18px;
}

.brand {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 14px;
}

.brand-icon {
  width: 48px;
  height: 48px;
  border-radius: 14px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 16px rgba(102, 126, 234, 0.35);
  flex-shrink: 0;
}

.brand-icon-inner {
  color: #fff;
  font-size: 24px;
  font-weight: 800;
  font-family: -apple-system, BlinkMacSystemFont, 'PingFang SC', 'Noto Sans CJK SC', 'Microsoft YaHei', sans-serif;
}

.brand-name {
  font-size: 26px;
  font-weight: 800;
  letter-spacing: 2px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f472b6 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin: 0;
  line-height: 1.2;
}

.brand-tagline {
  font-size: 13px;
  color: #999;
  margin: 2px 0 0;
  letter-spacing: 1px;
}

/* Top-level Navigation */
.top-nav {
  position: relative;
  z-index: 1;
  display: flex;
  justify-content: center;
  padding: 0 16px;
  margin-bottom: 8px;
}

.top-nav-tabs {
  display: flex;
  gap: 8px;
  background: rgba(255, 255, 255, 0.6);
  backdrop-filter: blur(12px);
  border-radius: 14px;
  padding: 4px;
  border: 1px solid rgba(255, 255, 255, 0.4);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.nav-tab {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 10px 24px;
  border-radius: 11px;
  cursor: pointer;
  font-size: 15px;
  font-weight: 500;
  color: #666;
  transition: all 0.25s ease;
  user-select: none;
}

.nav-tab:hover {
  color: #333;
}

.nav-tab.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #fff;
  box-shadow: 0 2px 8px rgba(102, 126, 234, 0.35);
}

.nav-tab .el-icon {
  font-size: 18px;
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
    padding: 28px 16px 14px;
  }

  .brand-name {
    font-size: 22px;
  }

  .brand-icon {
    width: 40px;
    height: 40px;
    border-radius: 12px;
  }

  .brand-icon-inner {
    font-size: 20px;
  }

  .nav-tab {
    padding: 8px 16px;
    font-size: 13px;
  }

  .nav-tab .el-icon {
    font-size: 16px;
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
