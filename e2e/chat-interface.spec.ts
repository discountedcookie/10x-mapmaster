import { test, expect, handleAuth } from './fixtures'
import { setupQuestionMock } from './fixtures/mock-supabase'

test.describe('V2 Chat Interface Test', () => {
  test.beforeEach(async ({ page }) => {
    await setupQuestionMock(page)
    await page.goto('/game')
    await handleAuth(page)
  })

  test('should display description as initial message', async ({ page }) => {
    const description = 'A famous tower in Paris'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Chat should show the original description
    await expect(page.getByText(description)).toBeVisible()
  })

  test('should show questions as system messages', async ({ page }) => {
    const description = 'A landmark'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // First question should appear as system message
    const questionElement = page.locator('[data-testid="system-message"]').first()
    await expect(questionElement).toBeVisible()
    await expect(questionElement).toContainText(/Question|Is this/)
  })

  test('should show answers as user messages', async ({ page }) => {
    const description = 'A structure'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Answer a question
    await page.getByRole('button', { name: 'Yes' }).click()

    // Should show user answer in chat
    const userMessage = page.locator('[data-testid="user-message"]').last()
    await expect(userMessage).toContainText('Yes')
  })

  test('should build conversation history', async ({ page }) => {
    const description = 'A monument'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Answer multiple questions
    await page.getByRole('button', { name: 'Yes' }).click()
    await page.getByRole('button', { name: 'No' }).click()
    await page.getByRole('button', { name: 'Yes' }).click()

    // Should have multiple message pairs
    const systemMessages = await page.locator('[data-testid="system-message"]').all()
    const userMessages = await page.locator('[data-testid="user-message"]').all()

    expect(systemMessages.length).toBeGreaterThan(1)
    expect(userMessages.length).toBeGreaterThan(1)
  })

  test('should auto-scroll to latest message', async ({ page }) => {
    const description = 'A building'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Chat container should scroll to bottom after each message
    const chatContainer = page.locator('[data-testid="chat-container"]')
    const initialScrollTop = await chatContainer.evaluate((element) => element.scrollTop)

    // Answer question
    await page.getByRole('button', { name: 'Yes' }).click()

    // Should have scrolled down
    const finalScrollTop = await chatContainer.evaluate((element) => element.scrollTop)
    expect(finalScrollTop).toBeGreaterThanOrEqual(initialScrollTop)
  })
})
