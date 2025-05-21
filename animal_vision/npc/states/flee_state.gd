# npc/states/flee_state.gd
class_name FleeState
extends NPCStateBase

@export var flee_distance: float = 15.0
var threat_object: Node3D = null # The object to flee from

func enter():
    super.enter()
    # print("%s: Fleeing!" % npc_controller.name)
    # Threat detection should ideally happen before entering Flee, 
    # and the threat passed to the state. For now, search for it.
    find_threat() 
    if threat_object:
        pick_flee_destination()
    else:
        # No threat found, maybe go back to idle or wander
        if npc_controller and npc_controller.states.has("idle"):
            npc_controller.change_state("idle")

func find_threat():
    # Simplified: check for any node in threat_tags groups.
    # A real system would use perception events.
    if not npc_controller: return
    for tag in npc_controller.threat_tags:
        var threats_in_group = get_tree().get_nodes_in_group(tag)
        for t_node in threats_in_group:
            if t_node is Node3D and npc_controller.can_see_target(t_node): # or can_hear_target
                threat_object = t_node
                # print("%s: Threat detected: %s" % [npc_controller.name, threat_object.name])
                return


func pick_flee_destination():
    if not npc_controller or not threat_object: return

    var direction_from_threat = (npc_controller.global_transform.origin - threat_object.global_transform.origin).normalized()
    var target_pos = npc_controller.global_transform.origin + direction_from_threat * flee_distance
    
    var nav_map_rid = npc_controller.get_world_3d().navigation_map
    var closest_reachable_point = NavigationServer3D.map_get_closest_point(nav_map_rid, target_pos)

    npc_controller.current_target_position = closest_reachable_point
    if npc_controller.navigation_agent:
        npc_controller.navigation_agent.target_position = npc_controller.current_target_position
    # print("%s: Fleeing to %s from %s" % [npc_controller.name, npc_controller.current_target_position, threat_object.name])


func execute(delta: float):
    super.execute(delta)
    if not threat_object or not npc_controller:
        if npc_controller and npc_controller.states.has("idle"): npc_controller.change_state("idle"); return
        return

    # If threat is no longer perceivable or far enough, stop fleeing
    if not npc_controller.can_see_target(threat_object) and not npc_controller.can_hear_target(threat_object):
         # print("%s: Threat lost. Returning to idle." % npc_controller.name)
         if npc_controller.states.has("idle"): npc_controller.change_state("idle"); return

    if npc_controller.navigation_agent and npc_controller.navigation_agent.is_target_reached():
        # Reached flee destination, but threat might still be there. Re-evaluate.
        pick_flee_destination() # Pick a new spot or hold position if threat still visible


func exit():
    super.exit()
    threat_object = null
```
