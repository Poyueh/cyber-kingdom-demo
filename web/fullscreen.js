/* Fullscreen must start inside the player's own gesture. Godot arms this on the button
   press; the release of that same tap or click performs the switch. */
(() => {
  const root = document.documentElement;
  const enter = root.requestFullscreen || root.webkitRequestFullscreen;
  const leave = document.exitFullscreen || document.webkitExitFullscreen;
  const current = () => document.fullscreenElement || document.webkitFullscreenElement;
  let armed = false;
  const toggle = () => {
    if (!armed) return;
    armed = false;
    const result = current() ? leave.call(document) : enter.call(root);
    if (result && typeof result.catch === 'function') result.catch(() => {});
  };
  for (const type of ['pointerup', 'touchend', 'keyup']) window.addEventListener(type, toggle, true);
  window.CyberKingdomFullscreen = Object.freeze({
    available: () => Boolean(enter && leave && (document.fullscreenEnabled || document.webkitFullscreenEnabled)),
    arm: () => { armed = true; },
  });
})();
