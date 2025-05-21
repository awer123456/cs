# npc/states/npc_state_base.gd
class_name NPCStateBase
extends Node # States can be nodes if added as children to AIController

var npc_controller: NPCAnimalAIController = null # Set by NPCAnimalAIController
var state_key: String = "" # Set by NPCAnimalAIController, e.g., "idle"

func _init(p_controller = null): # Allow controller to be passed in init
    npc_controller = p_controller
    # Node name might be set if added in editor.
    # state_key will be set if initialized programmatically by NPCController

func set_npc_controller(controller: NPCAnimalAIController):
    npc_controller = controller

func set_state_key(key: String):
    state_key = key
    name = key.capitalize() + "StateNode" # Update node name if desired

# Called when entering the state
func enter():
    # print("%s entering %s state" % [npc_controller.name if npc_controller else "NPC", name])
    pass

# Called every physics frame while in the state
func execute(delta: float):
    pass

# Called when exiting the state
func exit():
    # print("%s exiting %s state" % [npc_controller.name if npc_controller else "NPC", name])
    pass
```
