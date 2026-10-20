/* Local diagnostic only. Counts WebAudio allocations without retaining AudioNodes. */
(() => {
  const totals = {buffers:0, pcmBytes:0, sources:0, gains:0, splitters:0, mergers:0, starts:0, stops:0, ended:0, disconnects:0};
  const methods = {createBufferSource:'sources', createGain:'gains', createChannelSplitter:'splitters',createChannelMerger:'mergers'};
  for (const [method,key] of Object.entries(methods)) {
    const original=BaseAudioContext.prototype[method];
    BaseAudioContext.prototype[method]=function(...args) {
      totals[key]++;
      const value=original.apply(this,args);
      if(key==='sources') value.addEventListener('ended',()=>totals.ended++,{once:true});
      return value;
    };
  }
  const buffer=BaseAudioContext.prototype.createBuffer;
  BaseAudioContext.prototype.createBuffer=function(channels,length,rate) {
    totals.buffers++;totals.pcmBytes+=channels*length*4;
    return buffer.call(this,channels,length,rate);
  };
  for (const name of ['start','stop']) {
    const original=AudioBufferSourceNode.prototype[name];
    AudioBufferSourceNode.prototype[name]=function(...args) {
      totals[name==='start'?'starts':'stops']++;
      return original.apply(this,args);
    };
  }
  const disconnect=AudioNode.prototype.disconnect;
  AudioNode.prototype.disconnect=function(...args){totals.disconnects++;return disconnect.apply(this,args);};
  let rows=[];
  window.CKSoak={receive(row) {
    const result={...row,audio:{...totals},jsHeap:performance.memory?.usedJSHeapSize??null};
    rows.push(result); if(rows.length>70)rows.shift();
    let pre=document.getElementById('soak-report');
    if(!pre) {
      pre=document.createElement('pre');pre.id='soak-report';
      Object.assign(pre.style,{position:'fixed',right:'0',top:'0',maxHeight:'95vh',overflow:'auto',fontSize:'11px',background:'#071018',color:'#adebdf',pointerEvents:'none'});
      document.body.append(pre);
    }
    pre.textContent=JSON.stringify({latest:result,samples:rows},null,2);
  }};
})();
