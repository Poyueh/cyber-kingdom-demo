"""Unpack a release's verified web builds into the Pages site: Demo at the root, main game under main/."""
import argparse
import hashlib
import zipfile
from pathlib import Path

RUNTIME = ('index.html', 'index.js', 'index.wasm', 'index.pck', 'guide.html')
MAIN_FOLDER = 'main'
SYMLINK = 0o120000


def _verified(archive: Path, checksums: dict) -> Path:
    if hashlib.sha256(archive.read_bytes()).hexdigest() != checksums.get(archive.name):
        raise SystemExit('Web archive checksum mismatch: '+archive.name)
    return archive


def _extract(archive: Path, destination: Path) -> None:
    destination = destination.resolve()
    with zipfile.ZipFile(archive) as bundle:
        for entry in bundle.infolist():
            target = (destination/entry.filename).resolve()
            if not target.is_relative_to(destination) or (entry.external_attr >> 16) & 0o170000 == SYMLINK:
                raise SystemExit('Unsafe archive path: '+entry.filename)
        destination.mkdir(parents=True, exist_ok=True)
        bundle.extractall(destination)
    for name in RUNTIME:
        if not (destination/name).is_file() or (destination/name).stat().st_size == 0:
            raise SystemExit('Missing web runtime: '+name)


def unpack(release: Path, site: Path) -> dict:
    checksums = dict(line.split(maxsplit=1)[::-1] for line in (release/'SHA256SUMS.txt').read_text().splitlines() if line.strip())
    # Releases before the split shipped a single Cyber-Kingdom-Web archive.
    demo = sorted(release.glob('Cyber-Kingdom-Demo-Web-*.zip')) or sorted(release.glob('Cyber-Kingdom-Web-*.zip'))
    main = sorted(release.glob('Cyber-Kingdom-Main-Web-*.zip'))
    if len(demo) != 1 or len(main) > 1:
        raise SystemExit('Expected one Demo web archive and at most one main web archive')
    _extract(_verified(demo[0], checksums), site)
    if main:
        _extract(_verified(main[0], checksums), site/MAIN_FOLDER)
    (site/'.nojekyll').touch()
    return {'demo': demo[0].name, 'main': main[0].name if main else None}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--release', type=Path, required=True)
    parser.add_argument('--site', type=Path, required=True)
    args = parser.parse_args()
    print(unpack(args.release, args.site))
