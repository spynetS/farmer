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

game: ^og.Game

create_debug :: proc(game: ^og.Game) {
    fps := og.new_gameobject(game.ecs)
    fps.transform.pos = {50,50}
    text := og.add_component(fps, ecs.NewUiText("asd"))
    og.add_component(fps, ecs.NewScriptComponent(ecs.NewScript(data=text, update = proc (data:ecs.ScriptData) {
        text := cast(^ecs.UIText)data.data
        text.text = fmt.tprintf("%d",cast(int) (1/data.dt))
    })))
}


main :: proc() {
    game = og.init_game(og.RenderSettings({144}));
    og.current_game = game;
    
    create_debug(game)

    create_player(game)

    _map := tiled.load_map(game.assetsManager, "./assets/map.tmj")
    fmt.println("MAP:",_map.tilesets)
    defer tiled.destroy_map(_map)
    tiled.create_from_map(game, _map, {6,6}, on_create = proc(obj: tiled.Object, transform: ecs.Transform) {});


    og.start_game(game);
    og.destroy_game(game);
}


