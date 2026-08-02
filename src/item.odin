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
    use : proc (data: ecs.ScriptData)
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

generate_item_from_tag :: proc(tag: string) -> Item{
    switch tag {
    case "wood":
        return Item({tag=tag, use=proc(data:ecs.ScriptData) {
            i := create_item(game, data.gameObject.transform.pos + {0, 200}, generate_item_from_tag("hoe"))
            og.add_component(i, ecs.NewSpriteRenderer(sprite=io.load(game.assetsManager, "./assets/farm/objects&items/hoe.png")))
        }})
    case "hoe":
        return Item({tag=tag, use=proc(data:ecs.ScriptData) {
            gs :f32= 100
            wp := input.get_world_mouse_position()
            wp = {
                math.round_f32((wp.x - gs/2) / gs) * gs + gs / 2,
                math.round_f32((wp.y - gs/2) / gs) * gs + gs / 2
            }

            og.add_child(data.gameObject, create_tool(game))
            create_field(game, wp);

        }})
    case "pumpkin":
        return Item({tag=tag, use=proc(data:ecs.ScriptData) {
            pdata := cast(^PlayerData)data.data

            gs :f32= 100
            wp := input.get_world_mouse_position()
            wp = {
                math.round_f32((wp.x - gs/2) / gs) * gs + gs / 2,
                math.round_f32((wp.y - gs/2) / gs) * gs + gs / 2
            }

            if get_count(&pdata.inventory, "pumpkin") > 0 {
                if plant, ok := create_plant(game,wp); ok {
                    // FIXME memory leaks
                    path := "./assets/farm/objects&items/plants free.png"
                    sprites : [][]io.Sprite = make([][]io.Sprite,5)
                    sprites[0] = make([]io.Sprite,1)
                    sprites[0][0] = io.load(game.assetsManager, path, {0,0}, {16,16})
                    sprites[1] = make([]io.Sprite,1)
                    sprites[1][0] = io.load(game.assetsManager, path, {1,0}, {16,16})
                    sprites[2] = make([]io.Sprite,1)
                    sprites[2][0] = io.load(game.assetsManager, path, {2,0}, {16,16})
                    sprites[3] = make([]io.Sprite,1)
                    sprites[3][0] = io.load(game.assetsManager, path, {3,0}, {16,16})
                    sprites[4] = make([]io.Sprite,1)
                    sprites[4][0] = io.load(game.assetsManager, path, {4,0}, {16,16})

                    og.add_component(plant, ecs.NewSpriteAnimator(sprites=sprites))
                    remove_item(&pdata.inventory, "pumpkin")
                }

            }

        }})
    }
    return Item({tag="unkown", use=nil})
}
