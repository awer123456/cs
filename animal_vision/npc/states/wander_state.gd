# npc/states/wander_state.gd
class_name WanderState
extends NPCStateBase

@export var wander_radius: float = 10.0 # How far to pick a random point
var time_since_last_wander: float = 0.0
@export var wander_interval: float = 5.0 # How often to pick a new point if not reached

func enter():
    super.enter()
    # print("%s: Starting to wander." % npc_controller.name)
    pick_new_wander_target()
    time_since_last_wander = 0.0

func execute(delta: float):
    super.execute(delta)
    time_since_last_wander += delta

    if npc_controller and npc_controller.navigation_agent:
        if npc_controller.navigation_agent.is_target_reached() or time_since_last_wander > wander_interval:
            # Reached destination or took too long, pick a new one or switch state
            # For now, just pick a new wander target. Could transition to Idle.
            pick_new_wander_target()
            time_since_last_wander = 0.0
    
    # Basic threat detection (example)
    # In a more complex system, perception would be handled more centrally or by the state itself.
    # For now, this is a simplified check.
    # var threats = get_tree().get_nodes_in_group("Player") # Assuming player is in this group
    # for threat_node in threats:
    #    if npc_controller.can_see_target(threat_node): # Assuming threat_node is Node3D
    #        if npc_controller.states.has("flee"):
    #            npc_controller.change_state("flee")
    #            return


func pick_new_wander_target():
    if not npc_controller: return

    var random_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
    var target_pos = npc_controller.global_transform.origin + random_direction * randf_range(wander_radius * 0.5, wander_radius)
    
    # Use NavigationServer to find a reachable point near the random target
    var nav_map_rid = npc_controller.get_world_3d().navigation_map
    var closest_reachable_point = NavigationServer3D.map_get_closest_point(nav_map_rid, target_pos)

    npc_controller.current_target_position = closest_reachable_point
    if npc_controller.navigation_agent:
        npc_controller.navigation_agent.target_position = npc_controller.current_target_position
    # print("%s: New wander target set to %s" % [npc_controller.name, npc_controller.current_target_position])


func exit():
    super.exit()
    if npc_controller and npc_controller.navigation_agent: # Stop current movement
         npc_controller.navigation_agent.target_position = npc_controller.global_transform.origin
```
