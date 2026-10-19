/* Web frame cap without blocking. Godot's own max_fps waits in a busy loop on a
   single-threaded page, which keeps the phone's CPU at 100%. Instead the animation
   frame callback is simply not run until the frame interval has passed, so the main
   thread rests between frames. Godot sets the cap at startup (data/web_performance.tres). */
(() => {
  const request = window.requestAnimationFrame.bind(window);
  let interval = 0;
  let last = 0;
  window.requestAnimationFrame = (callback) => request(function frame(time) {
    // 1 ms tolerance keeps a 60 Hz screen at an even 30 instead of dropping to 20.
    if (interval > 0 && time - last < interval - 1) return request(frame);
    last = time;
    callback(time);
  });
  window.CyberKingdomFrames = Object.freeze({
    cap: (fps) => { interval = fps > 0 ? 1000 / fps : 0; },
  });
})();
