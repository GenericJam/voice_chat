const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log('Navigating to robot debug page...');
  await page.goto('https://chat.boltbrain.ca/robot_debug');

  // Wait for page to load
  await page.waitForTimeout(2000);

  // Take initial screenshot
  await page.screenshot({ path: '/tmp/robot_debug_initial.png', fullPage: true });
  console.log('Screenshot saved: /tmp/robot_debug_initial.png');

  // Click the speak button if it exists
  const speakButton = await page.locator('button:has-text("Speak:")').first();
  if (await speakButton.isVisible()) {
    console.log('Clicking speak button...');
    await speakButton.click();
    await page.waitForTimeout(1000);
    await page.screenshot({ path: '/tmp/robot_debug_speaking.png', fullPage: true });
    console.log('Screenshot saved: /tmp/robot_debug_speaking.png');
  }

  await page.waitForTimeout(3000);

  await browser.close();
  console.log('Done!');
})();
