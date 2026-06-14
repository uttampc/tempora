174   _emit(event, data) {
175     if (this._listeners[event]) {
176       this._listeners[event].forEach((cb) => {
177         try {
178           cb(data);
179         } catch (err) {
180           console.error(`[SessionEngine] Listener for "${event}" threw:`, err);
181         }
182       });
183     }
184   }

