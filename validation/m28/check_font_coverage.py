from pathlib import Path
import struct,json
root=Path('outputs/duoduo-game');raw=(root/'assets/fonts/CourtyardSans.ttf').read_bytes()
u16=lambda p:struct.unpack_from('>H',raw,p)[0]
u32=lambda p:struct.unpack_from('>I',raw,p)[0]
s16=lambda p:struct.unpack_from('>h',raw,p)[0]
tables={raw[p:p+4].decode():u32(p+8) for p in range(12,12+u16(4)*16,16)}
cmap=tables['cmap'];subtables={cmap+u32(p+4) for p in range(cmap+4,cmap+4+u16(cmap+2)*8,8)}
def has(ch):
 for p in subtables:
  fmt=u16(p)
  if fmt==12:
   for g in range(p+16,p+16+u32(p+12)*12,12):
    lo,hi,glyph=struct.unpack_from('>III',raw,g)
    if lo<=ch<=hi:return glyph+ch-lo!=0
  elif fmt==4 and ch<=0xffff:
   n=u16(p+6)//2;end=p+14;start=end+2*n+2;delta=start+2*n;offset=delta+2*n
   for i in range(n):
    if u16(start+2*i)<=ch<=u16(end+2*i):
     d=s16(delta+2*i);r=u16(offset+2*i)
     if not r:g=(ch+d)&65535
     else:
      g=u16(offset+2*i+r+2*(ch-u16(start+2*i)))
      if g:g=(g+d)&65535
     if g:return True
 return False
chars=set()
for p in root.rglob('*.gd'):
 if 'tests' not in p.parts:chars.update(ord(c) for c in p.read_text() if '\u3400'<=c<='\u9fff')
missing=sorted(c for c in chars if not has(c));report={'cjk_used':len(chars),'missing':missing,'missing_text':''.join(chr(c) for c in missing),'method':'actual sfnt cmap 4/12 nonzero glyph mapping; comments and development labels included'}
Path('work/m28/font-coverage.json').write_text(json.dumps(report,ensure_ascii=False,indent=2));print(json.dumps(report,ensure_ascii=False))
