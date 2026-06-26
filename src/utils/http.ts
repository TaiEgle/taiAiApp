/**
 * HTTP request utilities for UniApp X.
 */

interface RequestOptions {
  url: string
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE'
  headers?: Record<string, string>
  body?: string
}

export async function httpPost<T>(options: RequestOptions, apiKey: string): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${apiKey}`,
    ...options.headers,
  }

  const response = await uni.request({
    url: options.url,
    method: options.method || 'POST',
    header: headers,
    data: options.body ? JSON.parse(options.body) : undefined,
  })

  const [error, result] = response
  if (error || result.statusCode !== 200) {
    throw new Error(`请求失败 (${result.statusCode})`)
  }

  return result.data as T
}

export async function httpGet<T>(url: string, apiKey: string): Promise<T> {
  const response = await uni.request({
    url,
    method: 'GET',
    header: {
      'Authorization': `Bearer ${apiKey}`,
    },
  })

  const [error, result] = response
  if (error || result.statusCode !== 200) {
    throw new Error(`请求失败 (${result.statusCode})`)
  }

  return result.data as T
}

/**
 * Handle HTTP error responses
 */
export function handleHttpError(status: number, data: any): Error {
  if (status === 401) {
    return new Error('API Key 无效或已过期，请在配置中心更新')
  }
  if (status === 429) {
    return new Error('请求过于频繁，请稍后再试')
  }
  const msg = data?.error?.message || data?.message || ''
  return new Error(`请求失败 (${status}): ${msg}`)
}
