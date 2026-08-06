package main
import og "../ogamer"
import "../ogamer/ecs"
import "../ogamer/input"
import "../ogamer/renderer"
import "../ogamer/events"
import "../ogamer/io"
import "core:math"
import "core:math/linalg"
import "core:fmt"

import b2 "vendor:box2d"

SPEED :: 10

PlayerState :: enum {
    IDLE,
    WALKING_RIGHT,
    WALKING_LEFT,
    WALKING_UP,
    WALKING_DOWN,    
}

PlayerData :: struct {
    state:PlayerState,
    gameObject: ecs.GameObject,
    selected_tool: int,
    start, end : [2]f32,
    inventory: Inventory
}

lerp :: proc (a, b: og.Vector2, t:f32) -> og.Vector2 {
    return a + (b - a) * t
}

playerData : ^PlayerData

create_player :: proc (game: ^og.Game) {
    pData := new(PlayerData)
    playerData = pData

    append(&pData.inventory.filter,
           ItemTag(.WOOD),
           ItemTag(.PUMPKIN),
           ItemTag(.PUMPKIN_SEED),
           ItemTag(.CARROT),
           ItemTag(.CARROT_SEED),
           ItemTag(.HOE),
          )

    player := og.new_gameobject(game.ecs);
    player.transform.size = {150,150}

    pData.gameObject = player


    og.add_component(player, ecs.NewRigidbody(type=ecs.BodyType.dynamicBody, disabled_gravity=true, disabled_rotation=true, linear_damping=10))
    og.add_component(player, ecs.NewCollider(trigger=true, size={-60,0}))
    og.add_component(player, ecs.NewDepthSort(offset={0,20}))

    
    camera := og.new_gameobject(game.ecs)
    og.add_component(camera, ecs.NewCamera(zoom=0.8))
    og.add_component(camera, ecs.NewScriptComponent(ecs.NewScript(data=pData, update = proc (data: ecs.ScriptData) {
        pdata := cast(^PlayerData)data.data
        pt := og.get_component(pdata.gameObject, ecs.Transform)
        data.gameObject.transform.pos = lerp(data.gameObject.transform.pos, pt.pos, 0.05)
    })))

    leng := make([]int,3)
    leng[0] = 2
    leng[1] = 8
    leng[2] = 8
    og.add_component(player, ecs.NewSpriteAnimator(
        sprites_length=leng,
        sprites=io.new_tilesheet(game.assetsManager, "./assets/farm/characters/main character/walk and idle.png", {24,24}).sprites))

    og.add_component(player, ecs.NewScriptComponent(ecs.NewScript(
        data = pData,
        update=player_update,
        on_trigger_enter = proc (data:ecs.ScriptData, other: og.GameObject) {
            pdata := cast(^PlayerData)data.data
            if tag, has := og.get_component(other, ecs.Tag); has {
                sprite_comp, ok := og.get_component(other, ecs.SpriteRenderer)
                if item_tag, ok := string_to_itemtag(tag.tag); ok {
                    if add_item(&pdata.inventory, generate_item_from_tag(item_tag), sprite=sprite_comp.sprite) {
                        ecs.destroy_entity(data.ecs, other.entity)
                    }
                }
            }
        },
    )))
}

hanlde_animation :: proc(pData: ^PlayerData) {

    animator    := og.get_component(pData.gameObject, ecs.SpriteAnimator)
    sprite_comp := og.get_component(pData.gameObject, ecs.SpriteRenderer)

    #partial switch (pData.state) {
        case .IDLE:
        animator.active_animation = 0
        animator.time = 0.2
        case .WALKING_RIGHT:
        animator.active_animation = 1
        animator.time = 0.1
        sprite_comp.inverted = true
        case .WALKING_LEFT:
        animator.active_animation = 1
        animator.time = 0.1
        sprite_comp.inverted = false
        case .WALKING_UP, .WALKING_DOWN:
        animator.active_animation = 1
        animator.time = 0.1

    }
}


player_update :: proc(data: ecs.ScriptData) {
    pdata := cast(^PlayerData)data.data
    hanlde_animation(pdata)
    // reset walking ilde
    if pdata.state == .WALKING_RIGHT ||
        pdata.state == .WALKING_LEFT ||
        pdata.state == .WALKING_UP ||
        pdata.state == .WALKING_DOWN
    {pdata.state = .IDLE}

    // warlking
    if og.is_key_down(input.KeyboardKey.A) {
        pdata.state = .WALKING_LEFT
        og.apply_force(data.gameObject.entity, {-1,0}*SPEED)
    }
    if og.is_key_down(input.KeyboardKey.D) {
        pdata.state = .WALKING_RIGHT
        og.apply_force(data.gameObject.entity, {1,0}*SPEED)
    }
    if og.is_key_down(input.KeyboardKey.W) {
        pdata.state = .WALKING_UP
        og.apply_force(data.gameObject.entity, {0,1}*SPEED)
    }
    if og.is_key_down(input.KeyboardKey.S) {
        pdata.state = .WALKING_DOWN
        og.apply_force(data.gameObject.entity, {0,-1}*SPEED)
    }

    // DROPPING SELECTED ITEM
    if og.is_key_pressed(input.KeyboardKey.Q) {
        if item, ok := get_item(&pdata.inventory, pdata.selected_tool); ok {
            remove_item(&pdata.inventory, item.tag)
            dropped := create_item(game, data.gameObject.transform.pos + {100,0}, item)
            og.add_component(dropped, ecs.NewSpriteRenderer(sprite=get_item_sprite(item.tag)))
        }
    }

    
    gs :f32 = 100
    wp := input.get_world_mouse_position()
    // wp = {
    //     math.round_f32((wp.x - gs/2) / gs) * gs + gs / 2,
    //     math.round_f32((wp.y - gs/2) / gs) * gs + gs / 2 
    // }
    wp = {
        math.round_f32(wp.x/gs) * gs,
        math.round_f32(wp.y/gs) * gs
    }


    // rendering the tileselector
    sprite := io.load(game.assetsManager, "./assets/tileselector.png")
    renderer.add_command(game.renderer, renderer.Sprite({
        pos= wp,
        size={100,100},
        rot=0,
        sprite=sprite,
        layer=10000000000
    }))

    // useing item
    if og.is_mouse_pressed(input.MouseButton.RIGHT) {
        if item, ok := get_item(&pdata.inventory, pdata.selected_tool); ok do use_item(&pdata.inventory, item.tag, data)
        
    }
    // Attack
    if og.is_mouse_pressed(input.MouseButton.LEFT) {
        
        pos := data.gameObject.transform.pos
        mpos := input.get_world_mouse_position()
        direction := linalg.normalize0(mpos-pos) * 300
        result := og.raycast(pos, direction);
        
        pdata.start, pdata.end = pos, pos+direction

        // swosh animation
        t := create_tool(game, io.new_tilesheet(game.assetsManager, "./assets/swosh.png", {16,16}))
        t.transform.local_pos = input.get_mouse_position().x > 1920/2 ? {30,0} : {-30,0}
        og.add_child(data.gameObject, t)

    }
    
    // Handle inventory item selection
    if og.is_key_pressed(input.KeyboardKey.ONE) {
        pdata.selected_tool = 0;
    }
    if og.is_key_pressed(input.KeyboardKey.TWO) {
        pdata.selected_tool = 1;
    }
    if og.is_key_pressed(input.KeyboardKey.THREE) {
        pdata.selected_tool = 2;
    }
    if og.is_key_pressed(input.KeyboardKey.FOUR) {
        pdata.selected_tool = 3;
    }
    if og.is_key_pressed(input.KeyboardKey.FIVE) {
        pdata.selected_tool = 4;
    }

//    renderer.add_command(data.renderer, renderer.Line({pdata.start, pdata.end, renderer.get_color(0x00ff00ff)}))

    draw_inventory(data.renderer, &pdata.inventory, pdata.selected_tool)
}

plant :: proc (data: ecs.ScriptData) {

}
