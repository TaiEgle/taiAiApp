<template>
  <div class="config-panel" :class="{ 'config-open': store.configVisible }">
    <!-- Toggle Button -->
    <el-button
      class="config-toggle"
      circle
      size="large"
      @click="store.configVisible = !store.configVisible"
    >
      <el-icon><Setting /></el-icon>
    </el-button>

    <!-- Panel Content -->
    <Transition name="slide">
      <div v-if="store.configVisible" class="config-overlay" @click.self="store.configVisible = false">
        <div class="config-card">
          <div class="config-header">
            <span class="config-title">⚙️ 配置中心</span>
            <el-button text size="small" @click="store.configVisible = false">
              <el-icon><Close /></el-icon>
            </el-button>
          </div>

          <el-form label-position="top" size="default">
            <!-- API URL -->
            <el-form-item label="API 地址">
              <el-input
                v-model="store.apiUrl"
                placeholder="https://api.example.com/v1/images/generations"
                clearable
              />
            </el-form-item>

            <!-- API Key -->
            <el-form-item label="API Key">
              <el-input
                v-model="store.apiKey"
                type="password"
                show-password
                placeholder="请输入你的 API Key"
                clearable
              />
            </el-form-item>

            <!-- Response Format -->
            <el-form-item label="输出格式">
              <el-switch
                v-model="responseFormatBool"
                active-text="Base64"
                inactive-text="URL"
              />
            </el-form-item>

            <!-- Image Size -->
            <el-form-item label="图片尺寸">
              <el-select v-model="store.selectedSize" style="width: 100%">
                <el-option
                  v-for="s in store.sizes"
                  :key="s.value"
                  :label="s.label"
                  :value="s.value"
                />
              </el-select>
            </el-form-item>

            <!-- Clear History -->
            <el-form-item label="历史记录">
              <el-button
                type="danger"
                plain
                size="small"
                @click="store.clearHistory()"
              >
                <el-icon><Delete /></el-icon> 清空历史
              </el-button>
            </el-form-item>
          </el-form>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useAppStore } from '../store'

const store = useAppStore()

const responseFormatBool = computed({
  get: () => store.responseFormat === 'b64_json',
  set: (val) => { store.responseFormat = val ? 'b64_json' : 'url' }
})
</script>

<style scoped>
.config-panel {
  position: fixed;
  top: 12px;
  right: 12px;
  z-index: 1000;
}

.config-toggle {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  backdrop-filter: blur(12px);
  background: rgba(255, 255, 255, 0.7) !important;
  border: 1px solid rgba(255, 255, 255, 0.3);
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
  transition: all 0.3s ease;
}

.config-toggle:hover {
  transform: rotate(90deg);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.12);
}

.config-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.3);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 80px;
}

.config-card {
  width: 90%;
  max-width: 420px;
  background: rgba(255, 255, 255, 0.92);
  backdrop-filter: blur(20px);
  border-radius: 16px;
  padding: 24px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.5);
}

.config-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.config-title {
  font-size: 18px;
  font-weight: 600;
  color: #1d1d1f;
}

/* Transition */
.slide-enter-active,
.slide-leave-active {
  transition: opacity 0.3s ease, transform 0.3s ease;
}

.slide-enter-from,
.slide-leave-to {
  opacity: 0;
  transform: translateY(-20px);
}

@media (max-width: 640px) {
  .config-overlay {
    align-items: stretch;
    padding-top: 0;
  }
  .config-card {
    border-radius: 16px 16px 0 0;
    margin-top: auto;
  }
}
</style>
