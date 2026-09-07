extends RefCounted

const RIVER := Rect2(1024, 100, 392, 960)
const WINCH := Vector2(960, 620)
const EXIT := Vector2(1540, 640)
const LOCKS: Array[Vector2] = [Vector2(1132, 640), Vector2(1252, 640), Vector2(1372, 640)]
var solo_mode := false
var deployed: int = 0
var unlocked: int = 0
var revision: int = 0
var falls: int = 0
var confirmed: Array[bool] = [false, false]
var confirmed_cat: int = -1
var finished: bool = false
var message: String = "向右到绞盘旁，准备一起修桥"

func interact(slot: int, cat: int, positions: Array) -> bool:
    if slot < 0 or slot > 1 or positions.size() != 3 or cat < 1 or cat > 2 or finished:
        return false
    var actor := 0 if slot == 0 else cat
    if unlocked == 3:
        if positions[actor].distance_to(EXIT) > 80:
            message = "桥已修好，一起走到右岸集合圈"
            return false
        confirmed[slot] = true
        if slot == 1:
            confirmed_cat = cat
        message = "已确认，等另一位和两只猫咪到齐"
        tick(positions, cat)
        return true
    if slot == 0:
        if positions[0].distance_to(WINCH) > 56:
            message = "朵朵先到近岸绞盘旁"
        elif deployed > unlocked:
            message = "踏板已固定，等团团解开这一段的卡扣"
        else:
            deployed += 1
            revision += 1
            message = "第 %d 段已就位，团团可以出发" % deployed
            return true
    elif cat != 1:
        message = "这段低通道交给团团，按面键上方切猫"
    elif deployed <= unlocked:
        message = "等朵朵先调好下一段踏板"
    elif positions[1].distance_to(LOCKS[unlocked]) > 42:
        message = "团团靠近亮着的卡扣，再按互动键"
    else:
        unlocked += 1
        revision += 1
        message = "木桥落稳了！叫上圆圆一起过桥" if unlocked == 3 else "卡扣已解开，轮到朵朵调下一段"
        return true
    return false

func allows(actor: int, point: Vector2) -> bool:
    if not RIVER.has_point(point):
        return true
    if unlocked == 3:
        return absf(point.y - 640) <= 56
    return actor == 1 and deployed > 0 and absf(point.y - 640) <= 24 and point.x <= 1040 + deployed * 120 - 16

func would_fall(actor: int, from: Vector2, to: Vector2) -> bool:
    return actor == 1 and unlocked < 3 and deployed > 0 and RIVER.has_point(from) and RIVER.has_point(to) and absf(from.y - 640) <= 24 and absf(to.y - 640) > 24

func checkpoint() -> Vector2:
    return Vector2(1000, 640) if unlocked == 0 else LOCKS[unlocked - 1]

func recover() -> Vector2:
    falls += 1
    message = "脚下一滑，回到安全点了；已解开的卡扣保留"
    return checkpoint()

func tick(positions: Array, cat: int) -> void:
    if finished or unlocked < 3:
        return
    if positions[0].distance_to(EXIT) > 80:
        confirmed[0] = false
    if cat != confirmed_cat or positions[cat].distance_to(EXIT) > 80:
        confirmed[1] = false
    if (confirmed[0] or confirmed[1]) if solo_mode else (confirmed[0] and confirmed[1]):
        for point in positions:
            if point.distance_to(EXIT) > 120:
                return
        finished = true
        message = "合作完成！朵朵、团团、圆圆都过桥了"

func objective() -> String:
    if finished:
        return "第一段合作完成 · 暂停后可重玩"
    if unlocked == 3:
        return "全队到右岸集合，双方按面键下方确认"
    if deployed == unlocked:
        return "朵朵：到绞盘旁调好第 %d 段" % (unlocked + 1)
    return "团团：沿窄踏板到第 %d 个卡扣开锁" % (unlocked + 1)
