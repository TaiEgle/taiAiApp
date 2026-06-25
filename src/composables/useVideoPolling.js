import { ref, onUnmounted } from 'vue'

/**
 * Composable for polling Agnes video generation API.
 * Handles async task status polling with cleanup on unmount.
 *
 * @param {string} baseUrl - API base URL (e.g. https://apihub.agnes-ai.com)
 * @param {string} apiKey - Authorization Bearer token
 * @param {string} videoId - The video task ID to poll
 * @returns {object} Reactive state and control functions
 */
export function useVideoPolling(baseUrl, apiKey, videoId) {
  const progress = ref(0)
  const status = ref('')
  const currentVideoUrl = ref('')
  const error = ref('')
  let pollingInterval = null

  function startPolling() {
    if (!videoId.value) return

    error.value = ''
    currentVideoUrl.value = ''
    progress.value = 0
    status.value = '排队中...'

    pollingInterval = setInterval(async () => {
      try {
        const pollUrl = `${baseUrl.value}/agnesapi?video_id=${videoId.value}&model_name=agnes-video-v2.0`
        const response = await fetch(pollUrl, {
          headers: {
            'Authorization': `Bearer ${apiKey.value.trim()}`
          }
        })

        if (!response.ok) {
          if (response.status === 401) {
            throw new Error('API Key 无效或已过期')
          }
          throw new Error(`轮询失败 (${response.status})`)
        }

        const data = await response.json()

        // Update progress
        if (data.progress !== undefined && data.progress !== null) {
          progress.value = Math.round(data.progress * 100)
        }

        // Update status text
        if (data.status) {
          const statusMap = {
            queued: '排队中...',
            in_progress: `生成中 ${progress.value}%`,
            completed: '已完成！',
            failed: '生成失败'
          }
          status.value = statusMap[data.status] || data.status
        }

        // Check for completion
        if (data.status === 'completed' || data.remixed_from_video_id) {
          clearInterval(pollingInterval)
          pollingInterval = null
          currentVideoUrl.value = data.remixed_from_video_id || data.video_url || ''
          if (!currentVideoUrl.value) {
            error.value = '视频生成完成但未找到视频链接'
          }
          status.value = '已完成！'
          progress.value = 100
        }

        // Check for failure
        if (data.status === 'failed' || data.error) {
          clearInterval(pollingInterval)
          pollingInterval = null
          error.value = data.error || data.status || '视频生成失败'
          status.value = '生成失败'
        }
      } catch (err) {
        clearInterval(pollingInterval)
        pollingInterval = null
        error.value = err.message || '轮询出错'
        status.value = '轮询失败'
      }
    }, 5000)

    status.value = '排队中...'
    progress.value = 0
  }

  function stopPolling() {
    if (pollingInterval) {
      clearInterval(pollingInterval)
      pollingInterval = null
    }
  }

  // Auto-cleanup on unmount
  onUnmounted(() => {
    stopPolling()
  })

  return {
    progress,
    status,
    currentVideoUrl,
    error,
    startPolling,
    stopPolling
  }
}
