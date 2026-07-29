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

main :: proc() {
    game = og.init_game();
    og.current_game = game;
    
    create_player(game)

    _map := tiled.load_map(game.assetsManager, "./assets/map.tmj")
    fmt.println("MAP:",_map.tilesets)
    defer tiled.destroy_map(_map)
    tiled.create_from_map(game, _map, {6,6}, on_create = proc(obj: tiled.Object, transform: ecs.Transform) {});


    og.start_game(game);
    og.destroy_game(game);
}


