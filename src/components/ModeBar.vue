<template>
  <div class="mode-bar">
    <div class="mode-tabs">
      <div
        class="tab-item"
        :class="{ active: mode === 'txt2img' }"
        @click="mode = 'txt2img'"
      >
        <el-icon><EditPen /></el-icon>
        <span>文生图</span>
      </div>
      <div
        class="tab-item"
        :class="{ active: mode === 'img2img' }"
        @click="mode = 'img2img'"
      >
        <el-icon><Picture /></el-icon>
        <span>图生图</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useAppStore } from '../store'

const store = useAppStore()
const mode = computed({
  get: () => store.mode,
  set: (val) => { store.mode = val }
})
</script>

<style scoped>
.mode-bar {
  display: flex;
  justify-content: center;
  padding: 0 16px;
}

.mode-tabs {
  display: flex;
  gap: 8px;
  background: rgba(255, 255, 255, 0.6);
  backdrop-filter: blur(12px);
  border-radius: 12px;
  padding: 4px;
  border: 1px solid rgba(255, 255, 255, 0.4);
}

.tab-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 10px 20px;
  border-radius: 10px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  color: #666;
  transition: all 0.25s ease;
  user-select: none;
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
  font-size: 16px;
}
</style>
