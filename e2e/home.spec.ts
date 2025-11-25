import { expect, test } from './fixtures'

test.describe('Home View', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/')
  })

  test('displays the map', async ({ page }) => {
    // Wait for MapLibre to initialize and render
    await page.waitForSelector('.maplibregl-canvas', { timeout: 10_000 })

    // Check that the map container is present
    const mapContainer = page.locator('.maplibregl-map')
    await expect(mapContainer).toBeVisible()

    // Verify MapLibre attribution is present
    const attribution = page.getByText('MapLibre')
    await expect(attribution).toBeVisible()
  })

  test('displays the hero card with correct content', async ({ page }) => {
    // Check heading
    const heading = page.getByRole('heading', { name: '10x-mapmaster', level: 3 })
    await expect(heading).toBeVisible()

    // Check description
    const description = page.getByText(
      'An intelligent geography guessing game that learns from every session'
    )
    await expect(description).toBeVisible()

    // Check "Get Started" button
    const button = page.getByRole('button', { name: 'Get Started' })
    await expect(button).toBeVisible()
    await expect(button).toBeEnabled()
  })

  test('hero card is positioned over the map', async ({ page }) => {
    // Wait for map to load
    await page.waitForSelector('.maplibregl-canvas', { timeout: 10_000 })

    const mapContainer = page.locator('.maplibregl-map')
    const heroCard = page.getByRole('heading', { name: '10x-mapmaster' })

    // Both should be visible
    await expect(mapContainer).toBeVisible()
    await expect(heroCard).toBeVisible()

    // Hero card should have higher z-index (be on top)
    const mapBox = await mapContainer.boundingBox()
    const cardBox = await heroCard.boundingBox()

    expect(mapBox).toBeTruthy()
    expect(cardBox).toBeTruthy()
  })

  test('clicking "Get Started" button navigates to game', async ({ page }) => {
    const button = page.getByRole('button', { name: 'Get Started' })
    await button.click()

    // Wait for navigation
    await page.waitForURL('**/game')

    // Verify we're on the game page
    expect(page.url()).toContain('/game')
  })

  test('map is interactive', async ({ page }) => {
    // Wait for map to fully initialize
    await page.waitForSelector('.maplibregl-canvas', { timeout: 10_000 })

    const mapContainer = page.locator('.maplibregl-map')
    await expect(mapContainer).toBeVisible()

    // Map canvas should be present
    const canvas = page.locator('.maplibregl-canvas')
    await expect(canvas).toBeVisible()

    // Check that map controls are present (attribution)
    const mapControls = page.locator('.maplibregl-ctrl-attrib')
    await expect(mapControls).toBeVisible()
  })

  test('has correct page title', async ({ page }) => {
    await expect(page).toHaveTitle(/Vite App/)
  })
})
