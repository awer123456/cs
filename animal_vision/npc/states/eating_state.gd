# npc/states/eating_state.gd
class_name EatingState
extends NPCStateBase

@export var eating_duration: float = 3.0
var eating_timer: float = 0.0
# var food_item_being_eaten: Node3D = null # Could be passed from ForageState

func enter():
    super.enter()
    eating_timer = eating_duration
    # print("%s: Started eating." % npc_controller.name)
    # Stop movement
    if npc_controller and npc_controller.navigation_agent:
        npc_controller.navigation_agent.target_position = npc_controller.global_transform.origin
    
    # Placeholder: Consume the food item
    # if food_item_being_eaten and food_item_being_eaten.has_method("consume"):
    #    food_item_being_eaten.consume()
    # elif food_item_being_eaten:
    #    food_item_being_eaten.queue_free() # Simple removal


func execute(delta: float):
    super.execute(delta)
    eating_timer -= delta
    if eating_timer <= 0:
        # Finished eating, decide what to do next (e.g., wander or idle)
        # print("%s: Finished eating." % npc_controller.name)
        # Placeholder: Restore hunger if NPC has hunger stat
        # if npc_controller.has_method("restore_hunger"): npc_controller.restore_hunger(50)
        if npc_controller and npc_controller.states.has("idle"):
            npc_controller.change_state("idle")


func exit():
    super.exit()
    # food_item_being_eaten = null
```
