<template>
  <div class="video-result-area">
    <!-- Error Message -->
    <Transition name="fade">
      <div v-if="error" class="error-banner">
        <el-alert :title="error" type="error" closable show-icon @close="error = ''" />
      </div>
    </Transition>

    <!-- Stage 1: Submitting / Queued (no real progress yet) -->
    <Transition name="fade">
      <div v-if="showSubmittingState" class="submitting-state">
        <div class="submitting-animation">
          <!-- Sparkle particles -->
          <span class="particle p1"></span>
          <span class="particle p2"></span>
          <span class="particle p3"></span>
          <span class="particle p4"></span>
          <span class="particle p5"></span>

          <!-- Central icon -->
          <div class="center-icon">
            <el-icon :size="48" class="spin-slow"><VideoCamera /></el-icon>
          </div>

          <!-- Orbiting dots -->
          <div class="orbit">
            <span class="orbit-dot d1"></span>
            <span class="orbit-dot d2"></span>
            <span class="orbit-dot d3"></span>
          </div>
        </div>

        <p class="submitting-main">{{ submittingText }}</p>
        <p class="submitting-sub">视频生成通常需要 3-5 分钟，请耐心等待</p>

        <!-- Elapsed timer -->
        <div class="elapsed">
          <el-icon><Timer /></el-icon>
          <span>已等待 {{ elapsedSeconds }} 秒</span>
        </div>

        <!-- Cancel button -->
        <el-button
          text
          size="small"
          type="danger"
          class="cancel-btn"
          @click="$emit('stop-polling')"
        >
          <el-icon><CircleClose /></el-icon> 取消生成
        </el-button>
      </div>
    </Transition>

    <!-- Stage 2: Real progress from API -->
    <Transition name="fade">
      <div v-if="polling && hasRealProgress && !currentVideoUrl && !error" class="polling-state">
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
import { ref, computed, watch, onUnmounted } from 'vue'
import { useAppStore } from '../store'

const store = useAppStore()

const props = defineProps({
  polling: Boolean,
  progress: Number,
  status: String,
  currentVideoUrl: { type: String, default: '' },
  error: { type: String, default: '' }
})

const emit = defineEmits(['stop-polling'])

const fullscreenSrc = ref('')

// --- Submitting state ---
const elapsedSeconds = ref(0)
let elapsedTimer = null
const hasRealProgress = ref(false)

const submittingText = computed(() => {
  if (props.status === '排队中...') return '正在排队，即将开始生成'
  if (props.status === '提交中...') return '正在提交任务，请稍候'
  return '正在生成视频...'
})

function startElapsedTimer() {
  elapsedSeconds.value = 0
  if (elapsedTimer) clearInterval(elapsedTimer)
  elapsedTimer = setInterval(() => {
    elapsedSeconds.value++
  }, 1000)
}

function stopElapsedTimer() {
  if (elapsedTimer) {
    clearInterval(elapsedTimer)
    elapsedTimer = null
  }
}

// Detect when real progress data arrives (> 0 and not just "queued")
watch(() => props.progress, (val) => {
  if (val > 0 && val <= 100) {
    hasRealProgress.value = true
  }
})

watch(() => props.status, (val) => {
  if (val && !val.includes('排队') && !val.includes('提交')) {
    hasRealProgress.value = true
  }
})

// Show submitting state: polling is on AND (no real progress yet OR progress is 0)
const showSubmittingState = computed(() => {
  if (!props.polling) return false
  if (props.error) return false
  if (props.currentVideoUrl) return false
  // Show submitting while waiting for real progress
  return !hasRealProgress.value || props.progress <= 0
})

// Start/stop timer based on polling
watch(() => props.polling, (val) => {
  if (val) {
    startElapsedTimer()
    hasRealProgress.value = false
  } else {
    stopElapsedTimer()
    hasRealProgress.value = false
  }
})

onUnmounted(stopElapsedTimer)

// --- Status text ---
const statusText = ref(props.status || '排队中...')
watch(() => props.status, (val) => { statusText.value = val || '排队中...' })
watch(() => props.progress, (val) => {
  if (val > 0 && val < 100) {
    statusText.value = `生成中 ${val}%`
  }
})

// --- Actions ---
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

/* ===== Submitting State (Stage 1) ===== */
.submitting-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  padding: 60px 0;
}

.submitting-animation {
  position: relative;
  width: 160px;
  height: 160px;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Central spinning icon */
.center-icon {
  position: relative;
  z-index: 2;
  color: #667eea;
  filter: drop-shadow(0 0 12px rgba(102, 126, 234, 0.4));
}

.spin-slow {
  animation: spinSlow 3s linear infinite;
}

@keyframes spinSlow {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

/* Orbiting dots */
.orbit {
  position: absolute;
  inset: 0;
  animation: orbitSpin 2.5s linear infinite;
}

@keyframes orbitSpin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.orbit-dot {
  position: absolute;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea, #764ba2);
  box-shadow: 0 0 10px rgba(102, 126, 234, 0.6);
}

.orbit-dot.d1 { top: 0; left: 50%; transform: translate(-50%, -50%); }
.orbit-dot.d2 { bottom: 0; left: 50%; transform: translate(-50%, 50%); }
.orbit-dot.d3 { top: 50%; right: 0; transform: translate(50%, -50%); }

/* Sparkle particles */
.particle {
  position: absolute;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #a78bfa;
  opacity: 0;
}

.p1 { top: 10%; left: 10%; animation: sparkle 1.8s ease-in-out 0s infinite; }
.p2 { top: 5%; right: 15%; animation: sparkle 1.8s ease-in-out 0.4s infinite; }
.p3 { bottom: 15%; left: 5%; animation: sparkle 1.8s ease-in-out 0.8s infinite; }
.p4 { bottom: 10%; right: 10%; animation: sparkle 1.8s ease-in-out 1.2s infinite; }
.p5 { top: 40%; left: 0%; animation: sparkle 1.8s ease-in-out 1.6s infinite; }

@keyframes sparkle {
  0%, 100% { opacity: 0; transform: scale(0.5); }
  50% { opacity: 0.8; transform: scale(1.2); }
}

.submitting-main {
  font-size: 17px;
  font-weight: 600;
  color: #444;
  margin: 0;
  animation: pulseText 2s ease-in-out infinite;
}

@keyframes pulseText {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}

.submitting-sub {
  font-size: 13px;
  color: #aaa;
  margin: 0;
}

.elapsed {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #999;
  padding: 6px 16px;
  background: rgba(102, 126, 234, 0.06);
  border-radius: 20px;
}

.elapsed .el-icon {
  color: #667eea;
}

.cancel-btn {
  font-size: 13px;
  color: #ccc;
  transition: color 0.2s;
}

.cancel-btn:hover {
  color: #f56c6c;
}

/* ===== Polling State (Stage 2: real progress) ===== */
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

/* ===== Result Display ===== */
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

/* ===== Empty State ===== */
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

/* ===== Fullscreen Overlay ===== */
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

/* ===== Transitions ===== */
.fade-enter-active, .fade-leave-active { transition: opacity 0.3s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

.zoom-enter-active, .zoom-leave-active { transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1); }
.zoom-enter-from, .zoom-leave-to { opacity: 0; transform: scale(0.92); }

.overlay-enter-active, .overlay-leave-active { transition: opacity 0.25s ease; }
.overlay-enter-from, .overlay-leave-to { opacity: 0; }
</style>
