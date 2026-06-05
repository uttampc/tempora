$ grep -n "edit-exercise\|remove-exercise\|data-action" src/views/routineEdit.js 
231:          <button type="button" class="btn-icon-only" data-action="edit" data-exercise-id="${escapeHtml(ex.id)}" aria-label="Edit exercise">✎</button>
232:          <button type="button" class="btn-icon-only btn-icon-danger" data-action="remove" data-exercise-id="${escapeHtml(ex.id)}" aria-label="Remove exercise">✕</button>
253:          <button type="button" class="btn-icon-only" data-action="edit-exercise" data-exercise-id="${escapeHtml(ex.id)}" aria-label="Edit">
256:          <button type="button" class="btn-icon-only btn-icon-danger" data-action="remove-exercise" data-exercise-id="${escapeHtml(ex.id)}" aria-label="Remove">
269:    exercisesContainer.querySelectorAll('[data-action="remove"]').forEach((btn) => {
272:    exercisesContainer.querySelectorAll('[data-action="edit"]').forEach((btn) => {

> document.querySelectorAll('[data-action="edit-exercise"]').forEach((b, i) => { console.log(i, b, 'click handlers:', getEventListeners?.(b)); });
VM12924:1 0 <button type=​"button" class=​"btn-icon-only" data-action=​"edit-exercise" data-exercise-id=​"mq0mtqvm-dm1d" aria-label=​"Edit">​ ✎ ​</button>​flex 'click handlers:' {}[[Prototype]]: Object
VM12924:1 1 <button type=​"button" class=​"btn-icon-only" data-action=​"edit-exercise" data-exercise-id=​"mq0mtqvm-b76g" aria-label=​"Edit">​ ✎ ​</button>​flex 'click handlers:' {}
VM12924:1 2 <button type=​"button" class=​"btn-icon-only" data-action=​"edit-exercise" data-exercise-id=​"mq0mtqvm-gwsb" aria-label=​"Edit">​ ✎ ​</button>​flex 'click handlers:' {}
VM12924:1 3 <button type=​"button" class=​"btn-icon-only" data-action=​"edit-exercise" data-exercise-id=​"mq0mtqvm-tqwm" aria-label=​"Edit">​ ✎ ​</button>​flex 'click handlers:' {}
VM12924:1 4 <button type=​"button" class=​"btn-icon-only" data-action=​"edit-exercise" data-exercise-id=​"mq0mtqvm-kedd" aria-label=​"Edit">​ ✎ ​</button>​flex 'click handlers:' {}
