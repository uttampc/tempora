$ grep -n "lastExerciseId\|lastSet\|lastPhase\|lastSavedAt\|lastExerciseName\|lastExerciseIndex" src/views/player.js 
152:        lastExerciseId: exercise ? exercise.id : null,
153:        lastExerciseName: exercise ? exercise.name : null,
154:        lastExerciseIndex: state.currentExerciseIndex,
155:        lastSet: state.currentSet,
156:        lastPhase: data.to,
158:        lastSavedAt: Date.now(),
212:    const exercise = routine.exercises[resumeSnapshot.lastExerciseIndex];
213:    const exerciseName = resumeSnapshot.lastExerciseName || (exercise ? exercise.name : 'last exercise');
215:    const ageMs = Date.now() - (resumeSnapshot.lastSavedAt || resumeSnapshot.startedAt);
224:      setNumber: resumeSnapshot.lastSet,

$ grep -n "lastExerciseId\|lastSet\|lastPhase\|lastSavedAt\|lastExerciseName\|lastExerciseIndex" src/db/store.js 
501:    lastExerciseId: null,
502:    lastExerciseName: null,
503:    lastExerciseIndex: 0,
504:    lastSet: 1,
505:    lastPhase: null,
507:    lastSavedAt: Date.now(),
527:      s.lastPhase !== null &&
