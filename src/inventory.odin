package main;

import rn "../ogamer/renderer"
import "../ogamer/io"
import "core:fmt"


Inventory :: struct {
    count: map[ItemTag]int,
    sprites: map[ItemTag]io.Sprite
}
ItemTag :: string

add_item :: proc(inv: ^Inventory, item: ItemTag, amount: int = 1, sprite: io.Sprite = io.Sprite({})) {
    inv.count[item] += amount
    if sprite.texture != "" do inv.sprites[item] = sprite
}

remove_item :: proc(inv: ^Inventory, item: ItemTag, amount: int = 1) {
    inv.count[item] -= amount
    // TODO remove sprites from inventory aswell
}

get_count :: proc (inv: ^Inventory, item: ItemTag) -> int {
    return inv.count[item]
}
 
draw_inventory :: proc(renderer: ^rn.Renderer, inv: ^Inventory) {
    i := 0
    for item, amount in inv.count {
        rn.add_command(renderer, rn.UIText({
            {100,50*cast(f32)i+200},
            36,
            0,
            fmt.tprintf("%d", amount),
            rn.get_color(0x181818ff),
            1
        }))
        rn.add_command(renderer, rn.UISprite({
            pos={100-50,50*cast(f32)i+200+25},
            offset={0,0},
            size={50,50},
            rot=0,
            inverted=false,
            sprite=inv.sprites[item],
            layer=10,
            repeated_x=false,
            repeated_y=false
            
        }))
        i+=1
    }
    
}
