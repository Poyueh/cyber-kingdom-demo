(() => {
  'use strict';
  const chapters = [...document.querySelectorAll('.chapter')];
  const links = [...document.querySelectorAll('[data-chapter]')];
  const search = document.querySelector('#search');
  const filter = document.querySelector('#status-filter');
  const status = document.querySelector('#search-status');
  const empty = document.querySelector('#empty');
  const normalize = text => text.normalize('NFKC').toLocaleLowerCase().trim();
  const text = new Map(chapters.map(chapter => [chapter.id, normalize(chapter.textContent)]));
  function apply() {
    const terms = normalize(search.value).split(/\s+/).filter(Boolean);
    let count = 0;
    chapters.forEach(chapter => {
      const visible = (filter.value === 'all' || filter.value === chapter.dataset.status) &&
        terms.every(term => text.get(chapter.id).includes(term));
      chapter.hidden = !visible;
      if (visible) count++;
      const link = links.find(item => item.dataset.chapter === chapter.id);
      link.hidden = !visible;
    });
    empty.hidden = count !== 0;
    status.textContent = terms.length || filter.value !== 'all'
      ? `顯示 ${count} / ${chapters.length} 個章節 · 清空搜尋可恢復完整內容`
      : `共 ${chapters.length} 個章節 · 以目前新旅程為基準`;
  }
  function reset() { search.value = ''; filter.value = 'all'; apply(); }
  search.addEventListener('input', apply);
  filter.addEventListener('change', apply);
  document.querySelector('#reset').addEventListener('click', () => { reset(); search.focus(); });
  document.querySelector('#print').addEventListener('click', () => window.print());
  // Deep links remain readable after a search hid their target; printing always
  // includes the complete document via print CSS, without destroying the filter.
  function showHash() {
    const id = decodeURIComponent(location.hash.slice(1));
    const target = chapters.find(chapter => chapter.id === id);
    if (target?.hidden) { reset(); target.scrollIntoView(); }
  }
  window.addEventListener('hashchange', showHash);
  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver(entries => {
      const visible = entries.filter(entry => entry.isIntersecting && !entry.target.hidden);
      if (!visible.length) return;
      const id = visible[0].target.id;
      links.forEach(link => {
        const active = link.dataset.chapter === id;
        link.classList.toggle('active', active);
        if (active) link.setAttribute('aria-current', 'location');
        else link.removeAttribute('aria-current');
      });
    }, {rootMargin: '-10% 0px -65% 0px'});
    chapters.forEach(chapter => observer.observe(chapter));
  }
})();
