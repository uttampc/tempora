$ grep -n -A 8 "resuming && resumeSnapshot" src/views/player.js 
330:  if (resuming && resumeSnapshot) {
331-    engine.resumeFromSnapshot(resumeSnapshot);
332-    // Engine is now paused at the saved phase — render first, then resume
333-    engine.resume();
334-    renderPlayerUI(container, routine, engine.getState());
335-  } else {
336-    engine.start();
337-  }
338-}
