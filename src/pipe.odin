package main;

import og "../ogamer"
import "../ogamer/ecs"


spawn_pipe :: proc (game: ^og.Game) {
    pipe := og.new_gameobject(game.ecs)
    og.add_component(pipe, ecs.NewScriptComponent(ecs.NewScript(
        on_trigger_enter = proc(data:ecs.ScriptData, other: ecs.GameObject) {
            
        }
    )))
}
