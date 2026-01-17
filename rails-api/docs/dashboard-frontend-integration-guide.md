# Dashboard Frontend Integration Guide

## Epic 15: Progress Dashboard - Complete Implementation

This guide provides comprehensive instructions for integrating the Progress Dashboard backend with your frontend application.

---

## Table of Contents

1. [API Endpoints](#api-endpoints)
2. [Chart.js Integration](#chartjs-integration)
3. [Action Cable (WebSocket) Integration](#action-cable-integration)
4. [Widget System](#widget-system)
5. [JavaScript Controllers](#javascript-controllers)
6. [Example Implementation](#example-implementation)

---

## API Endpoints

### Dashboard Statistics

#### GET /dashboard/statistics
Get statistics for a specific period.

**Parameters:**
- `period` (optional): `day`, `week`, `month`, `year` (default: `week`)

**Response:**
```json
{
  "success": true,
  "period": "week",
  "data": {
    "week_start": "2026-01-13",
    "week_end": "2026-01-19",
    "sessions_count": 15,
    "questions_answered": 450,
    "correct_answers": 360,
    "study_time_hours": 12.5,
    "average_score": 80.0,
    "daily_breakdown": [...],
    "improvement_rate": 5.2
  }
}
```

#### GET /dashboard/progress
Get overall progress or progress for a specific study set.

**Parameters:**
- `study_set_id` (optional): ID of specific study set

**Response:**
```json
{
  "success": true,
  "data": {
    "total_concepts": 250,
    "mastered_concepts": 120,
    "weak_concepts": 30,
    "untested_concepts": 100,
    "mastery_percentage": 48.0,
    "progress_by_study_set": [...]
  }
}
```

#### GET /dashboard/charts
Get chart data for visualization.

**Parameters:**
- `type` (required): `line`, `bar`, `radar`, `doughnut`, `scatter`, `heatmap`, `area`, `all`
- `period` (optional): `week`, `month`, `year`
- `weeks` (optional): Number of weeks for heatmap (default: 12)

**Response:**
```json
{
  "success": true,
  "type": "line",
  "data": {
    "type": "line",
    "data": {
      "labels": ["01/13", "01/14", "01/15", ...],
      "datasets": [...]
    },
    "options": {...}
  }
}
```

#### GET /dashboard/achievements
Get user achievements and badges.

**Response:**
```json
{
  "success": true,
  "data": {
    "total_points": 1250,
    "level": 13,
    "badges": [
      {
        "name": "First Steps",
        "description": "Completed first test"
      }
    ],
    "milestones": [...],
    "next_milestone": {...}
  }
}
```

#### GET /dashboard/predictions
Get AI predictions for performance.

**Response:**
```json
{
  "success": true,
  "predictions": {
    "next_score": 85.5,
    "next_score_range": [80.5, 90.5],
    "days_to_full_mastery": 45,
    "estimated_completion_date": "2026-03-01",
    "confidence": 78.5
  }
}
```

#### POST /dashboard/export
Export dashboard report.

**Parameters:**
- `format`: `pdf`, `csv`, `json`
- `period`: `day`, `week`, `month`, `year`

**Response:** File download (PDF/CSV) or JSON data

#### GET /dashboard/realtime_status
Get real-time dashboard status.

**Response:**
```json
{
  "success": true,
  "data": {
    "active_sessions": 1,
    "current_streak": 7,
    "pending_notifications": {
      "upcoming_exams": 2,
      "weak_concepts": 5,
      "recommendations": 3,
      "achievements": 1
    },
    "last_update": "2026-01-15T12:00:00Z"
  }
}
```

---

## Widget Management

### GET /widgets
Get all user widgets.

**Parameters:**
- `visible_only` (optional): boolean

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "widget_type": "progress",
      "title": "Overall Progress",
      "position": 0,
      "visible": true,
      "layout": "medium",
      "width": 6,
      "height": 4,
      "configuration": {...}
    }
  ]
}
```

### POST /widgets
Create a new widget.

**Body:**
```json
{
  "widget": {
    "widget_type": "progress",
    "title": "My Progress",
    "position": 0,
    "visible": true,
    "layout": "medium",
    "width": 6,
    "height": 4
  }
}
```

### PATCH /widgets/:id
Update a widget.

### DELETE /widgets/:id
Delete a widget.

### POST /widgets/batch_update
Update multiple widgets at once.

**Body:**
```json
{
  "widgets": [
    {
      "id": 1,
      "position": 0,
      "width": 6,
      "height": 4,
      "visible": true
    }
  ]
}
```

### POST /widgets/reorder
Reorder widgets.

**Body:**
```json
{
  "widget_ids": [3, 1, 5, 2, 4]
}
```

### GET /widgets/presets
Get available widget layout presets.

**Response:**
```json
{
  "success": true,
  "data": {
    "default": [...],
    "analytics_focus": [...],
    "minimal": [...]
  }
}
```

### POST /widgets/apply_preset
Apply a widget preset.

**Body:**
```json
{
  "preset_name": "analytics_focus"
}
```

---

## Chart.js Integration

### Installation

```bash
npm install chart.js chartjs-adapter-date-fns
```

### Basic Chart Setup

```javascript
import Chart from 'chart.js/auto';

// Fetch chart data from API
async function loadChart(chartType) {
  const response = await fetch(`/dashboard/charts?type=${chartType}`);
  const result = await response.json();

  if (result.success) {
    const chartData = result.data;
    const ctx = document.getElementById('myChart').getContext('2d');

    new Chart(ctx, {
      type: chartData.type,
      data: chartData.data,
      options: chartData.options
    });
  }
}

// Load a line chart
loadChart('line');
```

### All 7 Chart Types

#### 1. Line Chart - Performance Trend
```html
<canvas id="performanceChart" width="400" height="200"></canvas>
```

```javascript
async function loadPerformanceChart() {
  const response = await fetch('/dashboard/charts?type=line&period=month');
  const result = await response.json();

  const ctx = document.getElementById('performanceChart').getContext('2d');
  new Chart(ctx, result.data);
}
```

#### 2. Bar Chart - Subject Performance
```html
<canvas id="subjectChart" width="400" height="200"></canvas>
```

```javascript
async function loadSubjectChart() {
  const response = await fetch('/dashboard/charts?type=bar');
  const result = await response.json();

  const ctx = document.getElementById('subjectChart').getContext('2d');
  new Chart(ctx, result.data);
}
```

#### 3. Radar Chart - Capability Analysis
```html
<canvas id="capabilityChart" width="400" height="400"></canvas>
```

```javascript
async function loadCapabilityChart() {
  const response = await fetch('/dashboard/charts?type=radar');
  const result = await response.json();

  const ctx = document.getElementById('capabilityChart').getContext('2d');
  new Chart(ctx, result.data);
}
```

#### 4. Doughnut Chart - Progress Distribution
```html
<canvas id="progressChart" width="300" height="300"></canvas>
```

```javascript
async function loadProgressChart() {
  const response = await fetch('/dashboard/charts?type=doughnut');
  const result = await response.json();

  const ctx = document.getElementById('progressChart').getContext('2d');
  new Chart(ctx, result.data);
}
```

#### 5. Scatter Chart - Difficulty vs Accuracy
```html
<canvas id="difficultyChart" width="400" height="400"></canvas>
```

```javascript
async function loadDifficultyChart() {
  const response = await fetch('/dashboard/charts?type=scatter');
  const result = await response.json();

  const ctx = document.getElementById('difficultyChart').getContext('2d');
  new Chart(ctx, result.data);
}
```

#### 6. Heatmap - Study Activity
```html
<canvas id="heatmapChart" width="600" height="300"></canvas>
```

```javascript
import { MatrixController, MatrixElement } from 'chartjs-chart-matrix';
Chart.register(MatrixController, MatrixElement);

async function loadHeatmapChart() {
  const response = await fetch('/dashboard/charts?type=heatmap&weeks=12');
  const result = await response.json();

  const ctx = document.getElementById('heatmapChart').getContext('2d');
  new Chart(ctx, result.data);
}
```

#### 7. Area Chart - Cumulative Progress
```html
<canvas id="cumulativeChart" width="400" height="200"></canvas>
```

```javascript
async function loadCumulativeChart() {
  const response = await fetch('/dashboard/charts?type=area');
  const result = await response.json();

  const ctx = document.getElementById('cumulativeChart').getContext('2d');
  new Chart(ctx, result.data);
}
```

---

## Action Cable (WebSocket) Integration

### Setup Action Cable Connection

```javascript
import { createConsumer } from "@rails/actioncable"

const cable = createConsumer()

const dashboardChannel = cable.subscriptions.create("DashboardChannel", {
  connected() {
    console.log("Connected to Dashboard Channel");
  },

  disconnected() {
    console.log("Disconnected from Dashboard Channel");
  },

  received(data) {
    console.log("Received:", data);
    handleDashboardUpdate(data);
  },

  // Request statistics update
  requestStatistics() {
    this.perform('request_statistics', {});
  },

  // Request chart update
  requestChart(chartType) {
    this.perform('request_chart', { chart_type: chartType });
  },

  // Request full dashboard refresh
  refreshDashboard() {
    this.perform('refresh_dashboard', {});
  },

  // Toggle widget visibility
  toggleWidget(widgetId) {
    this.perform('toggle_widget', { widget_id: widgetId });
  },

  // Send ping to keep connection alive
  ping() {
    this.perform('ping', {});
  }
});
```

### Handle Real-time Updates

```javascript
function handleDashboardUpdate(data) {
  switch(data.type) {
    case 'initial_data':
      // Initialize dashboard with data
      initializeDashboard(data);
      break;

    case 'statistics_update':
      // Update statistics display
      updateStatistics(data.data);
      break;

    case 'session_completed':
      // Show completion notification
      showSessionCompleted(data.session);
      updateStatistics(data.updated_stats);
      break;

    case 'mastery_updated':
      // Update mastery display
      updateMasteryDisplay(data.mastery);
      break;

    case 'achievement_unlocked':
      // Show achievement animation
      showAchievement(data.achievement);
      break;

    case 'chart_update':
      // Update specific chart
      updateChart(data.chart_type, data.chart_data);
      break;

    case 'widget_created':
    case 'widget_updated':
    case 'widget_deleted':
      // Update widget layout
      updateWidgetLayout();
      break;

    case 'notification':
      // Show notification
      showNotification(data.notification);
      break;
  }
}
```

### Auto-refresh Setup

```javascript
// Refresh statistics every 30 seconds
setInterval(() => {
  dashboardChannel.requestStatistics();
}, 30000);

// Ping every 5 minutes to keep connection alive
setInterval(() => {
  dashboardChannel.ping();
}, 300000);
```

---

## Widget System

### Widget Grid Layout (using Gridstack.js)

```bash
npm install gridstack
```

```html
<div class="grid-stack">
  <!-- Widgets will be added here -->
</div>
```

```javascript
import { GridStack } from 'gridstack';
import 'gridstack/dist/gridstack.min.css';

// Initialize grid
const grid = GridStack.init({
  column: 12,
  cellHeight: 80,
  animate: true,
  draggable: {
    handle: '.widget-header'
  }
});

// Load widgets from API
async function loadWidgets() {
  const response = await fetch('/widgets?visible_only=true');
  const result = await response.json();

  if (result.success) {
    result.data.forEach(widget => {
      addWidget(widget);
    });
  }
}

// Add widget to grid
function addWidget(widgetData) {
  const widgetHTML = `
    <div class="grid-stack-item" gs-id="${widgetData.id}">
      <div class="grid-stack-item-content widget-card">
        <div class="widget-header">
          <h3>${widgetData.title}</h3>
          <button onclick="removeWidget(${widgetData.id})">×</button>
        </div>
        <div class="widget-body" id="widget-${widgetData.id}">
          <!-- Widget content will be loaded here -->
        </div>
      </div>
    </div>
  `;

  grid.addWidget(widgetHTML, {
    x: widgetData.position % 12,
    y: Math.floor(widgetData.position / 12),
    w: widgetData.width,
    h: widgetData.height,
    id: widgetData.id
  });

  // Load widget data
  loadWidgetData(widgetData.id, widgetData.widget_type);
}

// Load widget data
async function loadWidgetData(widgetId, widgetType) {
  const response = await fetch(`/widgets/data/${widgetId}`);
  const result = await response.json();

  if (result.success) {
    renderWidget(widgetId, widgetType, result.data);
  }
}

// Render widget content
function renderWidget(widgetId, widgetType, data) {
  const container = document.getElementById(`widget-${widgetId}`);

  switch(widgetType) {
    case 'progress':
      renderProgressWidget(container, data);
      break;
    case 'recent_scores':
      renderScoresWidget(container, data);
      break;
    case 'weakness_analysis':
      renderWeaknessWidget(container, data);
      break;
    // ... other widget types
  }
}

// Save widget positions after drag
grid.on('change', (event, items) => {
  const updates = items.map(item => ({
    id: item.id,
    position: item.y * 12 + item.x,
    width: item.w,
    height: item.h,
    visible: true
  }));

  fetch('/widgets/batch_update', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
    },
    body: JSON.stringify({ widgets: updates })
  });
});
```

### Widget Templates

```javascript
// Progress Widget
function renderProgressWidget(container, data) {
  container.innerHTML = `
    <div class="progress-widget">
      <div class="stat">
        <span class="label">Total Concepts:</span>
        <span class="value">${data.total_concepts}</span>
      </div>
      <div class="stat">
        <span class="label">Mastered:</span>
        <span class="value">${data.mastered_concepts}</span>
      </div>
      <div class="progress-bar">
        <div class="progress-fill" style="width: ${data.mastery_percentage}%"></div>
      </div>
      <div class="percentage">${data.mastery_percentage}%</div>
    </div>
  `;
}

// Recent Scores Widget
function renderScoresWidget(container, chartData) {
  const canvas = document.createElement('canvas');
  container.innerHTML = '';
  container.appendChild(canvas);

  new Chart(canvas, chartData);
}

// Weakness Analysis Widget
function renderWeaknessWidget(container, weakAreas) {
  const list = weakAreas.map(area => `
    <div class="weak-area">
      <span class="concept">${area.concept}</span>
      <span class="level">${area.mastery_level}</span>
      <span class="attempts">${area.attempts} attempts</span>
    </div>
  `).join('');

  container.innerHTML = `
    <div class="weakness-list">
      <h4>Focus on these areas:</h4>
      ${list}
    </div>
  `;
}
```

---

## JavaScript Controllers (Stimulus)

### Dashboard Controller

```javascript
// app/javascript/controllers/dashboard_controller.js
import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"
import Chart from 'chart.js/auto'

export default class extends Controller {
  static targets = ["statistics", "chart", "widgets"]

  connect() {
    console.log("Dashboard controller connected")
    this.setupWebSocket()
    this.loadInitialData()
    this.startAutoRefresh()
  }

  disconnect() {
    this.stopAutoRefresh()
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  setupWebSocket() {
    const cable = createConsumer()
    this.subscription = cable.subscriptions.create("DashboardChannel", {
      connected: () => {
        console.log("WebSocket connected")
      },

      disconnected: () => {
        console.log("WebSocket disconnected")
      },

      received: (data) => {
        this.handleUpdate(data)
      }
    })
  }

  async loadInitialData() {
    // Load statistics
    const statsResponse = await fetch('/dashboard/statistics?period=week')
    const statsData = await statsResponse.json()
    this.updateStatistics(statsData.data)

    // Load charts
    const chartsResponse = await fetch('/dashboard/charts?type=all')
    const chartsData = await chartsResponse.json()
    this.renderCharts(chartsData.data)
  }

  updateStatistics(data) {
    if (this.hasStatisticsTarget) {
      this.statisticsTarget.innerHTML = `
        <div class="stat-card">
          <h3>Sessions</h3>
          <p class="value">${data.sessions_count}</p>
        </div>
        <div class="stat-card">
          <h3>Avg Score</h3>
          <p class="value">${data.average_score}%</p>
        </div>
        <div class="stat-card">
          <h3>Study Time</h3>
          <p class="value">${data.study_time_hours}h</p>
        </div>
      `
    }
  }

  renderCharts(chartData) {
    // Render each chart type
    Object.keys(chartData).forEach(chartType => {
      const canvas = document.getElementById(`${chartType}-chart`)
      if (canvas) {
        new Chart(canvas, chartData[chartType])
      }
    })
  }

  handleUpdate(data) {
    switch(data.type) {
      case 'statistics_update':
        this.updateStatistics(data.data)
        break
      case 'chart_update':
        this.updateChart(data.chart_type, data.chart_data)
        break
      case 'achievement_unlocked':
        this.showAchievement(data.achievement)
        break
    }
  }

  startAutoRefresh() {
    this.refreshInterval = setInterval(() => {
      this.subscription.perform('request_statistics')
    }, 30000)
  }

  stopAutoRefresh() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
    }
  }

  async exportReport(event) {
    const format = event.target.dataset.format
    const response = await fetch(`/dashboard/export?format=${format}&period=month`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })

    if (response.ok) {
      const blob = await response.blob()
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `dashboard-report.${format}`
      a.click()
    }
  }

  showAchievement(achievement) {
    // Show toast notification
    const toast = document.createElement('div')
    toast.className = 'achievement-toast'
    toast.innerHTML = `
      <h3>🏆 Achievement Unlocked!</h3>
      <p>${achievement.name}: ${achievement.description}</p>
    `
    document.body.appendChild(toast)

    setTimeout(() => {
      toast.classList.add('show')
    }, 100)

    setTimeout(() => {
      toast.classList.remove('show')
      setTimeout(() => toast.remove(), 300)
    }, 3000)
  }
}
```

---

## Complete Example Implementation

### HTML Structure

```html
<!-- app/views/dashboard/index.html.erb -->
<div data-controller="dashboard">
  <!-- Header -->
  <div class="dashboard-header">
    <h1>My Dashboard</h1>
    <div class="actions">
      <button data-action="click->dashboard#exportReport" data-format="pdf">
        Export PDF
      </button>
      <button data-action="click->dashboard#exportReport" data-format="csv">
        Export CSV
      </button>
    </div>
  </div>

  <!-- Statistics Cards -->
  <div class="statistics-grid" data-dashboard-target="statistics">
    <!-- Statistics will be loaded here -->
  </div>

  <!-- Charts Section -->
  <div class="charts-section">
    <div class="chart-container">
      <h2>Performance Trend</h2>
      <canvas id="performance_line-chart"></canvas>
    </div>

    <div class="chart-container">
      <h2>Subject Performance</h2>
      <canvas id="subject_bar-chart"></canvas>
    </div>

    <div class="chart-container">
      <h2>Capability Analysis</h2>
      <canvas id="capability_radar-chart"></canvas>
    </div>

    <div class="chart-container">
      <h2>Progress Distribution</h2>
      <canvas id="progress_doughnut-chart"></canvas>
    </div>
  </div>

  <!-- Custom Widgets Grid -->
  <div class="widgets-section">
    <h2>Custom Dashboard</h2>
    <div class="grid-stack" data-dashboard-target="widgets">
      <!-- Widgets will be loaded here -->
    </div>
  </div>
</div>
```

### CSS Styling

```css
/* dashboard.css */
.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.statistics-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.stat-card {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.stat-card h3 {
  color: #666;
  font-size: 0.875rem;
  margin-bottom: 0.5rem;
}

.stat-card .value {
  font-size: 2rem;
  font-weight: bold;
  color: #333;
}

.charts-section {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 2rem;
  margin-bottom: 2rem;
}

.chart-container {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.chart-container h2 {
  font-size: 1.25rem;
  margin-bottom: 1rem;
}

.widget-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  height: 100%;
  display: flex;
  flex-direction: column;
}

.widget-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  border-bottom: 1px solid #eee;
  cursor: move;
}

.widget-body {
  flex: 1;
  padding: 1rem;
  overflow: auto;
}

.achievement-toast {
  position: fixed;
  top: 20px;
  right: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.2);
  transform: translateX(400px);
  transition: transform 0.3s ease;
  z-index: 1000;
}

.achievement-toast.show {
  transform: translateX(0);
}
```

---

## Testing the Implementation

### 1. Test API Endpoints

```bash
# Get statistics
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/dashboard/statistics?period=week

# Get charts
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/dashboard/charts?type=line

# Get widgets
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/widgets
```

### 2. Test WebSocket Connection

```javascript
// In browser console
const cable = ActionCable.createConsumer()
const subscription = cable.subscriptions.create("DashboardChannel", {
  received(data) {
    console.log("Received:", data)
  }
})

// Request statistics
subscription.perform('request_statistics')
```

### 3. Test Chart Rendering

```javascript
// Load and render a chart
fetch('/dashboard/charts?type=line')
  .then(r => r.json())
  .then(data => {
    const ctx = document.getElementById('myChart').getContext('2d')
    new Chart(ctx, data.data)
  })
```

---

## Performance Optimization

### 1. Chart Update Throttling

```javascript
let chartUpdateTimer = null

function throttleChartUpdate(chartType, delay = 1000) {
  clearTimeout(chartUpdateTimer)
  chartUpdateTimer = setTimeout(() => {
    updateChart(chartType)
  }, delay)
}
```

### 2. Widget Data Caching

```javascript
const widgetDataCache = new Map()
const CACHE_DURATION = 60000 // 1 minute

async function getWidgetData(widgetId, widgetType) {
  const cacheKey = `${widgetId}-${widgetType}`
  const cached = widgetDataCache.get(cacheKey)

  if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
    return cached.data
  }

  const response = await fetch(`/widgets/data/${widgetId}`)
  const result = await response.json()

  widgetDataCache.set(cacheKey, {
    data: result.data,
    timestamp: Date.now()
  })

  return result.data
}
```

### 3. Lazy Loading Charts

```javascript
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const chartType = entry.target.dataset.chartType
      loadChart(chartType)
      observer.unobserve(entry.target)
    }
  })
})

document.querySelectorAll('.chart-container').forEach(container => {
  observer.observe(container)
})
```

---

## Summary

Epic 15 is now 100% complete with:

1. ✅ 7 Chart Types (Line, Bar, Radar, Doughnut, Scatter, Heatmap, Area)
2. ✅ Real-time Updates via Action Cable
3. ✅ 10 Customizable Widgets
4. ✅ Drag & Drop Widget Management
5. ✅ PDF/CSV Report Export
6. ✅ 15+ API Endpoints
7. ✅ Performance Predictions
8. ✅ Advanced Analytics
9. ✅ Comprehensive Frontend Integration

All backend components are implemented and ready for frontend integration.
