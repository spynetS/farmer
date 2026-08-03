package main;

import og "../ogamer/"
import "../ogamer/ecs"
import "../ogamer/io"

import "core:fmt"


Recipe :: struct {
    input  : map[ItemTag]int, // whats needed to produce output
    output : map[ItemTag]int, // what the recipe outputs
    time   : f32           // the amount of time it takes
}

Slot :: struct {
    recipe: Recipe,
    time: f32,
    working : bool
}

MachineTag :: distinct string

Machine :: struct {
    inventory    : Inventory,
    tag          : MachineTag,
    recipies     : []Recipe,  // recipes that can be made
    working_slot : []Slot,    // recipes that are worked on
}

machine_script :: proc(data:ecs.ScriptData) {
    mdata := cast(^Machine)data.data
    for &slot in mdata.working_slot {        
        if slot.working {
            slot.time += data.dt
            // Its done
            if slot.time >= slot.recipe.time {
                for o_item, amount in slot.recipe.output {
                    for i in 0..<amount {
                        item := create_item(game, data.gameObject.transform.pos, generate_item_from_tag(o_item))
                        og.add_component(item, ecs.NewSpriteRenderer(sprite=get_item_sprite(o_item), layer=100))
                    }
                    remove_item(&mdata.inventory, o_item, slot.recipe.input[o_item])
                }
                slot.time = 0
                slot.working = false
            }
        }
        else {
            enough := true
            for tag, amount in slot.recipe.input {
                if mdata.inventory.count[tag] <= amount {
                    enough = false
                }
            }
            if !enough do continue
            for tag, amount in slot.recipe.input {
                remove_item(&mdata.inventory, tag, amount)
            }
            slot.working = true
            
        }
    }
}

