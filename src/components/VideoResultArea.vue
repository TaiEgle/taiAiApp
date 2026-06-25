<template>
  <div class="video-result-area">
    <!-- Error Message -->
    <Transition name="fade">
      <div v-if="error" class="error-banner">
        <el-alert :title="error" type="error" closable show-icon @close="error = ''" />
      </div>
    </Transition>

    <!-- Polling / Progress State -->
    <Transition name="fade">
      <div v-if="polling && !currentVideoUrl && !error" class="polling-state">
        <div class="progress-ring">
          <svg viewBox="0 0 120 120">
            <circle cx="60" cy="60" r="52" fill="none" stroke="rgba(102,126,234,0.12)" stroke-width="8" />
            <circle
              cx="60" cy="60" r="52" fill="none"
              stroke="url(#progressGradient)" stroke-width="8"
              stroke-linecap="round"
              :stroke-dasharray="326.73"
              :stroke-dashoffset="326.73 * (1 - progress / 100)"
              transform="rotate(-90 60 60)"
              style="transition: stroke-dashoffset 0.5s ease"
            />
            <defs>
              <linearGradient id="progressGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stop-color="#667eea" />
                <stop offset="100%" stop-color="#764ba2" />
              </linearGradient>
            </defs>
          </svg>
          <span class="progress-text">{{ progress }}%</span>
        </div>
        <p class="status-text">{{ statusText }}</p>
      </div>
    </Transition>

    <!-- Result Video -->
    <Transition name="zoom">
      <div v-if="currentVideoUrl && !polling" class="result-display">
        <div class="result-video-wrapper" @click="openFullscreen">
          <video :src="currentVideoUrl" controls class="result-video" preload="metadata" />
          <div class="fullscreen-hint">
            <el-icon><FullScreen /></el-icon>
            <span>点击全屏预览</span>
          </div>
        </div>
        <div class="result-actions">
          <el-button type="primary" size="default" round @click.stop="downloadVideo">
            <el-icon><Download /></el-icon>
            下载视频
          </el-button>
        </div>
      </div>
    </Transition>

    <!-- Empty State -->
    <div v-if="!currentVideoUrl && !polling && !error" class="empty-state">
      <el-icon class="empty-icon"><VideoCamera /></el-icon>
      <p class="empty-text">你的视频将在这里展示</p>
      <p class="empty-sub">输入描述，点击生成开始创作</p>
    </div>

    <!-- Fullscreen Preview Overlay -->
    <Transition name="overlay">
      <div v-if="fullscreenSrc" class="overlay" @click="closeFullscreen">
        <div class="overlay-close" @click.stop="closeFullscreen">
          <el-icon :size="28"><Close /></el-icon>
        </div>
        <video :src="fullscreenSrc" controls autoplay class="overlay-video" @click.stop />
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useVideoPolling } from '../composables/useVideoPolling'
import { useAppStore } from '../store'

const store = useAppStore()

const props = defineProps({
  videoId: { type: String, default: null },
  polling: Boolean,
  progress: Number,
  status: String,
  currentVideoUrl: { type: String, default: '' },
  error: { type: String, default: '' }
})

const emit = defineEmits(['stop-polling'])

const fullscreenSrc = ref('')

function openFullscreen() {
  if (props.currentVideoUrl) {
    fullscreenSrc.value = props.currentVideoUrl
  }
}

function closeFullscreen() {
  fullscreenSrc.value = ''
}

async function downloadVideo() {
  if (!props.currentVideoUrl) return
  try {
    const response = await fetch(props.currentVideoUrl)
    const blob = await response.blob()
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `ai-video-${Date.now()}.mp4`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    setTimeout(() => URL.revokeObjectURL(url), 5000)
  } catch {
    // Fallback: open in new tab
    window.open(props.currentVideoUrl, '_blank')
  }
}

// Close on Escape
watch(fullscreenSrc, (val) => {
  if (val) {
    document.body.style.overflow = 'hidden'
    const handler = (e) => { if (e.key === 'Escape') closeFullscreen() }
    document.addEventListener('keydown', handler)
    setTimeout(() => { document.removeEventListener('keydown', handler); document.body.style.overflow = '' }, 100)
  } else {
    document.body.style.overflow = ''
  }
})

// Status text mapping
const statusText = ref(props.status || '排队中...')
watch(() => props.status, (val) => { statusText.value = val || '排队中...' })
watch(() => props.progress, (val) => {
  if (val > 0 && val < 100) {
    statusText.value = `生成中 ${val}%`
  }
})
</script>

<style scoped>
.video-result-area {
  width: 100%;
  max-width: 680px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  min-height: 200px;
}

.error-banner {
  width: 100%;
}

/* Polling State */
.polling-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  padding: 40px 0;
}

.progress-ring {
  position: relative;
  width: 120px;
  height: 120px;
}

.progress-ring svg {
  width: 120px;
  height: 120px;
}

.progress-text {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 22px;
  font-weight: 700;
  background: linear-gradient(135deg, #667eea, #764ba2);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.status-text {
  color: #888;
  font-size: 15px;
  margin: 0;
}

/* Result Display */
.result-display {
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
}

.result-video-wrapper {
  position: relative;
  width: 100%;
  border-radius: 16px;
  overflow: hidden;
  background: rgba(255, 255, 255, 0.6);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.5);
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06);
  cursor: zoom-in;
}

.result-video {
  width: 100%;
  display: block;
  border-radius: 16px;
}

.fullscreen-hint {
  position: absolute;
  top: 12px;
  right: 12px;
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 6px 12px;
  background: rgba(0, 0, 0, 0.45);
  backdrop-filter: blur(8px);
  border-radius: 20px;
  color: #fff;
  font-size: 12px;
  opacity: 0;
  transition: opacity 0.25s;
  pointer-events: none;
}

.result-video-wrapper:hover .fullscreen-hint {
  opacity: 1;
}

.result-actions {
  display: flex;
  justify-content: center;
  padding: 12px 0 16px;
}

/* Empty State */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 60px 0;
}

.empty-icon {
  font-size: 64px;
  color: #d0d0d0;
}

.empty-text {
  font-size: 18px;
  font-weight: 500;
  color: #999;
}

.empty-sub {
  font-size: 14px;
  color: #bbb;
}

/* Fullscreen Overlay */
.overlay {
  position: fixed;
  inset: 0;
  z-index: 9999;
  background: rgba(0, 0, 0, 0.9);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  cursor: zoom-out;
}

.overlay-close {
  position: absolute;
  top: 16px;
  right: 16px;
  width: 44px;
  height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.15);
  color: #fff;
  cursor: pointer;
  transition: background 0.2s;
  z-index: 1;
}

.overlay-close:hover {
  background: rgba(255, 255, 255, 0.3);
}

.overlay-video {
  max-width: 95vw;
  max-height: 90vh;
  border-radius: 8px;
  box-shadow: 0 8px 48px rgba(0, 0, 0, 0.5);
  animation: overlayZoomIn 0.35s cubic-bezier(0.34, 1.56, 0.64, 1);
}

@keyframes overlayZoomIn {
  from { opacity: 0; transform: scale(0.88); }
  to { opacity: 1; transform: scale(1); }
}

/* Transitions */
.fade-enter-active, .fade-leave-active { transition: opacity 0.3s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

.zoom-enter-active, .zoom-leave-active { transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1); }
.zoom-enter-from, .zoom-leave-to { opacity: 0; transform: scale(0.92); }

.overlay-enter-active, .overlay-leave-active { transition: opacity 0.25s ease; }
.overlay-enter-from, .overlay-leave-to { opacity: 0; }
</style>
