/**
 * ScreenAwake
 */

class ScreenAwake {
  constructor() {
    this.wakeLock = null;
    this.isActive = false;
    this.duration = 'alwaysOn';
    this.timer = null;
    this.endTime = null;
    this.startTime = null;
    
    this.init();
  }

  init() {
    if (!('wakeLock' in navigator)) {
      console.warn('Wake Lock API not supported');
      this.showUnsupportedMessage();
      return;
    }

    this.bindEvents();
    this.updateUI();
    
    if (window.lucide) {
      window.lucide.createIcons();
    }
  }

  bindEvents() {
    const toggle = document.getElementById('awake-toggle');
    const durationSelect = document.getElementById('duration-select');
    const customHours = document.getElementById('custom-hours');
    const customMinutes = document.getElementById('custom-minutes');

    if (toggle) {
      toggle.addEventListener('change', () => this.handleToggle());
    }

    if (durationSelect) {
      durationSelect.addEventListener('change', (e) => {
        this.duration = e.target.value;
        this.toggleCustomDuration();

        if (this.isActive) {
          this.deactivate();
          const toggle = document.getElementById('awake-toggle');
          if (toggle) {
            toggle.checked = false;
          }
        }
      });
    }

    [customHours, customMinutes].forEach(input => {
      if (input) {
        input.addEventListener('input', () => this.validateCustomTime());
      }
    });

    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible' && this.isActive) {
        this.reacquireWakeLock();
      }
    });
  }

  toggleCustomDuration() {
    const customDiv = document.getElementById('custom-duration');
    if (customDiv) {
      customDiv.classList.toggle('hidden', this.duration !== 'custom');
    }
  }
 validateCustomTime() {
    const hours = parseInt(document.getElementById('custom-hours')?.value || 0);
    const minutes = parseInt(document.getElementById('custom-minutes')?.value || 0);
    
    if (hours < 0 || hours > 23) {
      document.getElementById('custom-hours').value = Math.max(0, Math.min(23, hours));
    }
    if (minutes < 0 || minutes > 59) {
      document.getElementById('custom-minutes').value = Math.max(0, Math.min(59, minutes));
    }
  }

  async handleToggle() {
    const toggle = document.getElementById('awake-toggle');
    if (!toggle) return;

    if (toggle.checked) {
      await this.activate();
    } else {
      this.deactivate();
    }
  }

  async activate() {
    try {
      this.wakeLock = await navigator.wakeLock.request('screen');
      this.isActive = true;      
      this.startTime = Date.now();
      
      this.setEndTime();      
      this.startTimer(); 
      this.updateUI();
      console.log('Screen Wake Lock activated');

      // Wake Lock
      this.wakeLock.addEventListener('release', () => {
        console.log('Screen Wake Lock released');
      });

   } catch (err) {
      console.error('Failed to activate Wake Lock:', err);
      this.showError('Failed to activate Wake lock');
      this.deactivate();
    }
  }

  deactivate() {
    if (this.wakeLock) {
      this.wakeLock.release();
      this.wakeLock = null;
    }
    
    this.isActive = false;
    this.endTime = null;
    this.startTime = null;
    
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
    
    this.updateUI();
    
    console.log('Screen Wake Lock deactivated');
  }

  setEndTime() {
    if (this.duration === 'alwaysOn') {
      this.endTime = null;
      return;
    }

    let minutes = 0;
    
    switch (this.duration) {
      case '10min':
        minutes = 10;
        break;
      case '30min':
        minutes = 30;
        break;
     case '1hour':
        minutes = 60;
        break;
      case '2hours':
        minutes = 120;
        break;
      case 'custom':
        const hours = parseInt(document.getElementById('custom-hours')?.value || 0);
        const customMinutes = parseInt(document.getElementById('custom-minutes')?.value || 0);
        minutes = hours * 60 + customMinutes;
        break;
    }

    if (minutes > 0) {
      this.endTime = Date.now() + (minutes * 60 * 1000);
    } else {
      this.endTime = null;
    }
  }

  startTimer() {
    if (this.timer) {
      clearInterval(this.timer);
    }

    this.timer = setInterval(() => {
      if (this.endTime && Date.now() >= this.endTime) {
        this.deactivate();
        document.getElementById('awake-toggle').checked = false;
      } else {
        this.updateTimerDisplay();
      }
    }, 1000);
  }

 updateTimerDisplay() {
    const timerIcon = document.getElementById('timer-icon');
    const timerText = document.getElementById('timer-text');
    if (!timerIcon || !timerText) return;

    if (this.endTime) {
      const remaining = this.endTime - Date.now();
      if (remaining > 0) {
        const hours = Math.floor(remaining / (1000 * 60 * 60));
        const minutes = Math.floor((remaining % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((remaining % (1000 * 60)) / 1000);
        
        let timeStr = '';
        if (hours > 0) {
          timeStr = `${hours}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        } else {
          timeStr = `${minutes}:${seconds.toString().padStart(2, '0')}`;
        }
        
        timerIcon.innerHTML = '<i data-lucide="timer" class="w-4 h-4"></i>';
        timerText.textContent = timeStr;
      }
    } else {
      if (this.startTime) {
        const elapsed = Date.now() - this.startTime;
        const hours = Math.floor(elapsed / (1000 * 60 * 60));
        const minutes = Math.floor((elapsed % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((elapsed % (1000 * 60)) / 1000);
        
        let timeStr = '';
        if (hours > 0) {
          timeStr = `${hours}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        } else {
          timeStr = `${minutes}:${seconds.toString().padStart(2, '0')}`;
        }
        
        // 使用时钟图标
        timerIcon.innerHTML = '<i data-lucide="clock" class="w-4 h-4"></i>';
        timerText.textContent = timeStr;
      } else {
        timerIcon.innerHTML = '<i data-lucide="clock" class="w-4 h-4"></i>';
        timerText.textContent = 'Always On';
      }
    }
    
   if (window.lucide) {
      window.lucide.createIcons();
    }
  }

  updateUI() {
    const toggleBg = document.getElementById('toggle-bg');
    const toggleCircle = document.getElementById('toggle-circle');
    const statusDisplay = document.getElementById('status-display');
    
    if (this.isActive) {
      toggleBg?.classList.remove('bg-[#505050]');
      toggleBg?.classList.add('bg-green-600');
      toggleCircle?.classList.remove('translate-x-1');
      toggleCircle?.classList.add('translate-x-6');
      statusDisplay?.classList.remove('hidden');
      
      this.updateTimerDisplay();
    } else {
      toggleBg?.classList.remove('bg-green-600');
      toggleBg?.classList.add('bg-[#505050]');
      toggleCircle?.classList.remove('translate-x-6');
      toggleCircle?.classList.add('translate-x-1');
      statusDisplay?.classList.add('hidden');
    }
  }

  async reacquireWakeLock() {
    if (this.isActive && !this.wakeLock) {
      try {
        this.wakeLock = await navigator.wakeLock.request('screen');
        console.log('Screen Wake Lock reacquired');
      } catch (err) {
        console.error('Failed to reacquire Wake Lock:', err);
      }
    }
  }

  showError(message) {
    console.error(message);
  }

  showUnsupportedMessage() {
    const widget = document.querySelector('.bg-\\[\\#262626\\]');
    if (widget) {
      const locale = window.APP_CONFIG?.locale || 'en';
      const locales = window.APP_CONFIG?.locales || {};
      const unsupportedConfig = locales[locale]?.widget?.unsupported || locales.en?.widget?.unsupported || {
        title: 'Browser Not Supported',
        message: 'Your browser does not support the Screen Wake Lock API. Please use Chrome 84+, Edge 84+, or other supported modern browsers.'
      };
      
      widget.innerHTML = `
        <div class="text-center p-6">
          <h3 class="text-white text-lg font-medium mb-3">${unsupportedConfig.title}</h3>
          <p class="text-gray-400 text-sm">
            ${unsupportedConfig.message}
          </p>
        </div>
      `;
    }
  }
}

document.addEventListener('DOMContentLoaded', () => {
  new ScreenAwake();
});
