<template>
  <div class="history-section">
    <div class="history-header" @click="collapsed = !collapsed">
      <span>🕐 生成历史</span>
      <el-icon :class="{ rotated: collapsed }"><ArrowDown /></el-icon>
    </div>
    <Transition name="slideDown">
      <div v-if="!collapsed && store.history.length" class="history-grid">
        <div
          v-for="(item, idx) in store.history"
          :key="idx"
          class="history-item"
          @click="showHistoryImage(item)"
        >
          <img :src="item.displaySrc" :alt="item.prompt" />
          <div class="history-tooltip">{{ item.prompt }}</div>
        </div>
      </div>
    </Transition>
    <div v-if="!collapsed && !store.history.length" class="history-empty">
      还没有生成记录
    </div>

    <!-- Fullscreen Preview Overlay -->
    <Transition name="overlay">
      <div v-if="fullscreenSrc" class="overlay" @click="closeFullscreen">
        <div class="overlay-close" @click.stop="closeFullscreen">
          <el-icon :size="28"><Close /></el-icon>
        </div>
        <img :src="fullscreenSrc" alt="preview" class="overlay-image" @click.stop />
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

function showHistoryImage(item) {
  fullscreenSrc.value = item.displaySrc
}

function closeFullscreen() {
  fullscreenSrc.value = ''
}

onMounted(() => {
  // Load persisted history from localStorage
  const saved = localStorage.getItem('ai-image-history')
  if (saved) {
    try {
      store.history = JSON.parse(saved)
    } catch {}
  }
})

// Close on Escape key
watch(fullscreenSrc, (val) => {
  if (val) {
    const handler = (e) => {
      if (e.key === 'Escape') closeFullscreen()
    }
    document.addEventListener('keydown', handler)
    document.body.style.overflow = 'hidden'
    setTimeout(() => document.removeEventListener('keydown', handler), 100)
  } else {
    document.body.style.overflow = ''
  }
})
</script>

<style scoped>
.history-section {
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
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 10px;
  padding: 12px 0;
}

.history-item {
  position: relative;
  aspect-ratio: 1;
  border-radius: 10px;
  overflow: hidden;
  cursor: pointer;
  border: 2px solid transparent;
  transition: all 0.25s;
}

.history-item:hover {
  border-color: rgba(102, 126, 234, 0.5);
  transform: scale(1.03);
}

.history-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.history-tooltip {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 4px 8px;
  background: rgba(0, 0, 0, 0.6);
  color: #fff;
  font-size: 11px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  opacity: 0;
  transition: opacity 0.2s;
}

.history-item:hover .history-tooltip {
  opacity: 1;
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

@media (max-width: 640px) {
  .history-grid {
    grid-template-columns: repeat(3, 1fr);
    gap: 8px;
  }
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
</style>
