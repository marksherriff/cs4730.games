#!/usr/bin/env python3
"""Export f26 cartridges and regenerate the static class gallery (Python 3)."""
import argparse
import html
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unicodedata
from urllib.parse import quote

ROOT = Path(__file__).resolve().parent

def display(value):
    value = value.replace('_', ' ').replace('-', ' ').strip()
    return value.title() if value.islower() else value

def metadata(path):
    name = re.sub(r'\.p8$', '', path.stem, flags=re.IGNORECASE)
    canvas_name = re.match(r'^[^_]+_\d+_\d+_(?P<name>.+)$', name)
    if canvas_name:
        name = canvas_name.group('name')
        name = re.sub(r'(?:\s*\(\d+\)|[-_ ]\d+)$', '', name)
    else:
        name = re.sub(r'\s*\(\d+\)$', '', name)
    parts = name.rsplit('-', 2)
    if len(parts) != 3 or any(not p.strip() for p in parts):
        parts = name.rsplit('_', 2)
    if len(parts) != 3 or any(not p.strip() for p in parts):
        raise ValueError(f'{path.name}: use gamename-lastname-firstname.p8')
    title, last, first = parts
    return display(title), f'{display(first)} {display(last)}'

def sort_key(value):
    return ''.join(c for c in unicodedata.normalize('NFKD', value.casefold())
                   if not unicodedata.combining(c))

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pico8', default=os.environ.get('PICO8'), help='Path to the PICO-8 executable')
    args = parser.parse_args()
    source = ROOT / 'f26'
    source.mkdir(exist_ok=True)
    carts = [p for p in source.iterdir() if p.is_file() and p.suffix.lower() == '.p8']
    try:
        games = [(p, *metadata(p)) for p in carts]
    except ValueError as error:
        parser.error(str(error))
    games.sort(key=lambda g: (sort_key(g[1]), sort_key(g[2]), g[0].name))
    executable = args.pico8 or shutil.which('pico8')
    if not executable:
        for candidate in ['/Applications/pico-8/PICO-8.app/Contents/MacOS/pico8', '/Applications/PICO-8.app/Contents/MacOS/pico8']:
            if Path(candidate).is_file():
                executable = candidate
                break
    if games and not executable:
        parser.error('PICO-8 was not found. Use --pico8 /path/to/pico8.')
    cards = []
    # Stage exports first: an invalid cart never replaces the current gallery.
    with tempfile.TemporaryDirectory(prefix='pico-gallery-') as temporary:
        stage = Path(temporary)
        for number, (cart, title, designer) in enumerate(games):
            slug = cart.stem
            work = stage / str(number)
            work.mkdir()
            # A fixed output name keeps spaces and punctuation out of the export command.
            # PICO-8 refuses HTML export without a saved label. Add a plain
            # background to a temporary copy, preserving the submitted file.
            cartridge = cart.read_text(encoding='utf-8')
            export_cart = cart
            if '__label__' not in cartridge.splitlines():
                export_cart = work / 'input.p8'
                export_cart.write_text(cartridge.rstrip() + '\n__label__\n' + ('1' * 128 + '\n') * 128)
            result = subprocess.run([executable, str(export_cart), '-export', 'index.html'], cwd=work,
                                    capture_output=True, text=True, timeout=120)
            if result.returncode or not (work / 'index.html').is_file() or not (work / 'index.js').is_file():
                raise RuntimeError(f'Export failed for {cart.name}:\n{result.stdout}\n{result.stderr}')
            url = 'f26/players/' + quote(slug, safe='') + '/index.html'
            cards.append(f'''<article class="game">
  <iframe src="{html.escape(url, quote=True)}" title="Play {html.escape(title, quote=True)}" loading="lazy" allow="autoplay; fullscreen; gamepad" allowfullscreen></iframe>
  <div class="caption"><h2>{html.escape(title)}</h2><p>{html.escape(designer)}</p>
  <a href="{html.escape(url, quote=True)}" target="_blank" rel="noopener">Play in full window <span aria-hidden="true">↗</span></a></div>
</article>''')
        for number, (cart, _, _) in enumerate(games):
            destination = source / 'players' / cart.stem
            destination.mkdir(parents=True, exist_ok=True)
            for exported in (stage / str(number)).iterdir():
                if exported.suffix in {'.html', '.js', '.wasm'}:
                    shutil.copy2(exported, destination / exported.name)
    content = '\n'.join(cards) if cards else '<p class="empty">Games will appear here once the Fall 2026 submissions are ready.</p>'
    template = (ROOT / 'gallery-template.html').read_text()
    page = template.replace('<!-- GAME_COUNT -->', f'{len(games)} game' + ('' if len(games) == 1 else 's'))
    page = page.replace('<!-- GAMES -->', content)
    pending = ROOT / 'index.html.tmp'
    pending.write_text(page)
    pending.replace(ROOT / 'index.html')
    print(f'Built {len(games)} games: {ROOT / "index.html"}')

if __name__ == '__main__':
    main()
