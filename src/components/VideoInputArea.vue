<template>
  <div class="video-input-area">
    <!-- Prompt Input -->
    <div class="prompt-wrapper">
      <el-input
        v-model="prompt"
        type="textarea"
        :rows="3"
        placeholder="描述你想要的视频… 例如：一只猫在夕阳下的沙滩上奔跑"
        resize="none"
        class="prompt-input"
      />
    </div>

    <!-- Advanced Options Collapse -->
    <div class="advanced-toggle" @click="advancedOpen = !advancedOpen">
      <span>高级选项</span>
      <el-icon :class="{ rotated: advancedOpen }"><ArrowDown /></el-icon>
    </div>

    <Transition name="slideDown">
      <div v-if="advancedOpen" class="advanced-panel">
        <el-form label-position="top" size="default">
          <!-- Aspect Ratio -->
          <el-form-item label="宽高比">
            <el-select v-model="aspectRatio" style="width: 100%">
              <el-option
                v-for="a in aspectRatios"
                :key="a.value"
                :label="a.label"
                :value="a.value"
              />
            </el-select>
          </el-form-item>

          <!-- Duration Buttons -->
          <el-form-item label="视频时长">
            <div class="duration-buttons">
              <button
                type="button"
                v-for="d in durations"
                :key="d.value"
                class="dur-btn"
                :class="{ active: duration === d.value }"
                @click="duration = d.value"
              >
                {{ d.label }}
              </button>
            </div>
          </el-form-item>

          <!-- Frame Rate -->
          <el-form-item label="帧率 (fps)">
            <el-input-number
              v-model="frameRate"
              :min="1"
              :max="60"
              :step="1"
              controls-position="right"
              style="width: 100%"
            />
          </el-form-item>

          <!-- Seed -->
          <el-form-item label="随机种子 (可选)">
            <el-input-number
              v-model="seed"
              :min="-1"
              :max="999999999"
              :step="1"
              controls-position="right"
              style="width: 100%"
              placeholder="留空则随机"
            />
          </el-form-item>

          <!-- Negative Prompt -->
          <el-form-item label="负向提示词 (可选)">
            <el-input
              v-model="negativePrompt"
              type="textarea"
              :rows="2"
              placeholder="不希望在视频中出现的元素…"
              resize="none"
            />
          </el-form-item>
        </el-form>
      </div>
    </Transition>

    <!-- Image Upload Section (conditional) -->
    <Transition name="fade">
      <div v-if="needImage" class="image-upload-section">
        <!-- Single image mode (img2video) -->
        <template v-if="mode === 'img2video'">
          <div class="url-input-row">
            <el-input
              v-model="singleImageUrl"
              placeholder="输入图片公网 URL"
              size="default"
              clearable
            >
              <template #prefix>
                <el-icon><Link /></el-icon>
              </template>
            </el-input>
          </div>
          <div class="upload-area" @click="triggerSingleUpload">
            <input
              ref="singleFileInput"
              type="file"
              accept="image/*"
              style="display: none"
              @change="handleSingleFileChange"
            />
            <el-icon class="upload-icon"><UploadFilled /></el-icon>
            <span class="upload-text">点击上传本地图片</span>
            <span v-if="singleLocalImage" class="upload-text success">✓ {{ singleImageName }}</span>
          </div>
          <Transition name="zoom">
            <div v-if="singleLocalImage" class="preview-container">
              <img :src="singleLocalImage" alt="preview" />
              <el-icon class="close-preview" @click="clearSingleImage"><CircleCloseFilled /></el-icon>
            </div>
          </Transition>
        </template>

        <!-- Multi-image / keyframes mode -->
        <template v-else>
          <div class="multi-image-label">
            <span>图片序列（至少 2 张）</span>
            <el-button text size="small" type="primary" @click="addImageSlot">
              <el-icon><Plus /></el-icon> 添加图片
            </el-button>
          </div>

          <div
            v-for="(slot, idx) in imageSlots"
            :key="idx"
            class="image-slot"
          >
            <div class="slot-header">
              <span class="slot-label">关键帧 {{ idx + 1 }}</span>
              <el-button
                v-if="imageSlots.length > 2"
                text
                size="small"
                type="danger"
                @click="removeImageSlot(idx)"
              >
                <el-icon><Delete /></el-icon>
              </el-button>
            </div>

            <!-- URL input -->
            <div class="url-input-row">
              <el-input
                v-model="slot.imageUrl"
                placeholder="或输入图片 URL"
                size="small"
                clearable
              >
                <template #prefix>
                  <el-icon><Link /></el-icon>
                </template>
              </el-input>
            </div>

            <!-- Upload button -->
            <div class="upload-area small" @click="triggerSlotUpload(idx)">
              <input
                :ref="(el) => setSlotFileInput(el, idx)"
                type="file"
                accept="image/*"
                style="display: none"
                @change="(e) => handleSlotFileChange(e, idx)"
              />
              <el-icon class="upload-icon"><UploadFilled /></el-icon>
              <span class="upload-text">上传本地图片</span>
              <span v-if="slot.localImage" class="upload-text success">✓ {{ slot.imageName || '已上传' }}</span>
            </div>

            <!-- Preview -->
            <Transition name="zoom">
              <div v-if="slot.localImage" class="preview-container">
                <img :src="slot.localImage" alt="preview" />
                <el-icon class="close-preview" @click="clearSlotImage(idx)">
                  <CircleCloseFilled />
                </el-icon>
              </div>
            </Transition>
          </div>
        </template>
      </div>
    </Transition>

    <!-- Generate Button -->
    <button class="generate-btn" :disabled="loading || !canGenerate" @click="handleGenerate">
      <el-icon v-if="loading" class="is-loading"><Loading /></el-icon>
      <el-icon v-else><Promotion /></el-icon>
      <span>{{ loading ? '生成中…' : '生成视频' }}</span>
    </button>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useAppStore } from '../store'

const store = useAppStore()
const emit = defineEmits(['generate'])

// Prompt
const prompt = ref('')

// Advanced options
const advancedOpen = ref(false)
const aspectRatio = ref(store.videoAspectRatio)
const duration = ref(store.videoDuration)
const frameRate = ref(store.videoFrameRate)
const seed = ref(store.videoSeed)
const negativePrompt = ref(store.videoNegativePrompt)

// Watch store changes
import { watch } from 'vue'
watch(() => store.videoAspectRatio, (v) => { aspectRatio.value = v })
watch(() => store.videoDuration, (v) => { duration.value = v })
watch(() => store.videoFrameRate, (v) => { frameRate.value = v })
watch(() => store.videoSeed, (v) => { seed.value = v })
watch(() => store.videoNegativePrompt, (v) => { negativePrompt.value = v })

// Save to store on change
watch([aspectRatio, duration, frameRate, seed, negativePrompt], () => {
  store.videoAspectRatio = aspectRatio.value
  store.videoDuration = duration.value
  store.videoFrameRate = frameRate.value
  store.videoSeed = seed.value
  store.videoNegativePrompt = negativePrompt.value
})

const aspectRatios = [
  { label: '16:9 (1280×720)', value: '16:9' },
  { label: '9:16 (720×1280)', value: '9:16' },
  { label: '1:1 (1024×1024)', value: '1:1' },
  { label: '4:3 (1024×768)', value: '4:3' },
  { label: '3:4 (768×1024)', value: '3:4' },
]

const durations = [
  { label: '~3秒', value: '3' },
  { label: '~5秒', value: '5' },
  { label: '~10秒', value: '10' },
  { label: '~18秒', value: '18' },
]

// Single image mode (img2video)
const singleImageUrl = ref('')
const singleLocalImage = ref('')
const singleImageName = ref('')
const singleFileInput = ref(null)

// Multi-image mode
const imageSlots = ref([])
const slotFileInputs = ref({})

const mode = computed(() => store.videoMode)
const loading = ref(false)

const needImage = computed(() => {
  return mode.value === 'img2video' || mode.value === 'multi-img' || mode.value === 'keyframes'
})

const canGenerate = computed(() => {
  if (!prompt.value.trim()) return false
  if (mode.value === 'img2video') {
    return singleLocalImage.value || singleImageUrl.value.trim()
  }
  if (mode.value === 'multi-img' || mode.value === 'keyframes') {
    const validSlots = imageSlots.value.filter(s => s.localImage || s.imageUrl.trim())
    return validSlots.length >= 2
  }
  return true // txt2video only needs prompt
})

// Single image handlers
function triggerSingleUpload() {
  singleFileInput.value?.click()
}

function handleSingleFileChange(e) {
  const file = e.target.files[0]
  if (!file) return
  singleImageName.value = file.name
  const reader = new FileReader()
  reader.onload = (ev) => { singleLocalImage.value = ev.target.result }
  reader.readAsDataURL(file)
}

function clearSingleImage() {
  singleLocalImage.value = ''
  singleImageName.value = ''
  singleImageUrl.value = ''
  if (singleFileInput.value) singleFileInput.value.value = ''
}

// Multi-image handlers
function addImageSlot() {
  imageSlots.value.push({ localImage: '', imageUrl: '', imageName: '' })
}

function removeImageSlot(idx) {
  imageSlots.value.splice(idx, 1)
}

function setSlotFileInput(el, idx) {
  if (el) slotFileInputs.value[idx] = el
}

function triggerSlotUpload(idx) {
  slotFileInputs.value[idx]?.click()
}

function handleSlotFileChange(e, idx) {
  const file = e.target.files[0]
  if (!file) return
  imageSlots.value[idx].imageName = file.name
  const reader = new FileReader()
  reader.onload = (ev) => { imageSlots.value[idx].localImage = ev.target.result }
  reader.readAsDataURL(file)
}

function clearSlotImage(idx) {
  imageSlots.value[idx].localImage = ''
  imageSlots.value[idx].imageUrl = ''
  imageSlots.value[idx].imageName = ''
  if (slotFileInputs.value[idx]) slotFileInputs.value[idx].value = ''
}

// Initialize with 2 slots for multi-img / keyframes
import { watchEffect } from 'vue'
watchEffect(() => {
  if ((mode.value === 'multi-img' || mode.value === 'keyframes') && imageSlots.value.length < 2) {
    while (imageSlots.value.length < 2) {
      addImageSlot()
    }
  }
})

// Generate handler
async function handleGenerate() {
  if (loading.value || !canGenerate.value) return
  loading.value = true

  try {
    // Build image data based on mode
    let imageSlotsData = []
    let singleImageData = null

    if (mode.value === 'img2video') {
      singleImageData = {
        localImage: singleLocalImage.value,
        imageUrl: singleImageUrl.value.trim()
      }
    } else if (mode.value === 'multi-img' || mode.value === 'keyframes') {
      imageSlotsData = imageSlots.value.map(s => ({
        localImage: s.localImage,
        imageUrl: s.imageUrl.trim(),
        imageName: s.imageName
      }))
    }

    emit('generate', {
      prompt: prompt.value.trim(),
      aspectRatio: aspectRatio.value,
      duration: duration.value,
      frameRate: frameRate.value,
      seed: seed.value,
      negativePrompt: negativePrompt.value.trim(),
      singleImageData,
      imageSlots: imageSlotsData
    })
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.video-input-area {
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

/* Advanced Toggle */
.advanced-toggle {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 4px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  color: #888;
  user-select: none;
}

.advanced-toggle .el-icon {
  transition: transform 0.3s ease;
  font-size: 16px;
}

.advanced-toggle .el-icon.rotated {
  transform: rotate(-90deg);
}

/* Advanced Panel */
.advanced-panel {
  background: rgba(255, 255, 255, 0.5);
  backdrop-filter: blur(12px);
  border-radius: 14px;
  padding: 16px;
  border: 1px solid rgba(255, 255, 255, 0.4);
}

.advanced-panel :deep(.el-form-item) {
  margin-bottom: 14px;
}

.advanced-panel :deep(.el-form-item:last-child) {
  margin-bottom: 0;
}

.duration-buttons {
  display: flex;
  gap: 8px;
}

.dur-btn {
  flex: 1;
  padding: 8px 12px;
  border: 1px solid rgba(200, 200, 200, 0.4);
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.6);
  color: #666;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.dur-btn:hover {
  border-color: rgba(102, 126, 234, 0.4);
  color: #333;
}

.dur-btn.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #fff;
  border-color: transparent;
  box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
}

/* Image Upload */
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
  padding: 14px;
  border: 2px dashed rgba(102, 126, 234, 0.3);
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.25s;
  background: rgba(255, 255, 255, 0.4);
}

.upload-area.small {
  padding: 10px;
}

.upload-area:hover {
  border-color: rgba(102, 126, 234, 0.6);
  background: rgba(255, 255, 255, 0.7);
}

.upload-icon {
  font-size: 22px;
  color: #667eea;
}

.upload-text {
  font-size: 13px;
  color: #888;
}

.upload-text.success {
  color: #67c23a;
  font-weight: 500;
}

.preview-container {
  position: relative;
  width: 100%;
  max-height: 180px;
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.4);
}

.preview-container img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  max-height: 180px;
  display: block;
}

.close-preview {
  position: absolute;
  top: 6px;
  right: 6px;
  font-size: 18px;
  color: #fff;
  background: rgba(0, 0, 0, 0.5);
  border-radius: 50%;
  width: 26px;
  height: 26px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background 0.2s;
}

.close-preview:hover {
  background: rgba(220, 53, 69, 0.8);
}

/* Multi-image slots */
.multi-image-label {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 14px;
  font-weight: 600;
  color: #666;
}

.image-slot {
  background: rgba(255, 255, 255, 0.5);
  backdrop-filter: blur(12px);
  border-radius: 14px;
  padding: 14px;
  border: 1px solid rgba(255, 255, 255, 0.4);
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.slot-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.slot-label {
  font-size: 13px;
  font-weight: 600;
  color: #555;
}

/* Generate Button */
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
  max-height: 600px;
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
  transition: all 0.3s ease;
}

.zoom-enter-from,
.zoom-leave-to {
  opacity: 0;
  transform: scale(0.92);
}

@media (max-width: 640px) {
  .duration-buttons {
    flex-wrap: wrap;
  }

  .dur-btn {
    flex: 1 1 calc(50% - 4px);
  }
}
</style>
