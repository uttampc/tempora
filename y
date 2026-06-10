holdon$ ls -R src
src:
assets  components  core  db  main.js  style.css  utils  views

src/assets:
hero.png

src/components:
activityPicker.js  dialog.js  exerciseEditor.js  historyModal.js  modal.js

src/core:
cueManager.js  sessionEngine.js  totals.js

src/db:
cueDefaults.js  importValidation.js  seed.js  store.js

src/utils:
beep.js  format.js  id.js  platform.js  router.js  routineDuration.js  video.js  wakeLock.js

src/views:
aboutSection.js        dataSection.js     player.js         routineEdit.js  settings.js
cueDefaultsSection.js  librarySection.js  routineDetail.js  routineList.js  settingsLibrary.js

$ cat index.html 
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/icon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover, user-scalable=no" />
    <meta name="theme-color" content="#1a1a1a" media="(prefers-color-scheme: dark)" />
    <meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)" />
    <meta name="mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
    <meta name="apple-mobile-web-app-title" content="HoldOn" />
    <meta name="description" content="Simple timers for poses, holds & reps." />
    <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
    <title>HoldOn</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.js"></script>
  </body>
</html>

Following is a snippet from routineDetail.js where it gets routine details (list of activities/exercises) and starts a session

import { getRoutine, deleteRoutine } from '../db/store.js';
import { calculateRoutineDuration, countTotalSets } from '../core/totals.js';
import { formatDuration } from '../utils/format.js';
import { parseVideoUrl } from '../utils/video.js';
import { router } from '../utils/router.js';
import { confirmModal, alertModal } from '../components/dialog.js';
import { unlockAudio } from '../utils/beep.js';
import { openHistoryModal } from '../components/historyModal.js';

/**
 * Renders the routine detail view.
 * @param {HTMLElement} container
 * @param {string} routineId
 */
export async function renderRoutineDetail(container, routineId) {
...
 container.innerHTML = `
    <main class="container">
      <header class="screen-header">
        <button class="btn-link" id="back-btn">← Back</button>
        <h2>${escapeHtml(routine.title)}</h2>
        <button class="btn-link" id="edit-btn">Edit</button>
      </header>

      ${routine.description ? `<p class="routine-detail-desc">${escapeHtml(routine.description)}</p>` : ''}

      <section class="summary-card">
        <div class="summary-stat">
          <div class="summary-stat-value">${exerciseCount}</div>
          <div class="summary-stat-label">exercise${exerciseCount === 1 ? '' : 's'}</div>
        </div>
        <div class="summary-stat-divider"></div>
        <div class="summary-stat">
          <div class="summary-stat-value">${totalSets}</div>
          <div class="summary-stat-label">total set${totalSets === 1 ? '' : 's'}</div>
        </div>
        <div class="summary-stat-divider"></div>
        <div class="summary-stat">
          <div class="summary-stat-value">~${formatDuration(duration)}</div>
          <div class="summary-stat-label">duration</div>
        </div>
      </section>

      ${exerciseCount === 0 ? renderEmptyExercises() : renderExerciseList(routine.exercises)}

      <div class="primary-action">
        <div class="routine-actions-group">
          <button class="btn btn-primary btn-large" id="start-btn" ${exerciseCount === 0 ? 'disabled' : ''}>
            ▶ Start Session
          </button>
          <button class="btn btn-secondary" id="history-btn">
            <span class="btn-icon">📊</span>
            <span>History</span>
          </button>
        </div>
      </div>
     <div class="danger-action">
        <button class="btn btn-danger" id="delete-btn">Delete Routine</button>
      </div>
    </main>
  `;

  // Wire up handlers
  container.querySelector('#back-btn').addEventListener('click', () => router.navigate('/'));
  container.querySelector('#edit-btn').addEventListener('click', () => {
    router.navigate(`/routine/${routine.id}/edit`);
  });

  container.querySelector('#start-btn').addEventListener('click', async () => {
    if (exerciseCount === 0) {
      await alertModal({
        title: 'No exercises',
        message: 'Add at least one activity before starting.',
      });
    }
    unlockAudio();
    router.navigate(`/play/${routine.id}`);
  });
...
}


From main.js
import { renderPlayer, cleanupEngine as cleanupPlayer } from './views/player.js';
async function init() {
  try {
    await seedIfNeeded();
...
 router.register('/play/:routineId', async (params) => {
      await renderPlayer(app, params.routineId);
    });
}

renderPlayer() uses acquireLock() function from wakelock.js
import { acquireWakeLock, releaseWakeLock } from '../utils/wakeLock.js';
...
And here is existing wakelock.js 

**
 * HoldOn — Screen Wake Lock helper
 *
 * Keeps the screen on during a workout. Gracefully no-ops on
 * browsers without Wake Lock API support (older Safari, some Firefox versions).
 */

let currentLock = null;

/**
 * Tries to acquire a screen wake lock. Safe to call multiple times.
 * Returns true if acquired (or already held), false if unsupported/failed.
 */
export async function acquireWakeLock() {
  if (typeof navigator === 'undefined' || !('wakeLock' in navigator)) {
    console.log('[WakeLock] Not supported in this browser');
    return false;
  }

  if (currentLock && !currentLock.released) {
    return true;  // already held
  }

  try {
    currentLock = await navigator.wakeLock.request('screen');
    console.log('[WakeLock] Acquired');

    currentLock.addEventListener('release', () => {
      console.log('[WakeLock] Released by system');
    });

    return true;
  } catch (err) {
    console.warn('[WakeLock] Could not acquire:', err.message);
    currentLock = null;
    return false;
  }
}

/**
 * Releases any held wake lock. Safe to call when no lock is held.
 */
export async function releaseWakeLock() {
  if (!currentLock) return;
  try {
    await currentLock.release();
    console.log('[WakeLock] Released');
  } catch (err) {
    console.warn('[WakeLock] Release failed:', err);
  }
  currentLock = null;
}

/**
 * Returns true if a wake lock is currently held.
 */
export function hasWakeLock() {
  return currentLock !== null && !currentLock.released;
}

/**
 * Returns true if the Wake Lock API is available in this browser.
 * Used to decide whether to show "browser doesn't support" hints.
 */
export function isWakeLockSupported() {
  return typeof navigator !== 'undefined' && 'wakeLock' in navigator;
}


