extends "res://game/storybook_sprite.gd"
const HOME = preload("res://assets/story-prologue/home-party.png")
func _ready() -> void:
    super._ready()
    for atlas in frame_cache: atlas.atlas = HOME
func pose(phase: float, stride: float, facing: float, reaction: float) -> void:
    super.pose(phase,stride,facing,reaction)
    for atlas in frame_cache: atlas.atlas = HOME
