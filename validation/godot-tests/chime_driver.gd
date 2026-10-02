extends RefCounted
# Same physical movements and routed button presses as a player. No state writes.
static func solve(host, single: bool) -> bool:
    var puzzle = host.lobby.chime_gate.puzzle
    if not await host.walk(0,puzzle.MIRRORS[0]+Vector2(0,45)): return false
    if int(puzzle.mirrors[0]) == 1: host.tap_key(KEY_E)
    await host.frames(105)
    if puzzle.stage != 2: return false
    if not await host.walk(0,puzzle.mirror_points()[0]+Vector2(0,45)): return false
    if int(puzzle.mirrors[0]) == 1: host.tap_key(KEY_E)
    if single: host.pick(1)
    elif puzzle.current_cat != 1: host.tap_key(KEY_TAB)
    if not await host.walk(1,puzzle.mirror_points()[1]+Vector2(0,45)): return false
    if int(puzzle.mirrors[1]) == 0: host.tap_key(KEY_R)
    if not await host.walk(0,puzzle.mirror_points()[2]+Vector2(0,45)): return false
    if int(puzzle.mirrors[2]) == 0: host.tap_key(KEY_E)
    if single: host.pick(2)
    elif puzzle.current_cat != 2: host.tap_key(KEY_TAB)
    if not await host.walk(2 if single else 1,puzzle.socket_points()[0]+Vector2(0,40)): return false
    host.tap_key(KEY_R)
    await host.frames(45)
    if not puzzle.finished: return false
    if not await host.walk(0,puzzle.EXIT+Vector2(-25,-20)): return false
    if not await host.walk(2 if single else 1,puzzle.EXIT+Vector2(15,30)): return false
    host.tap_key(KEY_E)
    await host.frames(2)
    return host.lobby.stage == "rest"
