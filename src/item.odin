package main;
import og "../ogamer"
import "../ogamer/io"
import "../ogamer/ecs"
import "../ogamer/input"

import "core:fmt"
import "core:math/rand"
import "core:math"



Item :: struct {
    tag : ItemTag,
    use : proc (item: ^Item, data: ecs.ScriptData)
}


create_item :: proc (game: ^og.Game, pos: [2]f32, item: Item) -> og.GameObject {
    item_obj := og.new_gameobject(game.ecs);
    item_obj.transform.pos = pos
    item_obj.transform.size = {75,75}
    
    og.add_component(item_obj, ecs.NewRigidbody(type=ecs.BodyType.dynamicBody, disabled_gravity = true, disabled_rotation = true, linear_damping=8))
    
    og.add_component(item_obj, ecs.NewCollider(trigger=true))
    og.add_component(item_obj, ecs.NewTag(item_tag_to_string(item.tag)))
    og.add_component(item_obj, ecs.NewScriptComponent(ecs.NewScript(start = proc(data : ecs.ScriptData) {
        og.apply_force(data.gameObject.entity, {30,30}*{cast(f32)rand.int_range(-1,1),cast(f32)rand.int_range(-1,1)})
    })))

    return item_obj
}
// Item factory
generate_item_from_tag :: proc(tag: ItemTag) -> (Item, bool) #optional_ok {
    switch tag {
    case .WOOD:
        return Item({tag=ItemTag(tag), use=nil}), true
    case .HOE:
        return Item({tag=ItemTag(tag), use=proc(item: ^Item, data:ecs.ScriptData) {
            gs :f32= 100
            wp := input.get_world_mouse_position()
            wp = {
                math.round_f32((wp.x - gs/2) / gs) * gs + gs / 2,
                math.round_f32((wp.y - gs/2) / gs) * gs + gs / 2
            }

            //og.add_child(data.gameObject, create_tool(game))
            t := create_tool(game, io.new_tilesheet(game.assetsManager, "./assets/swosh.png", {16,16}))
            t.transform.pos = wp
            create_field(game, wp);

        }}), true
    case .PUMPKIN, .CARROT: return Item({tag=ItemTag(tag), use=nil}), true
    case .PUMPKIN_SEED, .CARROT_SEED:
        return Item({tag=tag, use=proc(item: ^Item, data:ecs.ScriptData) {
            pdata := cast(^PlayerData)data.data

            gs :f32= 100
            wp := input.get_world_mouse_position()
            wp = {
                math.round_f32((wp.x - gs/2) / gs) * gs + gs / 2,
                math.round_f32((wp.y - gs/2) / gs) * gs + gs / 2
            }

            if get_count(&pdata.inventory, item.tag) > 0 {
                 if plant, ok := create_plant(game,wp, item.tag); ok {
                     remove_item(&pdata.inventory, item.tag)
                 }
            }
        }}), true
    }
    return Item({use=nil}), false
}
get_item_sprite :: proc (tag: ItemTag) -> io.Sprite {
    switch tag {
    case .WOOD: return io.load(game.assetsManager, "./assets/farm/objects&items/items free.png", {0,2}, {16,16})
    case .PUMPKIN: return io.load(game.assetsManager, "./assets/farm/objects&items/items free.png", {0,0}, {16,16})
    case .PUMPKIN_SEED: return io.load(game.assetsManager, "./assets/farm/objects&items/items free.png", {0,1}, {16,16})
    case .CARROT: return io.load(game.assetsManager, "./assets/farm/objects&items/items free.png", {2,0}, {16,16})
    case .CARROT_SEED: return io.load(game.assetsManager, "./assets/farm/objects&items/items free.png", {2,1}, {16,16})
    case .HOE: return io.load(game.assetsManager, "./assets/farm/objects&items/hoe.png")
    }
    return io.Sprite({})
}
