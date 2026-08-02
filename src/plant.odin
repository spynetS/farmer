package main

import og "../ogamer/"
import "../ogamer/io"
import "../ogamer/ecs"

PlantData :: struct {
    current_age : f32,
    max_age     : f32,
    sprite_comp : ^ecs.SpriteRenderer,
}

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
        if plant.transform.pos == pos do found =true
    }
    if found do return og.GameObject({}), false


    plant := og.new_gameobject(game.ecs)
    plant.transform.pos = pos

    tilesheet := io.new_tilesheet(game.assetsManager, "./assets/farm/objects&items/plants free.png", {16,16})

    pdata := new(PlantData)
    pdata.current_age = 0
    pdata.max_age = 4
    og.add_component(plant, ecs.Tag({tag="plant"}))


    og.add_component(plant, ecs.NewScriptComponent(ecs.NewScript(data=pdata, update=plant_script)))
    og.add_component(plant, ecs.NewDepthSort())
    return plant, true
}

kill_plant :: proc (data: ecs.ScriptData) {
    tilesheet := io.new_tilesheet(game.assetsManager, "./assets/farm/objects&items/items free.png", {16,16})
    item1 := create_item(game, data.gameObject.transform.pos+{10,0}, Item({"pumpkin"}))
    item2 := create_item(game, data.gameObject.transform.pos-{10,0}, Item({"pumpkin"}))
    og.add_component(item1, ecs.NewSpriteRenderer(sprite=tilesheet.sprites[0][0]))
    og.add_component(item2, ecs.NewSpriteRenderer(sprite=tilesheet.sprites[0][0]))

    ecs.destroy_entity(data.gameObject.ecs, data.gameObject.entity)
}

plant_script :: proc (data: ecs.ScriptData) {
    pdata := cast(^PlantData)data.data
    pdata.current_age += data.dt
    if pdata.current_age < pdata.max_age {
        pdata.current_age += data.dt
    }
    else {
        kill_plant(data)
    }
    if animator,has := og.get_component(data.gameObject, ecs.SpriteAnimator); has {
        animations := f32(len(animator.sprites))
        animator.active_animation = cast(int) (pdata.current_age/pdata.max_age * animations)        
    }

}
