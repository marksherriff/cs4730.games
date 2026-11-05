const $ = id => document.getElementById(id);
const audio = new Audio(); audio.preload = 'metadata'; audio.volume = .8;
let stopped = false;
let sounds = [], phrases = [], current = null, history = [], drawn = new Set(), excluded = new Set(), edits = {}, presenting = false, editing = null, request = 0;
try { const saved = JSON.parse(localStorage.getItem('audio-bingo-v1') || '{}'); excluded = new Set(saved.excluded || []); edits = saved.edits || {}; } catch {}
function persist() { try { localStorage.setItem('audio-bingo-v1', JSON.stringify({excluded:[...excluded], edits})); } catch { $('message').textContent = 'Browser storage unavailable; changes will last for this session only.'; } }
const neutral = s => `Sound ${String(s.number).padStart(2, '0')}`;
const title = s => presenting ? neutral(s) : s.name;
const associations = s => edits[s.id] ?? s.associations;
function node(tag, text, cls) { const n = document.createElement(tag); if (text != null) n.textContent = text; if (cls) n.className = cls; return n; }
function button(text, fn, cls) { const b = node('button', text, cls); b.onclick = fn; return b; }
function visible() { const query = $('search').value.toLowerCase(); return sounds.filter(s => (!$('type').value || s.type === $('type').value) && (!$('category').value || s.category === $('category').value) && [s.name,s.filename,s.category,...associations(s)].join(' ').toLowerCase().includes(query)); }
function pool() { return visible().filter(s => !excluded.has(s.id)); }
function render() {
  const list = presenting ? sounds : visible(); $('count').textContent = `(${list.length})`;
  $('sounds').replaceChildren();
  if (!list.length) $('sounds').append(node('p','No matching sounds. Try another search or filter.','hint'));
  for (const s of list) {
    const card = node('article', null, `card${current?.id === s.id ? ' active' : ''}`);
    const top = node('div', null, 'card-top'); top.append(node('span',neutral(s),'number')); if (!presenting) top.append(node('span',`${s.type === 'music' ? 'Music' : 'Effect'} / ${s.category}`,'kind')); card.append(top,node('h3',title(s)));
    if (!presenting) card.append(node('div',s.filename,'filename'),node('div',associations(s).join(' · ') || 'No suggestions yet','tags'));
    const actions = node('div',null,'card-actions'); actions.append(button('▶ Play',()=>play(s), current?.id === s.id ? 'primary' : ''));
    if (!presenting) { actions.append(button('Edit',()=>edit(s))); const label=node('label'); const check=node('input'); check.type='checkbox'; check.checked=!excluded.has(s.id); check.onchange=()=>{ check.checked ? excluded.delete(s.id) : excluded.add(s.id); persist(); updatePool(); }; label.append(check,document.createTextNode(' In pool')); actions.append(label); }
    card.append(actions); $('sounds').append(card);
  }
  $('history').replaceChildren();
  for (const entry of [...history].reverse()) { const li=node('li'); li.append(button(entry.sound.name,()=>play(entry.sound)),node('small',`${neutral(entry.sound)} · ${entry.at}`)); $('history').append(li); }
  if (!history.length) $('history').append(node('li','No sounds played yet.'));
  $('current').textContent = current ? title(current) : 'Ready when you are';
  $('detail').textContent = presenting ? 'Listen closely. What do you hear?' : current ? `${current.filename} · ${associations(current).join(' · ')}` : 'Choose a sound or let the shuffle decide.';
  updatePool();
}
function updatePool() { const selected=pool(); const remaining=selected.filter(s=>!drawn.has(s.id)).length; $('pool-count').textContent=`${remaining} of ${selected.length} sounds remaining in this shuffle. Filters define the pool.`; $('next').disabled=!remaining; }
function sync() { $('toggle').textContent=audio.paused ? 'Play' : 'Pause'; $('state').textContent=stopped ? 'Stopped' : audio.error ? 'Unavailable' : audio.ended ? 'Finished' : audio.paused ? (current ? 'Paused' : 'Idle') : 'Playing'; }
async function play(s, replay=false) {
  const token=++request; stopped=false; audio.pause(); $('message').textContent='';
  if (!replay || current?.id!==s.id) { audio.src=s.url.split('/').map(encodeURIComponent).join('/'); current=s; }
  audio.currentTime=0; audio.loop=s.type==='music' && $('loop').checked; $('loop').disabled=s.type!=='music';
  $('toggle').disabled=false; $('restart').disabled=false; render();
  try { await audio.play(); if(token!==request) return; drawn.add(s.id); history.push({sound:s,at:new Date().toLocaleTimeString([], {hour:'2-digit',minute:'2-digit'})}); render(); sync(); }
  catch(e) { if(token===request && e.name!=='AbortError') { $('message').textContent=presenting ? `${neutral(s)} cannot play. Try another sound.` : `Cannot play ${s.filename}. The file may be missing, unsupported, or blocked by the browser. Try another sound.`; $('state').textContent='Unavailable'; } }
}
function edit(s) { editing=s; $('edit-name').textContent=s.name; $('phrases').replaceChildren(); for(const p of phrases) {const label=node('label'); const c=node('input'); c.type='checkbox'; c.value=p;c.checked=associations(s).includes(p);label.append(c,document.createTextNode(' '+p));$('phrases').append(label);} $('editor').showModal(); }
$('save').onclick=()=>{edits[editing.id]=[...$('phrases').querySelectorAll('input:checked')].map(c=>c.value);persist();render();};
$('toggle').onclick=()=>{if(!current)return;stopped=false;if(audio.paused){audio.play().catch(()=>{$('message').textContent='Unable to resume. Try Replay or another sound.';});}else audio.pause();};
$('restart').onclick=()=>current && play(current,true);
$('stop').onclick=()=>{++request;stopped=true;audio.pause(); if(current)audio.currentTime=0; $('message').textContent='';sync();$('state').textContent='Stopped';};
$('volume').oninput=()=>audio.volume=Number($('volume').value);
$('loop').onchange=()=>audio.loop=current?.type==='music' && $('loop').checked;
$('seek').oninput=()=>{if(Number.isFinite(audio.duration))audio.currentTime=Number($('seek').value);};
const format=t=>Number.isFinite(t)?`${Math.floor(t/60)}:${String(Math.floor(t%60)).padStart(2,'0')}`:'0:00';
function progress(){const valid=Number.isFinite(audio.duration)&&audio.duration>0;$('seek').disabled=!valid;$('seek').max=valid?audio.duration:100;$('seek').value=audio.currentTime||0;$('time').textContent=`${format(audio.currentTime)} / ${format(audio.duration)}`;}
for(const event of ['timeupdate','loadedmetadata','durationchange','emptied']) audio.addEventListener(event,progress);
for(const event of ['play','pause','ended'])audio.addEventListener(event,sync);
audio.addEventListener('error',()=>{ $('state').textContent='Unavailable';$('message').textContent=presenting?'This sound is unavailable. Try another sound.':`Unable to load ${current?.filename || 'audio'}: missing file or unsupported audio format. Try another sound.`;});
$('next').onclick=()=>{const remaining=pool().filter(s=>!drawn.has(s.id));if(remaining.length)play(remaining[Math.floor(Math.random()*remaining.length)]);};
$('round').onclick=()=>{drawn.clear();updatePool();};
$('reset').onclick=()=>{history=[];drawn.clear();render();};
for(const id of ['search','type','category'])$(id).addEventListener(id==='search'?'input':'change',render);
$('include-all').onclick=()=>{visible().forEach(s=>excluded.delete(s.id));persist();render();};
$('exclude-all').onclick=()=>{visible().forEach(s=>excluded.add(s.id));persist();render();};
$('presentation').onclick=()=>{presenting=!presenting;$('editor').close();document.body.classList.toggle('presenting',presenting);$('presentation').setAttribute('aria-pressed',presenting);$('presentation').textContent=presenting?'◎ Exit presentation':'◎ Presentation mode';$('message').textContent='';render();};
try { const response=await fetch('manifest.json');if(!response.ok)throw Error();const data=await response.json(); sounds=data.sounds;phrases=data.phrases;for(const c of [...new Set(sounds.map(s=>s.category))].sort()) {const o=node('option',c);o.value=c;$('category').append(o);}render(); }
catch { $('message').textContent='The sound library could not load. Run the build script and serve the dist folder over HTTP; see README.';$('next').disabled=true; }
