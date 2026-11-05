'use strict';
const container = document.querySelector('#sounds');
const status = document.querySelector('#status');
const players = [];
const time = value => Number.isFinite(value) ? value > 0 && value < 1 ? `${value.toFixed(2)} s` : `${Math.floor(value / 60)}:${String(Math.floor(value % 60)).padStart(2, '0')}` : '–:––';
async function init() {
  try {
    const response = await fetch('sounds.json');
    if (!response.ok) throw new Error();
    const sounds = await response.json();
    if (sounds.length !== 10) throw new Error();
    sounds.forEach(({label, url}, index) => {
      const id = `s${index + 1}`;
      const card = document.createElement('article');
      card.className = 'sound';
      card.setAttribute('aria-labelledby', `${id}-title`);
      card.innerHTML = `<div class="card-top"><h3 id="${id}-title"></h3><label class="loop"><input type="checkbox" aria-label="Loop ${label}"> Loop</label></div><audio preload="metadata"></audio><div class="controls"><button class="play" disabled aria-label="Play ${label}">Play</button><button class="restart" disabled aria-label="Restart ${label}">Restart</button></div><label class="sr" for="${id}-seek">Playback position</label><input id="${id}-seek" class="seek" type="range" min="0" max="1" step="0.01" value="0" disabled aria-label="Seek ${label}"><div class="time"><span class="elapsed">0:00</span><span class="duration">–:––</span></div><label class="volume">Volume <input type="range" min="0" max="1" step="0.01" value="0.7" aria-label="Volume ${label}"></label><p class="error" role="status"></p>`;
      card.querySelector('h3').textContent = label;
      const audio = card.querySelector('audio');
      audio.src = url;
      audio.volume = 0.7;
      audio.setAttribute('aria-label', label);
      players.push(audio);
      const play = card.querySelector('.play');
      const restart = card.querySelector('.restart');
      const seek = card.querySelector('.seek');
      const error = card.querySelector('.error');
      const update = () => {
        card.querySelector('.elapsed').textContent = time(audio.currentTime);
        card.querySelector('.duration').textContent = time(audio.duration);
        if (Number.isFinite(audio.duration)) {
          seek.max = audio.duration;
          seek.value = audio.currentTime;
          seek.setAttribute('aria-valuetext', `${time(audio.currentTime)} of ${time(audio.duration)}`);
        }
      };
      const start = async () => {
        players.forEach(other => { if (other !== audio) other.pause(); });
        try { await audio.play(); error.textContent = ''; }
        catch { error.textContent = 'Playback could not start. Please try again.'; }
      };
      audio.addEventListener('loadedmetadata', () => { play.disabled = restart.disabled = seek.disabled = false; update(); });
      audio.addEventListener('timeupdate', update);
      audio.addEventListener('play', () => { players.forEach(other => { if (other !== audio) other.pause(); }); play.textContent = 'Pause'; play.setAttribute('aria-label', `Pause ${label}`); });
      const paused = () => { play.textContent = 'Play'; play.setAttribute('aria-label', `Play ${label}`); };
      audio.addEventListener('pause', paused);
      audio.addEventListener('ended', paused);
      audio.addEventListener('error', () => { error.textContent = 'This sound could not load. Refresh the page to try again.'; });
      play.addEventListener('click', () => audio.paused ? start() : audio.pause());
      restart.addEventListener('click', () => { audio.currentTime = 0; update(); start(); });
      seek.addEventListener('input', () => { audio.currentTime = Number(seek.value); update(); });
      card.querySelector('.volume input').addEventListener('input', event => { audio.volume = Number(event.target.value); });
      card.querySelector('.loop input').addEventListener('change', event => { audio.loop = event.target.checked; });
      container.append(card);
    });
    status.textContent = '';
  } catch { status.textContent = 'The examples could not load. Please refresh the page.'; }
}
init();
