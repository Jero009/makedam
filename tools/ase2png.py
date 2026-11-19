import struct, zlib, sys, os
from PIL import Image

def parse_ase(path):
    with open(path,'rb') as f: data = f.read()
    frames = struct.unpack_from('<H', data, 6)[0]
    W = struct.unpack_from('<H', data, 8)[0]
    H = struct.unpack_from('<H', data, 10)[0]
    depth = struct.unpack_from('<H', data, 12)[0]
    off = 128
    layers, cels = [], []
    for fi in range(frames):
        old_chunks = struct.unpack_from('<H', data, off+6)[0]
        chunks = struct.unpack_from('<I', data, off+12)[0] if old_chunks == 0xFFFF else old_chunks
        off += 16
        for ci in range(chunks):
            csize = struct.unpack_from('<I', data, off)[0]
            ctype = struct.unpack_from('<H', data, off+4)[0]
            body = off+6
            if ctype == 0x2004:
                nlen = struct.unpack_from('<H', data, body+16)[0]
                name = data[body+18:body+18+nlen].decode('utf8','replace')
                layers.append(name)
            elif ctype == 0x2005:
                lidx = struct.unpack_from('<H', data, body)[0]
                x, y = struct.unpack_from('<2h', data, body+2)
                op = data[body+6]
                ct = struct.unpack_from('<H', data, body+7)[0]
                cw, ch = struct.unpack_from('<2H', data, body+16)
                if ct == 0:
                    px = data[body+20:body+20+cw*ch*4]
                    im = Image.frombytes('RGBA', (cw,ch), px)
                elif ct == 2:
                    raw = zlib.decompress(data[body+20:off+csize])
                    im = Image.frombytes('RGBA', (cw,ch), raw[:cw*ch*4])
                else:
                    continue
                cels.append((lidx,x,y,op,im))
            off += csize
    canvas = Image.new('RGBA', (W,H), (0,0,0,0))
    for lidx,x,y,op,im in cels:
        a = im.getchannel('A').point(lambda v,o=op: v*o//255)
        im.putalpha(a)
        canvas.alpha_composite(im,(x,y))
    return canvas

base = '/home/jero/Programming/games/makedam/assets'
names = sys.argv[1:]
for n in names:
    src = os.path.join(base, n)
    try:
        im = parse_ase(src)
        im.save(os.path.join(base, os.path.splitext(n)[0]+'.png'))
        cols = im.getcolors(maxcolors=10000)
        print(n, im.size, 'colors:', len(cols) if cols else '>10k')
    except Exception as e:
        print(n, 'FAILED:', repr(e))
