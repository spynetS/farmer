package main;

import og "../ogamer/"
import "../ogamer/ecs"
import "../ogamer/io"

import "core:fmt"
import "core:slice"


RecipeTag  :: ItemTag
MachineTag :: ItemTag

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
    inventory       : Inventory,
    tag             : MachineTag,
    slots           : [dynamic]Slot,    // recipes that are worked on
    on_slot_working : proc (^Machine, ^Slot, og.GameObject),
    on_slot_done    : proc (^Machine, ^Slot, og.GameObject)
}

machine_add_item :: proc(machine: ^Machine, item: Item) -> bool {
    return add_item(&machine.inventory, item)
}

machine_set_slot :: proc(machine: ^Machine, slot: Slot, index: int) -> bool {

    // for rec in machine.recipies {
    //     if rec.tag != slot.recipe.tag do return false
    // }

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
                if tag, ok := string_to_itemtag(tag.tag); ok {
                    if item, has := generate_item_from_tag(tag); has {
                        mdata := cast(^Machine)data.data
                        if machine_add_item(mdata, item) do ecs.destroy_entity(other.ecs, other.entity)
                        
                    }
                }
            }
        }
    )))
    return machine_obj
}

machine_drop_items :: proc (mdata: ^Machine, slot: Slot, pos: og.Vector2) {
    for o_item, amount in slot.recipe.output {
        for i in 0..<amount {
            item := create_item(game, pos, generate_item_from_tag(o_item))
            og.add_component(item, ecs.NewSpriteRenderer(sprite=get_item_sprite(o_item), layer=100))
        }
        remove_item(&mdata.inventory, o_item, slot.recipe.input[o_item])
    }

}

machine_script :: proc(data:ecs.ScriptData) {
    mdata := cast(^Machine)data.data
    slots: for &slot in mdata.slots {

        if slot.working {
            slot.time += data.dt
            if mdata.on_slot_working != nil do mdata.on_slot_working(mdata, &slot, data.gameObject)

            // Its done
            if slot.time >= slot.recipe.time {
                slot.time = 0
                slot.working = false
                if mdata.on_slot_done != nil do mdata.on_slot_done(mdata, &slot, data.gameObject)
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
    #partial switch tag {
    case .WOOD:
        hoe := Recipe({time = 10})
        hoe.input[.WOOD] = 5
        hoe.output[.HOE] = 1

        seeds := Recipe({time = 1})
        seeds.input[.PUMPKIN] = 1
        seeds.output[.PUMPKIN_SEED] = 1
        seeds.input[.CARROT] = 1
        seeds.output[.CARROT_SEED] = 1

                
        slot := Slot({
            recipe=hoe,
        })
        slot2 := Slot({
            recipe=seeds,
        })
        
        machine := new(Machine)
        append(&machine.inventory.filter,
               ItemTag(.PUMPKIN),
               ItemTag(.CARROT),
               ItemTag(.WOOD)
              )

        machine_set_slot(machine, slot, 0)
        machine_set_slot(machine, slot2, 1)
        return machine
    case .PUMPKIN_SEED:
        pumpkin := Recipe({time = 5})
        pumpkin.input [.PUMPKIN_SEED] = 1
        pumpkin.output[.PUMPKIN] = 2
        
        slot := Slot({
            recipe=pumpkin,
        })
        
        machine := new(Machine)
        machine.tag = .PUMPKIN_SEED

        machine_set_slot(machine, slot, 0)
        append(&machine.inventory.filter,
               ItemTag(.PUMPKIN_SEED),
              )
        add_item(&machine.inventory, generate_item_from_tag(.PUMPKIN_SEED))


        return machine
        case .CARROT_SEED:
        pumpkin := Recipe({time = 5})
        pumpkin.input [.CARROT_SEED] = 1
        pumpkin.output[.CARROT] = 2
        
        slot := Slot({
            recipe=pumpkin,
        })
        
        machine := new(Machine)
        machine.tag = .CARROT_SEED

        machine_set_slot(machine, slot, 0)
        append(&machine.inventory.filter,
               ItemTag(.CARROT_SEED),
              )
        add_item(&machine.inventory, generate_item_from_tag(.CARROT_SEED))


        return machine

    }
    return nil
}
