package main;
import og "../ogamer"
import "../ogamer/ecs"
import "../ogamer/io"

import "core:fmt"


create_field :: proc (game: ^og.Game, pos: [2]f32) {

    fields := ecs.get_gameobjects_tag(game.ecs, "field")
    found := false
    for field in fields {
        if field.transform.pos == pos do found = true
    }
    if found do return

    field := og.new_gameobject(game.ecs);
    field.transform.pos = pos


    sprite := io.load(game.assetsManager, "./assets/farm/field.png")
    og.add_component(field, ecs.Tag({tag="field"}))
    og.add_component(field, ecs.NewRigidbody(type=ecs.BodyType.staticBody))
    og.add_component(field, ecs.NewSpriteRenderer(sprite=sprite, layer=-1))
}
