package main;
import og "../ogamer"
import "../ogamer/io"
import "../ogamer/ecs"

import "core:fmt"



Item :: struct {
    sprite: io.Sprite,
    rigid: ^ecs.Rigidbody
}


create_item :: proc (game: ^og.Game, pos: [2]f32, _item: Item) {
    item_obj := og.new_gameobject(game.ecs);
    item_obj.transform.pos = pos
    item_obj.transform.size = {75,75}

    og.add_component(item_obj, ecs.NewSpriteRenderer(sprite=_item.sprite))

    item := new(Item)
    item.sprite = _item.sprite

    item.rigid = og.add_component(item_obj, ecs.NewRigidbody(disabled_gravity=true, type=ecs.BodyType.dynamicBody, disabled_rotation=true, linear_damping=8))
    
    og.add_component(item_obj, ecs.NewCollider(trigger=true))
    og.add_component(item_obj, ecs.NewScriptComponent(ecs.NewScript(data=item, start = proc(data : ecs.ScriptData) {
        fmt.println("STARTED")
        og.apply_force(data.gameObject.entity, {600,600}*data.dt)
    })))
    
}
