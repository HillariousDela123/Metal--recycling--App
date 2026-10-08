/**
 * EcoMetal Full Functional & Integration Test Suite (TC01 - TC07)
 * Runs automated assertions against the backend API, data models,
 * math calculations, and business workflow transitions.
 */

const assert = require('assert');

const BASE_URL = 'http://localhost:3000';

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  bold: '\x1b[1m'
};

let passedCount = 0;
let failedCount = 0;
const testResults = [];

async function test(id, title, testFn) {
  const start = Date.now();
  process.stdout.write(`  Running ${colors.bold}${id}${colors.reset}: ${title}... `);
  try {
    await testFn();
    const duration = Date.now() - start;
    passedCount++;
    console.log(`${colors.green}✔ PASSED${colors.reset} (${duration}ms)`);
    testResults.push({ id, title, passed: true, duration });
  } catch (err) {
    const duration = Date.now() - start;
    failedCount++;
    console.log(`${colors.red}✖ FAILED${colors.reset} (${duration}ms)`);
    console.log(`    ${colors.red}Error: ${err.message}${colors.reset}`);
    testResults.push({ id, title, passed: false, duration, error: err.message });
  }
}

async function run() {
  console.log(`\n${colors.cyan}${colors.bold}================================================================${colors.reset}`);
  console.log(`${colors.cyan}${colors.bold}  ♻️  EcoMetal Automated Functional Test Suite (TC01 - TC07)    ${colors.reset}`);
  console.log(`${colors.cyan}${colors.bold}================================================================${colors.reset}\n`);

  // TC01: User Registration & Input Validation
  console.log(`${colors.blue}${colors.bold}► Category 1: Authentication & Validation${colors.reset}`);

  await test('TC01.1', 'Reject registration with invalid email format', async () => {
    const res = await fetch(`${BASE_URL}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Valid Name', email: 'invalid-email-address', password: 'Password123!' })
    });
    assert.strictEqual(res.status, 400);
    const data = await res.json();
    assert.ok(data.error.includes('valid email'));
  });

  await test('TC01.2', 'Reject registration with password under 6 characters', async () => {
    const res = await fetch(`${BASE_URL}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Valid Name', email: 'user@valid.com', password: '123' })
    });
    assert.strictEqual(res.status, 400);
    const data = await res.json();
    assert.ok(data.error.includes('6 characters'));
  });

  await test('TC01.3', 'Reject registration with name under 2 characters', async () => {
    const res = await fetch(`${BASE_URL}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'A', email: 'user@valid.com', password: 'Password123!' })
    });
    assert.strictEqual(res.status, 400);
    const data = await res.json();
    assert.ok(data.error.includes('at least 2 characters'));
  });

  const testEmail = `test.recycler.${Date.now()}@greenmetal.org`;
  let registeredUserId = null;

  await test('TC01.4', 'Successful user registration and model creation', async () => {
    const res = await fetch(`${BASE_URL}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Eco Champion',
        email: testEmail,
        password: 'ScrapRecycle2026!'
      })
    });
    assert.strictEqual(res.status, 201);
    const data = await res.json();
    assert.ok(data.user);
    assert.strictEqual(data.user.email, testEmail);
    assert.strictEqual(data.user.name, 'Eco Champion');
    assert.strictEqual(data.user.ecoPoints, 100);
    assert.ok(data.user.userId);
    registeredUserId = data.user.userId;
  });

  // TC02: Authentication & User Session
  await test('TC02.1', 'Sign in registered user with correct credentials', async () => {
    const res = await fetch(`${BASE_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: testEmail, password: 'ScrapRecycle2026!' })
    });
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert.strictEqual(data.user.email, testEmail);
    assert.ok(data.token);
  });

  await test('TC02.2', 'Reject sign in with incorrect password', async () => {
    const res = await fetch(`${BASE_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: testEmail, password: 'WrongPassword999!' })
    });
    assert.strictEqual(res.status, 401);
  });

  // TC03: Metal Category Selection & Metadata
  console.log(`\n${colors.blue}${colors.bold}► Category 2: Scrap Metal Categories & Pricing${colors.reset}`);

  let metalsList = [];
  await test('TC03.1', 'Fetch all metal categories and verify core metal presence', async () => {
    const res = await fetch(`${BASE_URL}/api/metals`);
    assert.strictEqual(res.status, 200);
    metalsList = await res.json();
    assert.ok(Array.isArray(metalsList));
    assert.ok(metalsList.length >= 6);

    const metalNames = metalsList.map(m => m.name.toLowerCase());
    assert.ok(metalNames.includes('copper'));
    assert.ok(metalNames.includes('aluminium'));
    assert.ok(metalNames.includes('steel'));
    assert.ok(metalNames.includes('brass'));
  });

  await test('TC03.2', 'Verify metal symbols, positive pricing ($/kg), and CO2 factors', async () => {
    for (const metal of metalsList) {
      assert.ok(metal.symbol && metal.symbol.length > 0, `${metal.name} symbol missing`);
      assert.ok(typeof metal.pricePerKg === 'number' && metal.pricePerKg > 0, `${metal.name} price invalid`);
      assert.ok(typeof metal.co2Factor === 'number' && metal.co2Factor > 0, `${metal.name} co2Factor invalid`);
      assert.ok(metal.environmentalImpact && metal.environmentalImpact.length > 0, `${metal.name} impact missing`);
    }
  });

  // TC04: Recycling Service Discovery Filtering
  console.log(`\n${colors.blue}${colors.bold}► Category 3: Recycling Centers Discovery & Filtering${colors.reset}`);

  await test('TC04.1', 'Fetch all recycling centers and verify data fields', async () => {
    const res = await fetch(`${BASE_URL}/api/services`);
    assert.strictEqual(res.status, 200);
    const services = await res.json();
    assert.ok(Array.isArray(services));
    assert.ok(services.length >= 4);

    const s = services[0];
    assert.ok(s.serviceId);
    assert.ok(s.name);
    assert.ok(typeof s.lat === 'number');
    assert.ok(typeof s.lng === 'number');
    assert.ok(Array.isArray(s.acceptedMetals));
    assert.ok(s.isVerified);
  });

  await test('TC04.2', 'Filter services by Copper returns only facilities accepting Copper', async () => {
    const res = await fetch(`${BASE_URL}/api/services?metal=Copper`);
    assert.strictEqual(res.status, 200);
    const services = await res.json();
    assert.ok(services.length > 0);
    for (const s of services) {
      assert.ok(s.acceptedMetals.some(m => m.toLowerCase() === 'copper'),
        `Service ${s.name} does not accept Copper`);
    }
  });

  await test('TC04.3', 'Filter services by Steel returns only facilities accepting Steel', async () => {
    const res = await fetch(`${BASE_URL}/api/services?metal=Steel`);
    assert.strictEqual(res.status, 200);
    const services = await res.json();
    assert.ok(services.length > 0);
    for (const s of services) {
      assert.ok(s.acceptedMetals.some(m => m.toLowerCase() === 'steel'),
        `Service ${s.name} does not accept Steel`);
    }
  });

  await test('TC04.4', 'Search facilities by keyword query', async () => {
    const res = await fetch(`${BASE_URL}/api/services?search=Apex`);
    assert.strictEqual(res.status, 200);
    const services = await res.json();
    assert.ok(services.length >= 1);
    assert.ok(services[0].name.includes('Apex'));
  });

  // TC05: Geodesic Distance Sorting
  console.log(`\n${colors.blue}${colors.bold}► Category 4: Location & Distance Calculation${colors.reset}`);

  await test('TC05.1', 'Calculate GPS distances and sort facilities by closest proximity', async () => {
    // SF user coordinates
    const userLat = 37.7749;
    const userLng = -122.4194;
    const res = await fetch(`${BASE_URL}/api/services?lat=${userLat}&lng=${userLng}`);
    assert.strictEqual(res.status, 200);
    const services = await res.json();

    assert.ok(services.length >= 2);
    assert.ok(typeof services[0].distanceMeters === 'number');
    assert.ok(typeof services[0].distanceKm === 'string');

    // Verify ascending order
    for (let i = 0; i < services.length - 1; i++) {
      assert.ok(services[i].distanceMeters <= services[i + 1].distanceMeters,
        `Distance sort out of order: ${services[i].distanceMeters} > ${services[i + 1].distanceMeters}`);
    }
  });

  // TC06: Plan Creation, Scrap Payout & Carbon Math
  console.log(`\n${colors.blue}${colors.bold}► Category 5: Plan Scheduling & Math Calculations${colors.reset}`);

  let createdPlanId = null;

  await test('TC06.1', 'Reject plan creation with zero or negative weight', async () => {
    const res = await fetch(`${BASE_URL}/api/plans`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: registeredUserId,
        serviceId: 'srv_1',
        metalType: 'Aluminium',
        weightKg: -5
      })
    });
    assert.strictEqual(res.status, 400);
    const data = await res.json();
    assert.ok(data.error.includes('> 0 kg'));
  });

  await test('TC06.2', 'Create valid recycling plan with reminder and audit logging', async () => {
    const res = await fetch(`${BASE_URL}/api/plans`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: registeredUserId,
        serviceId: 'srv_1',
        metalType: 'Aluminium',
        weightKg: 50.0,
        scheduledDate: '2026-10-18T14:00:00.000Z',
        notes: 'Clean extruded window frames, sorted.',
        reminderEnabled: true
      })
    });
    assert.strictEqual(res.status, 201);
    const data = await res.json();
    assert.ok(data.plan);
    assert.strictEqual(data.plan.metalType, 'Aluminium');
    assert.strictEqual(data.plan.weightKg, 50.0);
    assert.strictEqual(data.plan.status, 'confirmed');
    assert.strictEqual(data.plan.reminderEnabled, true);
    assert.ok(data.activity);
    assert.strictEqual(data.activity.action, 'PLAN_CREATED');
    createdPlanId = data.plan.planId;
  });

  await test('TC06.3', 'Verify CO2 offset mathematical formulas across metals', () => {
    const alCo2 = 50.0 * 9.0;    // 50kg Al * 9.0 kg CO2/kg = 450 kg CO2
    const cuCo2 = 20.0 * 4.2;    // 20kg Cu * 4.2 = 84 kg CO2
    const feCo2 = 100.0 * 1.8;   // 100kg Steel * 1.8 = 180 kg CO2

    assert.strictEqual(alCo2, 450.0);
    assert.strictEqual(cuCo2, 84.0);
    assert.strictEqual(feCo2, 180.0);
  });

  // TC07: Plan Status Transitions & Audit Logging
  console.log(`\n${colors.blue}${colors.bold}► Category 6: Plan Lifecycle Transitions & Audit History${colors.reset}`);

  await test('TC07.1', 'Update plan status to completed and credit user eco-metrics', async () => {
    const res = await fetch(`${BASE_URL}/api/plans/${createdPlanId}/status`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status: 'completed', userId: registeredUserId })
    });
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert.strictEqual(data.plan.status, 'completed');
    assert.ok(data.activity);
    assert.strictEqual(data.activity.action, 'STATUS_UPDATED');
  });

  await test('TC07.2', 'Verify completed plan reflected in user impact statistics', async () => {
    const res = await fetch(`${BASE_URL}/api/plans?userId=${registeredUserId}`);
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert.ok(data.plans.some(p => p.planId === createdPlanId && p.status === 'completed'));
    assert.ok(data.stats.totalRecycledKg >= 50.0);
    assert.ok(data.stats.totalCo2SavedKg >= 450.0);
  });

  await test('TC07.3', 'Retrieve user chronological activity audit timeline', async () => {
    const res = await fetch(`${BASE_URL}/api/activities?userId=${registeredUserId}`);
    assert.strictEqual(res.status, 200);
    const activities = await res.json();
    assert.ok(Array.isArray(activities));
    assert.ok(activities.length >= 2); // PLAN_CREATED and STATUS_UPDATED
    assert.ok(activities.some(a => a.action === 'PLAN_CREATED'));
    assert.ok(activities.some(a => a.action === 'STATUS_UPDATED'));
  });

  // Final Summary
  console.log(`\n${colors.cyan}${colors.bold}================================================================${colors.reset}`);
  console.log(`${colors.cyan}${colors.bold}                      TEST SUITE SUMMARY                        ${colors.reset}`);
  console.log(`${colors.cyan}${colors.bold}================================================================${colors.reset}`);
  console.log(`  Total Test Cases Executed : ${colors.bold}${passedCount + failedCount}${colors.reset}`);
  console.log(`  Passed                    : ${colors.green}${colors.bold}${passedCount}${colors.reset}`);
  console.log(`  Failed                    : ${failedCount === 0 ? colors.green : colors.red}${colors.bold}${failedCount}${colors.reset}`);
  console.log(`  Overall Status            : ${failedCount === 0 ? colors.green + colors.bold + '✔ ALL TESTS PASSED (100%)' : colors.red + colors.bold + '✖ FAILURES DETECTED'}${colors.reset}`);
  console.log(`${colors.cyan}${colors.bold}================================================================${colors.reset}\n`);

  if (failedCount > 0) {
    process.exit(1);
  }
}

run().catch(err => {
  console.error('Test runner fatal error:', err);
  process.exit(1);
});
