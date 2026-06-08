 sed -n '28,90p' src/components/modal.js 
export function openModal({ title, content, onClose, dismissable = true }) {
  modalCount++;
  
  const modal = document.createElement('div');
  modal.className = 'modal-overlay';
  modal.dataset.modalId = `modal-${modalCount}`;
  
  modal.innerHTML = `
    <div class="modal-backdrop" data-action="backdrop"></div>
    <div class="modal-panel" role="dialog" aria-modal="true" aria-labelledby="modal-title-${modalCount}">
      <header class="modal-header">
        <h2 class="modal-title" id="modal-title-${modalCount}">${escapeHtml(title)}</h2>
        <button class="modal-close-btn" data-action="close" aria-label="Close">✕</button>
      </header>
      <div class="modal-body"></div>
    </div>
  `;
  
  // Insert content into body
  const bodyEl = modal.querySelector('.modal-body');
  if (typeof content === 'string') {
    bodyEl.innerHTML = content;
  } else if (content instanceof HTMLElement) {
    bodyEl.appendChild(content);
  }
  
  // Wire up close handlers
  const closeHandler = () => doClose(modal, onClose);
  modal.querySelector('[data-action="close"]').addEventListener('click', closeHandler);
  
  if (dismissable) {
    modal.querySelector('[data-action="backdrop"]').addEventListener('click', closeHandler);
  }
  
  // Escape key to close
  const escapeHandler = (e) => {
    if (e.key === 'Escape' && dismissable) {
      closeHandler();
    }
  };
  document.addEventListener('keydown', escapeHandler);
  modal._escapeHandler = escapeHandler;  // store for cleanup
  
  // Lock body scroll
  document.body.classList.add('modal-open');
  
  // Append and animate in
  document.body.appendChild(modal);
  // Trigger CSS transition by adding 'visible' class after a frame
  requestAnimationFrame(() => {
    modal.classList.add('visible');
  });
  
  return modal;
}

/**
 * Closes a modal programmatically.
 */
export function closeModal(modal) {
  if (modal) doClose(modal, null);
}

