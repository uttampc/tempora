$ cat src/views/player.js
/**
 * Centerline — Session Player (Workout Runner)
 * 
 * Full-screen view that guides user through a workout routine.
 * Step 2.3: Connected to SessionEngine for live timer + phase transitions.
 * 
 * Route: #/play/:routineId
 */

import { getRoutine, getMeta, setMeta, createSession, updateSession, deleteSession } from '../db/store.js';
import { router } from '../utils/router.js';
import { confirmModal, alertModal } from '../components/dialog.js';
import { SessionEngine } from '../core/sessionEngine.js';
import { CueManager } from '../core/cueManager.js';
import { acquireWakeLock, releaseWakeLock } from '../utils/wakeLock.js';
import { openModal, closeModal } from '../components/modal.js';

// Module-level reference to the active engine (for cleanup on navigation away)
let activeEngine = null;
let activeCues = null;
let activeContainer = null;
let activeSession = null;
let activeRoutine = null;
let visibilityHandler = null;
let pauseReason = null;
let unsubscribers = [];

export async function renderPlayer(container, routineId) {
  // Cleanup any previous engine (e.g., user navigated away and came back)
  cleanupEngine();
  
  let routine;
  try {
    routine = await getRoutine(routineId);
  } catch (err) {
    console.error('[Player] Failed to load routine:', err);
    await alertModal({
      title: 'Could not load routine',
      message: err.message || 'The routine could not be found.',
    });
    router.navigate('/');
    return;
  }
  
  if (!routine) {
    await alertModal({
      title: 'Routine not found',
      message: 'This routine no longer exists.',
    });
    router.navigate('/');
    return;
  }
  
  if (!routine.exercises || routine.exercises.length === 0) {
    await alertModal({
      title: 'No exercises',
      message: 'This routine has no exercises. Add some first!',
    });
    router.navigate(`/routine/${routineId}`);
    return;
  }
  // Capture the expected route before showing modal -- used to detect navigation away
  const expectedPath = `#/play/${routineId}`;

  // Show first-time education modal about screen lock behavior
  try {
    const educationShown = await getMeta('wakeLockEducationShown');
    if (!educationShown) {
      const result = await showWakeLockEducation();

      if (location.hash !== expectedPath) {
        console.log('[Player DEBUG] User navigated away during education modal -- aborting workout');
        return;
      }

      if (result.acknowledged) {
        await setMeta('wakeLockEducationShown', true);
      } else {
        console.log('[Player DEBUG] Education modal dismissed via navigation -- NOT setting flag');
      }
    }
  } catch (err) {
    console.warn('[Player] Could not check/show education modal:', err);
  }

  if (location.hash !== expectedPath) {
    console.log('[Player DEBUG] Route changed during setup -- aborting');
    return;
  }

  // Load cue defaults from settings
  let cueSettings = { cueType: 'beep', countdownAnnounce: true, volume: 70 };
  try {
    const saved = await getMeta('cueDefaults');
    //console.log('[Player DEBUG] Raw saved value:', saved);
    if (saved) cueSettings = { ...cueSettings, ...saved };
    //console.log('[Player DEBUG] Final cueSettigs used:', cueSettings);
  } catch (err) {
    console.warn('[Player] Could not load cue defaults, using fallback:', err);
  }
  
  // Create the engine and cue manager
  const engine = new SessionEngine(routine, { prepDuration: 3 });
  const cues = new CueManager(cueSettings);
  //console.log('[Player DEBUG] CueManager internal settings:', cues.settings);
  cues.unlock();  // ensure audio is unlocked (was already unlocked by Start button, but be defensive)
  
  activeEngine = engine;
  activeCues = cues;
  activeContainer = container;
  
  // Initial render with idle state
  renderPlayerUI(container, routine, engine.getState());
    
  // Subscribe to engine events
  const unsubTick = engine.on('tick', (state) => {
    updateTimerOnly(container, state);
    
    // Fire countdown cue at integer seconds in last 3 seconds
    if (!state.isPaused && state.timeRemaining >= 1 && state.timeRemaining <= 3) {
      cues.cueCountdown(state.timeRemaining);
    }
  });
  
  const unsubPhase = engine.on('phaseChange', (data) => {
    if (data.to === 'complete') return;  // handled by 'complete' event
    
    // Track session progress; every transition AWAY from 'work' means a set was
    // completed. 
    if (data.from === 'work' && activeSession) {
      activeSession.setsCompleted += 1;
      // If we just left work AND are starting a non-set rest, that means execise was completed
      if (data.to === 'rest-exercise') {
        activeSession.exercisesCompleted += 1;
      }
    }

    // Fire phase-start cue
    const context = buildCueContext(data, routine);
    cues.cuePhaseStart(data.to, context);
    
    renderPlayerUI(container, routine, data.state);
  });
  
  const unsubComplete = engine.on('complete', async (data) => {
    cues.cueComplete();

    // Release wake lock - workout is done, system should manage screen from here
    releaseWakeLock().catch(() => {});

    // Finalize session record
    if (activeSession) {
      try {
        // Last set just completed + last exercise just completed
        activeSession.setsCompleted += 1;
        activeSession.exercisesCompleted += 1;
        
        const finalized = await updateSession(activeSession.id, {
          completedAt: Date.now(),
          status: 'complete',
          totalElapsed: data.totalElapsed,
          exercisesCompleted: activeSession.exercisesCompleted,
          setsCompleted: activeSession.setsCompleted,
        });
        activeSession = finalized;
        console.log('[Player] Session saved (complete):', finalized);
      } catch (err) {
        console.warn('[Player] Could not save session:', err);
      }
    }
  
    renderCompletionScreen(container, routine, data);
  });
  
  unsubscribers = [unsubTick, unsubPhase, unsubComplete];
  // Create session record
  const totalSets = routine.exercises.reduce((sum, ex) => sum + (ex.sets || 1), 0);
  try {
    activeSession = await createSession({
      routineId: routine.id,
      routineTitle: routine.title,
      totalExercises: routine.exercises.length,
      totalSets,
    });
    console.log('[Player] Session started:', activeSession.id);
  } catch (err) {
    console.warn('[Player] Could not create session record:', err);
    // Continue anyway — workout works without recording
  }

  // Acquire wake lock (best effort)
  await acquireWakeLock();

  // Stash routine so visibility handler can re-order
  activeRoutine = routine;

  // Set up a visibility handler - auto-pause when user backgrounds the app
  visibilityHandler = () => handleVisibilityChange(container);
  document.addEventListener('visibilitychange', visibilityHandler);

  // Start the workout
  engine.start();
}

/**
 * Called when browser tab becomes hidden (background/lock) or visible (return).
 * - On hide: pause the workout (audio cues don't work in background anyway)
 * - On show: re-acquire wake lock; user must manually tap Resume
 */
async function handleVisibilityChange(container) {
  if (!activeEngine) return;

  console.log(`[Player] Visibility changed: ${document.hidden ? 'HIDDEN' : 'VISIBLE'}`);
  if (document.hidden) {
    // Going to background — pause if currently running
    if (activeEngine.isActive() && !activeEngine.isPaused()) {
      console.log('[Player] Backgrounded — auto-pausing');
      activeEngine.pause();
      if (activeCues) activeCues.stop();
      pauseReason = 'visibility';

      // Re-render to show paused state with reason banner
      if (activeRoutine) {
        renderPlayerUI(container, activeRoutine, activeEngine.getState());
      }
    }
 } else {
    // Coming back to foreground
    if (activeEngine.isActive()) {
      // Re-acquire wake lock (system may have released it while backgrounded)
      await acquireWakeLock();

      // Re-render to ensure UI matches current state (banner still visible)
      if (activeRoutine) {
        renderPlayerUI(container, activeRoutine, activeEngine.getState());
      }
    }
  }
}

/**
 * Builds context for cues based on phase transition.
 */
function buildCueContext(phaseChangeData, routine) {
  const state = phaseChangeData.state;
  const exercise = state.currentExercise;
  
  // Detect "new exercise" — when transitioning from rest-exercise or from prep
  const isNewExercise = phaseChangeData.from === 'rest-exercise' 
    || phaseChangeData.from === 'prep'
    || (phaseChangeData.from === 'idle' && phaseChangeData.to === 'prep');
  
  // For rest-exercise, look up the upcoming exercise name
  let nextExerciseName = null;
  if (phaseChangeData.to === 'rest-exercise' && state.currentExerciseIndex < routine.exercises.length - 1) {
    nextExerciseName = routine.exercises[state.currentExerciseIndex + 1].name;
  }
  
  return {
    exercise,
    set: state.currentSet,
    totalSets: exercise ? exercise.sets : 0,
    isNewExercise,
    nextExerciseName,
  };
}

/**
 * Called when navigating away from the player route.
 * Exported so main.js router can invoke it via teardown.
 */
export function cleanupEngine() {
  if (activeEngine) {
    activeEngine.stop();
    activeEngine = null;
  }
  if (activeCues) {
    activeCues.stop();
    activeCues=null;
  }

  // Release wake lock
  releaseWakeLock().catch(() => {});

  if (visibilityHandler) {
    document.removeEventListener('visibilitychange', visibilityHandler);
    visibilityHandler = null;
  }

  // NOTE: activeSession is NOT cleaned up here - it's handled by the exit flow
  // (saved as incomplete or discarded) before navigation
  activeSession = null;
  activeRoutine = null;
  pauseReason = null;
  unsubscribers.forEach((unsub) => {
    try { unsub(); } catch (e) {}
  });
  unsubscribers = [];
  activeContainer = null;
}

// ============================================================
// RENDERING
// ============================================================

/**
 * Full UI re-render (called on phase changes, NOT on every tick).
 */
function renderPlayerUI(container, routine, state) {
  const currentExercise = state.currentExercise;
  const phaseInfo = getPhaseInfo(state.phase);
  const nextUp = getNextUpLabel(routine, state);
  const isPaused = state.isPaused;
  
  container.innerHTML = `
    <div class="player" data-phase="${state.phase}" data-paused="${isPaused ? 'true' : 'false'}">
      <div class="player-top">
        <div class="player-routine-title">${escapeHtml(routine.title)}</div>
        <div class="player-exercise-progress">
          Exercise ${state.currentExerciseIndex + 1} of ${state.totalExercises}
        </div>
      </div>
      
      <div class="player-main">
        ${currentExercise ? `
          <div class="player-exercise-name">${escapeHtml(currentExercise.name)}</div>
          
          ${currentExercise.description ? `
            <div class="exercise-detail-desc">${escapeHtml(currentExercise.description)}</div>
          ` : ''}

          ${currentExercise.sets > 1 ? `
            <div class="player-set-counter">Set ${state.currentSet} of ${currentExercise.sets}</div>
          ` : ''}
          
          <div class="player-phase-label">
            <span class="player-phase-dot"></span>
            ${escapeHtml(phaseInfo.label)}
          </div>
          
          <div class="player-timer" id="player-timer">${formatTime(state.timeRemaining)}</div>
          
          ${nextUp ? `
            <div class="player-next">${escapeHtml(nextUp)}</div>
          ` : ''}
        ` : ''}
               ${isPaused ? `
          <div class="player-paused-banner">
            ⏸ ${escapeHtml(getPausedBannerText())}
          </div>
        ` : ''}
      </div>
      
      <div class="player-controls">
        <button type="button" class="player-control-btn player-pause-btn" id="player-pause-btn">
          <span class="player-control-icon">${isPaused ? '▶' : '⏸'}</span>
          <span class="player-control-label">${isPaused ? 'Resume' : 'Pause'}</span>
        </button>
        <button type="button" class="player-control-btn player-skip-btn" id="player-skip-btn">
          <span class="player-control-icon">⏭</span>
          <span class="player-control-label">Skip</span>
        </button>
        <button type="button" class="player-control-btn player-exit-btn" id="player-exit-btn">
          <span class="player-control-icon">✕</span>
          <span class="player-control-label">Exit</span>
        </button>
      </div>
      <div class="player-hint">🔒 Locking the screen will pause this workout</div>
    </div>
  `;
  
  wirePlayerControls(container, routine);
}

function getPausedBannerText() {
  if (pauseReason === 'visibility') {
    return 'Paused while screen was locked';
  }
  return 'Paused';
}

/**
 * Lightweight update for every tick — only changes the timer text.
 * Avoids re-rendering the whole player on every 100ms tick.
 */
function updateTimerOnly(container, state) {
  const timerEl = container.querySelector('#player-timer');
  if (timerEl) {
    timerEl.textContent = formatTime(state.timeRemaining);
  }
}
function renderCompletionScreenOLD(container, routine, completeData) {
  const totalMinutes = Math.floor(completeData.totalElapsed / 60);
  const totalSeconds = completeData.totalElapsed % 60;
  const timeLabel = totalMinutes > 0
    ? `${totalMinutes}m ${totalSeconds}s`
    : `${totalSeconds}s`;
  
  container.innerHTML = `
    <div class="player player-complete" data-phase="complete">
      <div class="player-main">
        <div class="player-complete-icon">🎉</div>
        <div class="player-complete-title">Workout Complete!</div>
        <div class="player-complete-routine">${escapeHtml(routine.title)}</div>
        
        <div class="player-complete-stats">
          <div class="player-complete-stat">
            <div class="player-complete-stat-value">${timeLabel}</div>
            <div class="player-complete-stat-label">Total Time</div>
          </div>
          <div class="player-complete-stat">
            <div class="player-complete-stat-value">${routine.exercises.length}</div>
            <div class="player-complete-stat-label">Exercise${routine.exercises.length === 1 ? '' : 's'}</div>
          </div>
        </div>
        
        <div class="player-complete-note muted">
          Session recording coming in Step 2.6.
        </div>
      </div>
      
      <div class="player-controls">
        <button type="button" class="player-control-btn player-exit-btn" id="player-complete-done">
          <span class="player-control-icon">✓</span>
          <span class="player-control-label">Done</span>
        </button>
      </div>
    </div>
  `;
  
  container.querySelector('#player-complete-done').addEventListener('click', () => {
    cleanupEngine();
    router.navigate(`/routine/${routine.id}`);
  });
}
function renderCompletionScreen(container, routine, completeData) {
  const totalMinutes = Math.floor(completeData.totalElapsed / 60);
  const totalSeconds = completeData.totalElapsed % 60;
  const timeLabel = totalMinutes > 0
    ? `${totalMinutes}m ${totalSeconds}s`
    : `${totalSeconds}s`;

  const totalSets = routine.exercises.reduce((sum, ex) => sum + (ex.sets || 1), 0);

  container.innerHTML = `
    <div class="player player-complete" data-phase="complete">
      <div class="player-main">
        <div class="player-complete-icon">🎉</div>
        <div class="player-complete-title">Workout Complete!</div>
        <div class="player-complete-routine">${escapeHtml(routine.title)}</div>

        <div class="player-complete-stats">
          <div class="player-complete-stat">
            <div class="player-complete-stat-value">${timeLabel}</div>
            <div class="player-complete-stat-label">Total Time</div>
          </div>
          <div class="player-complete-stat">
            <div class="player-complete-stat-value">${routine.exercises.length}</div>
            <div class="player-complete-stat-label">Exercise${routine.exercises.length === 1 ? '' : 's'}</div>
          </div>
          <div class="player-complete-stat">
            <div class="player-complete-stat-value">${totalSets}</div>
            <div class="player-complete-stat-label">Set${totalSets === 1 ? '' : 's'}</div>
          </div>
        </div>

        <div class="player-complete-note muted">
          Session saved to history.
        </div>
      </div>

      <div class="player-controls">
        <button type="button" class="player-control-btn player-exit-btn" id="player-complete-done">
          <span class="player-control-icon">✓</span>
          <span class="player-control-label">Done</span>
        </button>
      </div>
    </div>
  `;

  container.querySelector('#player-complete-done').addEventListener('click', () => {
    cleanupEngine();
    router.navigate(`/routine/${routine.id}`);
  });
}

function renderCompletionScreen(container, routine, completeData) {
  const totalMinutes = Math.floor(completeData.totalElapsed / 60);
  const totalSeconds = completeData.totalElapsed % 60;
  const timeLabel = totalMinutes > 0
    ? `${totalMinutes}m ${totalSeconds}s`
    : `${totalSeconds}s`;

  const totalSets = routine.exercises.reduce((sum, ex) => sum + (ex.sets || 1), 0);

  container.innerHTML = `
    <div class="player player-complete" data-phase="complete">
      <div class="player-main">
        <div class="player-complete-icon">🎉</div>
        <div class="player-complete-title">Workout Complete!</div>
        <div class="player-complete-routine">${escapeHtml(routine.title)}</div>

        <div class="player-complete-stats">
          <div class="player-complete-stat">
            <div class="player-complete-stat-value">${timeLabel}</div>
            <div class="player-complete-stat-label">Total Time</div>
          </div>
          <div class="player-complete-stat">
            <div class="player-complete-stat-value">${routine.exercises.length}</div>
            <div class="player-complete-stat-label">Exercise${routine.exercises.length === 1 ? '' : 's'}</div>
          </div>
          <div class="player-complete-stat">
            <div class="player-complete-stat-value">${totalSets}</div>
            <div class="player-complete-stat-label">Set${totalSets === 1 ? '' : 's'}</div>
          </div>
        </div>

        <div class="player-complete-note muted">
          Session saved to history.
        </div>
      </div>

      <div class="player-controls">
        <button type="button" class="player-control-btn player-exit-btn" id="player-complete-done">
          <span class="player-control-icon">✓</span>
          <span class="player-control-label">Done</span>
        </button>
      </div>
    </div>
  `;

  container.querySelector('#player-complete-done').addEventListener('click', () => {
    cleanupEngine();
    router.navigate(`/routine/${routine.id}`);
  });
}
// ============================================================
// CONTROLS
// ============================================================

function wirePlayerControls(container, routine) {
  const pauseBtn = container.querySelector('#player-pause-btn');
  const skipBtn = container.querySelector('#player-skip-btn');
  const exitBtn = container.querySelector('#player-exit-btn');
  
  if (pauseBtn) {
    pauseBtn.addEventListener('click', () => {
      if (!activeEngine) return;
      if (activeEngine.isPaused()) {
        activeEngine.resume();
        pauseReason = null; // clear reason on resume
      } else {
        activeEngine.pause();
        if (activeCues) activeCues.stop(); // Stop any in-progress speech
        pauseReason = 'manual'; // user explicitly paused
      }

      // Re-render to reflect new pause state
      renderPlayerUI(container, routine, activeEngine.getState());
    });
  }
  
  if (skipBtn) {
    skipBtn.addEventListener('click', async () => {
      if (!activeEngine) return;
      const confirmed = await confirmModal({
        title: 'Skip current phase?',
        message: 'This will advance to the next phase.',
        confirmLabel: 'Skip',
        cancelLabel: 'Cancel',
      });
      if (confirmed && activeEngine) {
        activeEngine.skip();
      }
    });
  }

  if (exitBtn) {
    exitBtn.addEventListener('click', async () => {
      // Pause while user decides
      const wasPaused = activeEngine ? activeEngine.isPaused() : true;
      if (activeEngine && !wasPaused) {
        activeEngine.pause();
        if (activeCues) activeCues.stop();
        pauseReason = 'manual'; // user explicitly paused
      }
      
      // Capture progress for the prompt
      const elapsed = activeEngine ? Math.floor(activeEngine.getState().totalElapsed) : 0;
      const setsDone = activeSession ? activeSession.setsCompleted : 0;
      const hasProgress = elapsed >= 5;  // worth asking only if at least 5 seconds in
      
      let exitDecision;
      
      if (hasProgress) {
        // Three-way choice: Save partial / Discard / Keep going
        const result = await showExitPrompt({ elapsed, setsDone });
        exitDecision = result;
     } else {
        // No meaningful progress yet — simple confirm
        const ok = await confirmModal({
          title: 'Exit workout?',
          message: 'You just started — exit anyway?',
          confirmLabel: 'Exit',
          cancelLabel: 'Keep going',
          danger: true,
        });
        exitDecision = ok ? 'discard' : 'cancel';
      }
      
      if (exitDecision === 'cancel') {
        if (activeEngine && !wasPaused) {
          activeEngine.resume();
          pauseReason = null;
          renderPlayerUI(container, routine, activeEngine.getState());
        }
        return;
      }
      
      if (exitDecision === 'save') {
        // Save as incomplete
        if (activeSession) {
          try {
            await updateSession(activeSession.id, {
              completedAt: Date.now(),
              status: 'incomplete',
              totalElapsed: elapsed,
              setsCompleted: setsDone,
              exercisesCompleted: activeSession.exercisesCompleted,
            });
            console.log('[Player] Session saved (incomplete)');
          } catch (err) {
            console.warn('[Player] Could not save partial session:', err);
          }
        }
      } else if (exitDecision === 'discard') {
        // Delete the session record we created at start
        if (activeSession) {
          try {
            await deleteSession(activeSession.id);
            console.log('[Player] Session discarded');
          } catch (err) {
            console.warn('[Player] Could not delete session:', err);
          }
        }
      }
      
      cleanupEngine();
      router.navigate(`/routine/${routine.id}`);
    });
  }
}
// ============================================================
// HELPERS
// ============================================================

function getPhaseInfo(phase) {
  const phaseMap = {
    'idle':         { label: 'Ready',     color: 'gray'  },
    'prep':         { label: 'Get Ready', color: 'amber' },
    'work':         { label: 'Work',      color: 'blue'  },
    'rest-set':     { label: 'Rest',      color: 'green' },
    'rest-exercise':{ label: 'Rest',      color: 'green' },
    'complete':     { label: 'Complete!', color: 'gold'  },
  };
  return phaseMap[phase] || { label: phase, color: 'gray' };
}

function getNextUpLabel(routine, state) {
  const currentExercise = state.currentExercise;
  if (!currentExercise) return '';
  
  if (state.phase === 'prep') {
    return `Next: Work (${currentExercise.workDuration}s)`;
  }
  
  if (state.phase === 'work') {
    if (state.currentSet < currentExercise.sets) {
      return currentExercise.restBetweenSets > 0
        ? `Next: Rest (${currentExercise.restBetweenSets}s)`
        : `Next: Set ${state.currentSet + 1}`;
    }
    if (state.currentExerciseIndex < routine.exercises.length - 1) {
      const nextEx = routine.exercises[state.currentExerciseIndex + 1];
      return routine.restBetweenExercises > 0
        ? `Next: Rest (${routine.restBetweenExercises}s) → ${nextEx.name}`
        : `Next: ${nextEx.name}`;
    }
    return 'Last set!';
  }
  
  if (state.phase === 'rest-set') {
    return `Next: Set ${state.currentSet + 1} of ${currentExercise.sets}`;
  }
  
  if (state.phase === 'rest-exercise') {
    const nextEx = routine.exercises[state.currentExerciseIndex + 1];
    return nextEx ? `Next: ${nextEx.name}` : '';
  }
  
  return '';
}

function formatTime(seconds) {
  if (seconds == null || seconds < 0) return '00:00';
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}
/**
 * Three-way exit prompt: Save partial / Discard / Keep going.
 * Returns 'save' | 'discard' | 'cancel'.
 */
async function showExitPrompt({ elapsed, setsDone }) {
  
  const minutes = Math.floor(elapsed / 60);
  const seconds = elapsed % 60;
  const timeLabel = minutes > 0 ? `${minutes}m ${seconds}s` : `${seconds}s`;
  
  return new Promise((resolve) => {
    const content = document.createElement('div');
    content.className = 'exit-prompt';
    content.innerHTML = `
      <p class="exit-prompt-intro">
        You've been working out for <strong>${timeLabel}</strong>${setsDone > 0 ? ` and completed <strong>${setsDone} set${setsDone === 1 ? '' : 's'}</strong>` : ''}.
      </p>
      
      <p class="exit-prompt-question">What would you like to do?</p>
      
      <button type="button" class="import-action-btn" id="exit-save-btn">
        <div class="import-action-content">
          <div class="import-action-label">Save partial session</div>
          <div class="import-action-hint">
            Record your progress so far. You can pick up another time.
          </div>
        </div>
      </button>
      
      <button type="button" class="import-action-btn" id="exit-discard-btn">
        <div class="import-action-content">
          <div class="import-action-label">Discard and exit</div>
          <div class="import-action-hint">
            Don't save anything. Your progress will be lost.
          </div>
        </div>
      </button>
      
      <div class="editor-actions">
        <button type="button" class="btn btn-secondary" id="exit-cancel-btn">Keep going</button>
      </div>
    `;
    
    const modal = openModal({
      title: 'Exit workout?',
      content,
      dismissable: false,
    });
    
    let resolved = false;
    const finish = (decision) => {
      if (resolved) return;
      resolved = true;
      closeModal(modal);
      resolve(decision);
    };
    
    content.querySelector('#exit-save-btn').addEventListener('click', () => finish('save'));
    content.querySelector('#exit-discard-btn').addEventListener('click', () => finish('discard'));
    content.querySelector('#exit-cancel-btn').addEventListener('click', () => finish('cancel'));
  });
}
/**
 * Shows the one-time educational modal about screen lock behavior.
 * Returns a Promise that resolves when user dismisses.
 */
async function showWakeLockEducation() {

  return new Promise((resolve) => {
    const content = document.createElement('div');
    content.className = 'wake-lock-education';
    content.innerHTML = `
      <div class="wake-lock-education-icon">📱</div>

      <p class="wake-lock-education-intro">
        Centerline will <strong>keep your screen on</strong> during workouts so you don't miss any cues.
      </p>

      <div class="wake-lock-education-note">
        <div class="wake-lock-education-note-title">⚠️  If you lock your screen</div>
        <p>
          Your workout will <strong>pause automatically</strong>. Audio cues can't play when your screen is locked (browser limitation).
        </p>
        <p>
          Tap <strong>Resume</strong> when you unlock to continue.
        </p>
      </div>

      <div class="editor-actions">
        <button type="button" class="btn btn-primary" id="education-ok-btn">Got it</button>
      </div>
    `;

    let resolved = false;
    const finish = (acknowledged) => {
      if (resolved)  return;
      resolved = true;
      resolve({ acknowledged });
    };

    const modal = openModal({
      title: 'About Screen & Audio',
      content,
      onClose: (reason) => {
        const acknowledged = reason !== 'popstate';
        finish(acknowledged);
      },
    });

    content.querySelector('#education-ok-btn').addEventListener('click', () => {
      closeModal(modal);
      finish(true);
    });
  });
}
function escapeHtml(str) {
  if (str == null) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}






 




$ cat src/core/sessionEngine.js
/**
 * Centerline — Session Engine
 * 
 * Drift-resistant timer + state machine for running a workout routine.
 * Emits events that the UI subscribes to.
 * 
 * Phases:
 *   - 'idle'         : not started
 *   - 'prep'         : 3-second countdown before workout
 *   - 'work'         : active exercise (countdown)
 *   - 'rest-set'     : rest between sets of same exercise
 *   - 'rest-exercise': rest between different exercises
 *   - 'complete'     : workout finished
 * 
 * Events:
 *   - 'tick'        : { timeRemaining, totalElapsed, state }
 *   - 'phaseChange' : { from, to, state }
 *   - 'complete'    : { state, totalElapsed }
 * 
 * Usage:
 *   const engine = new SessionEngine(routine, { prepDuration: 3 });
 *   engine.on('tick', (data) => { ... });
 *   engine.on('phaseChange', (data) => { ... });
 *   engine.on('complete', (data) => { ... });
 *   engine.start();
 */

const TICK_INTERVAL_MS = 100;  // 10 updates per second — smooth display
const DEFAULT_PREP_DURATION = 3;

export class SessionEngine {
  constructor(routine, options = {}) {
    if (!routine || !Array.isArray(routine.exercises) || routine.exercises.length === 0) {
      throw new Error('SessionEngine requires a routine with at least one exercise');
    }
    
    this.routine = routine;
    this.prepDuration = options.prepDuration ?? DEFAULT_PREP_DURATION;
    
    // State
    this.phase = 'idle';
    this.currentExerciseIndex = 0;
    this.currentSet = 1;
    this.timeRemaining = 0;       // seconds remaining in current phase
    this.phaseDuration = 0;       // total seconds for current phase
    this.totalElapsed = 0;        // total seconds elapsed since start
    
    // Tick mechanics
    this._tickHandle = null;
    this._phaseStartTime = null;  // performance.now() when phase began
    this._pausedAt = null;        // performance.now() when paused, null if running
    this._sessionStartTime = null;
    this._totalPausedDuration = 0;
    
    // Event listeners
    this._listeners = {
      tick: [],
      phaseChange: [],
      complete: [],
    };
  }
 // ============================================================
  // PUBLIC API
  // ============================================================
  
  /**
   * Start the workout (transitions from 'idle' to 'prep').
   */
  start() {
    if (this.phase !== 'idle') {
      console.warn('[SessionEngine] start() called but phase is not idle:', this.phase);
      return;
    }
    
    this._sessionStartTime = performance.now();
    this._transitionTo('prep', this.prepDuration);
    this._startTicking();
  }
  
  /**
   * Pause the timer (freezes remaining time).
   */
  pause() {
    if (this._pausedAt !== null) return;  // already paused
    if (this.phase === 'idle' || this.phase === 'complete') return;
    
    this._pausedAt = performance.now();
    this._stopTicking();
  }
  
  /**
   * Resume from pause.
   */
  resume() {
    if (this._pausedAt === null) return;  // not paused
    
    // Adjust phase start time so timeRemaining stays correct
    const pauseDuration = performance.now() - this._pausedAt;
    this._phaseStartTime += pauseDuration;
    this._totalPausedDuration += pauseDuration;
    this._pausedAt = null;
    
    this._startTicking();
  }
  
  /**
   * Skip to the next phase immediately.
   */
  skip() {
    if (this.phase === 'idle' || this.phase === 'complete') return;
    this._advancePhase();
  }
  
  /**
   * Stop the workout entirely (transitions to 'idle' or 'complete' depending on context).
   * Use this for "exit" — does not auto-advance.
   */
  stop() {
    this._stopTicking();
    this.phase = 'idle';
    this._pausedAt = null;
  }
  
  /**
   * Returns true if currently paused.
   */
  isPaused() {
    return this._pausedAt !== null;
  }
  
  /**
   * Returns true if engine is in an active phase (not idle/complete).
   */
  isActive() {
    return this.phase !== 'idle' && this.phase !== 'complete';
  }
  
  /**
   * Returns a snapshot of the current state (for UI rendering).
   */
  getState() {
    return {
      phase: this.phase,
      currentExerciseIndex: this.currentExerciseIndex,
      currentExercise: this.routine.exercises[this.currentExerciseIndex] || null,
      currentSet: this.currentSet,
      timeRemaining: Math.max(0, Math.ceil(this.timeRemaining)),
      phaseDuration: this.phaseDuration,
      totalElapsed: Math.floor(this.totalElapsed),
      isPaused: this.isPaused(),
      totalExercises: this.routine.exercises.length,
    };
  }
  
  // ============================================================
  // EVENT SUBSCRIPTION
  // ============================================================
  
  on(event, callback) {
    if (this._listeners[event]) {
      this._listeners[event].push(callback);
    }
    // Return an unsubscribe function
    return () => this.off(event, callback);
  }
  
  off(event, callback) {
    if (this._listeners[event]) {
      this._listeners[event] = this._listeners[event].filter((cb) => cb !== callback);
    }
  }
   if (this._listeners[event]) {
      this._listeners[event].forEach((cb) => {
        try {
          cb(data);
        } catch (err) {
          console.error(`[SessionEngine] Listener for "${event}" threw:`, err);
        }
      });
    }
  }
  
  // ============================================================
  // INTERNAL: TICK LOOP
  // ============================================================
  
  _startTicking() {
    if (this._tickHandle !== null) return;
    this._tickHandle = setInterval(() => this._tick(), TICK_INTERVAL_MS);
  }
  
  _stopTicking() {
    if (this._tickHandle !== null) {
      clearInterval(this._tickHandle);
      this._tickHandle = null;
    }
  }
  
  _tick() {
    if (this._pausedAt !== null) return;  // safety: shouldn't happen but just in case
    
    const now = performance.now();
    const elapsedInPhase = (now - this._phaseStartTime) / 1000;  // seconds
    this.timeRemaining = this.phaseDuration - elapsedInPhase;
    this.totalElapsed = (now - this._sessionStartTime - this._totalPausedDuration) / 1000;
    
    this._emit('tick', this.getState());
    
    if (this.timeRemaining <= 0) {
      this._advancePhase();
    }
  }
  
  // ============================================================
  // INTERNAL: PHASE TRANSITIONS
  // ============================================================
    _advancePhase() {
    const currentExercise = this.routine.exercises[this.currentExerciseIndex];
    if (!currentExercise) {
      this._complete();
      return;
    }
    
    if (this.phase === 'prep') {
      // Prep → Work (first exercise, first set)
      this._transitionTo('work', currentExercise.workDuration);
      return;
    }
    
    if (this.phase === 'work') {
      // Work done — what's next?
      const isLastSet = this.currentSet >= currentExercise.sets;
      const isLastExercise = this.currentExerciseIndex >= this.routine.exercises.length - 1;
      
      if (!isLastSet) {
        // More sets of this exercise
        if (currentExercise.restBetweenSets > 0) {
          this._transitionTo('rest-set', currentExercise.restBetweenSets);
        } else {
          // No rest configured — go straight to next set
          this.currentSet++;
          this._transitionTo('work', currentExercise.workDuration);
        }
        return;
      }
      
      // Last set of this exercise — is there a next exercise?
      if (!isLastExercise) {
        if (this.routine.restBetweenExercises > 0) {
          this._transitionTo('rest-exercise', this.routine.restBetweenExercises);
        } else {
          // No rest configured — go straight to next exercise
          this.currentExerciseIndex++;
          this.currentSet = 1;
          const nextEx = this.routine.exercises[this.currentExerciseIndex];
          this._transitionTo('work', nextEx.workDuration);
        }
        return;
      }
      
      // Last set of last exercise — DONE!
      this._complete();
      return;
    }
    
    if (this.phase === 'rest-set') {
      // Rest done — move to next set of same exercise
      this.currentSet++;
      this._transitionTo('work', currentExercise.workDuration);
      return;
    }
    if (this.phase === 'rest-exercise') {
      // Rest done — move to next exercise, set 1
      this.currentExerciseIndex++;
      this.currentSet = 1;
      const nextEx = this.routine.exercises[this.currentExerciseIndex];
      if (!nextEx) {
        this._complete();
        return;
      }
      this._transitionTo('work', nextEx.workDuration);
      return;
    }
  }
  
  _transitionTo(newPhase, duration) {
    const fromPhase = this.phase;
    this.phase = newPhase;
    this.phaseDuration = duration;
    this.timeRemaining = duration;
    this._phaseStartTime = performance.now();
    
    this._emit('phaseChange', {
      from: fromPhase,
      to: newPhase,
      state: this.getState(),
    });
    
    console.log(`[SessionEngine] ${fromPhase} → ${newPhase} (${duration}s)`);
  }
  
  _complete() {
    this._stopTicking();
    const fromPhase = this.phase;
    this.phase = 'complete';
    this.timeRemaining = 0;
    
    this._emit('phaseChange', {
      from: fromPhase,
      to: 'complete',
      state: this.getState(),
    });
    
    this._emit('complete', {
      state: this.getState(),
      totalElapsed: Math.floor(this.totalElapsed),
    });
    
    console.log(`[SessionEngine] Workout complete! Total: ${Math.floor(this.totalElapsed)}s`);
  }
}

