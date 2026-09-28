#!/bin/bash
# Рендер одной анимации:  ./render.sh <папка уровня> <имя> <скрипт> [ПЕРЕМЕННАЯ=значение ...]
# Пример:                 ./render.sh level2 L2_feed_happy_treats anim_feed_items.py ITEM=treats
# Результат: renders/<имя>/f0000.png ...  +  renders/<имя>_60fps.mp4 (белый фон)  +  renders/<имя>_alpha.webm (альфа)
set -e
cd "$(dirname "$0")"
LEVEL=$1; NAME=$2; SCRIPT=$3; shift 3
OUT="$PWD/renders"; mkdir -p "$OUT"; rm -rf "$OUT/$NAME"
( cd "$LEVEL" && env "$@" python3 "$SCRIPT" "$OUT/$NAME" )
ffmpeg -v error -y -framerate 60 -i "$OUT/$NAME/f%04d.png" -filter_complex "color=white:s=960x960:r=60[bg];[bg][0]overlay=shortest=1,format=yuv420p" -c:v libx264 -crf 16 -preset slow -movflags +faststart "$OUT/${NAME}_60fps.mp4"
ffmpeg -v error -y -framerate 60 -i "$OUT/$NAME/f%04d.png" -c:v libvpx-vp9 -pix_fmt yuva420p -b:v 0 -crf 22 -row-mt 1 -auto-alt-ref 0 "$OUT/${NAME}_alpha.webm"
echo "готово: $OUT/${NAME}_60fps.mp4, $OUT/${NAME}_alpha.webm"
