#!/usr/bin/env python3
"""Generate polished, name-aware artwork for every menu dish without a photo.

The image uses a charcoal tabletop, ceramic serving plate, food-specific
silhouette, ingredient colors inferred from the dish name, and a clear caption.
All artwork is deterministic, so rebuilding the same product keeps its image.
Matching food photographs take priority in the app.

Usage:
    python3 scripts/generate_dish_images.py                 # all dishes missing art
    python3 scripts/generate_dish_images.py --limit 200     # quick sample
"""
import argparse
import colorsys
import hashlib
import json
import random
import re
import sys
import unicodedata
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError:
    sys.exit('Pillow is required: pip install Pillow')

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'frontend' / 'assets' / 'images' / 'generated'
W, H = 640, 480

# Cuisine background tints — kept warm and light to sit on the app's ivory UI.
CUISINE_TINT = {
    'Indian': (24, 0.52, 0.52), 'Italian': (8, 0.48, 0.54),
    'Burgers': (28, 0.52, 0.54), 'Asian': (350, 0.32, 0.50),
    'South Indian': (38, 0.52, 0.52), 'Mexican': (12, 0.52, 0.54),
    'Japanese': (210, 0.22, 0.52), 'Thai': (20, 0.48, 0.52),
    'Korean': (8, 0.45, 0.50), 'Mediterranean': (190, 0.28, 0.50),
    'Lebanese': (42, 0.48, 0.54), 'Healthy': (120, 0.28, 0.50),
    'Desserts': (330, 0.40, 0.60), 'Bakery': (30, 0.38, 0.58),
    'Breakfast': (45, 0.52, 0.58), 'Beverages': (25, 0.40, 0.52),
    'BBQ': (18, 0.48, 0.44), 'Bengali': (35, 0.50, 0.48),
    'Seafood': (200, 0.35, 0.46), 'Street Food': (15, 0.52, 0.52),
}

# Dish-type templates. Specific foods come before broad ingredient words so
# pasta, dumplings, pastries and South Indian breakfast foods get their own art.
# (keyword, template_id) — first match wins.
DISH_TYPE = [
    (['pizza', 'margherita'], 'pizza'),
    (['pasta', 'lasagna', 'spaghetti', 'fettuccine', 'carbonara', 'risotto'], 'pasta'),
    (['burger'], 'burger'),
    (['sushi', 'maki', 'nigiri', 'sashimi'], 'sushi'),
    (['dumpling', 'gyoza', 'mandu', 'momo'], 'dumpling'),
    (['idli', 'vada', 'uttapam', 'pongal'], 'south_indian'),
    (['dosa'], 'dosa'),
    (['soup', 'shorba', 'ramen', 'broth'], 'soup'),
    (['noodle', 'hakka', 'pad thai', 'chow mein', 'lo mein', 'japchae'], 'noodles'),
    (['biryani', 'pulao', 'fried rice', 'rice bowl', 'chawal', 'risotto'], 'rice'),
    (['sandwich', 'wrap', 'kathi', 'shawarma', 'burrito'], 'wrap'),
    (['fries', 'wedges', 'nuggets', 'pakora', 'samosa', 'spring roll'], 'fried'),
    (['naan', 'roti', 'paratha', 'focaccia', 'toast', 'croissant', 'bread', 'loaf'], 'bread'),
    (['ice cream', 'kulfi', 'gelato', 'mochi', 'sundae', 'brownie',
      'cake', 'tiramisu', 'panna cotta', 'cheesecake', 'halwa', 'kheer',
      'gulab jamun', 'rasgulla', 'sandesh', 'mishti', 'pudding', 'tart',
      'waffle', 'pancake', 'muffin', 'cookie', 'croissant', 'bread', 'loaf',
      'pie', 'torte', 'flan', 'churros', 'knafeh'], 'dessert'),
    (['tea', 'coffee', 'latte', 'lassi', 'juice', 'soda', 'milkshake',
      'smoothie', 'lemonade', 'water', 'shake', 'chai', 'brew', 'espresso'], 'drink'),
    (['salad', 'bowl', 'quinoa', 'avocado'], 'salad'),
    (['taco', 'quesadilla', 'nachos', 'burrito', 'enchilada'], 'taco'),
    (['curry', 'masala', 'kadai', 'korma', 'dal', 'paneer', 'kofta',
      'chana', 'rajma', 'palak', 'aloo', 'gobi', 'bhindi', 'saag',
      'tikka', 'kebab', 'kabab', 'rogan', 'kadhi', 'chettinad',
      'chicken', 'mutton', 'lamb', 'fish', 'prawn', 'crab', 'squid',
      'seafood', 'shrimp', 'salmon', 'tuna'], 'curry'),
]


def seed_for(name: str) -> int:
    return int(hashlib.sha256(name.encode('utf-8')).hexdigest()[:12], 16)


def hsl(h, s, l):
    r, g, b = colorsys.hls_to_rgb((h % 360) / 360.0, l, s)
    return int(r * 255), int(g * 255), int(b * 255)


def load_font(size: int, bold: bool = False):
    candidates = [
        '/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf' % ('-Bold' if bold else ''),
        '/usr/share/fonts/truetype/liberation/LiberationSans%s.ttf'
        % ('-Bold' if bold else '-Regular'),
    ]
    for path in candidates:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def strip_portion(name: str) -> str:
    return re.split(r'\s·\s', name)[0].strip() or name.strip()


def wrap(draw, text, font, max_width):
    words, lines, current = text.split(), [], ''
    for word in words:
        candidate = f'{current} {word}'.strip()
        if draw.textlength(candidate, font=font) <= max_width or not current:
            current = candidate
        else:
            lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def dish_type(name: str) -> str:
    lowered = name.lower()
    for keywords, template in DISH_TYPE:
        if any(k in lowered for k in keywords):
            return template
    return 'curry'


def ingredient_colours(name: str, vegetarian: bool, hue: float):
    """Return a stable ingredient palette inferred from the actual dish name."""
    lowered = name.lower()
    colours = []
    cues = (
        (('tomato', 'marinara', 'red sauce', 'tikka', 'masala'), (202, 0.66, 0.46)),
        (('cheese', 'mozzarella', 'paneer', 'cream', 'butter'), (44, 0.66, 0.70)),
        (('spinach', 'palak', 'herb', 'basil', 'mint', 'avocado'), (126, 0.45, 0.43)),
        (('chicken', 'turkey'), (27, 0.49, 0.48)),
        (('beef', 'lamb', 'mutton', 'bacon', 'pork'), (14, 0.55, 0.38)),
        (('fish', 'prawn', 'shrimp', 'salmon', 'seafood', 'crab'), (195, 0.47, 0.55)),
        (('mushroom',), (25, 0.18, 0.35)),
        (('corn',), (49, 0.82, 0.57)),
        (('chocolate', 'cocoa', 'coffee'), (19, 0.58, 0.30)),
        (('strawberry', 'berry', 'raspberry'), (349, 0.70, 0.52)),
        (('mango', 'lemon', 'citrus', 'orange'), (39, 0.78, 0.57)),
        (('cucumber', 'lettuce', 'salad', 'greens'), (105, 0.46, 0.47)),
        (('egg',), (48, 0.72, 0.72)),
    )
    for words, colour in cues:
        if any(word in lowered for word in words):
            colours.append(hsl(*colour))
    if not colours:
        colours.append(hsl((hue + (24 if vegetarian else -12)) % 360, 0.52, 0.54))
    if len(colours) == 1:
        colours.append(hsl((hue + 78) % 360, 0.44, 0.50))
    return colours


def render(dish_name: str, cuisine: str, vegetarian: bool) -> Image.Image:
    seed = seed_for(dish_name)
    rng = random.Random(seed)
    base_hue, base_sat, base_light = CUISINE_TINT.get(cuisine, (35, 0.45, 0.52))
    hue = (base_hue + (seed % 20) - 10) % 360

    # Charcoal tabletop with warm cuisine-tinted grain, so the cream plate and
    # food remain the brightest parts of each tile.
    img = Image.new('RGB', (W, H), hsl(hue, base_sat * 0.30, 0.16))
    draw = ImageDraw.Draw(img)

    # Subtle texture bands.
    band_hue = (hue + 18 + (seed % 16)) % 360
    for i in range(7):
        offset = rng.randint(-220, 220)
        shade = (band_hue + i * 7) % 360
        colour = hsl(shade, base_sat * 0.28, 0.12 + i * 0.012)
        draw.polygon(
            [(offset, H), (offset + 240 + i * 32, 0), (offset + 360 + i * 32, 0),
             (offset + 140, H)],
            fill=colour,
        )
    img = img.filter(ImageFilter.GaussianBlur(20))
    draw = ImageDraw.Draw(img)
    for _ in range(24):
        px, py = rng.choice([rng.randint(20, 90), rng.randint(W - 90, W - 20)]), rng.randint(16, H - 120)
        radius = rng.randint(1, 3)
        draw.ellipse([px - radius, py - radius, px + radius, py + radius], fill=(104, 58, 32))

    cx, cy = W // 2, int(H * 0.405)
    template = dish_type(dish_name)
    food_hue = (hue + rng.randint(-6, 6)) % 360
    ingredients = ingredient_colours(dish_name, vegetarian, food_hue)

    # Raised ceramic plate, a soft drop shadow, and a fine double rim make the
    # dish read as a plated meal instead of floating shapes on a flat backdrop.
    draw.ellipse([cx - 183, cy - 112, cx + 183, cy + 145], fill=(91, 61, 43))
    draw.ellipse([cx - 177, cy - 120, cx + 177, cy + 132], fill=(255, 253, 248))
    draw.ellipse([cx - 157, cy - 103, cx + 157, cy + 114], fill=(234, 226, 211))
    draw.ellipse([cx - 148, cy - 96, cx + 148, cy + 105], fill=(250, 247, 238))

    if template == 'pizza':
        # Round pizza with crust and toppings.
        r = 135
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=hsl(food_hue, 0.35, 0.72))
        draw.ellipse([cx - r + 14, cy - r + 14, cx + r - 14, cy + r - 14],
                     fill=hsl(food_hue, 0.50, 0.52))
        # Toppings.
        for _ in range(8):
            px = cx + rng.randint(-70, 70)
            py = cy + rng.randint(-70, 70)
            if (px - cx) ** 2 + (py - cy) ** 2 < 4000:
                rr = rng.randint(6, 12)
                draw.ellipse([px - rr, py - rr, px + rr, py + rr],
                             fill=hsl((food_hue + 120) % 360, 0.45, 0.42))
    elif template == 'burger':
        # Bun, patty, lettuce.
        bw, bh = 150, 40
        draw.ellipse([cx - bw, cy - 30, cx + bw, cy + bh], fill=hsl(30, 0.55, 0.55))
        draw.rectangle([cx - bw + 10, cy - 10, cx + bw - 10, cy + 25], fill=hsl(20, 0.60, 0.38))
        draw.ellipse([cx - bw + 5, cy - 40, cx + bw - 5, cy - 10], fill=hsl(30, 0.55, 0.55))
        draw.ellipse([cx - bw + 20, cy - 25, cx - bw + 50, cy - 5], fill=hsl(110, 0.40, 0.45))
        draw.ellipse([cx + bw - 50, cy - 25, cx + bw - 20, cy - 5], fill=hsl(110, 0.40, 0.45))
    elif template == 'sushi':
        # Row of rolls.
        for i in range(5):
            x = cx - 90 + i * 45
            draw.ellipse([x - 22, cy - 22, x + 22, cy + 22], fill=hsl(0, 0.0, 0.15))
            draw.ellipse([x - 16, cy - 16, x + 16, cy + 16], fill=hsl(120, 0.35, 0.55))
            draw.ellipse([x - 6, cy - 6, x + 6, cy + 6], fill=hsl(0, 0.0, 0.95))
    elif template == 'dosa':
        # Crisp crepe with toasted spots, a visible fold, and two chutneys.
        dosa = [cx - 139, cy - 46, cx + 139, cy + 52]
        draw.ellipse(dosa, fill=(180, 112, 48))
        draw.ellipse([cx - 133, cy - 51, cx + 133, cy + 44], fill=(235, 181, 95))
        draw.ellipse([cx - 121, cy - 43, cx + 121, cy + 34], fill=(247, 211, 139))
        for _ in range(34):
            px, py = cx + rng.randint(-112, 112), cy + rng.randint(-36, 25)
            rr = rng.randint(2, 6)
            draw.ellipse([px - rr, py - rr, px + rr, py + rr], fill=(190, 126, 57))
        draw.arc([cx - 122, cy - 42, cx + 122, cy + 43], 190, 350, fill=(255, 229, 166), width=5)
        if any(word in dish_name.lower() for word in ('masala', 'paneer', 'cheese', 'potato')):
            for _ in range(10):
                px, py = cx + rng.randint(-48, 48), cy + rng.randint(-12, 22)
                draw.ellipse([px - 7, py - 5, px + 7, py + 5], fill=ingredients[0])
        if 'cheese' in dish_name.lower():
            for _ in range(8):
                px = cx + rng.randint(-72, 72)
                draw.line([(px, cy - 4), (px + rng.randint(-12, 12), cy + 20)], fill=(255, 236, 172), width=3)
        # Chutney bowls and sambar dots.
        draw.ellipse([cx - 132, cy + 54, cx - 82, cy + 95], fill=(221, 213, 193))
        draw.ellipse([cx - 127, cy + 56, cx - 87, cy + 88], fill=(115, 143, 79))
        draw.ellipse([cx + 84, cy + 54, cx + 134, cy + 95], fill=(221, 213, 193))
        draw.ellipse([cx + 89, cy + 56, cx + 129, cy + 88], fill=(173, 91, 48))
    elif template == 'south_indian':
        lowered = dish_name.lower()
        if 'idli' in lowered:
            for px, py in [(cx - 54, cy - 15), (cx + 5, cy - 32), (cx + 57, cy - 5)]:
                draw.ellipse([px - 34, py - 25, px + 34, py + 26], fill=(225, 218, 196))
                draw.ellipse([px - 29, py - 24, px + 29, py + 19], fill=(255, 250, 232))
        elif 'vada' in lowered:
            for px, py in [(cx - 52, cy - 8), (cx + 22, cy - 30), (cx + 69, cy + 24)]:
                draw.ellipse([px - 35, py - 34, px + 35, py + 34], fill=(190, 115, 48))
                draw.ellipse([px - 17, py - 17, px + 17, py + 17], fill=(250, 247, 238))
                draw.ellipse([px - 28, py - 27, px + 28, py + 27], outline=(234, 178, 94), width=5)
        else:
            draw.ellipse([cx - 108, cy - 58, cx + 108, cy + 67], fill=(197, 133, 65))
            draw.ellipse([cx - 98, cy - 55, cx + 98, cy + 54], fill=(238, 189, 107))
            for _ in range(20):
                px, py = cx + rng.randint(-76, 76), cy + rng.randint(-35, 34)
                draw.ellipse([px - 5, py - 4, px + 5, py + 4], fill=ingredients[1])
    elif template == 'soup':
        # Bowl with liquid.
        draw.ellipse([cx - 120, cy - 60, cx + 120, cy + 90], fill=hsl(0, 0.0, 0.92))
        draw.ellipse([cx - 105, cy - 45, cx + 105, cy + 75], fill=hsl(food_hue, 0.45, 0.55))
        for _ in range(5):
            px = cx + rng.randint(-60, 60)
            py = cy + rng.randint(-20, 40)
            draw.ellipse([px - 6, py - 6, px + 6, py + 6], fill=hsl(food_hue, 0.30, 0.75))
    elif template == 'noodles':
        # Tangled noodles in a bowl.
        draw.ellipse([cx - 134, cy - 58, cx + 134, cy + 88], fill=(193, 179, 155))
        draw.ellipse([cx - 120, cy - 47, cx + 120, cy + 73], fill=(89, 48, 31))
        draw.ellipse([cx - 109, cy - 40, cx + 109, cy + 61], fill=hsl(food_hue, 0.65, 0.38))
        for _ in range(38):
            x1 = cx + rng.randint(-91, 91)
            y1 = cy + rng.randint(-29, 43)
            x2 = x1 + rng.randint(-38, 38)
            y2 = y1 + rng.randint(-23, 23)
            draw.line([(x1, y1), (x2, y2)], fill=(247, 204, 118), width=rng.randint(3, 6))
        for _ in range(16):
            px, py = cx + rng.randint(-88, 88), cy + rng.randint(-26, 39)
            rr = rng.randint(4, 8)
            draw.ellipse([px - rr, py - rr, px + rr, py + rr], fill=ingredients[0])
        draw.ellipse([cx - 21, cy - 12, cx + 21, cy + 19], fill=(238, 192, 79))
    elif template == 'rice':
        # Rice mound with curry.
        draw.ellipse([cx - 120, cy - 30, cx + 120, cy + 70], fill=hsl(40, 0.15, 0.92))
        draw.ellipse([cx - 90, cy - 20, cx + 90, cy + 50], fill=hsl(40, 0.20, 0.88))
        draw.ellipse([cx - 50, cy - 5, cx + 50, cy + 40], fill=hsl(food_hue, 0.45, 0.52))
    elif template == 'taco':
        # Taco shape.
        draw.ellipse([cx - 120, cy - 60, cx + 120, cy + 60], fill=hsl(40, 0.60, 0.72))
        draw.ellipse([cx - 100, cy - 40, cx + 100, cy + 40], fill=hsl(food_hue, 0.45, 0.48))
        draw.ellipse([cx - 80, cy - 25, cx + 80, cy + 25], fill=hsl(110, 0.40, 0.42))
    elif template == 'dessert':
        # Layered dessert.
        draw.ellipse([cx - 110, cy - 40, cx + 110, cy + 60], fill=hsl(food_hue, 0.40, 0.88))
        draw.ellipse([cx - 90, cy - 25, cx + 90, cy + 45], fill=hsl(food_hue, 0.45, 0.72))
        draw.ellipse([cx - 70, cy - 10, cx + 70, cy + 30], fill=hsl(food_hue, 0.50, 0.58))
        # Cherry on top.
        draw.ellipse([cx - 12, cy - 55, cx + 12, cy - 28], fill=hsl(0, 0.70, 0.45))
    elif template == 'drink':
        # Glass.
        draw.rectangle([cx - 35, cy - 80, cx + 35, cy + 70], fill=hsl(food_hue, 0.40, 0.88))
        draw.ellipse([cx - 40, cy - 85, cx + 40, cy - 70], fill=hsl(food_hue, 0.35, 0.78))
        draw.ellipse([cx - 35, cy + 60, cx + 35, cy + 75], fill=hsl(food_hue, 0.40, 0.85))
        # Straw.
        draw.line([(cx + 15, cy - 80), (cx + 30, cy + 60)], fill=hsl(0, 0.0, 0.30), width=4)
    elif template == 'salad':
        # Bowl of greens.
        draw.ellipse([cx - 120, cy - 40, cx + 120, cy + 80], fill=hsl(0, 0.0, 0.92))
        for _ in range(12):
            px = cx + rng.randint(-80, 80)
            py = cy + rng.randint(-20, 50)
            r = rng.randint(10, 22)
            draw.ellipse([px - r, py - r, px + r, py + r], fill=hsl(110, 0.38, 0.50))
        draw.ellipse([cx - 30, cy + 10, cx + 30, cy + 45], fill=hsl(40, 0.50, 0.60))
    elif template == 'pasta':
        draw.ellipse([cx - 132, cy - 52, cx + 132, cy + 85], fill=(245, 239, 225))
        for _ in range(24):
            x1, y1 = cx + rng.randint(-92, 92), cy + rng.randint(-28, 44)
            x2, y2 = x1 + rng.randint(-44, 44), y1 + rng.randint(-16, 16)
            draw.arc([min(x1, x2), min(y1, y2), max(x1, x2) + 24, max(y1, y2) + 20],
                     rng.randint(0, 180), rng.randint(200, 360), fill=ingredients[0], width=6)
        for _ in range(12):
            px, py = cx + rng.randint(-88, 88), cy + rng.randint(-25, 45)
            draw.ellipse([px - 6, py - 5, px + 6, py + 5], fill=ingredients[-1])
    elif template == 'dumpling':
        for px, py in [(cx - 68, cy + 8), (cx, cy - 24), (cx + 66, cy + 7)]:
            draw.pieslice([px - 42, py - 30, px + 42, py + 38], 180, 360, fill=(240, 225, 196))
            draw.arc([px - 37, py - 24, px + 37, py + 27], 190, 350, fill=(177, 134, 92), width=4)
            for seam in range(-2, 3):
                draw.line([(px + seam * 12, py - 21), (px + seam * 9, py + 4)], fill=(213, 194, 163), width=2)
    elif template == 'fried':
        for _ in range(12):
            px, py = cx + rng.randint(-92, 92), cy + rng.randint(-45, 48)
            rw, rh = rng.randint(13, 26), rng.randint(8, 17)
            draw.rounded_rectangle([px - rw, py - rh, px + rw, py + rh], radius=7, fill=(210, 145, 62))
            draw.line([(px - rw + 4, py - rh + 3), (px + rw - 4, py - rh + 3)], fill=(247, 205, 122), width=3)
        for _ in range(8):
            px, py = cx + rng.randint(-86, 86), cy + rng.randint(-35, 44)
            draw.ellipse([px - 5, py - 5, px + 5, py + 5], fill=ingredients[0])
    elif template == 'bread':
        draw.rounded_rectangle([cx - 112, cy - 58, cx + 112, cy + 61], radius=45, fill=(166, 105, 51))
        draw.rounded_rectangle([cx - 99, cy - 53, cx + 99, cy + 47], radius=40, fill=(230, 181, 108))
        for _ in range(20):
            px, py = cx + rng.randint(-72, 72), cy + rng.randint(-35, 31)
            draw.ellipse([px - 3, py - 3, px + 3, py + 3], fill=(163, 107, 56))
    elif template == 'wrap':
        # Rolled wrap.
        draw.ellipse([cx - 130, cy - 40, cx + 130, cy + 40], fill=hsl(35, 0.50, 0.72))
        draw.ellipse([cx - 110, cy - 25, cx + 110, cy + 25], fill=hsl(food_hue, 0.45, 0.52))
        draw.line([(cx - 130, cy), (cx + 130, cy)], fill=hsl(35, 0.40, 0.60), width=3)
    else:  # curry, grilled mains and other plated dishes
        draw.ellipse([cx - 126, cy - 57, cx + 126, cy + 79], fill=(238, 230, 212))
        draw.ellipse([cx - 112, cy - 46, cx + 112, cy + 65], fill=hsl(food_hue, 0.58, 0.48))
        for _ in range(12):
            px, py = cx + rng.randint(-84, 84), cy + rng.randint(-30, 48)
            rx, ry = rng.randint(6, 13), rng.randint(5, 10)
            draw.ellipse([px - rx, py - ry, px + rx, py + ry], fill=ingredients[0])
        for _ in range(8):
            px, py = cx + rng.randint(-80, 80), cy + rng.randint(-27, 44)
            draw.ellipse([px - 3, py - 3, px + 3, py + 3], fill=(246, 222, 163))
        draw.arc([cx - 70, cy - 36, cx + 70, cy + 47], 205, 340, fill=(251, 223, 162), width=4)
    # Name-specific garnish colors make variants visibly different while
    # preserving a recognizable food silhouette for every dish type.
    if template not in {'drink', 'dosa', 'south_indian', 'dumpling', 'bread'}:
        garnish = ingredients[0]
        for _ in range(11):
            px, py = cx + rng.randint(-105, 105), cy + rng.randint(-46, 58)
            rr = rng.randint(3, 7)
            draw.ellipse([px - rr, py - rr, px + rr, py + rr], fill=garnish)
        for _ in range(3):
            px, py = cx + rng.randint(-90, 90), cy + rng.randint(-38, 45)
            draw.line([(px - 8, py), (px + 10, py - 5)], fill=ingredients[-1], width=3)
    # Veg / non-veg marker.
    badge = (28, 0.55, 0.42) if not vegetarian else (128, 0.45, 0.38)
    draw.ellipse([W - 72, 28, W - 32, 68], fill=hsl(*badge))
    draw.ellipse([W - 72, 28, W - 32, 68], outline=(255, 255, 255), width=2)

    # Caption band at the bottom.
    base = strip_portion(dish_name)
    title_font = load_font(28 if len(base) < 28 else 22, bold=True)
    lines = wrap(draw, base, title_font, W - 70)
    while len(lines) > 2:
        lines = lines[:2]
        base = ' '.join(base.split()[:-1]) + '…'
        lines = wrap(draw, base, title_font, W - 70)
    sub_font = load_font(16)
    label = cuisine
    if ' · ' in dish_name:
        label = f'{cuisine} · {dish_name.split(" · ", 1)[1]}'

    band_top = H - 24 - len(lines) * 34
    overlay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rectangle([0, band_top - 16, W, H], fill=(28, 22, 18, 170))
    img = Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB')
    draw = ImageDraw.Draw(img)

    y = band_top
    for line in lines:
        width = draw.textlength(line, font=title_font)
        draw.text(((W - width) / 2, y), line, font=title_font, fill=(255, 253, 250))
        y += 34
    sw = draw.textlength(label, font=sub_font)
    draw.text(((W - sw) / 2, y + 4), label, font=sub_font,
              fill=hsl(hue, 0.40, 0.86))
    return img


def slug(name: str) -> str:
    text = unicodedata.normalize('NFKD', name).encode('ascii', 'ignore').decode()
    text = re.sub(r'[^a-zA-Z0-9]+', '-', text).strip('-').lower()
    digest = hashlib.sha1(name.encode('utf-8')).hexdigest()[:6]
    return f'gen-{text[:48]}-{digest}'


def load_dish_names() -> list[tuple[str, str, bool]]:
    sys.path.insert(0, str(ROOT / 'backend'))
    from app.database.catalog import CATALOG  # noqa: E402

    rows: dict[str, tuple[str, bool]] = {}
    for kitchen in CATALOG:
        for dish in kitchen.menu:
            # Legacy dish-*.jpg files stay valid, but every regenerated menu
            # name must also have its own illustration file so "Photo
            # unavailable" can never appear for a real recipe.
            rows.setdefault(dish.name, (kitchen.cuisine, dish.vegetarian))
    return [(name, cuisine, veg) for name, (cuisine, veg) in sorted(rows.items())]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--limit', type=int, default=0)
    parser.add_argument('--force', action='store_true')
    args = parser.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)
    rows = load_dish_names()
    if args.limit:
        rows = rows[:args.limit]

    written = 0
    manifest = {}
    for index, (name, cuisine, vegetarian) in enumerate(rows, start=1):
        file = f'{slug(name)}.jpg'
        target = OUT / file
        manifest[name] = f'generated/{file}'
        if target.exists() and not args.force:
            continue
        render(name, cuisine, vegetarian).save(target, 'JPEG', quality=90, optimize=True)
        written += 1
        if index % 500 == 0:
            print(f'  {index}/{len(rows)} …', flush=True)

    (OUT / 'index.json').write_text(json.dumps(manifest, indent=0, sort_keys=True))
    print(f'Generated {written} new images, {len(manifest)} total mappings in '
          f'{OUT.relative_to(ROOT)}.')


if __name__ == '__main__':
    main()
