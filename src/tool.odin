package main;

import og "../ogamer"
import  "../ogamer/ecs"
import  "../ogamer/io"

create_tool :: proc (game: ^og.Game) -> og.GameObject {
    tool := og.new_gameobject(game.ecs)
    tool.transform.local_size = {-35,-35}
    tool.transform.local_pos = {-20,0}
    //og.add_component(tool, ecs.NewSpriteRenderer(sprite=io.new_tilesheet(game.assetsManager, "./assets/farm/objects&items/hoe-sheet.png",{16,16}).sprites[0][0]))
    og.add_component(tool, ecs.NewSpriteRenderer())
    og.add_component(tool, ecs.NewSpriteAnimator(sprites=io.new_tilesheet(game.assetsManager, "./assets/farm/objects&items/hoe-sheet.png",{16,16}).sprites))


    og.add_component(tool, ecs.NewScriptComponent(ecs.NewScript(on_animation_finished = proc(data: ecs.ScriptData, animator: ^ecs.SpriteAnimator) {
        ecs.destroy_entity(data.ecs, data.gameObject.entity)
    })))

    return tool
}
