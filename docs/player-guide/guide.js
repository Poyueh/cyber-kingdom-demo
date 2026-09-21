(() => {
  'use strict';
  const t = window.GuideText.t;
  const modeButtons = [...document.querySelectorAll('[data-mode]')];
  function setMode(mode) {
    modeButtons.forEach(button => button.setAttribute('aria-pressed', String(button.dataset.mode === mode)));
    document.querySelectorAll('.key').forEach(key => key.textContent = key.dataset[mode]);
    document.getElementById('control-grid').classList.toggle('mobile', mode === 'mobile');
    document.getElementById('control-note').textContent = mode === 'mobile'
      ? t('左右空白處短拖慢走、長拖快跑、下滑給晶。快滑放手給一顆；靠近目標下滑按住會繼續填格。攻擊使用劍按鍵。')
      : t('使用鍵盤操作；靠近物件後，看它上方的圖示與龍晶格。');
  }
  modeButtons.forEach(button => button.addEventListener('click', () => setMode(button.dataset.mode)));
  if (matchMedia('(pointer: coarse)').matches || innerWidth < 760) setMode('mobile');

  const projects = {
    camp: {title:t('升級聚落'), cost:4, done:t('營火已成為營地。接著招攬居民、準備器具。')},
    tools: {title:t('弓箭器具'), cost:2, done:t('弓已放上器具架，等待居民領取。')},
    rift: {title:t('委託裂隙封印'), cost:4, done:t('委託完成。接著護送工匠，清除附近的敵人。')}
  };
  const projectButtons = [...document.querySelectorAll('[data-project]')];
  const paid = {camp:0, tools:0, rift:0};
  let active = 'camp', wallet = 12;
  const refundTimers = {};
  const invest = document.getElementById('invest');
  function renderInvestment() {
    const project = projects[active];
    const complete = paid[active] === project.cost;
    document.getElementById('wallet').textContent = wallet;
    document.getElementById('site-title').textContent = project.title;
    const selected = projectButtons.find(button => button.dataset.project === active);
    document.getElementById('site-icon').src = selected.dataset.icon;
    projectButtons.forEach(button => button.setAttribute('aria-pressed', String(button === selected)));
    const slots = document.getElementById('gem-slots');
    slots.replaceChildren(...Array.from({length:project.cost}, (_, index) => {
      const gem = document.createElement('span');
      gem.className = 'gem' + (index < paid[active] ? ' filled' : '');
      gem.setAttribute('aria-hidden', 'true');
      return gem;
    }));
    slots.setAttribute('aria-label', t('已投入 {paid} 顆，共需 {cost} 顆龍晶', {paid:paid[active], cost:project.cost}));
    document.getElementById('investment-status').textContent = complete ? project.done : t('{paid} / {cost} 顆 · 還差 {remaining} 顆龍晶', {paid:paid[active], cost:project.cost, remaining:project.cost-paid[active]});
    invest.disabled = complete || wallet === 0;
    invest.textContent = complete ? t('這筆投入已完成 ✓') : t('投入一顆龍晶 ＋');
  }
  projectButtons.forEach(button => button.addEventListener('click', () => {
    active = button.dataset.project;
    renderInvestment();
  }));
  invest.addEventListener('click', () => {
    if (wallet <= 0 || paid[active] >= projects[active].cost) return;
    wallet--; paid[active]++;
    const key = active;
    clearTimeout(refundTimers[key]);
    if (paid[key] < projects[key].cost) refundTimers[key] = setTimeout(() => {
      wallet += paid[key]; paid[key] = 0; renderInvestment();
    }, 1000);
    renderInvestment();
  });
  document.getElementById('reset-demo').addEventListener('click', () => {
    Object.values(refundTimers).forEach(clearTimeout);
    wallet = 12; Object.keys(paid).forEach(key => paid[key] = 0); renderInvestment();
  });
  renderInvestment();

  const animation = document.getElementById('combo-image');
  const toggle = document.getElementById('animation-toggle');
  let playing = false;
  toggle.addEventListener('click', () => {
    playing = !playing;
    animation.src = playing ? animation.dataset.animated : animation.dataset.still;
    toggle.setAttribute('aria-pressed', String(playing));
    toggle.textContent = playing ? t('■ 停止示範') : t('▶ 播放連斬示範');
  });
})();
