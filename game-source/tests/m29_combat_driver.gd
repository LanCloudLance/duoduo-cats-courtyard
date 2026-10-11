extends "res://tests/m28_combat_driver.gd"
## M28 pilot preserved unchanged. M29 adds one readable choice: do not start a
## charged heavy when the rear bud is already closing; use the fast basic instead.
func pilot(slot:int)->void:
    var previous:bool=basic_only
    if not previous and arena.battle.actor(slot)==2:
        for enemy in arena.battle.enemies:
            if enemy.kind=="armored" and enemy.mode=="exposed" and enemy.timer<0.70:
                basic_only=true
    super.pilot(slot)
    basic_only=previous
