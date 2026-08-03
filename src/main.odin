package main;
import og "../ogamer"
import "../ogamer/tiled"
import "../ogamer/io"
import "../ogamer/ecs"
import "../ogamer/input "
import "../ogamer/events"
import rn "../ogamer/renderer"
import "core:fmt"
import b2 "vendor:box2d"
import "core:slice"

game: ^og.Game

create_debug :: proc(game: ^og.Game) {
    fps := og.new_gameobject(game.ecs)
    fps.transform.pos = {1050,50}
    text := og.add_component(fps, ecs.NewUiText("asd"))
    og.add_component(fps, ecs.NewScriptComponent(ecs.NewScript(data=text, update = proc (data:ecs.ScriptData) {
        text := cast(^ecs.UIText)data.data
        text.text = fmt.tprintf("%d",cast(int) (1/data.dt))
    })))
}


main :: proc() {
    game = og.init_game(og.RenderSettings({60}));
    og.current_game = game;
    
    create_debug(game)
    create_player(game)

    tilesheet := io.new_tilesheet(game.assetsManager, "./assets/farm/objects&items/items free.png", {16,16})
    start_pump := create_item(game, {-150,100}, generate_item_from_tag("pumpkin"))
    og.add_component(start_pump, ecs.NewSpriteRenderer(sprite=tilesheet.sprites[0][0]))

//    start_wood := create_item(game, {-150,0}, generate_item_from_tag("wood"))
    // og.add_component(start_wood, ecs.NewSpriteRenderer(sprite=tilesheet.sprites[2][0]))

    // start_hoe := create_item(game, {-150,-100}, generate_item_from_tag("hoe"))
    // og.add_component(start_hoe, ecs.NewSpriteRenderer(sprite=io.load(game.assetsManager, "./assets/farm/objects&items/hoe.png")))

    
    hoe := Recipe({time = 10})
    hoe.input["wood"] = 5
    hoe.output["hoe"] = 1

    seeds := Recipe({time = 5})
    seeds.input["pumpkin"] = 1
    seeds.output["pumpkin_seed"] = 1
    

    slot := Slot({
        recipe=hoe,
    })
    slot2 := Slot({
        recipe=seeds,
    })
    
    machine := Machine({
        tag="hoemaker",
        recipies = {hoe,seeds},
        slots = {slot,slot2}
    })
    machine.inventory.count["wood"] = 0
    machine.inventory.count["pumpkin"] = 0
    if !machine_set_slot(&machine, slot, 0) do panic("asd")
    machine_set_slot(&machine, slot2, 1)

    machine_obj := og.new_gameobject(game.ecs)
    machine_obj.transform.size = {200,200}
    og.add_component(machine_obj, ecs.NewRigidbody(type=ecs.BodyType.staticBody))
    og.add_component(machine_obj, ecs.NewDepthSort())
    
    og.add_component(machine_obj, ecs.NewSpriteRenderer())
    og.add_component(machine_obj, ecs.NewSpriteAnimator(sprites=io.new_tilesheet(game.assetsManager, "./assets/wood_machine.png", {32,32}).sprites))
    og.add_component(machine_obj, ecs.NewScriptComponent(ecs.NewScript(
        data=&machine,
        update=machine_script,
        on_trigger_enter = proc(data:ecs.ScriptData, other: ecs.GameObject) {
            if tag, has := og.get_component(other, ecs.Tag); has {
                if item, has := generate_item_from_tag(ItemTag(tag.tag)); has {
                    mdata := cast(^Machine)data.data
                    if machine_add_item(mdata, item) do ecs.destroy_entity(other.ecs, other.entity)


                }
            }
        }
    )))

    _map := tiled.load_map(game.assetsManager, "./assets/map.tmj")
    fmt.println("MAP:",_map.tilesets)
    defer tiled.destroy_map(_map)
    tiled.create_from_map(game, _map, {6,6}, on_create = proc(obj: tiled.Object, gameObject: ecs.GameObject) {
        fmt.println("PROPS:", obj.properties)
        for prop in obj.properties {
            if prop.name == "depth" {
                og.add_component(gameObject, ecs.DepthSort({offset={0, f32(prop.value.(f32))}}))
                og.add_component(gameObject, ecs.NewRigidbody(type=ecs.BodyType.kinematicBody, disabled_gravity=true, disabled_rotation=true))
                og.add_component(gameObject, ecs.NewCollider(trigger=true))
                og.add_component(gameObject, ecs.NewScriptComponent(create_resource()))
            }
            
        }
    });


    og.start_game(game);
    og.destroy_game(game);
}


