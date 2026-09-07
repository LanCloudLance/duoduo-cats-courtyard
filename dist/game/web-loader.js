// Transfer the official engine gzip as ordinary bytes, then stream-decompress it.
// This keeps each hosted asset small without requiring custom server headers.
const originalFetch = window.fetch.bind(window);
window.fetch = async function(input, init) {
  const url = new URL(typeof input === 'string' ? input : input.url, location.href);
  if (url.origin === location.origin && url.pathname.endsWith('/index.wasm')) {
    if (!('DecompressionStream' in window)) throw new Error('请更新浏览器后再进入庭院。');
    const response = await originalFetch(new URL('engine.bin', url), init);
    if (!response.ok) throw new Error('游戏加载失败，请重新打开页面。');
    return new Response(response.body.pipeThrough(new DecompressionStream('gzip')), {
      headers: {'Content-Type':'application/wasm'}
    });
  }
  return originalFetch(input, init);
};

window.addEventListener('message',event=>{
  if(event.origin===location.origin && event.source===parent && event.data.type==='duoduo-pause') window.duoduoPause?.();
});
