(() => {
 'use strict';
 const rows = __CATALOG__;
 const requested = new URLSearchParams(location.search).get('lang') || navigator.language;
 const code = requested.toLowerCase().replaceAll('-', '_');
 const locale = code === 'zh_tw' || code.includes('hant') || /^zh_(hk|mo)/.test(code) ? 'zh_TW' : code.startsWith('zh') ? 'zh_CN' : 'en';
 const t = (text, args = {}) => {
  let result = rows[text]?.[locale] ?? text;
  for (const [key, value] of Object.entries(args)) result = result.replaceAll('{'+key+'}', String(value));
  return result;
 };
 window.GuideText = { t, locale };
 document.documentElement.lang = {zh_TW:'zh-Hant',zh_CN:'zh-Hans',en:'en'}[locale];
 const walker = document.createTreeWalker(document.documentElement, NodeFilter.SHOW_TEXT);
 const nodes = [];
 while (walker.nextNode()) if (!['SCRIPT','STYLE'].includes(walker.currentNode.parentElement?.tagName)) nodes.push(walker.currentNode);
 for (const node of nodes) node.nodeValue = t(node.nodeValue);
 for (const element of document.querySelectorAll('[alt],[aria-label],[data-mobile],[data-desktop],meta[content]')) {
  for (const attr of ['alt','aria-label','data-mobile','data-desktop','content']) if(element.hasAttribute(attr)) element.setAttribute(attr,t(element.getAttribute(attr)));
 }
})();
