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
    length: int,
    output: Inventory
}


create_harvest :: proc (game: ^og.Game, pos: og.Vector2) -> og.GameObject { 

    harvester := new(Harvester)
    harvester.max_time = 1
    harvester.length = 3

    append(&harvester.output.filter, ItemTag.PUMPKIN, ItemTag.CARROT)

    raider := og.new_gameobject(game.ecs)
    raider.transform.pos = pos
    raider.transform.size = {100,100}

    og.add_component(raider, ecs.NewTag("harvester"))
    og.add_component(raider, ecs.NewRigidbody(type=ecs.BodyType.dynamicBody, disabled_gravity=true))
    og.add_component(raider, ecs.NewCollider(trigger=true ))
    og.add_component(raider, ecs.NewSpriteRenderer(sprite=io.load(game.assetsManager, "./assets/farm/objects&items/harvester.png")))
    og.add_component(raider, ecs.NewScriptComponent(ecs.NewScript(
        data = harvester,
        update = proc(data:ecs.ScriptData) {
            harvester := cast(^Harvester)data.data


            // if input.is_key_pressed(data.eventQueue,input.KeyboardKey.SPACE) {
            //     items := get_items_as_list(&harvester.output)
            //     for item in items {
            //         append(&transfer_requests, TransferRequest({
            //             from=&harvester.output,
            //             to = machine_inv,
            //             item=item,
            //             amount=harvester.output.count[item]
            //         }))
            //     }
            //     delete(items)
            // }



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
                for hit in hits {
                    if !hit.hit do continue
                    go := ecs.get_gameobject(data.ecs, hit.entity)
                    if tag, has := og.get_component(go, ecs.Tag); has && tag.tag == "plant" {
                        machine := cast(^Machine)og.get_component(go, ecs.ScriptComponent).scripts[0].data
                        if machine.slots[0].working == true do return
                        items := get_items_as_list(&machine.output)
                        for item in items {
                            append(&transfer_requests, TransferRequest({
                                from = &machine.output,
                                to = &harvester.output,
                                item = item,
                                amount = machine.output.count[item]
                            }))
                        }
                        delete(items)
                        ecs.destroy_entity(data.gameObject.ecs, hit.entity)
                    }
                }
                delete(hits)
            }
        }
    )))
    return raider
}
