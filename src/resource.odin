package main;

import og "../ogamer"
import "../ogamer/ecs"
import "../ogamer/io"
import "core:math/rand"
ResourceState :: enum {
    IDLE,
    BEGIN_DAMAGE,
    TAKING_DAMAGE,
}

Resource :: struct {
    state   : ResourceState,
    damage_timer   : f32,
    og_size : og.Vector2,
    health  : f32,
}

Timer :: struct {
    max_time: f32,
    current_time: f32
}

create_resource :: proc (health: f32 = 5) -> ecs.Script {

    data := new(Resource)
    data.health = health
    return ecs.NewScript(
        data = data,
        on_destroy = proc(data: ecs.ScriptData) {
            if data.data == nil do return
            rdata := cast(^Resource)data.data
            free(rdata)
        },
        update = proc(data: ecs.ScriptData) {
            rdata := cast(^Resource)data.data
            switch rdata.state {
            case .IDLE:
                break
            case .BEGIN_DAMAGE:
                rdata.og_size = data.gameObject.transform.size
                data.gameObject.transform.size *= 0.9
                rdata.damage_timer = 0.1
                rdata.state = ResourceState.TAKING_DAMAGE
                rdata.health -= 1

            case .TAKING_DAMAGE:
                rdata.damage_timer -= data.dt
                if rdata.damage_timer <= 0 {
                    if rdata.health <= 0 {
                        for i in 0..<rand.int_range(2,6) {
                            // TODO make this dynamic
                            item := create_item(game, data.gameObject.transform.pos, Item({tag=.WOOD, use=nil}));
                            tilesheet := io.new_tilesheet(game.assetsManager, "./assets/farm/objects&items/items free.png", {16,16})
                            og.add_component(item, ecs.NewSpriteRenderer(sprite=tilesheet.sprites[2][0]))
                        }
                        
                        ecs.destroy_entity(data.ecs, data.gameObject.entity)
                    }

                    rdata.state = ResourceState.IDLE
                    data.gameObject.transform.size = rdata.og_size
                }
                
            }
        },
        on_raycast_hit = proc(data: ecs.ScriptData) {
            rdata := cast(^Resource)data.data
            rdata.state = ResourceState.BEGIN_DAMAGE

            timer := new(Timer)
            timer.max_time = 0.2

            inventory := og.new_gameobject(game.ecs)
            inventory.transform.pos = data.gameObject.transform.pos + {0,data.gameObject.transform.size.y/2+40}
            og.add_component(inventory, ecs.NewText("35", color={255,255,255,255}))
            rigid := og.add_component(inventory, ecs.NewRigidbody(type=ecs.BodyType.dynamicBody, disabled_gravity=true, disabled_rotation=true))
            

            og.add_component(inventory, ecs.NewScriptComponent(ecs.NewScript(
                data=timer,
                on_destroy = proc(data:ecs.ScriptData) {
                    timer := cast(^Timer)data.data
                    if timer != nil do free(timer)
                },
                update = proc(data:ecs.ScriptData) {
                    timer := cast(^Timer)data.data
                    timer.current_time += data.dt
                    if timer.current_time >= timer.max_time {
                        ecs.destroy_entity(data.gameObject.ecs, data.gameObject.entity)
                    }
                    og.apply_force(data.gameObject.entity, {0,1})
                }
            )))

        }
    )
}
