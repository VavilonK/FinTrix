"""Builds the pitch deck (ТЗ, section 4) as PPTX.

Run from the project root:  python tool/build_presentation.py
Needs python-pptx. Uses the app icon and screenshots from docs/rustore/.
"""
import os

from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.util import Emu, Pt

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(ROOT, 'docs')
SHOTS = os.path.join(DOCS, 'rustore/screenshots')
OUT = os.path.join(DOCS, 'Презентация_Финансовый_питомец.pptx')

NAVY = RGBColor(0x08, 0x15, 0x4B)
BLUE = RGBColor(0x27, 0x80, 0xF7)
LIGHT = RGBColor(0xDC, 0xEE, 0xFF)
LAVENDER = RGBColor(0xF2, 0xF4, 0xFF)
GREY = RGBColor(0x59, 0x67, 0x97)
ORANGE = RGBColor(0xFF, 0xA5, 0x1F)
GREEN = RGBColor(0x55, 0xC9, 0x69)
PURPLE = RGBColor(0x86, 0x49, 0xF4)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
FONT = 'Segoe UI'

W, H = Emu(12192000), Emu(6858000)  # 16:9
CM = 360000


def cm(value):
    return Emu(int(value * CM))


def text_box(slide, x, y, w, h, text, size=18, bold=False, color=NAVY,
             align=PP_ALIGN.LEFT, anchor=MSO_ANCHOR.TOP):
    box = slide.shapes.add_textbox(cm(x), cm(y), cm(w), cm(h))
    frame = box.text_frame
    frame.word_wrap = True
    frame.vertical_anchor = anchor
    lines = text if isinstance(text, list) else [text]
    for index, line in enumerate(lines):
        paragraph = frame.paragraphs[0] if index == 0 else frame.add_paragraph()
        paragraph.alignment = align
        run = paragraph.add_run()
        run.text = line
        run.font.size = Pt(size)
        run.font.bold = bold
        run.font.color.rgb = color
        run.font.name = FONT
    return box


def bullets(slide, x, y, w, h, items, size=16, color=NAVY):
    box = slide.shapes.add_textbox(cm(x), cm(y), cm(w), cm(h))
    frame = box.text_frame
    frame.word_wrap = True
    for index, item in enumerate(items):
        paragraph = frame.paragraphs[0] if index == 0 else frame.add_paragraph()
        paragraph.space_after = Pt(6)
        bold, _, rest = item.partition('|') if '|' in item else ('', '', item)
        marker = paragraph.add_run()
        marker.text = '• '
        marker.font.color.rgb = BLUE
        marker.font.size = Pt(size)
        marker.font.bold = True
        if bold:
            run = paragraph.add_run()
            run.text = bold + ' '
            run.font.bold = True
            run.font.size = Pt(size)
            run.font.color.rgb = color
            run.font.name = FONT
        run = paragraph.add_run()
        run.text = rest
        run.font.size = Pt(size)
        run.font.color.rgb = color
        run.font.name = FONT
    return box


def card(slide, x, y, w, h, title, body, fill=LAVENDER, accent=BLUE, size=16):
    shape = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, cm(x), cm(y), cm(w), cm(h))
    shape.adjustments[0] = 0.12
    shape.fill.solid()
    shape.fill.fore_color.rgb = fill
    shape.line.color.rgb = fill
    shape.shadow.inherit = False
    text_box(slide, x + 0.35, y + 0.25, w - 0.7, 1.0, title, size=size + 3, bold=True, color=accent)
    text_box(slide, x + 0.35, y + 1.35, w - 0.7, h - 1.5, body, size=size, color=NAVY)


def arrow(slide, x, y, w=0.9):
    shape = slide.shapes.add_shape(MSO_SHAPE.RIGHT_ARROW, cm(x), cm(y), cm(w), cm(0.7))
    shape.fill.solid()
    shape.fill.fore_color.rgb = BLUE
    shape.line.fill.background()


def pill(slide, x, y, w, h, text, fill=BLUE, color=WHITE, size=13):
    shape = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, cm(x), cm(y), cm(w), cm(h))
    shape.adjustments[0] = 0.3
    shape.fill.solid()
    shape.fill.fore_color.rgb = fill
    shape.line.fill.background()
    shape.shadow.inherit = False
    frame = shape.text_frame
    frame.word_wrap = True
    frame.vertical_anchor = MSO_ANCHOR.MIDDLE
    for index, line in enumerate(text.split('\n')):
        paragraph = frame.paragraphs[0] if index == 0 else frame.add_paragraph()
        paragraph.alignment = PP_ALIGN.CENTER
        run = paragraph.add_run()
        run.text = line
        run.font.size = Pt(size)
        run.font.bold = index == 0
        run.font.color.rgb = color
        run.font.name = FONT


def phone(slide, name, x, y, height):
    width = height * 1080 / 2400
    slide.shapes.add_picture(os.path.join(SHOTS, name), cm(x), cm(y), cm(width), cm(height))
    return width


def base(prs, title, number):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    bar = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, cm(0.45), H)
    bar.fill.solid()
    bar.fill.fore_color.rgb = BLUE
    bar.line.fill.background()
    text_box(slide, 1.3, 0.7, 28, 1.6, title, size=30, bold=True)
    text_box(slide, 31.2, 17.7, 2.2, 0.8, str(number), size=11, color=GREY, align=PP_ALIGN.RIGHT)
    text_box(slide, 1.3, 17.7, 20, 0.8, 'Финансовый питомец · 1.0.0 (сборка 1)', size=11, color=GREY)
    return slide


def build():
    prs = Presentation()
    prs.slide_width, prs.slide_height = W, H

    # 1. Title
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    background = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, W, H)
    background.fill.gradient()
    background.fill.gradient_angle = 90
    stops = background.fill.gradient_stops
    stops[0].color.rgb = RGBColor(0xE8, 0xF4, 0xFF)
    stops[1].color.rgb = RGBColor(0x7E, 0xBC, 0xFF)
    background.line.fill.background()
    slide.shapes.add_picture(os.path.join(ROOT, 'assets/branding/app_icon_1024.png'),
                             cm(2.2), cm(4.2), cm(9), cm(9))
    text_box(slide, 12.8, 4.4, 20, 2.2, 'Финансовый питомец', size=48, bold=True)
    text_box(slide, 12.8, 7.0, 19, 3.0,
             'Игра для детей 7–11 лет: лисёнок Рыжик учит планировать бюджет, '
             'копить и тратить с умом', size=22, color=NAVY)
    text_box(slide, 12.8, 10.6, 19, 2.6,
             ['Android · Flutter · работает офлайн',
              'Команда: <вписать состав команды>'], size=16, color=GREY)

    # 2. Problem and audience
    slide = base(prs, 'Проблема и целевая аудитория', 2)
    bullets(slide, 1.3, 3.0, 17, 12, [
        'Дети 7–11 лет|рано сталкиваются с деньгами: карманные деньги, покупки в школе, игры и подписки.',
        'Навыки|планирования, накопления и безопасного обращения с деньгами формируются позже, а ошибки с реальными деньгами дорого стоят.',
        'Объяснения «на словах»|скучны и быстро забываются.',
        'Нужна|безопасная среда, где решения имеют понятные последствия, но ошибка ничего не стоит.',
    ], size=18)
    card(slide, 19.5, 3.0, 12.8, 5.8, 'Ребёнок 7–11 лет',
         'Играет сам: заботится о Рыжике, выполняет задания, решает, как потратить монеты.')
    card(slide, 19.5, 9.3, 12.8, 5.8, 'Взрослый',
         'Настраивает профиль, видит пройденные темы и прогресс, начисляет бонусы, может удалить данные.',
         accent=PURPLE)

    # 3. Learning outcomes
    slide = base(prs, 'Образовательные результаты', 3)
    text_box(slide, 1.3, 2.5, 30, 1.2,
             'Выбраны из Единой рамки компетенций по финансовой грамотности для младших школьников',
             size=15, color=GREY)
    outcomes = [
        ('Планирование', 'Распределяет доход по направлениям до трат и сравнивает план с фактом'),
        ('Потребности и желания', 'Отличает обязательные расходы от желаемых и выбирает порядок покупок'),
        ('Сбережения и цель', 'Регулярно откладывает, считает срок достижения цели'),
        ('Платежи и покупки', 'Считает деньги и сдачу, сравнивает цены, проверяет чек'),
        ('Безопасность', 'Не сообщает коды из СМС, при сомнении зовёт взрослого'),
        ('Непредвиденное', 'Понимает, зачем держать запас в копилке на неожиданные траты'),
    ]
    for index, (title, body) in enumerate(outcomes):
        col, row = index % 3, index // 3
        card(slide, 1.3 + col * 10.6, 4.2 + row * 6.3, 10.1, 5.8, title, body,
             accent=[BLUE, PURPLE, GREEN][col], size=17)

    # 4. Idea
    slide = base(prs, 'Идея: почему питомец', 4)
    bullets(slide, 1.3, 3.0, 19, 13, [
        'Забота|— понятная детям мотивация: Рыжику нужны еда и уход (важные траты), а игрушки радуют (приятные).',
        'Последствия видны сразу:|сытость, настроение, забота и реплика Рыжика объясняют, что случилось и почему.',
        'Рост в 3 стадии|зависит от решений за несколько дней: план, траты по плану, регулярные накопления — это учит думать наперёд.',
        'Копилка и цель|превращают «отложить» в осязаемую мечту: велосипед, самокат, конструктор.',
        'Жизненные ситуации|— звонок мошенника и визит к ветеринару — тренируют безопасность и «подушку».',
    ], size=17)
    phone(slide, '02_home.png', 23.0, 2.6, 14.6)

    # 5. User path and economy
    slide = base(prs, 'Пользовательский путь и игровая экономика', 5)
    steps = ['Знакомство\nи профиль', 'Задания\n→ монеты', 'План\nбюджета', 'Покупки\nи копилка',
             'Итоги дня', 'Рост\nРыжика']
    for index, step in enumerate(steps):
        x = 1.3 + index * 5.3
        pill(slide, x, 3.2, 4.3, 2.2, step, size=14)
        if index < len(steps) - 1:
            arrow(slide, x + 4.35, 3.95, 0.85)
    card(slide, 1.3, 6.4, 10.1, 9.8, 'Доход',
         '• Задания: 15–20 монет, объяснение при любом ответе\n'
         '• «Раздели награду» между кошельком и копилкой\n'
         '• Бонус от взрослого\n'
         '• Каждое начисление — в «Истории монет» с источником',
         accent=GREEN, size=16)
    card(slide, 11.9, 6.4, 10.1, 9.8, 'Расходы и накопления',
         '• План: на важное / на приятное / в копилку\n'
         '• Важное: еда, уход, ветеринар\n'
         '• Приятное: вкусняшка, игрушки в комнату\n'
         '• Минус невозможен: «не хватает N монет» и варианты',
         accent=BLUE, size=16)
    card(slide, 22.5, 6.4, 10.1, 9.8, 'Питомец',
         '• Сытость, забота, настроение 0–100, падают со временем\n'
         '• Голоден при сытости < 30\n'
         '• Очки роста за день (до 30): план, траты по плану, копилка, цель, задания\n'
         '• Стадии: < 40, 40–89, ≥ 90 очков',
         accent=ORANGE, size=16)

    # 6. Scope
    slide = base(prs, 'Обязательные функции и границы прототипа', 6)
    bullets(slide, 1.3, 3.0, 17.5, 14, [
        'Реализованы все требования 2.5.1–2.5.14|и минимум контента 2.6.',
        'Питомец:|4 цвета худи × аксессуары × 3 стадии — больше 9 вариантов.',
        'Контент:|26 шаблонов заданий, миссия из 12 заданий, 10 локаций на карте Москвы.',
        'Покупки:|8 позиций (еда, уход, игрушки), 3 цели накопления.',
        'Демо-режим:|5 дней без ожидания, панель для экспертов, сброс.',
        'Раздел взрослого:|PIN или биометрия, прогресс, начисления, удаление данных.',
    ], size=16)
    card(slide, 19.6, 3.0, 12.8, 9.0, 'Сознательно не делаем (ТЗ 2.7)',
         '• Реальные деньги, карты, СБП\n'
         '• Реклама, подписки, покупки\n'
         '• Чаты, рейтинги, соцсеть\n'
         '• Сервер, облако, ИИ — не нужны: всё офлайн\n'
         '• Удалённый родительский контроль',
         fill=RGBColor(0xFF, 0xF1, 0xE6), accent=ORANGE, size=18)

    # 7. UX/UI
    slide = base(prs, 'Ключевые UX/UI-решения', 7)
    bullets(slide, 1.3, 3.0, 12.7, 14, [
        'Всё главное на одном экране|и 5 вкладок снизу.',
        'Рыжик объясняет|состояние и последствия короткими фразами.',
        'Категории|подписаны текстом и значком, не только цветом.',
        'Нет тупиков:|при нехватке монет — следующий шаг.',
        'Доступность:|кнопки от 48 dp, текст от 16 sp, крупный шрифт системы, подписи для диктора, отключение звука и анимаций.',
        'Без стыда и страха:|ошибка = объяснение и способ исправить.',
    ], size=15)
    x = 14.4
    for name in ['01_intro.png', '04_budget.png', '03_shop.png']:
        x += phone(slide, name, x, 3.0, 12.8) + 0.45

    # 8. Architecture
    slide = base(prs, 'Архитектура, стек и данные', 8)
    layers = [
        ('Интерфейс', 'Экраны модулей: главная, задания, бюджет, цели, магазин, профиль, взрослый', BLUE),
        ('Состояние и экономика', 'AppController: баланс, план, покупки, копилка, периоды, рост, события', PURPLE),
        ('Учебный контент', 'Шаблоны заданий, генератор миссий, локации, демо-дни, события, магазин — отдельно от UI', GREEN),
        ('Хранение', 'SQLite: снимок профиля + журнал операций; PIN — в зашифрованном хранилище Android', ORANGE),
    ]
    for index, (title, body, color) in enumerate(layers):
        pill(slide, 1.3, 3.0 + index * 3.4, 6.5, 2.8, title, fill=color, size=15)
        text_box(slide, 8.3, 3.2 + index * 3.4, 12.5, 2.6, body, size=15,
                 anchor=MSO_ANCHOR.MIDDLE)
    card(slide, 21.6, 3.0, 10.8, 13.0, 'Стек',
         '• Flutter 3.47, Dart 3.13\n'
         '• sqflite, flutter_secure_storage, local_auth\n'
         '• Android 7.0+, пакет ru.financepet.ryzhik\n'
         '• Без сервера и сети\n\n'
         'Обновление контента: новое задание = новый шаблон в daily_task_templates.dart, '
         'генератор подхватывает его без изменения логики',
         size=16)

    # 9. Demo
    slide = base(prs, 'Демо-режим для экспертов', 9)
    bullets(slide, 1.3, 3.0, 17, 13, [
        '5 игровых дней|подряд, без ожидания календаря; отдельный профиль, обычный не затрагивается.',
        'День 2|— звонок мошенника, день 4 — Рыжик поранил лапку.',
        'Панель демо:|стадия Рыжика 1–3, переход к любому дню, «голоден», +500 монет, «Завершить день».',
        'Сброс|одной кнопкой «Начать демо заново».',
        'Раздел для родителей:|PIN 1234 (подсказка на экране входа).',
        'Сохранение:|закрыли и открыли — прогресс на месте.',
    ], size=17)
    phone(slide, '05_goals.png', 19.5, 2.6, 14.6)
    phone(slide, '06_tasks.png', 26.4, 2.6, 14.6)

    # 10. Testing
    slide = base(prs, 'Тестирование, ограничения и план', 10)
    card(slide, 1.3, 3.0, 10.1, 13.0, 'Проверено',
         '• 430 автотестов: бюджет, списания, копилка, цели, рост, периоды, сохранение, события\n'
         '• dart analyze — 0 замечаний\n'
         '• Релизный APK: запуск 1,4 с, отклик < 1 с\n'
         '• Ручные тест-кейсы по Приложению А',
         accent=GREEN, size=16)
    card(slide, 11.9, 3.0, 10.1, 13.0, 'Ограничения',
         '• APK ≈ 520 МБ из-за анимаций 60 fps\n'
         '• Только русский язык, портретная ориентация\n'
         '• Один детский профиль на устройство\n'
         '• Раздел взрослого — только на этом устройстве',
         accent=ORANGE, size=16)
    card(slide, 22.5, 3.0, 10.1, 13.0, 'Дальше',
         '• Сжать анимации до < 150 МБ\n'
         '• Новые события и задания про карты и платежи\n'
         '• Несколько профилей, задания от родителя\n'
         '• Озвучка реплик Рыжика\n'
         '• Публикация в RuStore',
         accent=PURPLE, size=16)

    # 11. Links
    slide = base(prs, 'Ссылки', 11)
    bullets(slide, 1.3, 3.2, 30, 12, [
        'Репозиторий:|https://github.com/VavilonK/Hackathon (тег v1.0.0)',
        'Сборка:|app-release.apk, версия 1.0.0, сборка 1, пакет ru.financepet.ryzhik',
        'Документация:|README.md и docs/Документация_Финансовый_питомец.docx',
        'Карточка RuStore:|docs/rustore/',
        'Резервное видео демонстрации:|<вставить ссылку>',
    ], size=20)
    slide.shapes.add_picture(os.path.join(ROOT, 'assets/branding/app_icon_1024.png'),
                             cm(26.0), cm(10.2), cm(6), cm(6))

    prs.save(OUT)
    print('written', OUT)


if __name__ == '__main__':
    build()
