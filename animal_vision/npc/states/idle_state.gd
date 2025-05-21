# npc/states/idle_state.gd
class_name IdleState
extends NPCStateBase

var idle_timer: float = 0.0
@export var min_idle_time: float = 2.0
@export var max_idle_time: float = 5.0

func enter():
    super.enter()
    idle_timer = randf_range(min_idle_time, max_idle_time)
    # print("%s: Idling for %.2f seconds." % [npc_controller.name, idle_timer])
    # Stop movement if any
    if npc_controller and npc_controller.navigation_agent:
        npc_controller.navigation_agent.target_position = npc_controller.global_transform.origin


func execute(delta: float):
    super.execute(delta)
    idle_timer -= delta
    if idle_timer <= 0:
        # Transition to Wander state after idling
        if npc_controller and npc_controller.states.has("wander"):
            npc_controller.change_state("wander")
        else:
            # Stay in idle if wander is not available, reset timer
            idle_timer = randf_range(min_idle_time, max_idle_time)


func exit():
    super.exit()
```
