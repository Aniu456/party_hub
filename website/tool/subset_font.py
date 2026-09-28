"""Create the bundled font from an upstream Noto Sans SC variable TTF.

Usage: python3 tool/subset_font.py /path/to/NotoSansSC.ttf
Requires fonttools. Rerun after changing the website's Chinese copy.
"""
from pathlib import Path
import sys

from fontTools import subset
from fontTools.ttLib import TTFont

root = Path(__file__).resolve().parents[1]
text = (root / 'lib/main.dart').read_text()
text += ''.join(chr(code) for code in range(32, 127))
options = subset.Options()
options.name_IDs = ['*']
font = TTFont(sys.argv[1])
missing = sorted(set(text) - set(map(chr, font.getBestCmap())) - {'\n', '\t', '\r'})
if missing:
    raise SystemExit(f'Source font lacks characters: {missing}')
subsetter = subset.Subsetter(options=options)
subsetter.populate(text=text)
subsetter.subset(font)
for record in font['name'].names:
    if record.nameID in {1, 3, 4, 6, 16}:
        record.string = 'PartySans'.encode(record.getEncoding())
font.save(root / 'assets/fonts/PartySans.ttf')
print('Bundled font updated.')
