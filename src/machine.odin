package main;

import og "../ogamer/"
import "../ogamer/ecs"
import "../ogamer/io"

import "core:fmt"
import "core:slice"


RecipeTag  :: distinct string
MachineTag :: distinct string

Recipe :: struct {
    tag    : RecipeTag,
    input  : map[ItemTag]int, // whats needed to produce output
    output : map[ItemTag]int, // what the recipe outputs
    time   : f32           // the amount of time it takes
}

Slot :: struct {
    recipe: Recipe,
    time: f32,
    working : bool
}

Machine :: struct {
    inventory    : Inventory,
    tag          : MachineTag,
    recipies     : []Recipe,  // recipes that can be made
    slots        : []Slot,    // recipes that are worked on
}

machine_add_item :: proc(machine: ^Machine, item: Item) -> bool {
    cant := true
    for recipe in machine.recipies {
        if recipe.input[item.tag] > 0 do cant = false
    }
    if cant do return false
    add_item(&machine.inventory, item)
    return true
}

machine_set_slot :: proc(machine: ^Machine, slot: Slot, index: int) -> bool {

    for rec in machine.recipies {
        if rec.tag != slot.recipe.tag do return false
    }


    machine.slots[index] = slot
    return true
}

machine_script :: proc(data:ecs.ScriptData) {
    mdata := cast(^Machine)data.data
    slots: for &slot in mdata.slots {
        animator := og.get_component(data.gameObject, ecs.SpriteAnimator) or_continue;
        if slot.working {
            animator.active_animation = 1

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
                animator.active_animation = 0
            }
        }
        else {
            not_enough := true
            for tag, amount in slot.recipe.input {
                if mdata.inventory.count[tag] >= amount {
                    not_enough = false
                }
            }

            if not_enough {
                continue
            }
            for tag, amount in slot.recipe.input {
                remove_item(&mdata.inventory, tag, amount)
            }
            slot.working = true            
        }
    }
}

