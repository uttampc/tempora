$ grep -n "currentExercise" src/core/sessionEngine.js |head -20
42:    this.currentExerciseIndex = 0;
95:    this.currentExerciseIndex = snapshot.lastExerciseIndex;
175:      currentExerciseIndex: this.currentExerciseIndex,
176:      currentExercise: this.routine.exercises[this.currentExerciseIndex] || null,
252:    const currentExercise = this.routine.exercises[this.currentExerciseIndex];
253:    if (!currentExercise) {
260:      this._transitionTo('work', currentExercise.workDuration);
266:      const isLastSet = this.currentSet >= currentExercise.sets;
267:      const isLastExercise = this.currentExerciseIndex >= this.routine.exercises.length - 1;
271:        if (currentExercise.restBetweenSets > 0) {
272:          this._transitionTo('rest-set', currentExercise.restBetweenSets);
276:          this._transitionTo('work', currentExercise.workDuration);
287:          this.currentExerciseIndex++;
289:          const nextEx = this.routine.exercises[this.currentExerciseIndex];
303:      this._transitionTo('work', currentExercise.workDuration);
309:      this.currentExerciseIndex++;
311:      const nextEx = this.routine.exercises[this.currentExerciseIndex];

$ grep -n -A 15 "getState()" src/core/sessionEngine.js |head -25
172:  getState() {
173-    return {
174-      phase: this.phase,
175-      currentExerciseIndex: this.currentExerciseIndex,
176-      currentExercise: this.routine.exercises[this.currentExerciseIndex] || null,
177-      currentSet: this.currentSet,
178-      timeRemaining: Math.max(0, Math.ceil(this.timeRemaining)),
179-      phaseDuration: this.phaseDuration,
180-      totalElapsed: Math.floor(this.totalElapsed),
181-      isPaused: this.isPaused(),
182-      totalExercises: this.routine.exercises.length,
183-    };
184-  }
185-  
186-  // ============================================================
187-  // EVENT SUBSCRIPTION
--
240:    this._emit('tick', this.getState());
241-    
242-    if (this.timeRemaining <= 0) {
243-      this._advancePhase();
244-    }
245-  }
246-  
247-  // ============================================================
