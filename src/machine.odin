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
    recipies     : [dynamic]Recipe,  // recipes that can be made
    slots        : [dynamic]Slot,    // recipes that are worked on
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

    //    machine.slots[index] = slot
    assign_at(&machine.slots, index, slot)
    return true
}

create_machine_drop :: proc (game: ^og.Game, machine: ^Machine) -> og.GameObject {
    machine_obj := og.new_gameobject(game.ecs)
    og.add_component(machine_obj, ecs.NewRigidbody(type=ecs.BodyType.staticBody))
    
    og.add_component(machine_obj, ecs.NewScriptComponent(ecs.NewScript(
        data=machine,
        update=machine_script,
        on_trigger_enter = proc(data:ecs.ScriptData, other: ecs.GameObject) {
            if tag, has := og.get_component(other, ecs.Tag); has {
                if item, has := generate_item_from_tag(ItemTag(tag.tag)); has {
                    mdata := cast(^Machine)data.data
                    if machine_add_item(mdata, item) do ecs.destroy_entity(other.ecs, other.entity)
                    
                }
            }
        }
    )))
    return machine_obj
}

machine_script :: proc(data:ecs.ScriptData) {
    mdata := cast(^Machine)data.data
    slots: for &slot in mdata.slots {
        animator, has_anim := og.get_component(data.gameObject, ecs.SpriteAnimator)
        if slot.working {
            if has_anim do animator.active_animation = 1

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
                if has_anim do animator.active_animation = 0
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
// have to free the machine memory
machine_factory :: proc (tag: MachineTag) -> ^Machine {
    switch tag {
    case "wood_machine":
        hoe := Recipe({time = 10})
        hoe.input["wood"] = 5
        hoe.output["hoe"] = 1

        seeds := Recipe({time = 5})
        seeds.input["pumpkin"] = 1
        seeds.output["pumpkin_seed"] = 1
                
        slot := Slot({
            recipe=hoe,
        })
        slot2 := Slot({
            recipe=seeds,
        })
        
        machine := new(Machine)
        machine.tag = "wood_machine"
        append(&machine.recipies, hoe, seeds)

        machine_set_slot(machine, slot, 0)
        machine_set_slot(machine, slot2, 1)
        return machine
    case "field":
        pumpkin := Recipe({time = 10})
        pumpkin.input["pumpkin_seed"] = 1
        pumpkin.output["pumpkin"] = 2
        
        slot := Slot({
            recipe=pumpkin,
        })
        
        machine := new(Machine)
        machine.tag = "field"
        append(&machine.recipies, pumpkin)
        machine_set_slot(machine, slot, 0)

        return machine
    }
    return nil
}
