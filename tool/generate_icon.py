import sys, math
from PIL import Image, ImageDraw, ImageFilter
out = sys.argv[1]
S = 4096  # supersampled canvas
def lerp(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))

def gradient_bg():
    top, bot = (76,175,112), (22,84,52)
    small = Image.new('RGB', (256,256))
    px = small.load()
    for y in range(256):
        for x in range(256):
            t = min(1, max(0, (x*0.35 + y*0.9)/ (256*1.25)))
            px[x,y] = lerp(top, bot, t)
    bg = small.resize((S,S), Image.BICUBIC)
    # soft highlight top-left
    glow = Image.new('L', (S,S), 0)
    ImageDraw.Draw(glow).ellipse((-S*0.35,-S*0.45,S*0.75,S*0.55), fill=38)
    glow = glow.filter(ImageFilter.GaussianBlur(S*0.08))
    bg = Image.composite(Image.new('RGB',(S,S),(255,255,255)), bg, glow)
    return bg

def leaf(draw, cx, cy, length, width, angle_deg, fill, vein=None):
    # vesica leaf: polygon sampled along two arcs
    pts = []
    n = 120
    for i in range(n+1):
        t = i/n
        x = (t-0.5)*length
        y = -math.sin(math.pi*t)**0.9 * width/2
        pts.append((x,y))
    for i in range(n, -1, -1):
        t = i/n
        x = (t-0.5)*length
        y = math.sin(math.pi*t)**0.9 * width/2
        pts.append((x,y))
    a = math.radians(angle_deg)
    rot = [(cx + x*math.cos(a) - y*math.sin(a), cy + x*math.sin(a) + y*math.cos(a)) for x,y in pts]
    draw.polygon(rot, fill=fill)
    if vein:
        p1 = (cx - length*0.42*math.cos(a), cy - length*0.42*math.sin(a))
        p2 = (cx + length*0.40*math.cos(a), cy + length*0.40*math.sin(a))
        draw.line([p1,p2], fill=vein, width=int(S*0.011))

def mark(layer, scale=1.0, ox=0, oy=0):
    d = ImageDraw.Draw(layer)
    def P(v): return v*scale
    cx, cy = S/2 + ox, S/2 + oy
    white = (255,255,255,255)
    # bowl: lower half-ellipse
    bw, bh = P(S*0.60), P(S*0.30)
    rim_y = cy + P(S*0.04)
    d.pieslice((cx-bw/2, rim_y-bh, cx+bw/2, rim_y+bh), 0, 180, fill=white)
    # rim band
    rb = P(S*0.035)
    d.rounded_rectangle((cx-bw/2-P(S*0.02), rim_y-rb, cx+bw/2+P(S*0.02), rim_y+rb*0.6), radius=rb, fill=white)
    # foot
    fw, fh = P(S*0.20), P(S*0.045)
    fy = rim_y + bh - P(S*0.005)
    d.rounded_rectangle((cx-fw/2, fy-fh*0.4, cx+fw/2, fy+fh), radius=fh*0.5, fill=white)
    # stem (slight curve) + leaves attached at the stem
    sx, sy = cx, rim_y - rb
    top = (sx + P(S*0.02), sy - P(S*0.15))
    mid = (sx + P(S*0.004), sy - P(S*0.075))
    d.line([(sx, sy + P(S*0.01)), mid, top], fill=white, width=int(P(S*0.03)), joint='curve')
    def attach(base, L, ang):
        a = math.radians(ang)
        return base[0] + L/2*math.cos(a), base[1] + L/2*math.sin(a)
    L1, W1, A1 = P(S*0.30), P(S*0.155), -40
    c1 = attach(top, L1*0.96, A1)
    leaf(d, c1[0], c1[1], L1, W1, A1, (196,240,122,255), vein=(126,196,84,255))
    L2, W2, A2 = P(S*0.22), P(S*0.11), -148
    c2 = attach(mid, L2*0.96, A2)
    leaf(d, c2[0], c2[1], L2, W2, A2, white, vein=(208,232,214,255))

# 1) full app icon (no alpha, for iOS)
bg = gradient_bg().convert('RGBA')
m = Image.new('RGBA', (S,S), (0,0,0,0))
mark(m, 0.86, 0, -S*0.005)
shadow = Image.new('RGBA', (S,S), (0,0,0,0))
shadow.paste((10,50,30,90), mask=m.split()[3])
shadow = shadow.filter(ImageFilter.GaussianBlur(S*0.018))
bg.alpha_composite(shadow, (0, int(S*0.012)))
bg.alpha_composite(m)
bg.convert('RGB').resize((1024,1024), Image.LANCZOS).save(out + '/app_icon.png')

# 2) adaptive foreground (transparent, content in centre safe zone)
fg = Image.new('RGBA', (S,S), (0,0,0,0))
mark(fg, 0.56, 0, 0)
fg.resize((1024,1024), Image.LANCZOS).save(out + '/app_icon_foreground.png')

# 3) splash mark (green mark on transparent; shown on brand background)
sp = Image.new('RGBA', (S,S), (0,0,0,0))
mark(sp, 0.86, 0, 0)
sp.resize((768,768), Image.LANCZOS).save(out + '/splash_logo.png')
print('ok')
