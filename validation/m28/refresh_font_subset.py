from pathlib import Path
from fontTools import subset
from fontTools.ttLib import TTFont
root=Path('outputs/duoduo-game')
out=root/'assets/fonts/CourtyardSans.ttf'
old=TTFont(out);points=set(old.getBestCmap());old.close()
for p in root.rglob('*.gd'):
    if 'tests' not in p.parts:points.update(ord(c) for c in p.read_text())
full=TTFont('work/fonts/CourtyardRegular.ttf');points&=set(full.getBestCmap())
options=subset.Options();options.name_IDs=['*'];options.name_legacy=True;options.name_languages=['*'];options.notdef_glyph=True;options.notdef_outline=True;options.recommended_glyphs=True
worker=subset.Subsetter(options=options);worker.populate(unicodes=points);worker.subset(full);full.save(out);full.close()
print('Retained prior glyphs and current production text:',len(points),'codepoints;',out.stat().st_size,'bytes')
