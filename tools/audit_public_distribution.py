"""Validate public Web assets and remove links to private development documents."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import zipfile

PUBLIC_SUFFIXES = {'.html', '.js', '.css', '.json', '.png', '.webp', '.svg',
                   '.wasm', '.pck', '.txt', '.ico', '.jpg', '.woff', '.woff2'}


def audit_archive(archive):
    with zipfile.ZipFile(archive) as bundle:
        for info in bundle.infolist():
            path = PurePosixPath(info.filename)
            if (path.is_absolute() or '..' in path.parts or '\\' in info.filename
                    or any(part.startswith('.') for part in path.parts)
                    or (info.external_attr >> 16) & 0o170000 == 0o120000):
                raise ValueError('Unsafe public archive path: ' + info.filename)
            # Only exported runtime files and the published reader/preview belong here.
            if len(path.parts) > 1 and path.parts[0] not in {'spec', 'social'}:
                raise ValueError('Not a public runtime directory: ' + info.filename)
            if not info.is_dir() and path.suffix.lower() not in PUBLIC_SUFFIXES:
                raise ValueError('Source or unsupported file in public archive: ' + info.filename)


def sanitize_site(site):
    # Historic releases retain their original ZIP/checksum. Only the served reader
    # loses internal source links; game bytes and published design claims stay intact.
    for spec in (site / 'spec', site / 'main/spec'):
        page = spec / 'index.html'
        if not page.exists():
            continue
        html = page.read_text()
        html = re.sub(r'<details class="sources">.*?</details>', '', html, flags=re.S)
        html = re.sub(r'<a\b[^>]*href="https://github\.com/Poyueh/cyber-kingdom(?:-demo)?/(?:blob|tree)/[^"]*"[^>]*>.*?</a>', '', html, flags=re.S)
        page.write_text(html)
        manifest_path = spec / 'manifest.json'
        manifest = json.loads(manifest_path.read_text())
        for name in manifest['files']:
            path = (spec / name).resolve()
            if not path.is_relative_to(spec.resolve()):
                raise ValueError('Unsafe specification manifest path')
            manifest['files'][name] = hashlib.sha256(path.read_bytes()).hexdigest()
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--release', type=Path, required=True)
    parser.add_argument('--site', type=Path)
    args = parser.parse_args()
    for archive in args.release.glob('*Web-*.zip'):
        audit_archive(archive)
    if args.site:
        sanitize_site(args.site)
