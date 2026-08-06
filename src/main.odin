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
    og.add_component(fps, ecs.NewUIText("asd"))

    timer := new(f32)
    
    og.add_component(fps, ecs.NewScriptComponent(ecs.NewScript(data=timer, update = proc (data:ecs.ScriptData) {
        timer := cast(^f32)data.data
        timer^ += 1
        if timer^ <= 50 do return
        timer^ = 0

        text := og.get_component(data.gameObject, ecs.UIText)
        text.text = fmt.tprintf("%d",cast(int) (1/data.dt))
    })))
}

main :: proc() {
    game = og.init_game(og.RenderSettings({600}));
    og.current_game = game;
    
    create_debug(game)
    create_player(game)

    tilesheet := io.new_tilesheet(game.assetsManager, "./assets/farm/objects&items/items free.png", {16,16})
    start_pump := create_item(game, {-150,100}, generate_item_from_tag(.PUMPKIN_SEED))
    og.add_component(start_pump, ecs.NewSpriteRenderer(sprite=tilesheet.sprites[1][0]))

    start_pump2 := create_item(game, {-150,100}, generate_item_from_tag(.CARROT_SEED))
    og.add_component(start_pump2, ecs.NewSpriteRenderer(sprite=tilesheet.sprites[1][1]))


//    start_wood := create_item(game, {-150,0}, generate_item_from_tag("wood"))
    // og.add_component(start_wood, ecs.NewSpriteRenderer(sprite=tilesheet.sprites[2][0]))

    start_hoe := create_item(game, {-150,-100}, generate_item_from_tag(.HOE))
    og.add_component(start_hoe, ecs.NewSpriteRenderer(sprite=io.load(game.assetsManager, "./assets/farm/objects&items/hoe.png")))

    machine := machine_factory(.WOOD)
    machine.on_slot_working = proc (machine: ^Machine, slot: ^Slot, gameobject: og.GameObject) {
        anim, has_anim := og.get_component(gameobject, ecs.SpriteAnimator)
        anim.active_animation = 1
    }
    machine.on_slot_done = proc (machine: ^Machine, slot: ^Slot, gameobject: og.GameObject) {
        machine_drop_items(machine, slot^, gameobject.transform.pos)
        anim, has_anim := og.get_component(gameobject, ecs.SpriteAnimator)
        anim.active_animation = 0
    }
    wood_machine := create_machine_drop(game, machine)


    og.add_component(wood_machine, ecs.NewSpriteAnimator(sprites=io.new_tilesheet(game.assetsManager, "./assets/wood_machine.png", {32,32}).sprites))
    wood_machine.transform.size = {200,200}

    

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


