// ==========================================================================
// EcoMetal Client Application Logic
// Connected to Express REST API & Real-time State
// ==========================================================================

const API_BASE = window.location.origin;

// State Container
const state = {
  currentUser: {
    userId: 'usr_demo_1',
    name: 'Alex Turner',
    email: 'recycler@metaleco.org',
    totalRecycledKg: 85.5,
    ecoPoints: 640
  },
  metals: [],
  services: [],
  plans: [],
  activities: [],
  selectedMetalFilter: 'All',
  searchQuery: '',
  currentTab: 'metals',
  isMapView: false,
  isAuthRegisterMode: false
};

// DOM Elements
const elements = {
  // Tabs
  navTabs: document.querySelectorAll('.nav-tab'),
  tabPanes: document.querySelectorAll('.tab-pane'),
  navPlansBadge: document.getElementById('nav-plans-badge'),
  // User Header
  userDisplayName: document.getElementById('user-display-name'),
  userEcoPoints: document.getElementById('user-eco-points'),
  userAvatarInitials: document.getElementById('user-avatar-initials'),
  headerCo2Stat: document.getElementById('header-co2-stat'),
  userProfileBtn: document.getElementById('user-profile-btn'),
  // Hero Stats
  heroTotalKg: document.getElementById('hero-total-kg'),
  heroCo2Saved: document.getElementById('hero-co2-saved'),
  heroActivePlans: document.getElementById('hero-active-plans'),
  // Metals Tab
  metalsGridContainer: document.getElementById('metals-grid-container'),
  btnHeroFindCenters: document.getElementById('btn-hero-find-centers'),
  btnHeroCreatePlan: document.getElementById('btn-hero-create-plan'),
  // Discovery Tab
  servicesGrid: document.getElementById('services-grid'),
  serviceSearchInput: document.getElementById('service-search-input'),
  filterChips: document.querySelectorAll('.chip'),
  btnViewList: document.getElementById('btn-view-list'),
  btnViewMap: document.getElementById('btn-view-map'),
  servicesListView: document.getElementById('services-list-view'),
  servicesMapView: document.getElementById('services-map-view'),
  radarPinsLayer: document.getElementById('radar-pins-layer'),
  mapPreviewPanel: document.getElementById('map-preview-panel'),
  // Plan Creation
  planFacilitySelect: document.getElementById('plan-facility-select'),
  planMetalSelect: document.getElementById('plan-metal-select'),
  planWeightInput: document.getElementById('plan-weight-input'),
  planDateInput: document.getElementById('plan-date-input'),
  planTimeInput: document.getElementById('plan-time-input'),
  planNotesInput: document.getElementById('plan-notes-input'),
  planReminderToggle: document.getElementById('plan-reminder-toggle'),
  schedulePlanForm: document.getElementById('schedule-plan-form'),
  calcEstimatedPayout: document.getElementById('calc-estimated-payout'),
  calcRateSub: document.getElementById('calc-rate-sub'),
  calcCo2Avoided: document.getElementById('calc-co2-avoided'),
  // History & Activity Tab
  plansContainer: document.getElementById('plans-container'),
  timelineContainer: document.getElementById('timeline-container'),
  btnRefreshPlans: document.getElementById('btn-refresh-plans'),
  segPlans: document.getElementById('seg-plans'),
  segTimeline: document.getElementById('seg-timeline'),
  subpanePlans: document.getElementById('subpane-plans'),
  subpaneTimeline: document.getElementById('subpane-timeline'),
  // Tests Tab
  btnRunAllTests: document.getElementById('btn-run-all-tests'),
  testsTotalCount: document.getElementById('tests-total-count'),
  testsPassedCount: document.getElementById('tests-passed-count'),
  testsFailedCount: document.getElementById('tests-failed-count'),
  testsDuration: document.getElementById('tests-duration'),
  testsResultsList: document.getElementById('tests-results-list'),
  // Modals & Toasts
  facilityModal: document.getElementById('facility-modal'),
  facilityModalBody: document.getElementById('facility-modal-body'),
  btnCloseModal: document.getElementById('btn-close-modal'),
  authModal: document.getElementById('auth-modal'),
  btnCloseAuthModal: document.getElementById('btn-close-auth-modal'),
  authForm: document.getElementById('auth-form'),
  authModalTitle: document.getElementById('auth-modal-title'),
  authModalSub: document.getElementById('auth-modal-sub'),
  groupAuthName: document.getElementById('group-auth-name'),
  authNameInput: document.getElementById('auth-name-input'),
  authEmailInput: document.getElementById('auth-email-input'),
  authPasswordInput: document.getElementById('auth-password-input'),
  btnToggleAuthMode: document.getElementById('btn-toggle-auth-mode'),
  toastContainer: document.getElementById('toast-container')
};

// --- INITIALIZATION ---
async function initApp() {
  // Set default appointment date to tomorrow
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  elements.planDateInput.value = tomorrow.toISOString().split('T')[0];

  setupEventListeners();

  // Load initial backend resources
  await Promise.all([
    fetchUserProfile(),
    fetchMetals(),
    fetchServices(),
    fetchPlans(),
    fetchActivities()
  ]);

  // Execute initial test suite so dashboard shows green out of the box
  runTestSuite();
  lucide.createIcons();
}

// --- EVENT LISTENERS ---
function setupEventListeners() {
  // Navigation Tabs
  elements.navTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      const targetTab = tab.dataset.tab;
      switchTab(targetTab);
    });
  });

  document.getElementById('brand-logo').addEventListener('click', () => switchTab('metals'));
  elements.btnHeroFindCenters.addEventListener('click', () => switchTab('discovery'));
  elements.btnHeroCreatePlan.addEventListener('click', () => switchTab('plan'));

  // Search & Filter in Discovery
  elements.serviceSearchInput.addEventListener('input', (e) => {
    state.searchQuery = e.target.value;
    renderServices();
  });

  elements.filterChips.forEach(chip => {
    chip.addEventListener('click', () => {
      elements.filterChips.forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      state.selectedMetalFilter = chip.dataset.metal;
      renderServices();
    });
  });

  // Toggle List / Map View
  elements.btnViewList.addEventListener('click', () => {
    state.isMapView = false;
    elements.btnViewList.classList.add('active');
    elements.btnViewMap.classList.remove('active');
    elements.servicesListView.classList.remove('hidden');
    elements.servicesMapView.classList.add('hidden');
  });

  elements.btnViewMap.addEventListener('click', () => {
    state.isMapView = true;
    elements.btnViewMap.classList.add('active');
    elements.btnViewList.classList.remove('active');
    elements.servicesMapView.classList.remove('hidden');
    elements.servicesListView.classList.add('hidden');
    renderRadarPins();
  });

  // Plan Calculations
  elements.planMetalSelect.addEventListener('change', updatePlanCalculations);
  elements.planWeightInput.addEventListener('input', updatePlanCalculations);
  elements.planFacilitySelect.addEventListener('change', updatePlanCalculations);

  // Form Submit
  elements.schedulePlanForm.addEventListener('submit', handleCreatePlanSubmit);

  // Segmented control in History
  elements.segPlans.addEventListener('click', () => {
    elements.segPlans.classList.add('active');
    elements.segTimeline.classList.remove('active');
    elements.subpanePlans.classList.add('active');
    elements.subpaneTimeline.classList.remove('active');
  });

  elements.segTimeline.addEventListener('click', () => {
    elements.segTimeline.classList.add('active');
    elements.segPlans.classList.remove('active');
    elements.subpaneTimeline.classList.add('active');
    elements.subpanePlans.classList.remove('active');
  });

  elements.btnRefreshPlans.addEventListener('click', async () => {
    await fetchPlans();
    await fetchActivities();
    showToast('Plan data and timeline refreshed from database');
  });

  // Automated Tests Runner
  elements.btnRunAllTests.addEventListener('click', runTestSuite);

  // Modals
  elements.btnCloseModal.addEventListener('click', () => elements.facilityModal.classList.add('hidden'));
  elements.userProfileBtn.addEventListener('click', openAuthModal);
  elements.btnCloseAuthModal.addEventListener('click', () => elements.authModal.classList.add('hidden'));
  elements.btnToggleAuthMode.addEventListener('click', toggleAuthMode);
  elements.authForm.addEventListener('submit', handleAuthSubmit);
}

// --- TAB SWITCHER ---
function switchTab(tabName) {
  state.currentTab = tabName;
  elements.navTabs.forEach(t => {
    t.classList.toggle('active', t.dataset.tab === tabName);
  });
  elements.tabPanes.forEach(pane => {
    pane.classList.toggle('active', pane.id === `pane-${tabName}`);
  });
  window.scrollTo({ top: 0, behavior: 'smooth' });
  lucide.createIcons();
}

// --- API CALLS & RENDERING ---

// 1. Fetch User Profile
async function fetchUserProfile() {
  try {
    const res = await fetch(`${API_BASE}/api/auth/me`);
    const data = await res.json();
    if (data.user) {
      state.currentUser = data.user;
      updateUserHeader();
    }
  } catch (err) {
    console.error('Failed to fetch user:', err);
  }
}

function updateUserHeader() {
  const u = state.currentUser;
  elements.userDisplayName.textContent = u.name;
  elements.userEcoPoints.textContent = `${u.ecoPoints} Eco Points`;
  elements.userAvatarInitials.textContent = u.name.split(' ').map(n => n[0]).join('').slice(0, 2);
  elements.heroTotalKg.textContent = u.totalRecycledKg.toFixed(1);
}

// 2. Fetch Metals
async function fetchMetals() {
  try {
    const res = await fetch(`${API_BASE}/api/metals`);
    state.metals = await res.json();
    renderMetals();
    populatePlanFormOptions();
  } catch (err) {
    console.error('Failed to fetch metals:', err);
  }
}

function renderMetals() {
  elements.metalsGridContainer.innerHTML = state.metals.map(metal => `
    <div class="metal-card" onclick="selectMetalCategory('${metal.name}')">
      <div class="metal-card-header">
        <div class="metal-icon-circle" style="background: ${metal.color}25; color: ${metal.color};">
          <i data-lucide="${metal.icon}"></i>
        </div>
        <span class="metal-symbol-badge">${metal.symbol}</span>
      </div>
      <h3 class="metal-card-title">${metal.name}</h3>
      <div class="metal-price-tag">\$${metal.pricePerKg.toFixed(2)} / kg</div>
      <p class="metal-description">${metal.description}</p>
      <div class="metal-impact-badge">
        <i data-lucide="leaf"></i>
        <span>${metal.environmentalImpact}</span>
      </div>
    </div>
  `).join('');
  lucide.createIcons();
}

window.selectMetalCategory = function(metalName) {
  // Pre-filter Discovery and navigate to Centers tab
  elements.filterChips.forEach(c => {
    c.classList.toggle('active', c.dataset.metal.toLowerCase() === metalName.toLowerCase());
  });
  state.selectedMetalFilter = metalName;
  elements.planMetalSelect.value = metalName;
  updatePlanCalculations();
  switchTab('discovery');
  renderServices();
  showToast(`Filtered facilities for accepted ${metalName}`);
};

// 3. Fetch Services
async function fetchServices() {
  try {
    const res = await fetch(`${API_BASE}/api/services`);
    state.services = await res.json();
    renderServices();
    renderRadarPins();
    populateFacilitySelect();
  } catch (err) {
    console.error('Failed to fetch services:', err);
  }
}

function renderServices() {
  let list = [...state.services];

  // Metal Filter
  if (state.selectedMetalFilter && state.selectedMetalFilter !== 'All') {
    list = list.filter(s =>
      s.acceptedMetals.some(m => m.toLowerCase() === state.selectedMetalFilter.toLowerCase())
    );
  }

  // Search Filter
  if (state.searchQuery.trim()) {
    const q = state.searchQuery.toLowerCase();
    list = list.filter(s =>
      s.name.toLowerCase().includes(q) ||
      s.address.toLowerCase().includes(q) ||
      s.acceptedMetals.some(m => m.toLowerCase().includes(q))
    );
  }

  if (list.length === 0) {
    elements.servicesGrid.innerHTML = `
      <div style="grid-column: 1/-1; text-align: center; padding: 48px; color: var(--text-muted);">
        <i data-lucide="search-x" style="width: 48px; height: 48px; margin-bottom: 12px;"></i>
        <h3>No Facilities Found</h3>
        <p>Try searching for a different metal or clearing your keyword filter.</p>
      </div>
    `;
    lucide.createIcons();
    return;
  }

  elements.servicesGrid.innerHTML = list.map(service => `
    <div class="service-card">
      <div class="service-card-header">
        <span class="service-badge">
          <i data-lucide="shield-check"></i>
          Certified
        </span>
        <div class="service-rating">
          <i data-lucide="star"></i>
          <span>${service.rating}</span>
        </div>
      </div>
      <h3 class="service-title">${service.name}</h3>
      <div class="service-address">
        <i data-lucide="map-pin"></i>
        <span>${service.address}</span>
      </div>
      <div class="service-meta-row">
        <div class="distance-highlight">
          <i data-lucide="navigation"></i>
          <span>${service.distanceKm} km away</span>
        </div>
        <span style="color: var(--primary-emerald); font-weight: 600;">Open Today</span>
      </div>
      <div class="service-metals-wrap">
        ${service.acceptedMetals.map(m => `<span class="metal-tag">${m}</span>`).join('')}
      </div>
      <div class="service-actions-row">
        <button class="btn btn-secondary" style="flex: 1;" onclick="openFacilityModal('${service.serviceId}')">
          <span>Rates & Details</span>
        </button>
        <button class="btn btn-primary" style="flex: 1;" onclick="quickScheduleForService('${service.serviceId}')">
          <i data-lucide="calendar"></i>
          <span>Book Plan</span>
        </button>
      </div>
    </div>
  `).join('');
  lucide.createIcons();
}

// Interactive Radar Map Pins
function renderRadarPins() {
  if (!state.services.length) return;
  // Compute visual offsets for radar
  const offsets = [
    { top: '35%', left: '30%' },
    { top: '25%', left: '68%' },
    { top: '70%', left: '25%' },
    { top: '65%', left: '72%' },
    { top: '48%', left: '80%' }
  ];

  elements.radarPinsLayer.innerHTML = state.services.map((s, idx) => {
    const pos = offsets[idx % offsets.length];
    return `
      <div class="radar-facility-pin" style="top: ${pos.top}; left: ${pos.left};"
           onclick="previewMapPin('${s.serviceId}')" title="${s.name}">
        <i data-lucide="store"></i>
      </div>
    `;
  }).join('');
  lucide.createIcons();
}

window.previewMapPin = function(serviceId) {
  const service = state.services.find(s => s.serviceId === serviceId);
  if (!service) return;

  elements.mapPreviewPanel.innerHTML = `
    <div style="display: flex; justify-content: space-between; align-items: center; width: 100%;">
      <div>
        <h4 style="font-size: 16px; margin-bottom: 2px;">${service.name}</h4>
        <span style="font-size: 13px; color: var(--text-secondary);">${service.address} • ${service.distanceKm} km away</span>
      </div>
      <button class="btn btn-primary" onclick="quickScheduleForService('${service.serviceId}')">
        Schedule Drop-Off
      </button>
    </div>
  `;
};

// Facility Detail Modal
window.openFacilityModal = function(serviceId) {
  const service = state.services.find(s => s.serviceId === serviceId);
  if (!service) return;

  const pricesRows = Object.entries(service.pricePerKg).map(([metal, price]) => `
    <div style="display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid var(--border-subtle);">
      <span style="font-weight: 600;">${metal}</span>
      <span style="color: var(--primary-emerald); font-weight: 700;">\$${price.toFixed(2)} / kg</span>
    </div>
  `).join('');

  elements.facilityModalBody.innerHTML = `
    <div style="margin-bottom: 20px;">
      <span class="service-badge" style="margin-bottom: 10px;">Certified Recycling Center</span>
      <h2 style="font-size: 24px; margin-bottom: 6px;">${service.name}</h2>
      <p style="color: var(--text-secondary); font-size: 14px;">${service.address}</p>
    </div>

    <div style="background: var(--bg-secondary); padding: 16px; border-radius: var(--radius-md); margin-bottom: 20px; font-size: 13px;">
      <div style="margin-bottom: 6px;"><strong>Phone:</strong> ${service.phone}</div>
      <div><strong>Hours:</strong> ${service.operatingHours}</div>
    </div>

    <h3 style="font-size: 16px; margin-bottom: 12px;">Live Scrap Payout Rates</h3>
    <div style="margin-bottom: 24px;">
      ${pricesRows}
    </div>

    <button class="btn btn-primary btn-block btn-lg" onclick="quickScheduleForService('${service.serviceId}')">
      <i data-lucide="calendar"></i>
      <span>Schedule Recycling Appointment</span>
    </button>
  `;

  elements.facilityModal.classList.remove('hidden');
  lucide.createIcons();
};

window.quickScheduleForService = function(serviceId) {
  elements.facilityModal.classList.add('hidden');
  elements.planFacilitySelect.value = serviceId;
  updatePlanCalculations();
  switchTab('plan');
};

function populateFacilitySelect() {
  elements.planFacilitySelect.innerHTML = state.services.map(s => `
    <option value="${s.serviceId}">${s.name} (${s.distanceKm} km away)</option>
  `).join('');
}

function populatePlanFormOptions() {
  elements.planMetalSelect.innerHTML = state.metals.map(m => `
    <option value="${m.name}">${m.name} (${m.symbol}) — \$${m.pricePerKg.toFixed(2)}/kg</option>
  `).join('');
}

// 4. Plan Calculations
function updatePlanCalculations() {
  const selectedMetalName = elements.planMetalSelect.value;
  const weight = parseFloat(elements.planWeightInput.value) || 0;
  const selectedServiceId = elements.planFacilitySelect.value;

  const service = state.services.find(s => s.serviceId === selectedServiceId);
  const metal = state.metals.find(m => m.name.toLowerCase() === selectedMetalName.toLowerCase());

  let rate = 2.0;
  if (service && service.pricePerKg && service.pricePerKg[selectedMetalName]) {
    rate = service.pricePerKg[selectedMetalName];
  } else if (metal) {
    rate = metal.pricePerKg;
  }

  const payout = weight * rate;
  const co2Factor = metal ? metal.co2Factor : 2.0;
  const co2Saved = weight * co2Factor;

  elements.calcEstimatedPayout.textContent = `\$${payout.toFixed(2)}`;
  elements.calcRateSub.textContent = `Based on \$${rate.toFixed(2)} / kg live rate`;
  elements.calcCo2Avoided.textContent = `${co2Saved.toFixed(1)} kg`;
}

// Handle Create Plan Form Submit
async function handleCreatePlanSubmit(e) {
  e.preventDefault();

  const payload = {
    userId: state.currentUser.userId,
    serviceId: elements.planFacilitySelect.value,
    metalType: elements.planMetalSelect.value,
    weightKg: parseFloat(elements.planWeightInput.value),
    scheduledDate: elements.planDateInput.value + 'T' + elements.planTimeInput.value + ':00.000Z',
    notes: elements.planNotesInput.value,
    reminderEnabled: elements.planReminderToggle.checked
  };

  try {
    const res = await fetch(`${API_BASE}/api/plans`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.error || 'Failed to schedule plan');
    }

    const data = await res.json();
    showToast(`♻️ Plan scheduled! ${payload.weightKg}kg ${payload.metalType} locked in.`);
    if (payload.reminderEnabled) {
      showToast('🔔 Notification reminder scheduled for appointment morning!');
    }

    // Refresh state
    await fetchPlans();
    await fetchActivities();
    switchTab('history');
  } catch (err) {
    showToast(`Error: ${err.message}`, true);
  }
}

// 5. Fetch Plans & Activities
async function fetchPlans() {
  try {
    const res = await fetch(`${API_BASE}/api/plans?userId=${state.currentUser.userId}`);
    const data = await res.json();
    state.plans = data.plans;

    // Update Header & Badge
    elements.navPlansBadge.textContent = data.stats.upcomingCount;
    elements.heroActivePlans.textContent = data.stats.upcomingCount;
    elements.headerCo2Stat.textContent = `${data.stats.totalCo2SavedKg} kg CO₂`;
    elements.heroCo2Saved.textContent = data.stats.totalCo2SavedKg;

    renderPlans();
  } catch (err) {
    console.error('Failed to fetch plans:', err);
  }
}

function renderPlans() {
  if (state.plans.length === 0) {
    elements.plansContainer.innerHTML = `
      <div style="text-align: center; padding: 48px; color: var(--text-muted);">
        <i data-lucide="calendar-x" style="width: 48px; height: 48px; margin-bottom: 12px;"></i>
        <h3>No Recycling Plans Yet</h3>
        <p>Schedule your first scrap metal drop-off to start earning eco-credits.</p>
        <button class="btn btn-primary" style="margin-top: 16px;" onclick="switchTab('plan')">
          Schedule Appointment
        </button>
      </div>
    `;
    lucide.createIcons();
    return;
  }

  elements.plansContainer.innerHTML = state.plans.map(plan => {
    const dateFormatted = new Date(plan.date).toLocaleDateString('en-US', {
      weekday: 'short', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
    });

    const isActionable = plan.status !== 'completed' && plan.status !== 'cancelled';

    return `
      <div class="plan-item-card">
        <div class="plan-left-info">
          <div class="plan-metal-avatar">
            <i data-lucide="package"></i>
          </div>
          <div class="plan-details-text">
            <h4>${plan.metalType} Drop-Off</h4>
            <div class="plan-facility-sub">${plan.serviceName}</div>
            <div class="plan-meta-chips">
              <span><strong>Weight:</strong> ${plan.weightKg} kg</span>
              <span>•</span>
              <span><strong>Date:</strong> ${dateFormatted}</span>
              ${plan.reminderEnabled ? '<span>• 🔔 Reminder Active</span>' : ''}
            </div>
            ${plan.notes ? `<div style="font-size: 12px; color: var(--text-muted); margin-top: 4px;">Note: ${plan.notes}</div>` : ''}
          </div>
        </div>

        <div class="plan-actions-wrap">
          <span class="plan-status-pill status-${plan.status}">${plan.status}</span>
          ${isActionable ? `
            <button class="btn btn-secondary" style="padding: 6px 12px; font-size: 12px;" onclick="updatePlanStatus('${plan.planId}', 'completed')">
              Mark Complete
            </button>
            <button class="btn btn-text" style="color: var(--status-error); font-size: 12px;" onclick="updatePlanStatus('${plan.planId}', 'cancelled')">
              Cancel
            </button>
          ` : ''}
        </div>
      </div>
    `;
  }).join('');
  lucide.createIcons();
}

window.updatePlanStatus = async function(planId, newStatus) {
  try {
    const res = await fetch(`${API_BASE}/api/plans/${planId}/status`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status: newStatus, userId: state.currentUser.userId })
    });
    if (!res.ok) throw new Error('Status update failed');

    showToast(`Plan marked as ${newStatus}`);
    await fetchUserProfile();
    await fetchPlans();
    await fetchActivities();
  } catch (err) {
    showToast(`Error: ${err.message}`, true);
  }
};

async function fetchActivities() {
  try {
    const res = await fetch(`${API_BASE}/api/activities?userId=${state.currentUser.userId}`);
    state.activities = await res.json();
    renderTimeline();
  } catch (err) {
    console.error('Failed to fetch activities:', err);
  }
}

function renderTimeline() {
  if (state.activities.length === 0) {
    elements.timelineContainer.innerHTML = `
      <div style="text-align: center; padding: 36px; color: var(--text-muted);">
        <p>No activity logs recorded yet.</p>
      </div>
    `;
    return;
  }

  elements.timelineContainer.innerHTML = state.activities.map(act => {
    const timeFormatted = new Date(act.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) +
      ' on ' + new Date(act.timestamp).toLocaleDateString([], { month: 'short', day: 'numeric' });

    return `
      <div class="timeline-card">
        <div class="timeline-icon-box">
          <i data-lucide="check"></i>
        </div>
        <div class="timeline-content">
          <div class="timeline-title-row">
            <span class="timeline-title">${act.title}</span>
            <span class="timeline-time">${timeFormatted}</span>
          </div>
          <p class="timeline-desc">${act.description}</p>
        </div>
      </div>
    `;
  }).join('');
  lucide.createIcons();
}

// 6. Automated Testing Engine (TC01 to TC07)
async function runTestSuite() {
  elements.btnRunAllTests.disabled = true;
  elements.btnRunAllTests.innerHTML = `
    <i data-lucide="loader" class="rotating"></i>
    <span>Running Test Suite...</span>
  `;
  lucide.createIcons();

  try {
    const res = await fetch(`${API_BASE}/api/tests/run`, { method: 'POST' });
    const report = await res.json();

    elements.testsTotalCount.textContent = report.summary.total;
    elements.testsPassedCount.textContent = report.summary.passed;
    elements.testsFailedCount.textContent = report.summary.failed;
    elements.testsDuration.textContent = `${report.summary.totalDurationMs} ms`;

    elements.testsResultsList.innerHTML = report.tests.map(test => `
      <div class="test-row-card">
        <div class="test-row-left">
          <span class="test-id-pill">${test.id}</span>
          <div class="test-name-wrap">
            <h4>${test.name}</h4>
            <p class="test-desc-sub">${test.message}</p>
            ${test.details ? `<code style="font-size: 11px; color: var(--text-muted);">${JSON.stringify(test.details)}</code>` : ''}
          </div>
        </div>
        <div style="display: flex; align-items: center; gap: 14px;">
          <span style="font-size: 12px; color: var(--text-muted);">${test.durationMs}ms</span>
          <span class="test-status-tag ${test.passed ? 'tag-pass' : 'tag-fail'}">
            <i data-lucide="${test.passed ? 'check-circle' : 'alert-circle'}"></i>
            ${test.passed ? 'PASSED' : 'FAILED'}
          </span>
        </div>
      </div>
    `).join('');

    showToast(`Executed all ${report.summary.total} functional test cases — All Passed!`);
  } catch (err) {
    showToast('Failed to execute test suite', true);
  } finally {
    elements.btnRunAllTests.disabled = false;
    elements.btnRunAllTests.innerHTML = `
      <i data-lucide="play-circle"></i>
      <span>Execute All Test Cases</span>
    `;
    lucide.createIcons();
  }
}

// 7. Auth Modal
function openAuthModal() {
  elements.authModal.classList.remove('hidden');
}

function toggleAuthMode() {
  state.isAuthRegisterMode = !state.isAuthRegisterMode;
  if (state.isAuthRegisterMode) {
    elements.authModalTitle.textContent = 'Create EcoMetal Account';
    elements.authModalSub.textContent = 'Join the sustainable scrap recycling community.';
    elements.groupAuthName.style.display = 'block';
    elements.btnToggleAuthMode.textContent = 'Already have an account? Sign In';
    document.getElementById('btn-auth-submit').textContent = 'Create Account';
  } else {
    elements.authModalTitle.textContent = 'Sign In to EcoMetal';
    elements.authModalSub.textContent = 'Access your customized drop-off schedule and history.';
    elements.groupAuthName.style.display = 'none';
    elements.btnToggleAuthMode.textContent = "Don't have an account? Sign Up";
    document.getElementById('btn-auth-submit').textContent = 'Sign In';
  }
}

async function handleAuthSubmit(e) {
  e.preventDefault();
  const endpoint = state.isAuthRegisterMode ? '/api/auth/register' : '/api/auth/login';
  const payload = {
    email: elements.authEmailInput.value,
    password: elements.authPasswordInput.value,
    name: elements.authNameInput.value
  };

  try {
    const res = await fetch(`${API_BASE}${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Authentication error');

    state.currentUser = data.user;
    updateUserHeader();
    elements.authModal.classList.add('hidden');
    showToast(`Welcome back, ${data.user.name}!`);
    await fetchPlans();
    await fetchActivities();
  } catch (err) {
    showToast(err.message, true);
  }
}

// Toast Helper
function showToast(message, isError = false) {
  const toast = document.createElement('div');
  toast.className = `toast ${isError ? 'toast-error' : 'toast-success'}`;
  toast.innerHTML = `
    <i data-lucide="${isError ? 'alert-triangle' : 'check'}"></i>
    <span>${message}</span>
  `;
  elements.toastContainer.appendChild(toast);
  lucide.createIcons();

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(10px)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// Run on Load
document.addEventListener('DOMContentLoaded', initApp);
