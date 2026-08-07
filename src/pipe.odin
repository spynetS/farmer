package main;

import og "../ogamer"
import "../ogamer/ecs"
import "../ogamer/io"
import rn "../ogamer/renderer"
import "core:math"
import "core:fmt"

rotate_pipe :: proc (gameobject: og.GameObject) {
    gameobject.transform.rot = gameobject.transform.rot + 90.0
    
    pipe := cast(^Pipe)og.get_component(gameobject, ecs.ScriptComponent).scripts[0].data
    pipe.input = nil
    pipe.output = nil
    animator := og.get_component(gameobject, ecs.SpriteAnimator)
    animator.active_animation = 0

}

round_pos :: proc(pos: og.Vector2) -> og.Vector2 {
    gs :f32 = 100
    return {
        math.round_f32(pos.x/gs) * gs,
        math.round_f32(pos.y/gs) * gs
    }

}

create_pipe :: proc (game: ^og.Game,  pos: og.Vector2, input, output: ^Inventory) {
    pipe_obj := og.new_gameobject(game.ecs)
    pipe_obj.transform.pos = pos
    og.add_component(pipe_obj, ecs.NewTag("pipe"))
    tilesheet := io.new_tilesheet(game.assetsManager, "./assets/pipe.png", {16,16})
    og.add_component(pipe_obj, ecs.NewSpriteAnimator(sprites=tilesheet.sprites))
    og.add_component(pipe_obj, ecs.NewCollider(trigger=true))
    og.add_component(pipe_obj, ecs.NewRigidbody(type=ecs.BodyType.staticBody))

    pipe := new(Pipe)
    pipe.input = input
    pipe.output = output
    append(&pipe.buffer.filter, ItemTag.PUMPKIN)

    og.add_component(pipe_obj, ecs.NewScriptComponent(ecs.NewScript(
        data = pipe,
        update = proc(data: ecs.ScriptData) {
            pipe := cast(^Pipe) data.data
            // time handling
            pipe.current_time += data.dt
            angle : int = int(data.gameObject.transform.rot)


            offset := og.Vector2{}
            if angle < 90.0 {
                offset = {0, 51}
            } else if angle < 180.0 {
                offset = {-51, 0}
            } else if angle < 270.0 {
                offset = {0, -51}
            } else {
                offset = {51, 0}
            }



            
            items := get_items_as_list(&pipe.buffer)
            if len(items) > 0 {
                for item in items {
                    rn.add_command(data.renderer, rn.Sprite({data.gameObject.transform.pos,{0,0}, {50,50}, 0, false, pipe.buffer.sprites[item],100, false, false}))
                }
            }
            delete(items)

            if pipe.current_time < 0.3 do return
            pipe.current_time = 0



            if pipe.input == nil {
                // we get gameobjects beside us
                rn.add_command(data.renderer, rn.Rectangle({round_pos(data.gameObject.transform.pos + offset),{50,50},0, rn.get_color(0x00ff00ff), false, 100}))

                if gameobject, found := ecs.get_gameobject_pos_all(data.ecs, round_pos(data.gameObject.transform.pos + offset)); found {
                    if tag, had := og.get_component(gameobject, ecs.Tag); had {
                        switch tag.tag {
                        case "harvester":
                            harvester := cast(^Harvester)og.get_component(gameobject, ecs.ScriptComponent).scripts[0].data
                            pipe.input = &harvester.output
                        case "pipe":
                            other_pipe := cast(^Pipe)og.get_component(gameobject, ecs.ScriptComponent).scripts[0].data
                            pipe.input = &other_pipe.buffer
                        }
                    }
                }
            }
            if pipe.output == nil {
                rn.add_command(data.renderer, rn.Rectangle({round_pos(data.gameObject.transform.pos - offset),{50,50},0, rn.get_color(0xff0000ff), false, 100}))
                if gameobject, found := ecs.get_gameobject_pos_all(data.ecs, round_pos(data.gameObject.transform.pos - offset)); found {

                    if tag, found := og.get_component(gameobject, ecs.Tag); found {
                        switch tag.tag {
                        case "wood_machine":
                            machine := cast(^Machine)og.get_component(gameobject, ecs.ScriptComponent).scripts[0].data
                            pipe.output = &machine.input
                        case "pipe":
                            other_pipe := cast(^Pipe)og.get_component(gameobject, ecs.ScriptComponent).scripts[0].data
                            pipe.output = &other_pipe.buffer
                        }
                    }
                }
            }

            if pipe.input != nil && pipe.output != nil {
                animator := og.get_component(data.gameObject, ecs.SpriteAnimator)
                animator.active_animation = 1
            }
            if pipe.input != nil {

                items := get_items_as_list(pipe.input)
                if len(items) > 0 {
                    for item in items {
                        append(&transfer_requests, TransferRequest({
                            from=pipe.input,
                            to=&pipe.buffer,
                            item = item,
                            amount = pipe.input.count[item]
                        }))
                    }
                }
                delete(items)
            }
            if pipe.output != nil {

                items := get_items_as_list(&pipe.buffer)
                if len(items) > 0 {
                    for item in items {
                        append(&transfer_requests, TransferRequest({
                            from=&pipe.buffer,
                            to=pipe.output,
                            item = item,
                            amount = pipe.buffer.count[item]
                        }))
                    }
                }
                delete(items)
            }

        }
    )))
}
