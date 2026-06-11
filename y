Snippet of html from Player.js

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
            ⏸  ${escapeHtml(getPausedBannerText())}
          </div>
        ` : ''}
      </div>
      
      <div class="player-controls">
        <button type="button" class="player-control-btn player-pause-btn" id="player-pause-btn">
          <span class="player-control-icon">${isPaused ? '▶' : '⏸ '}</span>
          <span class="player-control-label">${isPaused ? 'Resume' : 'Pause'}</span>
        </button>
        <button type="button" class="player-control-btn player-skip-btn" id="player-skip-btn">
          <span class="player-control-icon">⏭ </span>
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

From db/store.js we have following activity details,
  const activity = {
    id: generateId(),
    name: 'Untitled Activity',
    description: '',
    videoUrl: '',
    defaultWorkDuration: 30,
    defaultRestBetweenSets: 10,
    defaultSets: 3,
    isSeeded: false,
    tags: [],
    metadata: {},
    createdAt: now,
    updatedAt: now,
    ...data,
  };

So we need to display activity "description" under the name.
Is this enough?



