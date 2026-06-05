$ grep -n "edit-exercise\|remove-exercise\|data-action" src/views/routineEdit.js 
231:          <button type="button" class="btn-icon-only" data-action="edit" data-exercise-id="${escapeHtml(ex.id)}" aria-label="Edit exercise">✎</button>
232:          <button type="button" class="btn-icon-only btn-icon-danger" data-action="remove" data-exercise-id="${escapeHtml(ex.id)}" aria-label="Remove exercise">✕</button>
253:          <button type="button" class="btn-icon-only" data-action="edit-exercise" data-exercise-id="${escapeHtml(ex.id)}" aria-label="Edit">
256:          <button type="button" class="btn-icon-only btn-icon-danger" data-action="remove-exercise" data-exercise-id="${escapeHtml(ex.id)}" aria-label="Remove">
269:    exercisesContainer.querySelectorAll('[data-action="remove"]').forEach((btn) => {
272:    exercisesContainer.querySelectorAll('[data-action="edit"]').forEach((btn) => {

