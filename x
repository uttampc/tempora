$ grep -n "closeHandler\|popstateHandler\|reason" src/components/modal.js 
55:  const closeHandler = (reason) => doClose(modal, onClose, reason);
56:  modal.querySelector('[data-action="close"]').addEventListener('click', closeHandler('close-button'));
59:    modal.querySelector('[data-action="backdrop"]').addEventListener('click', closeHandler('backdrop'));
65:      closeHandler('escape');
72:  const popstateHandler = () => closeHandler('popstate');
73:  window.addEventListener('popstate',  popstateHandler);
74:  modal._popstateHandler = popstateHandler;
96:function doClose(modal, onClose, reason) {
106:  if (modal._popstateHandler) {
107:    document.removeEventListener('popstate', modal._popstateHandler);
122:      onClose(reason);
