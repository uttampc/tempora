$ cat  src/components/modal.js                                                                             12:11:27 [46/992]
/**                                                                                                                                                     
 * Centerline — Reusable Modal Component                                                                                                                
 *                                                                                                                                                      
 * Usage:                                                                                                                                               
 *   import { openModal, closeModal } from '../components/modal.js';                                                                                    
 *                                                                                                                                                      
 *   const modal = openModal({                                                                                                                          
 *     title: 'My Modal',                                                                                                                               
 *     content: '<p>Hello world</p>',  // string OR HTMLElement                                                                                         
 *     onClose: () => console.log('closed'),                                                                                                            
 *   });                                                                                                                                                
 *                                                                                                                                                      
 *   // Later:                                                                                                                                          
 *   closeModal(modal);                                                                                                                                 
 */                                                                                                                                                     
                                                                                                                                                        
let modalCount = 0;                                                                                                                                     
                                                                                                                                                        
/**                                                                                                                                                     
 * Opens a modal overlay.                                                                                                                               
 * @param {Object} options                                                                                                                              
 * @param {string} options.title - Header title                                                                                                         
 * @param {string|HTMLElement} options.content - Body content                                                                                           
 * @param {Function} [options.onClose] - Called after modal closes                                                                                      
 * @param {boolean} [options.dismissable=true] - Allow backdrop click to close                                                                          
 * @returns {HTMLElement} The modal root element (for later closeModal call)                                                                            
 */                                                                                                                                                     
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
  const closeHandler = (reason) => doClose(modal, onClose, reason);                                                                                     
  modal.querySelector('[data-action="close"]').addEventListener('click', () => closeHandler('close-button'));                                           

  if (dismissable) {                  
    modal.querySelector('[data-action="backdrop"]').addEventListener('click', () => closeHandler('backdrop'));                                          
  }                                   

  // Escape key to close                                                    
  const escapeHandler = (e) => {                                            
    if (e.key === 'Escape' && dismissable) {                                
      closeHandler('escape');                                               
    }                                 
  };                                  
  document.addEventListener('keydown', escapeHandler);                                                                                                  
  modal._escapeHandler = escapeHandler;  // store for cleanup                                                                                           

  // Browser back button - always closes modal (regardless of dismissable flag)                                                                         
  const popstateHandler = () => closeHandler('popstate');                                                                                               
  window.addEventListener('popstate',  popstateHandler);                                                                                                
  modal._popstateHandler = popstateHandler;                                 

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
  if (modal) doClose(modal, null, 'programmatic');                                                                                                      
}                                     

function doClose(modal, onClose, reason) {                                  
  if (!modal || !modal.parentNode) return;                                  

  modal.classList.remove('visible');                                        

  // Clean up escape handler                                                
  if (modal._escapeHandler) {                                               
    document.removeEventListener('keydown', modal._escapeHandler);                                                                                      
  }                                   

  if (modal._popstateHandler) {                                             
    window.removeEventListener('popstate', modal._popstateHandler);                                                                                     
  }                                   

  // Wait for transition, then remove                                       
  setTimeout(() => {                  
    if (modal.parentNode) {                                                 
      modal.parentNode.removeChild(modal);                                  
    }                                 

    // Unlock body scroll if no other modals are open                                                                                                   
    if (!document.querySelector('.modal-overlay')) {                                                                                                    
      document.body.classList.remove('modal-open');                                                                                                     
    }                                 

    if (typeof onClose === 'function') {                                    
      onClose(reason);                
    }                                 
  }, 200);  // matches CSS transition duration                              
}                                     

function escapeHtml(str) {                                                  
  if (str == null) return '';                                               
  return String(str)                  
    .replace(/&/g, '&amp;')                                                 
    .replace(/</g, '&lt;')                                                  
    .replace(/>/g, '&gt;')                                                  
    .replace(/"/g, '&quot;')                                                
    .replace(/'/g, '&#39;');                                                
}                              

In renderPlayer() calls to "confirmModal()
--->  If there is a Resumable snapshot ...
 if (resumeSnapshot) {
    const exercise = routine.exercises[resumeSnapshot.lastExerciseIndex];
    const exerciseName = resumeSnapshot.lastExerciseName || (exercise ? exercise.name : 'last exercise');

    const ageMs = Date.now() - (resumeSnapshot.lastSavedAt || resumeSnapshot.startedAt);
    const ageMin = Math.floor(ageMs / 60000);
    const ageLabel = ageMin < 1 ? 'just now'
      : ageMin === 1 ? '1 minute ago'
      : `${ageMin} minutes ago`;

    const wantResume = await confirmModal({
      title: 'Resume session?',
      message: `You were doing "${exerciseName}" (set ${resumeSnapshot.lastSet}) — paused ${ageLabel}. Resume where you left o
ff?`,
      confirmLabel: 'Resume',
      cancelLabel: 'Start fresh',
    });

    if (location.hash !== expectedPath) return;  // navigated away during modal

    if (wantResume) {
      resuming = true;
      activeSession = {
        id: resumeSnapshot.id,
        setsCompleted: resumeSnapshot.setsCompleted,
        exercisesCompleted: resumeSnapshot.exercisesCompleted,
      };
      console.log('[Player] Resuming session:', resumeSnapshot.id);
    } else {
      // User chose "Start fresh" — mark old session as abandoned
      try {
        await updateSession(resumeSnapshot.id, {
          status: 'abandoned',
          completedAt: Date.now(),
        });
        console.log('[Player] Old session abandoned, starting fresh');
      } catch (err) {
        console.warn('[Player] Could not abandon old session:', err);
      }
    }
  }


---> With skip button
  if (skipBtn) {
    skipBtn.addEventListener('click', async () => {
      if (!activeEngine) return;
      const confirmed = await confirmModal({
        title: 'Skip current phase?',
        message: 'This will advance to the next phase.',
        confirmLabel: 'Skip',
        cancelLabel: 'Cancel',
      });
      if (confirmed && activeEngine) {
        activeEngine.skip();
      }
    });
  }


---> With exit button
if (exitBtn) {
    exitBtn.addEventListener('click', async () => {
      // Pause while user decides
      const wasPaused = activeEngine ? activeEngine.isPaused() : true;
      if (activeEngine && !wasPaused) {
        activeEngine.pause();
        if (activeCues) activeCues.stop();
        pauseReason = 'manual'; // user explicitly paused
      }
      
      // Capture progress for the prompt
      const elapsed = activeEngine ? Math.floor(activeEngine.getState().totalElapsed) : 0;
      const setsDone = activeSession ? activeSession.setsCompleted : 0;
      const hasProgress = elapsed >= 5;  // worth asking only if at least 5 seconds in
      
      let exitDecision;
      
      if (hasProgress) {
        // Three-way choice: Save partial / Discard / Keep going
        const result = await showExitPrompt({ elapsed, setsDone });
        exitDecision = result;
      } else {
        // No meaningful progress yet — simple confirm
        const ok = await confirmModal({
          title: 'Exit workout?',
          message: 'You just started — exit anyway?',
          confirmLabel: 'Exit',
          cancelLabel: 'Keep going',
          danger: true,
        });
        exitDecision = ok ? 'discard' : 'cancel';
      }
      
      if (exitDecision === 'cancel') {
        if (activeEngine && !wasPaused) {
          activeEngine.resume();
          pauseReason = null;
          renderPlayerUI(container, routine, activeEngine.getState());
        }
        return;
      }
      
      if (exitDecision === 'save') {
        // Save as incomplete
        if (activeSession) {
          try {
            await updateSession(activeSession.id, {
              completedAt: Date.now(),
              status: 'incomplete',
              totalElapsed: elapsed,
              setsCompleted: setsDone,
              exercisesCompleted: activeSession.exercisesCompleted,
            });
            console.log('[Player] Session saved (incomplete)');
          } catch (err) {
            console.warn('[Player] Could not save partial session:', err);
          }
        }
      } else if (exitDecision === 'discard') {
        // Delete the session record we created at start
        if (activeSession) {
          try {
            await deleteSession(activeSession.id);
            console.log('[Player] Session discarded');
          } catch (err) {
            console.warn('[Player] Could not delete session:', err);
          }
        }
      }
      
      cleanupEngine();
      router.navigate(`/routine/${routine.id}`);
    });
  }
