"""Builds the app icon from Рыжик's artwork for Android, iOS and web.

Run from the project root:  python tool/generate_app_icon.py
Needs Pillow. Sources: the peeking fox and the coin from assets/images.
"""
import json
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FOX = os.path.join(ROOT, 'assets/images/characters/fox/fox_peeking_happy_level_05.png')
COIN = os.path.join(ROOT, 'assets/images/objects/finance/finance_coin_single.png')
MASTER = os.path.join(ROOT, 'assets/branding/app_icon_1024.png')

# Light sky gradient: the blue hoodie and the orange fur both stand out.
TOP = (232, 244, 255)
BOTTOM = (126, 188, 255)


def clean(image):
    """Drops the faint alpha noise around the artwork and trims to it."""
    image = image.convert('RGBA')
    alpha = image.getchannel('A').point(lambda a: 0 if a < 24 else a)
    image.putalpha(alpha)
    return image.crop(alpha.point(lambda a: 255 if a > 40 else 0).getbbox())


def background(size):
    """Vertical brand gradient with a soft light spot behind the head."""
    gradient = Image.new('RGB', (1, 256))
    for y in range(256):
        t = y / 255
        gradient.putpixel(
            (0, y), tuple(round(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3))
        )
    image = gradient.resize((size, size), Image.BICUBIC).convert('RGBA')
    glow = Image.new('L', (size, size), 0)
    r = size * 0.36
    cx, cy = size * 0.5, size * 0.42
    ImageDraw.Draw(glow).ellipse((cx - r, cy - r, cx + r, cy + r), fill=120)
    glow = glow.filter(ImageFilter.GaussianBlur(size * 0.09))
    white = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    image = Image.composite(white, image, glow)
    return image


def shadow_of(layer, radius, opacity):
    alpha = layer.getchannel('A').filter(ImageFilter.GaussianBlur(radius))
    alpha = alpha.point(lambda a: int(a * opacity))
    shadow = Image.new('RGBA', layer.size, (8, 21, 75, 0))
    shadow.putalpha(alpha)
    return shadow


def foreground(size):
    """Fox and coin on a transparent canvas of [size]."""
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    fox = clean(Image.open(FOX))
    fox_w = round(size * 0.86)
    fox = fox.resize((fox_w, round(fox.height * fox_w / fox.width)), Image.LANCZOS)
    fox_pos = ((size - fox_w) // 2 - round(size * 0.02), size - fox.height + round(size * 0.07))
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    layer.paste(fox, fox_pos, fox)
    canvas = Image.alpha_composite(canvas, shadow_of(layer, size * 0.02, 0.35))
    canvas = Image.alpha_composite(canvas, layer)

    coin = clean(Image.open(COIN))
    coin_w = round(size * 0.25)
    coin = coin.resize((coin_w, round(coin.height * coin_w / coin.width)), Image.LANCZOS)
    coin_layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    coin_layer.paste(coin, (round(size * 0.71), round(size * 0.66)), coin)
    canvas = Image.alpha_composite(canvas, shadow_of(coin_layer, size * 0.015, 0.4))
    canvas = Image.alpha_composite(canvas, coin_layer)
    return canvas


def full_icon(size):
    return Image.alpha_composite(background(size), foreground(size))


def save(image, *parts):
    path = os.path.join(ROOT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save(path, optimize=True)


def padded(content, size, scale):
    """[content] shrunk to [scale] and centred on a transparent [size]."""
    inner = round(size * scale)
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    offset = (size - inner) // 2
    canvas.paste(content.resize((inner, inner), Image.LANCZOS), (offset, offset))
    return canvas


def main():
    master = full_icon(1024)
    save(master, 'assets/branding/app_icon_1024.png')

    # Android legacy icons (pre-8.0 launchers).
    densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    corner = Image.new('L', (1024, 1024), 0)
    ImageDraw.Draw(corner).rounded_rectangle((0, 0, 1023, 1023), 180, fill=255)
    rounded = master.copy()
    rounded.putalpha(ImageChops.multiply(master.getchannel('A'), corner))
    for name, factor in densities.items():
        px = round(48 * factor)
        save(rounded.resize((px, px), Image.LANCZOS),
             f'android/app/src/main/res/mipmap-{name}/ic_launcher.png')
        # Adaptive layers: 108dp canvas, the icon art fills the 72dp safe zone.
        layer = round(108 * factor)
        save(background(layer),
             f'android/app/src/main/res/mipmap-{name}/ic_launcher_background.png')
        save(padded(foreground(1024), layer, 64 / 108),
             f'android/app/src/main/res/mipmap-{name}/ic_launcher_foreground.png')

    adaptive = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@mipmap/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '</adaptive-icon>\n'
    )
    path = os.path.join(ROOT, 'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as file:
        file.write(adaptive)

    # iOS: opaque squares, sizes from the asset catalog.
    ios_dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    with open(os.path.join(ROOT, ios_dir, 'Contents.json'), encoding='utf-8') as file:
        contents = json.load(file)
    opaque = master.convert('RGB')
    for entry in contents['images']:
        filename = entry.get('filename')
        if not filename:
            continue
        points = float(entry['size'].split('x')[0])
        px = round(points * int(entry['scale'].rstrip('x')))
        save(opaque.resize((px, px), Image.LANCZOS), ios_dir, filename)

    # Web.
    save(master.resize((192, 192), Image.LANCZOS), 'web/icons/Icon-192.png')
    save(master.resize((512, 512), Image.LANCZOS), 'web/icons/Icon-512.png')
    maskable = Image.alpha_composite(background(1024), padded(foreground(1024), 1024, 0.8))
    save(maskable.resize((192, 192), Image.LANCZOS), 'web/icons/Icon-maskable-192.png')
    save(maskable.resize((512, 512), Image.LANCZOS), 'web/icons/Icon-maskable-512.png')
    save(master.resize((32, 32), Image.LANCZOS), 'web/favicon.png')
    print('icons written')


if __name__ == '__main__':
    main()
