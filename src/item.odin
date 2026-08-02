package main;
import og "../ogamer"
import "../ogamer/io"
import "../ogamer/ecs"

import "core:fmt"
import "core:math/rand"



Item :: struct {
    tag : string
}


create_item :: proc (game: ^og.Game, pos: [2]f32, item: Item) -> og.GameObject {
    item_obj := og.new_gameobject(game.ecs);
    item_obj.transform.pos = pos
    item_obj.transform.size = {75,75}
    
    og.add_component(item_obj, ecs.NewRigidbody(type=ecs.BodyType.dynamicBody, disabled_gravity = true, disabled_rotation = true, linear_damping=8))
    
    og.add_component(item_obj, ecs.NewCollider(trigger=true))
    og.add_component(item_obj, ecs.NewTag(item.tag))
    og.add_component(item_obj, ecs.NewScriptComponent(ecs.NewScript(start = proc(data : ecs.ScriptData) {
        og.apply_force(data.gameObject.entity, {30,30}*{cast(f32)rand.int_range(-1,1),cast(f32)rand.int_range(-1,1)})
    })))

    return item_obj
    
}
