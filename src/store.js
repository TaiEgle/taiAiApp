import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useAppStore = defineStore('app', () => {
  // ========== Top-level navigation ==========
  const appMode = ref('image') // 'image' | 'video'

  // ========== API Configuration (shared) ==========
  const apiUrl = ref('https://apihub.agnes-ai.com/v1/images/generations')
  const apiKey = ref('')

  // Video-specific base URL
  const videoBaseUrl = ref('https://apihub.agnes-ai.com')

  // ========== Image Generation State ==========
  const mode = ref('txt2img') // 'txt2img' | 'img2img'
  const responseFormat = ref('url') // 'url' | 'b64_json'

  // Image size presets
  const sizes = [
    { label: '1024×1024', value: '1024x1024' },
    { label: '1024×768', value: '1024x768' },
    { label: '768×1024', value: '768x1024' },
    { label: '512×512', value: '512x512' },
    { label: '512×768', value: '512x768' },
    { label: '768×512', value: '768x512' },
  ]
  const selectedSize = ref('1024x1024')

  // Image history
  const history = ref([])

  // ========== Video Generation State ==========
  const videoMode = ref('txt2video') // 'txt2video' | 'img2video' | 'multi-img' | 'keyframes'

  // Video advanced options
  const videoAspectRatio = ref('16:9')
  const videoDuration = ref('5')
  const videoFrameRate = ref(24)
  const videoSeed = ref(null)
  const videoNegativePrompt = ref('')

  // Video polling state
  const videoPollingState = ref({
    videoId: null,
    progress: 0,
    status: '',
    currentVideoUrl: '',
    error: ''
  })

  // Video history
  const videoHistory = ref([])

  // ========== Config panel visibility ==========
  const configVisible = ref(false)

  // ========== Image helpers ==========
  function addToHistory(item) {
    history.value.unshift(item)
    if (history.value.length > 5) {
      history.value = history.value.slice(0, 5)
    }
  }

  function clearHistory() {
    history.value = []
  }

  // ========== Video helpers ==========
  function addToVideoHistory(item) {
    videoHistory.value.unshift(item)
    if (videoHistory.value.length > 3) {
      videoHistory.value = videoHistory.value.slice(0, 3)
    }
  }

  function clearVideoHistory() {
    videoHistory.value = []
  }

  function resetVideoPolling() {
    videoPollingState.value = {
      videoId: null,
      progress: 0,
      status: '',
      currentVideoUrl: '',
      error: ''
    }
  }

  // ========== Computed ==========
  const apiBaseUrl = computed(() => {
    try {
      const u = new URL(apiUrl.value)
      return `${u.protocol}//${u.host}`
    } catch {
      return 'https://apihub.agnes-ai.com'
    }
  })

  return {
    // Navigation
    appMode,
    // Shared API config
    apiUrl, apiKey, apiBaseUrl,
    // Video-specific
    videoBaseUrl,
    // Image state
    mode, responseFormat, sizes, selectedSize, history,
    // Video state
    videoMode, videoAspectRatio, videoDuration, videoFrameRate,
    videoSeed, videoNegativePrompt, videoPollingState, videoHistory,
    // Config
    configVisible,
    // Image helpers
    addToHistory, clearHistory,
    // Video helpers
    addToVideoHistory, clearVideoHistory, resetVideoPolling
  }
})
