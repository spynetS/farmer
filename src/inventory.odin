package main;

import rn "../ogamer/renderer"
import "../ogamer/io"
import "../ogamer/ecs"
import "core:fmt"
import "core:slice"



Inventory :: struct {
    items: map[ItemTag]Item,
    count: map[ItemTag]int,
    sprites: map[ItemTag]io.Sprite,
    filter: [dynamic]ItemTag
}
ItemTag :: distinct string

add_item :: proc(inv: ^Inventory, item: Item, amount: int = 1, sprite: io.Sprite = io.Sprite({})) -> bool {
    if !slice.contains(inv.filter[:], item.tag) do return false
    inv.count[item.tag] += amount
    inv.items[item.tag] = item
    if sprite.texture != "" do inv.sprites[item.tag] = sprite
    return true
}

remove_item :: proc(inv: ^Inventory, item: ItemTag, amount: int = 1) {
    inv.count[item] -= amount
    // TODO remove sprites from inventory aswell
}

get_count :: proc (inv: ^Inventory, item: ItemTag) -> int {
    return inv.count[item]
}

get_item :: proc (inv: ^Inventory, index: int) ->  (Item, bool) {
    i := 0
    for tag in get_items_as_list(inv) {
        if i == index {
            return inv.items[tag], inv.count[tag] > 0
        }
        i+=1
    }
    return Item({}), false
}

use_item :: proc(inv: ^Inventory, item: ItemTag, data: ecs.ScriptData) {
    if inv.items[item].use != nil do inv.items[item].use(data)
}

get_items_as_list :: proc (inv: ^Inventory) -> []ItemTag {
    // len(inv.count)
    keys := make([dynamic]ItemTag)
    for key in inv.count {
        append(&keys, ItemTag(key))
    }
    k := keys[:]
    slice.sort(k)
    return k
}

draw_inventory :: proc(renderer: ^rn.Renderer, inv: ^Inventory, selected_index: int) {
    rn.add_command(renderer, rn.UISprite({
        pos={100,200+50+60},
        offset={0,0},
        size={75,50*6},
        rot=0,
        inverted=false,
        sprite=io.load(game.assetsManager, "./assets/inventory.png"),
        layer=0,
        repeated_x=false,
        repeated_y=false
    }))
    i := 0
    for item in get_items_as_list(inv) {
        if i == selected_index {
            rn.add_command(renderer, rn.UISprite({
                pos={100,50*cast(f32)i+200},
                offset={0,0},
                size={50,50},
                rot=0,
                inverted=false,
                sprite=io.load(game.assetsManager, "./assets/tileselector.png"),
                layer=1,
                repeated_x=false,
                repeated_y=false
            }))

        }
        rn.add_command(renderer, rn.UISprite({
            pos={100,50*cast(f32)i+200},
            offset={0,0},
            size={50,50},
            rot=0,
            inverted=false,
            sprite=inv.sprites[item],
            layer=1,
            repeated_x=false,
            repeated_y=false
            
        }))

        rn.add_command(renderer, rn.UIText({
            {100+10,50*cast(f32)i+200+10},
            24,
            0,
            fmt.tprintf("%d", inv.count[item]),
            rn.get_color(0xffffffff),
            2
        }))
        
        i+=1
    }
    
}
