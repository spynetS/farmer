package main;

import og "../ogamer"
import "../ogamer/ecs"
import "../ogamer/io"
import "../ogamer/input"

import "core:math/linalg"
import "core:fmt"

Harvester :: struct {
    using base: Timer,
    child: og.Entity,
    length: int
}


create_harvest :: proc (game: ^og.Game, pos: og.Vector2) -> og.GameObject { 

    harvester := new(Harvester)
    harvester.max_time = 1
    harvester.length = 3

    raider := og.new_gameobject(game.ecs)
    raider.transform.pos = pos
    raider.transform.size = {100,100}

    inventory := new(Inventory)
    append(&inventory.filter, ItemTag.PUMPKIN, ItemTag.CARROT)

    collector := og.new_gameobject(game.ecs)
    og.add_component(collector, ecs.NewRigidbody(type=ecs.BodyType.kinematicBody))
    og.add_component(collector, ecs.NewCollider(trigger=true))
    og.add_component(collector, ecs.NewScriptComponent(ecs.NewScript(
        data = inventory,
        update = proc(data:ecs.ScriptData) {
            inv := cast(^Inventory)data.data

            if input.is_key_pressed(data.eventQueue,input.KeyboardKey.SPACE) {
                items := get_items_as_list(inv)
                for item in items {
                    append(&transfer_requests, TransferRequest({
                        from=inv,
                        to = &playerData.inventory,
                        item=item,
                        amount=inv.count[item]
                    }))
                }
                delete(items)
            }

                      
        },
        on_trigger_enter = proc(data:ecs.ScriptData, other:ecs.GameObject) {
            inv := cast(^Inventory)data.data
            // todo add to its inventory 
            if tag, has := og.get_component(other, ecs.Tag); has {
                if itag, ok := string_to_itemtag(tag.tag); ok {
                    add_item(inv, generate_item_from_tag(itag))
                    ecs.destroy_entity(other.ecs, other.entity)
                }
            }
        }
    )))
    

    collector.transform.pos = pos + {0, -200}
    collector.transform.size = {100,300}

    

    
    og.add_component(raider, ecs.NewSpriteRenderer(sprite=io.load(game.assetsManager, "./assets/farm/objects&items/harvester.png")))
    og.add_component(raider, ecs.NewScriptComponent(ecs.NewScript(
        data = harvester,
        update = proc(data:ecs.ScriptData) {
            harvester := cast(^Harvester)data.data
            harvester.current_time += data.dt
            // TODO only send raycast if there is plants infront of it
            if harvester.current_time > harvester.max_time {
                harvester.current_time = 0
                // collider, has := ecs.get_component(data.gameObject.ecs, harvester.child, ecs.Collider)
                // if !has do return
                // collider.disabled = !collider.disabled
                pos := data.gameObject.transform.pos
                bla := og.Vector2({f32(0),f32(-1)}) 
                direction := linalg.normalize0(bla)
                hits := og.raycast(pos, direction * f32(harvester.length)*100)
                delete(hits)
            }
        }
    )))
    return raider
}
