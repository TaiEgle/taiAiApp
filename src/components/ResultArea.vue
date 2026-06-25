<template>
  <div class="result-area">
    <!-- Error Message -->
    <Transition name="fade">
      <div v-if="error" class="error-banner">
        <el-alert
          :title="error"
          type="error"
          closable
          :closable="true"
          show-icon
          @close="error = ''"
        />
      </div>
    </Transition>

    <!-- Loading State -->
    <Transition name="fade">
      <div v-if="loading" class="loading-state">
        <div class="spinner"></div>
        <p>正在为你创作图片…</p>
      </div>
    </Transition>

    <!-- Current Result -->
    <Transition name="zoom">
      <div v-if="currentResult && !loading" class="result-display">
        <div class="result-image-wrapper" @click="openFullscreen(currentResult)">
          <img :src="currentResult" alt="generated image" class="result-image" />
          <div class="fullscreen-hint">
            <el-icon><FullScreen /></el-icon>
            <span>点击全屏预览</span>
          </div>
        </div>
        <div class="result-actions">
          <el-button
            type="primary"
            size="default"
            round
            @click.stop="downloadImage(currentResult)"
          >
            <el-icon><Download /></el-icon>
            下载图片
          </el-button>
        </div>
      </div>
    </Transition>

    <!-- Empty State -->
    <div v-if="!currentResult && !loading && !error" class="empty-state">
      <el-icon class="empty-icon"><Picture /></el-icon>
      <p class="empty-text">你的作品将在这里展示</p>
      <p class="empty-sub">输入描述，点击生成开始创作</p>
    </div>

    <!-- Fullscreen Preview Overlay -->
    <Transition name="overlay">
      <div v-if="fullscreenSrc" class="overlay" @click="closeFullscreen">
        <div class="overlay-close">
          <el-icon :size="28"><Close /></el-icon>
        </div>
        <img :src="fullscreenSrc" alt="fullscreen preview" class="overlay-image" />
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useAppStore } from '../store'

const store = useAppStore()

const props = defineProps({
  loading: Boolean,
  error: String,
  currentResult: String
})

const fullscreenSrc = ref('')

function openFullscreen(src) {
  fullscreenSrc.value = src
}

function closeFullscreen() {
  fullscreenSrc.value = ''
}

function downloadImage(src) {
  const a = document.createElement('a')
  a.href = src
  a.download = `ai-image-${Date.now()}.png`
  a.click()
}

// Close on Escape key
watch(fullscreenSrc, (val) => {
  if (val) {
    const handler = (e) => {
      if (e.key === 'Escape') closeFullscreen()
    }
    document.addEventListener('keydown', handler)
    // Prevent body scroll
    document.body.style.overflow = 'hidden'
    setTimeout(() => document.removeEventListener('keydown', handler), 100)
  } else {
    document.body.style.overflow = ''
  }
})
</script>

<style scoped>
.result-area {
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

.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  padding: 40px 0;
}

.spinner {
  width: 48px;
  height: 48px;
  border: 3px solid rgba(102, 126, 234, 0.15);
  border-top-color: #667eea;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.loading-state p {
  color: #888;
  font-size: 15px;
}

.result-display {
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
}

.result-image-wrapper {
  position: relative;
  width: 100%;
  border-radius: 16px;
  overflow: hidden;
  background: rgba(255, 255, 255, 0.6);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.5);
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06);
  cursor: zoom-in;
  transition: box-shadow 0.25s;
}

.result-image-wrapper:hover {
  box-shadow: 0 6px 32px rgba(0, 0, 0, 0.1);
}

.result-image {
  width: 100%;
  display: block;
  border-radius: 16px;
  transition: transform 0.3s;
}

.result-image-wrapper:hover .result-image {
  transform: scale(1.01);
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

.result-image-wrapper:hover .fullscreen-hint {
  opacity: 1;
}

.result-actions {
  display: flex;
  justify-content: center;
  padding: 12px 0 16px;
}

/* ===== Fullscreen Overlay ===== */
.overlay {
  position: fixed;
  inset: 0;
  z-index: 9999;
  background: rgba(0, 0, 0, 0.85);
  backdrop-filter: blur(16px);
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

.overlay-image {
  max-width: 95vw;
  max-height: 90vh;
  object-fit: contain;
  border-radius: 8px;
  box-shadow: 0 8px 48px rgba(0, 0, 0, 0.5);
  cursor: default;
  animation: overlayZoomIn 0.35s cubic-bezier(0.34, 1.56, 0.64, 1);
}

@keyframes overlayZoomIn {
  from {
    opacity: 0;
    transform: scale(0.88);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.overlay-enter-active,
.overlay-leave-active {
  transition: opacity 0.25s ease;
}

.overlay-enter-from,
.overlay-leave-to {
  opacity: 0;
}

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

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.zoom-enter-active,
.zoom-leave-active {
  transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.zoom-enter-from,
.zoom-leave-to {
  opacity: 0;
  transform: scale(0.92);
}
</style>
