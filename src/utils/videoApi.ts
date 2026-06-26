/**
 * Utility for constructing video generation API request bodies.
 * Maps UI inputs to the correct Agnes Video API format.
 */

interface VideoFormData {
  prompt: string
  aspectRatio: string
  duration: string
  frameRate: number
  seed: number | null
  negativePrompt: string
  singleImageData?: {
    localImage: string
    imageUrl: string
  }
  imageSlots?: Array<{
    localImage: string
    imageUrl: string
  }>
}

interface VideoStore {
  responseFormat: 'url' | 'b64_json'
  videoAspectRatio: string
  videoDuration: string
  videoFrameRate: number
  videoSeed: number | null
  videoNegativePrompt: string
}

const ASPECT_MAP: Record<string, { width: number; height: number }> = {
  '16:9':  { width: 1280, height: 720 },
  '9:16':  { width: 720, height: 1280 },
  '1:1':   { width: 1024, height: 1024 },
  '4:3':   { width: 1024, height: 768 },
  '3:4':   { width: 768, height: 1024 },
}

const DURATION_MAP: Record<string, number> = {
  '3':  81,
  '5':  121,
  '10': 241,
  '18': 441,
}

export function buildVideoRequestBody(
  videoMode: string,
  data: VideoFormData,
  store: VideoStore
): Record<string, unknown> {
  const body: Record<string, unknown> = {
    model: 'agnes-video-v2.0',
    prompt: data.prompt || '',
    extra_body: {} as Record<string, unknown>,
  }

  body.extra_body!.response_format = store.responseFormat === 'b64_json' ? 'b64_json' : 'url'

  const aspect = data.aspectRatio || store.videoAspectRatio || '16:9'
  const dims = ASPECT_MAP[aspect] || ASPECT_MAP['16:9']
  body.extra_body!.width = dims.width
  body.extra_body!.height = dims.height

  const duration = data.duration || store.videoDuration || '5'
  body.extra_body!.num_frames = DURATION_MAP[duration] || 121

  body.extra_body!.frame_rate = data.frameRate ?? store.videoFrameRate ?? 24

  if (data.seed != null && data.seed !== -1) {
    body.extra_body!.seed = data.seed
  }

  if (data.negativePrompt) {
    body.extra_body!.negative_prompt = data.negativePrompt
  }

  if (videoMode === 'img2video') {
    const slot = data.singleImageData
    if (slot?.localImage) {
      body.image = slot.localImage
    } else if (slot?.imageUrl) {
      body.image = slot.imageUrl
    }
  } else if (videoMode === 'multi-img' || videoMode === 'keyframes') {
    const urls = (data.imageSlots || [])
      .filter((s) => s.localImage || s.imageUrl)
      .map((s) => s.localImage || s.imageUrl)

    if (urls.length >= 2) {
      body.extra_body!.image = urls
    }

    if (videoMode === 'keyframes') {
      body.extra_body!.mode = 'keyframes'
    }
  }

  return body
}
