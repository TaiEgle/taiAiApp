<template>
  <div class="video-history-section">
    <div class="history-header" @click="collapsed = !collapsed">
      <span>🎬 视频历史</span>
      <el-icon :class="{ rotated: collapsed }"><ArrowDown /></el-icon>
    </div>

    <Transition name="slideDown">
      <div v-if="!collapsed && store.videoHistory.length" class="history-grid">
        <div
          v-for="(item, idx) in store.videoHistory"
          :key="idx"
          class="history-item"
          @click="openFullscreen(item.videoUrl)"
        >
          <video :src="item.videoUrl" class="history-video" muted preload="metadata" />
          <div class="play-overlay">
            <el-icon :size="24"><VideoPlay /></el-icon>
          </div>
          <div class="history-info">
            <span class="history-prompt">{{ item.prompt }}</span>
            <span class="history-meta">{{ item.durationLabel }}</span>
          </div>
        </div>
      </div>
    </Transition>

    <div v-if="!collapsed && !store.videoHistory.length" class="history-empty">
      还没有视频生成记录
    </div>

    <!-- Fullscreen Video Overlay -->
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
import { ref, onMounted, watch } from 'vue'
import { useAppStore } from '../store'

const store = useAppStore()
const collapsed = ref(true)
const fullscreenSrc = ref('')

function openFullscreen(src) {
  fullscreenSrc.value = src
}

function closeFullscreen() {
  fullscreenSrc.value = ''
}

onMounted(() => {
  const saved = localStorage.getItem('ai-video-history')
  if (saved) {
    try { store.videoHistory = JSON.parse(saved) } catch {}
  }
})

watch(
  () => store.videoHistory,
  (val) => {
    try { localStorage.setItem('ai-video-history', JSON.stringify(val.slice(0, 3))) } catch {}
  },
  { deep: true }
)

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
.video-history-section {
  width: 100%;
  max-width: 680px;
  margin-top: 24px;
}

.history-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 0;
  cursor: pointer;
  font-size: 14px;
  font-weight: 600;
  color: #888;
  user-select: none;
}

.history-header .el-icon {
  transition: transform 0.3s ease;
  font-size: 16px;
}

.history-header .el-icon.rotated {
  transform: rotate(-90deg);
}

.history-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 12px;
  padding: 12px 0;
}

.history-item {
  position: relative;
  border-radius: 12px;
  overflow: hidden;
  cursor: pointer;
  border: 2px solid transparent;
  transition: all 0.25s;
  background: rgba(0, 0, 0, 0.05);
  aspect-ratio: 16 / 9;
}

.history-item:hover {
  border-color: rgba(102, 126, 234, 0.5);
  transform: scale(1.02);
}

.history-video {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.play-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.2);
  color: #fff;
  opacity: 0;
  transition: opacity 0.25s;
}

.history-item:hover .play-overlay {
  opacity: 1;
}

.history-info {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 24px 8px 8px;
  background: linear-gradient(transparent, rgba(0, 0, 0, 0.7));
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.history-prompt {
  font-size: 11px;
  color: #fff;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.history-meta {
  font-size: 10px;
  color: rgba(255, 255, 255, 0.7);
}

.history-empty {
  padding: 16px 0;
  text-align: center;
  color: #ccc;
  font-size: 14px;
}

.slideDown-enter-active,
.slideDown-leave-active {
  transition: all 0.3s ease;
  overflow: hidden;
}

.slideDown-enter-from,
.slideDown-leave-to {
  opacity: 0;
  max-height: 0;
}

.slideDown-enter-to,
.slideDown-leave-from {
  opacity: 1;
  max-height: 500px;
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

.overlay-enter-active,
.overlay-leave-active {
  transition: opacity 0.25s ease;
}

.overlay-enter-from,
.overlay-leave-to {
  opacity: 0;
}

@media (max-width: 640px) {
  .history-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 8px;
  }
}
</style>
