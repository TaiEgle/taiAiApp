import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAppStore = defineStore('app', () => {
  // API Configuration
  const apiUrl = ref('https://apihub.agnes-ai.com/v1/images/generations')
  const apiKey = ref('')

  // Generation mode: 'txt2img' | 'img2img'
  const mode = ref('txt2img')

  // Response format: 'url' | 'b64_json'
  const responseFormat = ref('url')

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

  // History
  const history = ref([])

  // Config panel visibility
  const configVisible = ref(false)

  function addToHistory(item) {
    history.value.unshift(item)
    if (history.value.length > 5) {
      history.value = history.value.slice(0, 5)
    }
  }

  function clearHistory() {
    history.value = []
  }

  return {
    apiUrl, apiKey, mode, responseFormat,
    sizes, selectedSize, history, configVisible,
    addToHistory, clearHistory
  }
})
