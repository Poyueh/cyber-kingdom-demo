/* Phones: render the canvas at most at 2x device pixels. A 3x screen would fill 2.25x more
   pixels every frame for no visible gain in pixel art, and the extra GPU work heats the
   phone. Runs before the engine reads devicePixelRatio; desktops are unchanged. */
(() => {
  const MAX_PHONE_RATIO = 2;
  const real = window.devicePixelRatio || 1;
  if (navigator.maxTouchPoints > 0 && real > MAX_PHONE_RATIO) {
    Object.defineProperty(window, 'devicePixelRatio', { get: () => MAX_PHONE_RATIO, configurable: true });
  }
})();
