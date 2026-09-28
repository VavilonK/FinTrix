#!/bin/bash
# Рендерит все утверждённые анимации всех трёх уровней (30 роликов).
cd "$(dirname "$0")"
while read LEVEL NAME SCRIPT ENVV; do
  [ -z "$LEVEL" ] && continue
  case "$LEVEL" in \#*) continue;; esac
  if [ "$ENVV" = "-" ]; then ./render.sh "$LEVEL" "$NAME" "$SCRIPT"; else ./render.sh "$LEVEL" "$NAME" "$SCRIPT" $ENVV; fi
done <<'LIST'
level1 fox_hungry_idle anim.py -
level1 fox_happy_idle anim_happy.py -
level1 fox_pet_happy anim_pet7.py -
level1 fox_pet_hungry anim_pethungry.py -
level1 fox_feed_happy_bowl anim_feed_v4.py -
level1 fox_feed_happy_treats anim_feed_items.py ITEM=treats
level1 fox_feed_happy_cupcake anim_feed_items.py ITEM=cupcake
level1 fox_feed_hungry_to_happy_treats anim_feed_h2h.py ITEM=treats
level1 fox_feed_hungry_to_happy_dessert anim_feed_h2h.py ITEM=cupcake
level1 fox_feed_hungry_to_happy_bowl anim_feed_h2h.py ITEM=bowl
level2 L2_happy_idle anim_happy.py -
level2 L2_hungry_idle anim.py -
level2 L2_pet_happy anim_pet7.py -
level2 L2_pet_hungry anim_pethungry.py -
level2 L2_feed_happy_bowl anim_feed_v4.py -
level2 L2_feed_happy_treats anim_feed_items.py ITEM=treats
level2 L2_feed_happy_cupcake anim_feed_items.py ITEM=cupcake
level2 L2_feed_hungry_to_happy_treats anim_feed_h2h.py ITEM=treats
level2 L2_feed_hungry_to_happy_dessert anim_feed_h2h.py ITEM=cupcake
level2 L2_feed_hungry_to_happy_bowl anim_feed_h2h.py ITEM=bowl
level3 L3_happy_idle anim_happy.py -
level3 L3_hungry_idle anim.py -
level3 L3_pet_happy anim_pet7.py -
level3 L3_pet_hungry anim_pethungry.py -
level3 L3_feed_happy_bowl anim_feed_v4.py -
level3 L3_feed_happy_treats anim_feed_items.py ITEM=treats
level3 L3_feed_happy_cupcake anim_feed_items.py ITEM=cupcake
level3 L3_feed_hungry_to_happy_treats anim_feed_h2h.py ITEM=treats
level3 L3_feed_hungry_to_happy_dessert anim_feed_h2h.py ITEM=cupcake
level3 L3_feed_hungry_to_happy_bowl anim_feed_h2h.py ITEM=bowl
LIST
