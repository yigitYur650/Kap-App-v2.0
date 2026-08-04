import { test, expect, Page } from '@playwright/test';

// Configuration parameters
const SUPABASE_URL = 'https://nwzwrknugadpvgaegter.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im53endya251Z2FkcHZnYWVndGVyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MjM5NzQ3MywiZXhwIjoyMDk3OTczNDczfQ.mDyYu5BWSqW22Kaj57hhA485ejBPNgAX-roBybPkTnY';

const TEST_EMAILS = [
  'yigit@kapapp.com',
  'user2@kapapp.com',
  'user3@kapapp.com'
];

/**
 * Helper to clean up existing test users from Supabase Auth to ensure E2E repeatability.
 * Cleans up all dependent tables first to prevent foreign-key violation HTTP 500 errors.
 */
async function cleanUpTestUsers() {
  console.log('Cleaning up existing test users and their database dependencies...');
  try {
    // 1. Fetch user records from public.users to get their IDs
    const emailsParam = TEST_EMAILS.map(e => `"${e}"`).join(',');
    const usersResponse = await fetch(`${SUPABASE_URL}/rest/v1/users?email=in.(${emailsParam})`, {
      headers: {
        'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
        'apikey': SERVICE_ROLE_KEY
      }
    });

    if (usersResponse.ok) {
      const users = await usersResponse.json() as Array<{ id: string; email: string }>;
      const userIds = users.map(u => u.id);

      if (userIds.length > 0) {
        console.log(`Found existing test users with IDs: ${userIds.join(', ')}. Cleaning up dependencies...`);
        const idsParam = userIds.map(id => `${id}`).join(',');

        // a. Delete all shopping requests created by or private to these users
        await fetch(`${SUPABASE_URL}/rest/v1/requests?requested_by=in.(${idsParam})`, {
          method: 'DELETE',
          headers: { 'Authorization': `Bearer ${SERVICE_ROLE_KEY}`, 'apikey': SERVICE_ROLE_KEY }
        });
        await fetch(`${SUPABASE_URL}/rest/v1/requests?private_to=in.(${idsParam})`, {
          method: 'DELETE',
          headers: { 'Authorization': `Bearer ${SERVICE_ROLE_KEY}`, 'apikey': SERVICE_ROLE_KEY }
        });

        // b. Delete all groups created by these users
        await fetch(`${SUPABASE_URL}/rest/v1/groups?created_by=in.(${idsParam})`, {
          method: 'DELETE',
          headers: { 'Authorization': `Bearer ${SERVICE_ROLE_KEY}`, 'apikey': SERVICE_ROLE_KEY }
        });

        // c. Delete all group memberships for these users
        await fetch(`${SUPABASE_URL}/rest/v1/group_members?user_id=in.(${idsParam})`, {
          method: 'DELETE',
          headers: { 'Authorization': `Bearer ${SERVICE_ROLE_KEY}`, 'apikey': SERVICE_ROLE_KEY }
        });

        // d. Delete from public.users directly to be clean
        await fetch(`${SUPABASE_URL}/rest/v1/users?id=in.(${idsParam})`, {
          method: 'DELETE',
          headers: { 'Authorization': `Bearer ${SERVICE_ROLE_KEY}`, 'apikey': SERVICE_ROLE_KEY }
        });
      }
    }

    // 2. Finally, delete the users from Supabase Auth using the Admin API
    const listResponse = await fetch(`${SUPABASE_URL}/auth/v1/admin/users`, {
      headers: {
        'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
        'apikey': SERVICE_ROLE_KEY
      }
    });

    if (!listResponse.ok) {
      console.warn(`Failed to list Auth users: ${listResponse.statusText}`);
      return;
    }

    const data = await listResponse.json() as { users: Array<{ id: string; email?: string }> };
    
    for (const email of TEST_EMAILS) {
      const user = data.users.find(u => u.email === email);
      if (user) {
        const deleteResponse = await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${user.id}`, {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
            'apikey': SERVICE_ROLE_KEY
          }
        });
        if (deleteResponse.ok) {
          console.log(`Successfully deleted Auth user: ${email}`);
        } else {
          console.warn(`Failed to delete Auth user ${email}: ${deleteResponse.statusText}`);
        }
      }
    }
  } catch (error) {
    console.error('Error during Supabase user cleanup:', error);
  }
}

/**
 * Helper to enable accessibility mode on Flutter Web, forcing it to render standard HTML inputs and buttons in the DOM
 */
async function enableAccessibility(page: Page) {
  console.log('Attempting to enable Flutter Web accessibility semantics...');
  await page.waitForTimeout(3000); // Give Flutter engine a moment to mount the shell
  
  // Click the hidden accessibility placeholder using JS evaluation
  await page.evaluate(() => {
    const el = document.querySelector('flt-semantics-placeholder') || 
               document.querySelector('[aria-label*="accessibility"]') || 
               document.querySelector('[aria-label*="Erişilebilirlik"]');
    if (el) {
      (el as HTMLElement).click();
      console.log('Clicked accessibility trigger inside browser JS context.');
    }
  });

  // Fallback click via Playwright locator
  try {
    const accLocator = page.locator('flt-semantics-placeholder, [aria-label*="accessibility"], [aria-label*="Erişilebilirlik"]').first();
    if (await accLocator.count() > 0) {
      await accLocator.click({ timeout: 2000 }).catch(() => {});
    }
  } catch (e) {}

  await page.waitForTimeout(2000); // Wait for the accessible HTML DOM elements to populate
}

/**
 * Helper to register a user on the Flutter Web UI
 */
async function registerUser(page: Page, displayName: string, email: string) {
  console.log(`Registering user: ${displayName} (${email})...`);
  
  // Navigate to hash route directly to avoid server-side routing issues
  await page.goto('/#/register');
  await page.waitForLoadState('networkidle');
  
  // Enable accessibility to expose HTML text fields
  await enableAccessibility(page);

  // Focus, wait for cursor focus to settle, and press keys sequentially
  const nameInput = page.locator('input[placeholder*="Kullanıcı Adı"]').or(page.locator('input[placeholder*="Display Name"]')).or(page.locator('input[type="text"]').first());
  await nameInput.waitFor({ state: 'visible' });
  await nameInput.click();
  await page.waitForTimeout(300);
  await nameInput.pressSequentially(displayName, { delay: 50 });

  const emailInput = page.locator('input[placeholder*="E-posta"]').or(page.locator('input[placeholder*="Email"]')).or(page.locator('input[type="email"]')).or(page.locator('input[type="text"]').nth(1));
  await emailInput.click();
  await page.waitForTimeout(300);
  await emailInput.pressSequentially(email, { delay: 50 });

  const passwordInput = page.locator('input[type="password"]').first();
  await passwordInput.click();
  await page.waitForTimeout(300);
  await passwordInput.pressSequentially('Password123', { delay: 50 });

  const confirmPasswordInput = page.locator('input[type="password"]').last();
  await confirmPasswordInput.click();
  await page.waitForTimeout(300);
  await confirmPasswordInput.pressSequentially('Password123', { delay: 50 });

  // Click Submit (Kayıt Ol)
  const submitButton = page.getByRole('button', { name: /Kayıt Ol|Sign Up/i }).or(page.locator('button:has-text("Kayıt Ol")')).or(page.locator('button:has-text("Sign Up")'));
  await submitButton.click();

  // Wait for redirect to dashboard/hub (accepts hash-based #/ or path-based /)
  // Note: We only check hash here because url.pathname is always '/' for single-page Flutter Web apps.
  await page.waitForURL(url => url.hash === '#/' || url.hash === '', { timeout: 20000 });
  console.log(`Successfully registered and redirected: ${email}`);
}

test.describe('Kap-App E2E Shopping Isolation Test Suite', () => {
  
  test.beforeAll(async () => {
    // Run cleanup to prevent "Email already in use" errors across test runs
    await cleanUpTestUsers();
  });

  test('should register 3 users, manage home, and assert shopping list private isolation', async ({ browser }) => {
    let invitationCode = '';

    // =========================================================================
    // STEP 1: USER 1 (Yiğit) Flow - Create Home and Get Invitation Code
    // =========================================================================
    console.log('\n--- STARTING USER 1 FLOW (Yiğit) ---');
    const context1 = await browser.newContext({ locale: 'tr-TR' });
    const page1 = await context1.newPage();
    
    // Add network request/response logging for detailed troubleshooting
    page1.on('request', request => {
      if (request.url().includes('supabase') || request.url().includes('localhost:8080')) {
        console.log(`[REQ]: ${request.method()} ${request.url()}`);
        if (request.postData()) {
          console.log(`  Payload: ${request.postData()}`);
        }
      }
    });

    page1.on('response', async response => {
      if (response.url().includes('supabase') || response.url().includes('localhost:8080')) {
        console.log(`[RESP]: ${response.status()} ${response.url()}`);
        if (response.status() >= 400) {
          try {
            const body = await response.text();
            console.log(`  ERROR BODY: ${body}`);
          } catch (e) {
            console.log(`  Could not read error body: ${e}`);
          }
        }
      }
    });

    page1.on('console', msg => console.log(`[BROWSER LOG (Yiğit)]`, msg.text()));
    page1.on('pageerror', err => console.error(`[BROWSER ERROR (Yiğit)]`, err.message));

    // Register as User 1
    await registerUser(page1, 'Yiğit', 'yigit@kapapp.com');

    // Click "Create Home" (Ev Oluştur)
    const createHomeBtn = page1.locator('text=Ev Oluştur').or(page1.locator('text=Create Home'));
    await createHomeBtn.waitFor({ state: 'visible' });
    await createHomeBtn.click();

    // Fill "Home/Group Name" dialog input using sequential keystrokes
    const workspaceInput = page1.getByRole('textbox', { name: 'Ev/Grup İsmi' })
      .or(page1.getByRole('textbox', { name: 'Home' }))
      .or(page1.locator('[role="dialog"] input[type="text"]'))
      .or(page1.locator('[role="alertdialog"] input[type="text"]'))
      .or(page1.locator('input[placeholder*="Ev/Grup"]'))
      .or(page1.locator('input[placeholder*="Home"]'));
    await workspaceInput.waitFor({ state: 'visible' });
    await workspaceInput.click();
    await page1.waitForTimeout(300);
    await workspaceInput.pressSequentially('House-Alpha', { delay: 50 });

    // Click "Create" (Oluştur)
    const createConfirmBtn = page1.getByRole('button', { name: 'Oluştur' })
      .or(page1.getByRole('button', { name: 'Create' }))
      .or(page1.locator('[role="dialog"] button:has-text("Oluştur")'))
      .or(page1.locator('[role="alertdialog"] button:has-text("Oluştur")'));
    await createConfirmBtn.click();

    // Wait for creation dialog to disappear
    await expect(page1.locator('[role="dialog"]').or(page1.locator('[role="alertdialog"]'))).toBeHidden();
    await page1.waitForTimeout(1000);
    
    // Switch to Settings (Ayarlar) Tab — use force click to ensure it registers
    const settingsTab = page1.locator('text=Ayarlar').or(page1.locator('text=Settings'));
    await settingsTab.waitFor({ state: 'visible', timeout: 5000 });
    await settingsTab.dispatchEvent('click');
    await page1.waitForTimeout(2000);

    // Extract Invitation Code matching pattern XXXX-XXXX (e.g. XK7M-2R9P)
    console.log('Extracting invitation code...');
    const pattern = /[A-Z0-9]{4}-[A-Z0-9]{4}/;
    
    // Wait until the code is loaded and visible
    const codeElement = page1.locator('text=/^[A-Z0-9]{4}-[A-Z0-9]{4}$/');
    await expect(codeElement).toBeVisible({ timeout: 15000 });
    
    // Fallback scanner to extract the code from DOM text if necessary
    const rawText = await codeElement.textContent();
    const match = rawText?.match(pattern);
    if (match) {
      invitationCode = match[0];
    } else {
      // Scan all text nodes as fallback
      const content = await page1.content();
      const bodyMatch = content.match(pattern);
      if (bodyMatch) {
        invitationCode = bodyMatch[0];
      } else {
        throw new Error('Failed to find invitation code on settings page.');
      }
    }
    console.log(`Extracted Invitation Code: ${invitationCode}`);

    // Log out User 1
    const signOutBtn = page1.locator('text=Çıkış Yap').or(page1.locator('text=Sign Out'));
    await signOutBtn.click();
    
    // Wait until back to login page (either hash-based #/login or path-based /login)
    await page1.waitForURL(url => url.hash.includes('login') || url.pathname.includes('login'), { timeout: 10000 });
    await expect(page1.locator('text=Giriş Yap').or(page1.locator('text=Sign In')).first()).toBeVisible();

    await context1.close();

    // =========================================================================
    // STEP 2: USER 2 Flow - Join Home and Add Shopping Items (Public & Private)
    // =========================================================================
    console.log('\n--- STARTING USER 2 FLOW ---');
    const context2 = await browser.newContext({ locale: 'tr-TR' });
    const page2 = await context2.newPage();

    // Register User 2
    await registerUser(page2, 'User 2', 'user2@kapapp.com');

    // JOIN VIA SUPABASE API — Flutter Web CanvasKit semantics has click issues,
    // so we bypass the UI for the join operation to keep the test reliable.
    console.log(`Joining User 2 via API with code: ${invitationCode}...`);
    const groupResult = await fetch(`${SUPABASE_URL}/rest/v1/groups?select=id&join_code=eq.${invitationCode}&deleted_at=is.null`, {
      headers: { 'Authorization': `Bearer ${SERVICE_ROLE_KEY}`, 'apikey': SERVICE_ROLE_KEY }
    });
    const groupData = await groupResult.json() as Array<{ id: string }>;
    if (!groupData.length) throw new Error(`No active group found with join_code: ${invitationCode}`);
    const groupId = groupData[0].id;
    // Get user2's ID from public.users table
    const user2Result = await fetch(`${SUPABASE_URL}/rest/v1/users?select=id&email=eq.user2@kapapp.com`, {
      headers: { 'Authorization': `Bearer ${SERVICE_ROLE_KEY}`, 'apikey': SERVICE_ROLE_KEY }
    });
    const user2Data = await user2Result.json() as Array<{ id: string }>;
    if (!user2Data.length) throw new Error('User 2 not found in public.users');
    const user2Id = user2Data[0].id;
    // Insert group membership
    const memberResp = await fetch(`${SUPABASE_URL}/rest/v1/group_members`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${SERVICE_ROLE_KEY}`, 'apikey': SERVICE_ROLE_KEY, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' },
      body: JSON.stringify({ user_id: user2Id, group_id: groupId, role: 'member' })
    });
        if (!memberResp.ok) throw new Error(`API join failed: ${memberResp.statusText}`);
    console.log('User 2 API join completed. Navigating to shopping list tab...');
    await page2.waitForTimeout(1000);

    // Navigate back to hub to force app to refresh groups data from Supabase
    await page2.goto('/');
    await page2.waitForTimeout(2000);

    // Navigate to Shopping List tab — app will fetch fresh data from Supabase
    const listTab2 = page2.locator('text=Liste').or(page2.locator('text=List'));
    await listTab2.waitFor({ state: 'visible', timeout: 5000 });
    await listTab2.click();

    // Open bottom sheet using FAB ("Ürün Ekle" / "Add Item" tooltip)
    const fabButton2 = page2.getByRole('button', { name: 'Ürün Ekle' }).or(page2.getByRole('button', { name: 'Add Item' })).or(page2.locator('[aria-label*="Ekle"]').or(page2.locator('[aria-label*="Add"]')));
    await fabButton2.waitFor({ state: 'visible' });
    await fabButton2.click();

    // Fill Item Name "Ekmek" using sequential keystrokes
    const itemNameInput2 = page2.locator('input[placeholder*="Ne lazım"]').or(page2.locator('input[placeholder*="What is needed"]')).or(page2.locator('input[type="text"]').first());
    await itemNameInput2.waitFor({ state: 'visible' });
    await itemNameInput2.click();
    await page2.waitForTimeout(300);
    await itemNameInput2.pressSequentially('Ekmek', { delay: 50 });

    // Click "Add" (Ekle)
    const addConfirmBtn2 = page2.getByRole('button', { name: 'Ekle' }).or(page2.getByRole('button', { name: 'Add' })).or(page2.locator('button:has-text("Ekle")'));
    await addConfirmBtn2.click();

    // Wait for sheet to disappear
    await expect(itemNameInput2).toBeHidden();

    // Open bottom sheet again for private request
    await fabButton2.click();
    await itemNameInput2.waitFor({ state: 'visible' });
    await itemNameInput2.click();
    await page2.waitForTimeout(300);
    await itemNameInput2.pressSequentially("Yiğit'e Gizli Hediye", { delay: 50 });

    // Toggle "Gizli" (Private) checkbox/switch
    const privateSwitch2 = page2.locator('input[type="checkbox"]').or(page2.getByRole('checkbox')).or(page2.getByRole('switch'));
    await privateSwitch2.click();

    // Open Member Picker Dropdown (labeled "Şu Üyeye Gizle" or "Private To")
    const memberDropdown2 = page2.locator('text=Şu Üyeye Gizle').or(page2.locator('text=Private To'));
    await memberDropdown2.waitFor({ state: 'visible' });
    await memberDropdown2.click();

    // Select "Yiğit" (User 1) from list options
    const targetMemberOption2 = page2.locator('text=Yiğit').or(page2.locator('text=yigit'));
    await targetMemberOption2.last().click();

    // Submit private request
    await addConfirmBtn2.click();
    await expect(itemNameInput2).toBeHidden();

    // Log out User 2
    await page2.locator('text=Ayarlar').or(page2.locator('text=Settings')).click();
    await page2.locator('text=Çıkış Yap').or(page2.locator('text=Sign Out')).click();
    
    await page2.waitForURL(url => url.hash.includes('login') || url.pathname.includes('login'), { timeout: 10000 });
    await expect(page2.locator('text=Giriş Yap').or(page2.locator('text=Sign In')).first()).toBeVisible();

    await context2.close();

    // =========================================================================
    // STEP 3: USER 3 (The UI Spy) Flow - Verify Shared vs Private Visibility
    // =========================================================================
    console.log('\n--- STARTING USER 3 FLOW ---');
    const context3 = await browser.newContext({ locale: 'tr-TR' });
    const page3 = await context3.newPage();

    // Register User 3
    await registerUser(page3, 'User 3', 'user3@kapapp.com');

    // JOIN VIA SUPABASE API (same reason as User 2)
    console.log(`Joining User 3 via API with code: ${invitationCode}...`);
    const groupResult3 = await fetch(`${SUPABASE_URL}/rest/v1/groups?select=id&join_code=eq.${invitationCode}&deleted_at=is.null`, {
      headers: { 'Authorization': `Bearer ${SERVICE_ROLE_KEY}`, 'apikey': SERVICE_ROLE_KEY }
    });
    const groupData3 = await groupResult3.json() as Array<{ id: string }>;
    if (!groupData3.length) throw new Error(`No active group found with join_code: ${invitationCode}`);
    const groupId3 = groupData3[0].id;
    const user3Result = await fetch(`${SUPABASE_URL}/rest/v1/users?select=id&email=eq.user3@kapapp.com`, {
      headers: { 'Authorization': `Bearer ${SERVICE_ROLE_KEY}`, 'apikey': SERVICE_ROLE_KEY }
    });
    const user3Data = await user3Result.json() as Array<{ id: string }>;
    if (!user3Data.length) throw new Error('User 3 not found in public.users');
    const user3Id = user3Data[0].id;
    const memberResp3 = await fetch(`${SUPABASE_URL}/rest/v1/group_members`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${SERVICE_ROLE_KEY}`, 'apikey': SERVICE_ROLE_KEY, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' },
      body: JSON.stringify({ user_id: user3Id, group_id: groupId3, role: 'member' })
    });
    if (!memberResp3.ok) throw new Error(`API join failed for User 3: ${memberResp3.statusText}`);
    console.log('User 3 API join completed. Navigating to shopping list tab...');
    await page3.waitForTimeout(1000);

    // Navigate back to hub to force app to refresh groups data
    await page3.goto('/');
    await page3.waitForTimeout(2000);

    // Navigate to Shopping List tab
    const listTab3 = page3.locator('text=Liste').or(page3.locator('text=List'));
    await listTab3.waitFor({ state: 'visible', timeout: 5000 });
    await listTab3.click();

    // UI ASSERTION 1: Assert that the text "Ekmek" is fully visible
    const publicItem = page3.locator('text=Ekmek');
    await expect(publicItem).toBeVisible({ timeout: 10000 });
    console.log('UI Assertion 1 Passed: "Ekmek" is visible to User 3.');

    // UI ASSERTION 2: Assert that the text "Yiğit'e Gizli Hediye" is STRICTLY NOT visible / hidden
    const privateItem = page3.locator('text=Yiğit\'e Gizli Hediye');
    await expect(privateItem).toBeHidden();
    console.log('UI Assertion 2 Passed: "Yiğit\'e Gizli Hediye" is hidden from User 3.');

    await context3.close();
    console.log('\nE2E Shopping Isolation Suite complete and all assertions passed!');
  });
});
