/**
 * Shared reactive state module for UniApp X.
 * Uses Vue 3 reactive pattern compatible with UniApp X.
 */

import { reactive, ref, watch } from 'vue'

// Image size presets
export interface ImageSize {
  label: string
  value: string
}

export const IMAGE_SIZES: ImageSize[] = [
  { label: '1024×1024', value: '1024x1024' },
  { label: '1024×768', value: '1024x768' },
  { label: '768×1024', value: '768x1024' },
  { label: '512×512', value: '512x512' },
  { label: '512×768', value: '512x768' },
  { label: '768×512', value: '768x512' },
]

// Image history item
export interface ImageHistoryItem {
  displaySrc: string
  prompt: string
  timestamp: number
}

// Video history item
export interface VideoHistoryItem {
  videoUrl: string
  prompt: string
  durationLabel: string
  timestamp: number
}

// Create the shared reactive state
let _appState: ReturnType<typeof createAppState> | null = null

export function createAppState() {
  return {
    // Navigation
    appMode: 'image' as 'image' | 'video',

    // Shared API config
    apiUrl: 'https://apihub.agnes-ai.com/v1/images/generations',
    apiKey: '',
    videoBaseUrl: 'https://apihub.agnes-ai.com',

    // Image state
    imageMode: 'txt2img' as 'txt2img' | 'img2img',
    responseFormat: 'url' as 'url' | 'b64_json',
    selectedSize: '1024x1024',
    history: [] as ImageHistoryItem[],

    // Video state
    videoMode: 'txt2video' as 'txt2video' | 'img2video' | 'multi-img' | 'keyframes',
    videoAspectRatio: '16:9',
    videoDuration: '5',
    videoFrameRate: 24,
    videoSeed: null as number | null,
    videoNegativePrompt: '',
    videoHistory: [] as VideoHistoryItem[],

    // Config panel
    configVisible: false,
  }
}

// Singleton accessor
export function useAppStore() {
  if (!_appState) {
    _appState = createAppState()
    // Load persisted state
    try {
      const imgConfig = JSON.parse(uni.getStorageSync('ai-image-config') || '{}')
      if (imgConfig.url) _appState.apiUrl = imgConfig.url
      if (imgConfig.key) _appState.apiKey = imgConfig.key
      if (imgConfig.fmt) _appState.responseFormat = imgConfig.fmt as 'url' | 'b64_json'
    } catch {}

    try {
      const vidConfig = JSON.parse(uni.getStorageSync('ai-video-config') || '{}')
      if (vidConfig.url) _appState.videoBaseUrl = vidConfig.url
      if (vidConfig.key) _appState.apiKey = vidConfig.key
      if (vidConfig.fmt) _appState.responseFormat = vidConfig.fmt as 'url' | 'b64_json'
    } catch {}

    try {
      const imgHist = uni.getStorageSync('ai-image-history')
      if (imgHist) _appState.history = JSON.parse(imgHist)
    } catch {}

    try {
      const vidHist = uni.getStorageSync('ai-video-history')
      if (vidHist) _appState.videoHistory = JSON.parse(vidHist)
    } catch {}
  }
  return _appState
}

// Helper to save image config
export function saveImageConfig(state: ReturnType<typeof createAppState>) {
  try {
    uni.setStorageSync('ai-image-config', JSON.stringify({
      url: state.apiUrl,
      key: state.apiKey,
      fmt: state.responseFormat,
    }))
  } catch {}
}

// Helper to save video config
export function saveVideoConfig(state: ReturnType<typeof createAppState>) {
  try {
    uni.setStorageSync('ai-video-config', JSON.stringify({
      url: state.videoBaseUrl,
      key: state.apiKey,
      fmt: state.responseFormat,
    }))
  } catch {}
}

// Helper to save image history
export function saveImageHistory(state: ReturnType<typeof createAppState>) {
  try {
    uni.setStorageSync('ai-image-history', JSON.stringify(state.history.slice(0, 5)))
  } catch {}
}

// Helper to save video history
export function saveVideoHistory(history: VideoHistoryItem[]) {
  try {
    uni.setStorageSync('ai-video-history', JSON.stringify(history.slice(0, 3)))
  } catch {}
}
