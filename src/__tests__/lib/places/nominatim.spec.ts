import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { waitForRateLimit, withCache, apiCache } from '@/lib/places'

describe('waitForRateLimit', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('should enforce minimum delay between calls', async () => {
    const start = Date.now()

    // First call - should resolve immediately
    await waitForRateLimit()
    const afterFirst = Date.now()

    // Second call - should wait
    const waitPromise = waitForRateLimit()
    vi.advanceTimersByTime(1000)
    await waitPromise
    const afterSecond = Date.now()

    expect(afterFirst - start).toBeLessThan(100)
    expect(afterSecond - afterFirst).toBeGreaterThanOrEqual(1000)
  })
})

describe('withCache', () => {
  beforeEach(() => {
    apiCache.cache.clear()
  })

  it('should cache function results', async () => {
    let callCount = 0
    const expensiveFn = async () => {
      callCount++
      return 'result'
    }

    const result1 = await withCache('test-key', expensiveFn)
    const result2 = await withCache('test-key', expensiveFn)

    expect(result1).toBe('result')
    expect(result2).toBe('result')
    expect(callCount).toBe(1) // Function only called once
  })

  it('should use different cache entries for different keys', async () => {
    let callCount = 0
    const expensiveFn = async () => {
      callCount++
      return `result-${callCount}`
    }

    const result1 = await withCache('key1', expensiveFn)
    const result2 = await withCache('key2', expensiveFn)

    expect(result1).toBe('result-1')
    expect(result2).toBe('result-2')
    expect(callCount).toBe(2)
  })
})
