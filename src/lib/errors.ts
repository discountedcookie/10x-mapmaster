import { type Ref } from 'vue'
import { logger } from '@/lib/logger'

export class ApiError extends Error {
  constructor(
    public code: string,
    message: string,
    public details?: unknown
  ) {
    super(message)
    this.name = 'ApiError'
  }
}

export function transformError(error: unknown): ApiError {
  if (error instanceof ApiError) return error

  if (error instanceof Error) {
    // Handle known error patterns
    if (error.message.includes('LLM_UNAVAILABLE')) {
      return new ApiError('LLM_UNAVAILABLE', 'AI service is temporarily unavailable')
    }
    if (error.message.includes('EMBEDDING_UNAVAILABLE')) {
      return new ApiError('EMBEDDING_UNAVAILABLE', 'Embedding service is unavailable')
    }
    if (error.message.includes('RATE_LIMITED')) {
      return new ApiError('RATE_LIMITED', 'Please wait a few seconds before trying again')
    }
    if (error.message.includes('description too long')) {
      return new ApiError('INVALID_INPUT', 'Description is too long (max 100 characters)')
    }
    if (error.message.includes('invalid control characters')) {
      return new ApiError('INVALID_INPUT', 'Description contains invalid characters')
    }
    if (error.message.includes('excessive newlines')) {
      return new ApiError('INVALID_INPUT', 'Description contains too many line breaks')
    }
    if (error.message.includes('invalid content')) {
      return new ApiError('INVALID_INPUT', 'Description contains invalid content')
    }
    return new ApiError('UNKNOWN', error.message, error)
  }

  return new ApiError('UNKNOWN', 'An unexpected error occurred', error)
}

// Utility for async operations with loading/error state
export async function withLoadingState<T>(
  fn: () => Promise<T>,
  loading: Ref<boolean>,
  error: Ref<string | undefined>
): Promise<T | undefined> {
  try {
    loading.value = true
    error.value = undefined
    return await fn()
  } catch (e) {
    const apiError = transformError(e)
    error.value = apiError.message
    logger.error(apiError.message, apiError.details)
    return undefined
  } finally {
    loading.value = false
  }
}
