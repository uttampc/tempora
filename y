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
      
    // --- Save resume state on every phase transition ---
    if (activeSession && activeRoutine) {
      const state = data.state;
      const exercise = state.currentExercise;
      updateSession(activeSession.id, {
        totalElapsed: state.totalElapsed,
        setsCompleted: activeSession.setsCompleted,
        exercisesCompleted: activeSession.exercisesCompleted,
        lastExerciseId: exercise ? exercise.id : null,
        lastExerciseName: exercise ? exercise.name : null,
        lastExerciseIndex: state.currentExerciseIndex,
        lastSet: state.currentSet,
        lastPhase: data.to,
        lastTimeRemaining: Math.max(1, Math.ceil(state.timeRemaining)),
        lastSavedAt: Date.now(),
      }).catch(err => console.warn('[Player] Could not save resume state:', err));
    } 
      
    // Fire phase-start cue
    const context = buildCueContext(data, routine);
    cues.cuePhaseStart(data.to, context);

    renderPlayerUI(container, routine, data.state);
  });
