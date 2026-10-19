/* Phones: Godot only cancels touches that start on its canvas, and only while they are
   cancelable. Catch every other page swipe so it cannot scroll or pull-to-refresh.
   The player guide scrolls inside its own frame and is left alone. */
(() => {
  const inGuide = (target) => target instanceof Element && target.closest('#player-guide') !== null;
  document.addEventListener('touchmove', (event) => {
    if (event.cancelable && !inGuide(event.target)) event.preventDefault();
  }, { passive: false });
})();
