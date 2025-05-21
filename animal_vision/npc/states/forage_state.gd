# npc/states/forage_state.gd
class_name ForageState
extends NPCStateBase

@export var search_radius_for_food: float = 15.0
var food_target: Node3D = null

func enter():
    super.enter()
    # print("%s: Starting to forage." % npc_controller.name)
    find_food_source()

func find_food_source():
    if not npc_controller: return
    food_target = null # Reset
    for food_tag in npc_controller.food_tags:
        # This is a very simplified search. A real game might use an Octree, area checks, etc.
        # Or NPCs might know specific food spawn points.
        var potential_foods = get_tree().get_nodes_in_group(food_tag)
        var closest_food = null
        var min_dist_sq = search_radius_for_food * search_radius_for_food

        for food_item_node in potential_foods:
            if food_item_node is Node3D:
                var dist_sq = npc_controller.global_transform.origin.distance_squared_to(food_item_node.global_transform.origin)
                if dist_sq < min_dist_sq and npc_controller.can_see_target(food_item_node): # Check visibility
                    min_dist_sq = dist_sq
                    closest_food = food_item_node
        
        if closest_food:
            food_target = closest_food
            break # Found food from one of the tags

    if food_target:
        # print("%s: Food source found: %s at %s" % [npc_controller.name, food_target.name, food_target.global_transform.origin])
        npc_controller.current_target_position = food_target.global_transform.origin
        if npc_controller.navigation_agent:
            npc_controller.navigation_agent.target_position = npc_controller.current_target_position
    else:
        # print("%s: No food source found. Will wander." % npc_controller.name)
        if npc_controller.states.has("wander"): npc_controller.change_state("wander")


func execute(delta: float):
    super.execute(delta)
    if not food_target: # If no food target was found or it was consumed
        if npc_controller.states.has("wander"): npc_controller.change_state("wander"); return # Wander to find food
        return

    if npc_controller and npc_controller.navigation_agent and npc_controller.navigation_agent.is_target_reached():
        # Reached food source, transition to Eating state
        if npc_controller.states.has("eating"):
            # Pass the food target to the eating state if needed
            # npc_controller.states["eating"].set_food_target(food_target)
            npc_controller.change_state("eating")
        else: # No eating state, just wander again
            if npc_controller.states.has("wander"): npc_controller.change_state("wander")
    
    # Check for threats while foraging
    # Similar to Wander state, this is simplified.
    # var threats = get_tree().get_nodes_in_group("Player")
    # for threat_node in threats:
    #    if npc_controller.can_see_target(threat_node):
    #        if npc_controller.states.has("flee"):
    #            npc_controller.change_state("flee")
    #            return


func exit():
    super.exit()
    food_target = null
```
