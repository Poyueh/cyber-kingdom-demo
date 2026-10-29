"""Apply a hash-pinned visual-only overlay to the forest Demo, never main/."""
import argparse
import hashlib
import json
from pathlib import Path


def sha(data):
    return hashlib.sha256(data).hexdigest()


def snapshot(site):
    return {p.relative_to(site).as_posix(): sha(p.read_bytes()) for p in site.rglob('*') if p.is_file()}


def apply(site, branding, release_tag):
    request = json.loads((branding / 'logo-trial.json').read_text())
    if release_tag != request['base_release']:
        return {'status': 'skipped', 'reason': 'Different base release; logo revision is not inherited.'}
    if request['schema'] != 1 or request['scope'] != 'forest-demo-loading-only':
        raise ValueError('Unsupported branding scope')
    expected = {'index.png', 'loading-illustration.css'}
    if set(request['assets']) != expected or set(request['original']) != expected:
        raise ValueError('Only root loading image and CSS may change')
    before = snapshot(site)
    assets = {}
    for target, asset in request['assets'].items():
        name = asset['file']
        if Path(name).name != name:
            raise ValueError('Unsafe branding path')
        data = (branding / name).read_bytes()
        if sha(data) != asset['sha256'] or before.get(target) != request['original'][target]:
            raise ValueError('Branding or base release checksum mismatch: ' + target)
        assets[target] = data
    # Validate every asset before changing any file. Never touch .pck, .wasm or main/.
    for target, data in assets.items():
        (site / target).write_bytes(data)
    after = snapshot(site)
    changed = {p for p in before.keys() | after.keys() if before.get(p) != after.get(p)}
    if changed != expected:
        raise ValueError('Unexpected distribution change')
    result = {
        'schema': 1, 'label': request['label'], 'base_release': request['base_release'],
        'runtime_game_version': request['runtime_game_version'],
        'runtime_spec_revision': request['runtime_spec_revision'],
        'scope': request['scope'], 'changed_files': sorted(changed),
        'original_sha256': {p: before[p] for p in sorted(changed)},
        'patched_sha256': {p: after[p] for p in sorted(changed)},
        'preserved_runtime_sha256': {p: h for p, h in after.items() if p in ('index.pck', 'index.wasm', 'index.js', 'index.html', 'spec/manifest.json') or p.startswith('main/')},
    }
    (site / 'logo-trial.json').write_text(json.dumps(result, indent=2) + '\n')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--site', type=Path, required=True)
    parser.add_argument('--branding', type=Path, required=True)
    parser.add_argument('--release-tag', required=True)
    args = parser.parse_args()
    result = apply(args.site, args.branding, args.release_tag)
    print(json.dumps({k: v for k, v in result.items() if k != 'preserved_runtime_sha256'}, indent=2))
