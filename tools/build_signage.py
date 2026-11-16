#!/usr/bin/env python3
"""Original shelf lettering from bundled OFL Fredoka. fontTools is development-only."""
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.boundsPen import BoundsPen
root=Path(__file__).resolve().parent.parent
font=TTFont(root/'assets/fonts/Fredoka-Semibold.ttf');glyphs=font.getGlyphSet();cmap=font.getBestCmap()
labels={'tools':'Outillage','paint':'Peinture','garden':'Jardinage','electric':'Électricité','plumbing':'Plomberie','reserve':'RÉSERVE','delivery':'LIVRAISONS','extension1':'NOUVELLE AILE','extension2':'GRAND DÉPÔT','cash1':'CAISSE 1','cash2':'CAISSE 2','cash_locked':'+ CAISSE 2'}
labels.update({k+'_locked':'+ '+v for k,v in list(labels.items()) if k in ['tools','paint','garden','electric','plumbing']})
out=root/'assets/signs';out.mkdir(exist_ok=True)
for key,label in labels.items():
 pieces=[];x=0;lo=0;hi=0
 for char in label:
  name=cmap[ord(char)];g=glyphs[name];pen=SVGPathPen(glyphs);g.draw(pen);bounds=BoundsPen(glyphs);g.draw(bounds)
  if bounds.bounds:lo=min(lo,bounds.bounds[1]);hi=max(hi,bounds.bounds[3])
  pieces.append(f'<path transform="translate({x} 0)" d="{pen.getCommands()}"/>');x+=font['hmtx'][name][0]
 scale=min(968/max(1,x),192/max(1,hi-lo));tx=(1024-x*scale)/2;ty=(240+(hi+lo)*scale)/2
 svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="512" height="120" viewBox="0 0 1024 240"><title>{label}</title><g fill="#fff" transform="translate({tx:.3f} {ty:.3f}) scale({scale:.6f} {-scale:.6f})">'+''.join(pieces)+'</g></svg>'
 (out/(key+'.svg')).write_text(svg)
print(f'{len(labels)} original signs generated from bundled OFL font.')
