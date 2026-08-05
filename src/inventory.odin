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
ItemTag :: enum {
    WOOD,
    PUMPKIN,
    PUMPKIN_SEED,
    CARROT,
    CARROT_SEED,
    HOE
}

item_tag_to_string :: proc (tag: ItemTag) -> string {
    switch tag {
    case .WOOD: return "WOOD"
    case .PUMPKIN: return "PUMPKIN"
    case .PUMPKIN_SEED: return "PUMPKIN_SEED"
    case .CARROT: return "CARROT"
    case .CARROT_SEED: return "CARROT_SEED"
    case .HOE: return "HOE"
    }
    return ""
}

string_to_itemtag :: proc (str: string) -> (ItemTag, bool) {
    switch str {
    case "WOOD"         : return .WOOD, true
    case "PUMPKIN"      : return .PUMPKIN, true
    case "PUMPKIN_SEED" : return .PUMPKIN_SEED, true
    case "CARROT"      : return .CARROT, true
    case "CARROT_SEED" : return .CARROT_SEED, true
    case "HOE"          : return .HOE, true
    }
    return .WOOD, false
}

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
    items := get_items_as_list(inv)
    for tag in  items{
        if i == index {
            delete(items)
            return inv.items[tag], inv.count[tag] > 0
        }
        i+=1
    }
    delete(items)
    return Item({}), false
}

use_item :: proc(inv: ^Inventory, item: ItemTag, data: ecs.ScriptData) {
    if inv.items[item].use != nil do inv.items[item].use(&inv.items[item], data)
}

get_items_as_list :: proc (inv: ^Inventory) -> []ItemTag {
    // len(inv.count)
    keys := make([dynamic]ItemTag)
    for key in inv.count {
        append(&keys, key)
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
    items := get_items_as_list(inv)
    defer delete(items)
    for item in items{
        if inv.count[item] == 0 {
            i += 1
            continue
        }
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
