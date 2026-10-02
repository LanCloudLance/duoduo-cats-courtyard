const frame=document.querySelector('#game'),welcome=document.querySelector('#welcome'),play=document.querySelector('#play'),dialog=document.querySelector('dialog'),status=document.querySelector('#status');
function enter(mode){welcome.hidden=true;play.hidden=false;document.body.classList.add('playing');frame.src='game/index.html?mode='+encodeURIComponent(mode);frame.focus();}
function home(){frame.removeAttribute('src');play.hidden=true;welcome.hidden=false;document.body.classList.remove('playing');status.textContent='';}
document.querySelectorAll('[data-mode]').forEach(b=>b.onclick=()=>enter(b.dataset.mode));
document.querySelector('#help').onclick=()=>{dialog.showModal();frame.contentWindow?.postMessage({type:'duoduo-pause'},location.origin);};
document.querySelector('#close-help').onclick=()=>{dialog.close();if(!play.hidden)frame.focus();};
document.querySelector('#fullscreen').onclick=async()=>{try{if(!document.fullscreenElement)await (play.hidden?document.documentElement:play).requestFullscreen();else await document.exitFullscreen();}catch{status.textContent='此窗口暂不支持全屏，可使用浏览器独立窗口。';}};
window.addEventListener('message',e=>{if(e.origin!==location.origin||e.source!==frame.contentWindow)return;if(e.data.type==='duoduo-exit')home();if(e.data.type==='duoduo-error'){home();status.textContent='暂时无法进入游戏，请刷新重试。'+e.data.message;}});

document.querySelectorAll("[data-trial]").forEach(b=>b.onclick=()=>enter("trial-"+b.dataset.trial+"-"+document.querySelector("#trial-mode").value));
