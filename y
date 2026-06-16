146:function renderExerciseList(exercises) {
147-  return `
148-    <section class="exercise-detail-list">
149-      <h3 class="section-heading">Exercises</h3>
150-      ${exercises.map((ex, i) => renderExerciseItem(ex, i + 1)).join('')}
151-    </section>
152-  `;
153-}

155:function renderExerciseItem(exercise, position) {
156-  const video = parseVideoUrl(exercise.videoUrl);
157-  const videoLink = video
158-    ? `<a href="${escapeHtml(video.originalUrl)}" target="_blank" rel="noopener noreferrer" class="video-link">▶ Watch demonstration</a>`
159-    : '';
160-
161-  const restNote = exercise.sets > 1 && exercise.restBetweenSets > 0
162-    ? ` · ${exercise.restBetweenSets}s rest`
163-    : '';
164-
165-  return `
166-    <article class="exercise-detail-item">
167-      <div class="exercise-position">${position}</div>
168-      <div class="exercise-detail-main">
169-        <h4 class="exercise-detail-name">${escapeHtml(exercise.name)}</h4>
170-        ${exercise.description ? `<p class="exercise-detail-desc">${escapeHtml(exercise.description)}</p>` : ''}
171-        <p class="exercise-detail-meta">
172-          ${exercise.workDuration}s hold × ${exercise.sets} set${exercise.sets === 1 ? '' : 's'}${restNote}
173-        </p>
174-        ${videoLink}
175-      </div>
176-    </article>
177-  `;
178-}
