package main

import og "../ogamer/"
import "../ogamer/io"
import "../ogamer/ecs"

import "core:fmt"


create_plant :: proc(game: ^og.Game, pos: [2]f32) -> (og.GameObject, bool) {

    fields := ecs.get_gameobjects_tag(game.ecs, "field")
    found := false
    for field in fields {
        if field.transform.pos == pos do found =true
    }
    if !found do return og.GameObject({}), false
    
    plants := ecs.get_gameobjects_tag(game.ecs, "plant")
    found = false
    for plant in plants {
        if plant.transform.pos == pos {
            found = true
        }
    }
    if found do return og.GameObject({}), false


    plant := og.new_gameobject(game.ecs)
    plant.transform.pos = pos
    tilesheet := io.new_tilesheet(game.assetsManager, "./assets/farm/objects&items/plants free.png", {16,16})
    og.add_component(plant, ecs.NewRigidbody(type=ecs.BodyType.kinematicBody, disabled_gravity=true, disabled_rotation=true))
    og.add_component(plant, ecs.NewCollider(trigger=true))


    og.add_component(plant, ecs.NewSpriteRenderer())
    og.add_component(plant, ecs.NewSpriteAnimator(sprites=tilesheet.sprites, manual = true))
    plant_machine := machine_factory("plant")
    // TODO make so we have multiple plants
    plant_machine.on_slot_working = proc (machine: ^Machine, slot: ^Slot, gameobject: og.GameObject) {
        anim, has_anim := og.get_component(gameobject, ecs.SpriteAnimator)
        anim.active_animation = 0
        anim.active_index = int(slot.time / slot.recipe.time * 4)
        fmt.println(slot.time)
    }

    og.add_component(plant, ecs.NewScriptComponent(ecs.NewScript(
        data = plant_machine,
        update = machine_script,
        on_raycast_hit = proc(data: ecs.ScriptData) {
            machine := cast(^Machine)data.data
            if machine.slots[0].working == true do return
            machine_drop_items(machine, machine.slots[0], data.gameObject.transform.pos)
            ecs.destroy_entity(data.gameObject.ecs, data.gameObject.entity)

        }
    )))

    
    og.add_component(plant, ecs.NewDepthSort())
    return plant, true
}
