package main;

import og "../ogamer"
import  "../ogamer/ecs"
import  "../ogamer/io"
import  "../ogamer/input"

create_tool :: proc (game: ^og.Game, tilesheet: ^io.TileSheet) -> og.GameObject {
    tool := og.new_gameobject(game.ecs)
    tool.transform.local_size = {-35,-35}
    tool.transform.local_pos = {-20,0}

    sc := og.add_component(tool, ecs.NewSpriteRenderer())
    sc.inverted = input.get_mouse_position().x > 1920/2 // This works idk why
    og.add_component(tool, ecs.NewSpriteAnimator(sprites=tilesheet.sprites))


    og.add_component(tool, ecs.NewScriptComponent(ecs.NewScript(on_animation_finished = proc(data: ecs.ScriptData, animator: ^ecs.SpriteAnimator) {
        ecs.destroy_entity(data.ecs, data.gameObject.entity)
    })))

    return tool
}
