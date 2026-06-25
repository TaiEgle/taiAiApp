<template>
  <div class="input-area">
    <!-- Prompt Input -->
    <div class="prompt-wrapper">
      <el-input
        v-model="prompt"
        type="textarea"
        :rows="3"
        placeholder="描述你想要的图片… 例如：一只坐在月球上的猫咪，赛博朋克风格"
        resize="none"
        class="prompt-input"
      />
    </div>

    <!-- Image Upload (img2img mode) -->
    <Transition name="fade">
      <div v-if="mode === 'img2img'" class="image-upload-section">
        <!-- URL Input -->
        <div class="url-input-row">
          <el-input
            v-model="imageUrl"
            placeholder="或输入图片公网 URL"
            size="default"
            clearable
          >
            <template #prefix>
              <el-icon><Link /></el-icon>
            </template>
          </el-input>
        </div>

        <!-- Local File Upload -->
        <div class="upload-area" @click="triggerFileUpload">
          <input
            ref="fileInput"
            type="file"
            accept="image/*"
            style="display: none"
            @change="handleFileChange"
          />
          <el-icon class="upload-icon"><UploadFilled /></el-icon>
          <span class="upload-text">点击上传图片</span>
          <span v-if="localImage" class="upload-text success">✓ {{ localImageName }}</span>
        </div>

        <!-- Preview uploaded image -->
        <Transition name="zoom">
          <div v-if="localImage" class="preview-container">
            <img :src="localImage" alt="preview" />
            <el-icon class="close-preview" @click="clearLocalImage"><CircleCloseFilled /></el-icon>
          </div>
        </Transition>
      </div>
    </Transition>

    <!-- Generate Button -->
    <button class="generate-btn" :disabled="loading || !canGenerate" @click="handleGenerate">
      <el-icon v-if="loading" class="is-loading"><Loading /></el-icon>
      <el-icon v-else><Promotion /></el-icon>
      <span>{{ loading ? '生成中…' : '生成图片' }}</span>
    </button>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useAppStore } from '../store'

const store = useAppStore()
const emit = defineEmits(['generate'])

const prompt = ref('')
const imageUrl = ref('')
const localImage = ref('')
const localImageName = ref('')
const fileInput = ref(null)
const loading = ref(false)

const mode = computed(() => store.mode)

const canGenerate = computed(() => {
  if (!prompt.value.trim()) return false
  if (store.mode === 'img2img' && !localImage.value && !imageUrl.value.trim()) return false
  return true
})

function triggerFileUpload() {
  fileInput.value?.click()
}

function handleFileChange(e) {
  const file = e.target.files[0]
  if (!file) return
  localImageName.value = file.name
  const reader = new FileReader()
  reader.onload = (ev) => {
    localImage.value = ev.target.result
  }
  reader.readAsDataURL(file)
}

function clearLocalImage() {
  localImage.value = ''
  localImageName.value = ''
  if (fileInput.value) fileInput.value.value = ''
}

async function handleGenerate() {
  if (loading.value || !canGenerate.value) return
  loading.value = true
  try {
    await emit('generate', {
      prompt: prompt.value.trim(),
      imageUrl: imageUrl.value.trim(),
      localImage: localImage.value
    })
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.input-area {
  width: 100%;
  max-width: 680px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.prompt-wrapper {
  width: 100%;
}

.prompt-input :deep(.el-textarea__inner) {
  background: rgba(255, 255, 255, 0.7);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.5);
  border-radius: 14px;
  font-size: 15px;
  line-height: 1.6;
  color: #1d1d1f;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.04);
  transition: border-color 0.2s;
}

.prompt-input :deep(.el-textarea__inner):focus {
  border-color: rgba(102, 126, 234, 0.5);
  box-shadow: 0 2px 16px rgba(102, 126, 234, 0.1);
}

.image-upload-section {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.url-input-row {
  width: 100%;
}

.url-input-row :deep(.el-input__wrapper) {
  background: rgba(255, 255, 255, 0.7);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.5);
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.03);
}

.upload-area {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 16px;
  border: 2px dashed rgba(102, 126, 234, 0.3);
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.25s;
  background: rgba(255, 255, 255, 0.4);
}

.upload-area:hover {
  border-color: rgba(102, 126, 234, 0.6);
  background: rgba(255, 255, 255, 0.7);
}

.upload-icon {
  font-size: 24px;
  color: #667eea;
}

.upload-text {
  font-size: 14px;
  color: #888;
}

.upload-text.success {
  color: #67c23a;
  font-weight: 500;
}

.preview-container {
  position: relative;
  width: 100%;
  max-height: 200px;
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.4);
}

.preview-container img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  max-height: 200px;
  display: block;
}

.close-preview {
  position: absolute;
  top: 8px;
  right: 8px;
  font-size: 20px;
  color: #fff;
  background: rgba(0, 0, 0, 0.5);
  border-radius: 50%;
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background 0.2s;
}

.close-preview:hover {
  background: rgba(220, 53, 69, 0.8);
}

.generate-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  width: 100%;
  padding: 14px 24px;
  border: none;
  border-radius: 14px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #fff;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 16px rgba(102, 126, 234, 0.3);
}

.generate-btn:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 6px 24px rgba(102, 126, 234, 0.45);
}

.generate-btn:active:not(:disabled) {
  transform: translateY(0);
}

.generate-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Transitions */
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
  transition: all 0.3s ease;
}

.zoom-enter-from,
.zoom-leave-to {
  opacity: 0;
  transform: scale(0.9);
}
</style>
