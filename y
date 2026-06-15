$ cat src/components/dialog.js
export function confirmModal({
  title,
  message,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  danger = false,
}) {
  return new Promise((resolve) => {
    const content = document.createElement('div');
    content.className = 'dialog-content';
    content.innerHTML = `
      <p class="dialog-message">${formatMessage(message)}</p>
      
      <div class="dialog-actions">
        <button type="button" class="btn btn-secondary" id="dialog-cancel-btn">
          ${escapeHtml(cancelLabel)}
        </button>
        <button type="button" class="btn ${danger ? 'btn-danger' : 'btn-primary'}" id="dialog-confirm-btn">
          ${escapeHtml(confirmLabel)}
        </button>
      </div>
    `;
    
    const modal = openModal({
      title,
      content,
    });

    let resolved = false;
    const finish = (result) => {
      if (resolved) return;
      resolved = true;
      closeModal(modal);
      resolve(result);
    };

    content.querySelector('#dialog-cancel-btn').addEventListener('click', () => finish(false));
    content.querySelector('#dialog-confirm-btn').addEventListener('click', () => finish(true));

    // If user dismisses via backdrop click or Escape, treat as cancel
    const originalOnClose = modal.onClose;
    modal.onClose = () => {
      if (originalOnClose) originalOnClose();
      if (!resolved) {
        resolved = true;
        resolve(false);
      }
    };

    // Auto-focus the cancel button by default (safer for destructive actions)
    setTimeout(() => {
      content.querySelector('#dialog-cancel-btn').focus();
    }, 100);
  });
}

