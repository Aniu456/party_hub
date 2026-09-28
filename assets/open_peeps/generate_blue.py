"""Generate themed SVGs from the unmodified CC0 originals and reviewed clothing regions.

Restore originals from catalog.json sourceURL/path entries before running.
Run with Python 3 from any directory. The region paths use each body's local
coordinates. Head, face and accessory groups are never modified.
"""
import copy
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
NS = 'http://www.w3.org/2000/svg'
ET.register_namespace('', NS)
BLUE = '#3659E3'


def node(tag, **attrs):
    return ET.Element(f'{{{NS}}}{tag}', attrs)


def generate():
    regions = json.loads((ROOT / 'clothing_regions.json').read_text())
    catalog = json.loads((ROOT / 'catalog.json').read_text())
    if any(not (ROOT / 'originals' / a['category'] / f"{a['id']}.svg").is_file()
           for a in catalog['assets']):
        raise SystemExit('Original SVGs were removed. Restore them using catalog.json '
                         'sourceURL/path entries before regenerating; see README.md.')
    for asset in catalog['assets']:
        source = ROOT / 'originals' / asset['category'] / f"{asset['id']}.svg"
        tree = ET.parse(source)
        for group in list(tree.getroot().iter()):
            name = group.get('id', '')
            if not name.startswith(('body/', 'pose/')):
                continue
            paths = [p for p in group.iter() if p.tag == f'{{{NS}}}path']
            parents = {child: parent for parent in group.iter() for child in parent}
            # White garments: only reviewed areas receive a blue underpainting.
            inks = [p for p in paths if p.get('fill', '').upper() == '#000000']
            spec = regions.get(name, {})
            paint = node('g')
            for d in spec.get('paths', []):
                region = node('path', d=d, fill=BLUE)
                region.set('fill-rule', 'evenodd')
                paint.append(region)
            if spec.get('protect'):
                clip = node('clipPath', id='clothing-skin-protection')
                cutout = node('path', d='M-1000,-1000 H2000 V2000 H-1000 Z ' + ' '.join(spec['protect']))
                cutout.set('clip-rule', 'evenodd')
                clip.append(cutout)
                defs = node('defs')
                defs.append(clip)
                group.append(defs)
                paint.set('clip-path', 'url(#clothing-skin-protection)')
            group.append(paint)
            # Restore original lines over the sampled region boundary.
            for ink in inks:
                if parents[ink] is group:
                    group.remove(ink)
                    group.append(ink)
            # Black garments: tint their interior, keeping a black boundary.
            # Clipping to the original ink preserves all white holes and skin.
            for i, ink in enumerate(inks):
                clip_id = f'clothing-ink-{i}'
                defs = node('defs')
                clip = node('clipPath', id=clip_id)
                shape = copy.deepcopy(ink)
                shape.attrib.pop('id', None)
                clip.append(shape)
                defs.append(clip)
                parents[ink].append(defs)
                tint = copy.deepcopy(ink)
                tint.attrib.pop('id', None)
                tint.set('fill', BLUE)
                tint.set('stroke', '#000000')
                tint.set('stroke-width', '2.4')
                tint.set('stroke-linejoin', 'round')
                tint.set('clip-path', f'url(#{clip_id})')
                parents[ink].append(tint)
        destination = ROOT / 'blue' / asset['category'] / source.name
        destination.parent.mkdir(parents=True, exist_ok=True)
        tree.write(destination, encoding='utf-8', xml_declaration=True)
    print(f"Generated {len(catalog['assets'])} blue SVGs")


if __name__ == '__main__':
    generate()
