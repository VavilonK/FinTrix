"""Store screenshots and the 512 px icon for the RuStore card.

Run from the project root:  python tool/make_store_screenshots.py
Takes raw phone screenshots from docs/rustore/screenshots/ and writes framed
1080 x 1920 images with a caption to docs/rustore/store/.
"""
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, 'docs/rustore/screenshots')
OUT = os.path.join(ROOT, 'docs/rustore/store')
FONT = os.path.join(ROOT, 'assets/fonts/nunito/Nunito-Black.ttf')

SHOTS = [
    ('01_intro.png', 'Привет! Я Рыжик.\nНаучу обращаться с деньгами'),
    ('02_home.png', 'Заботься о Рыжике:\nкорми, играй, гладь'),
    ('04_budget.png', 'Распредели монеты:\nважное, приятное, копилка'),
    ('03_shop.png', 'Покупки с ценой\nи пользой для питомца'),
    ('05_goals.png', 'Копи на мечту\nи следи за прогрессом'),
    ('06_tasks.png', 'Задания на карте Москвы\nза игровые монеты'),
]

W, H = 1080, 1920
TOP = (232, 244, 255)
BOTTOM = (126, 188, 255)
NAVY = (8, 21, 75)


def gradient():
    column = Image.new('RGB', (1, 256))
    for y in range(256):
        t = y / 255
        column.putpixel((0, y), tuple(round(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3)))
    return column.resize((W, H), Image.BICUBIC).convert('RGBA')


def frame(raw_path, caption):
    canvas = gradient()
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(FONT, 58)
    draw.multiline_text((W // 2, 150), caption, font=font, fill=NAVY, anchor='mm',
                        align='center', spacing=14)

    shot = Image.open(raw_path).convert('RGBA')
    shot_h = 1560
    shot_w = round(shot.width * shot_h / shot.height)
    shot = shot.resize((shot_w, shot_h), Image.LANCZOS)
    mask = Image.new('L', shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, shot_w - 1, shot_h - 1), 48, fill=255)
    x, y = (W - shot_w) // 2, 300

    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    shadow_mask = Image.new('L', (W, H), 0)
    ImageDraw.Draw(shadow_mask).rounded_rectangle((x, y + 12, x + shot_w, y + shot_h + 12), 48, fill=90)
    shadow.putalpha(shadow_mask.filter(ImageFilter.GaussianBlur(24)))
    canvas = Image.alpha_composite(canvas, shadow)
    canvas.paste(shot, (x, y), mask)
    return canvas.convert('RGB')


def main():
    os.makedirs(OUT, exist_ok=True)
    for index, (name, caption) in enumerate(SHOTS, start=1):
        frame(os.path.join(RAW, name), caption).save(
            os.path.join(OUT, f'screenshot_{index}.png'), optimize=True)
    icon = Image.open(os.path.join(ROOT, 'assets/branding/app_icon_1024.png'))
    icon.convert('RGB').resize((512, 512), Image.LANCZOS).save(
        os.path.join(ROOT, 'docs/rustore/icon_512.png'), optimize=True)
    print('store images written')


if __name__ == '__main__':
    main()
