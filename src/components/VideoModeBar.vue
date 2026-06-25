<template>
  <div class="video-mode-bar">
    <div class="mode-tabs">
      <div
        v-for="tab in tabs"
        :key="tab.value"
        class="tab-item"
        :class="{ active: currentMode === tab.value }"
        @click="currentMode = tab.value"
      >
        <el-icon><component :is="tab.icon" /></el-icon>
        <span>{{ tab.label }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useAppStore } from '../store'

const store = useAppStore()

const currentMode = computed({
  get: () => store.videoMode,
  set: (val) => { store.videoMode = val }
})

const tabs = [
  { label: '文生视频', value: 'txt2video', icon: 'EditPen' },
  { label: '图生视频', value: 'img2video', icon: 'Picture' },
  { label: '多图视频', value: 'multi-img', icon: 'PictureFilled' },
  { label: '关键帧', value: 'keyframes', icon: 'VideoCamera' },
]
</script>

<style scoped>
.video-mode-bar {
  display: flex;
  justify-content: center;
  padding: 0 16px;
  margin-bottom: 4px;
}

.mode-tabs {
  display: flex;
  gap: 6px;
  background: rgba(255, 255, 255, 0.6);
  backdrop-filter: blur(12px);
  border-radius: 14px;
  padding: 4px;
  border: 1px solid rgba(255, 255, 255, 0.4);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.tab-item {
  display: flex;
  align-items: center;
  gap: 5px;
  padding: 9px 16px;
  border-radius: 11px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 500;
  color: #666;
  transition: all 0.25s ease;
  user-select: none;
  white-space: nowrap;
}

.tab-item:hover {
  color: #333;
}

.tab-item.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #fff;
  box-shadow: 0 2px 8px rgba(102, 126, 234, 0.35);
}

.tab-item .el-icon {
  font-size: 15px;
}

@media (max-width: 640px) {
  .tab-item {
    padding: 8px 12px;
    font-size: 12px;
  }
}
</style>
