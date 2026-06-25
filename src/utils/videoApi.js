/**
 * Utility for constructing video generation API request bodies.
 * Maps UI inputs to the correct Agnes Video API format.
 */

// Aspect ratio to width/height mapping
const ASPECT_MAP = {
  '16:9':  { width: 1280, height: 720 },
  '9:16':  { width: 720, height: 1280 },
  '1:1':   { width: 1024, height: 1024 },
  '4:3':   { width: 1024, height: 768 },
  '3:4':   { width: 768, height: 1024 },
}

// Duration (seconds) to num_frames mapping (all satisfy 8n+1)
const DURATION_MAP = {
  '3':  81,
  '5':  121,
  '10': 241,
  '18': 441,
}

/**
 * Build the request body for video generation.
 *
 * @param {string} videoMode - 'txt2video' | 'img2video' | 'multi-img' | 'keyframes'
 * @param {object} data - Form data from VideoInputArea
 * @param {object} store - Pinia store instance
 * @returns {object} API request body
 */
export function buildVideoRequestBody(videoMode, data, store) {
  const body = {
    model: 'agnes-video-v2.0',
    prompt: data.prompt || '',
    extra_body: {}
  }

  // Response format
  body.extra_body.response_format = store.responseFormat === 'b64_json' ? 'b64_json' : 'url'

  // Aspect ratio → width/height
  const aspect = data.aspectRatio || store.videoAspectRatio || '16:9'
  const dims = ASPECT_MAP[aspect] || ASPECT_MAP['16:9']
  body.extra_body.width = dims.width
  body.extra_body.height = dims.height

  // Duration → num_frames
  const duration = data.duration || store.videoDuration || '5'
  body.extra_body.num_frames = DURATION_MAP[duration] || 121

  // Frame rate
  body.extra_body.frame_rate = data.frameRate ?? store.videoFrameRate ?? 24

  // Optional: seed
  if (data.seed != null && data.seed !== '') {
    body.extra_body.seed = Number(data.seed)
  }

  // Optional: negative prompt
  if (data.negativePrompt) {
    body.extra_body.negative_prompt = data.negativePrompt
  }

  // Image inputs based on mode
  if (videoMode === 'img2video') {
    // Single image: use root-level image field (string)
    const slot = data.imageSlots?.[0]
    if (slot?.localImage) {
      body.image = slot.localImage
    } else if (slot?.imageUrl) {
      body.image = slot.imageUrl
    }
  } else if (videoMode === 'multi-img' || videoMode === 'keyframes') {
    // Multiple images: put in extra_body.image array
    const urls = (data.imageSlots || [])
      .filter(slot => slot.localImage || slot.imageUrl)
      .map(slot => slot.localImage || slot.imageUrl)

    if (urls.length >= 2) {
      body.extra_body.image = urls
    }

    // Keyframes mode flag
    if (videoMode === 'keyframes') {
      body.extra_body.mode = 'keyframes'
    }
  }

  return body
}
