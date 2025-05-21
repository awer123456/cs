# player/player_animal_controller.gd
class_name PlayerAnimalController
extends Node

# Core Properties
var current_animal_data: AnimalData = null
var unlocked_animal_ids: Array[String] = []
var current_animal_node: AnimalBaseController = null # Instantiated node like RabbitController

@export var player_survival_stats: PlayerSurvivalStats 

var animal_data_repository: Dictionary = {}
var ability_repository: Dictionary = {} 
var equipped_abilities: Array[AbilityBase] = []

signal animal_form_switched(new_animal_data)

# Node to parent the animal controller instance to.
# If null, PlayerAnimalController itself will be the parent.
@export var animal_anchor_node: Node3D 


func _ready():
    # (Repositories, stats checks, input map setup as before)
    # Example: add_animal_data_to_repository(load("res://player/animals/data/rabbit_data.tres"))
    #          add_ability_to_repository(load("res://player/abilities/sprint_ability.tres"))
    
    if not player_survival_stats:
        player_survival_stats = get_node_or_null("PlayerSurvivalStats") 
        if not player_survival_stats:
            printerr("PlayerAnimalController: PlayerSurvivalStats node not assigned and not found.")
            
    if not animal_anchor_node:
        # If self is Node3D, it can be the anchor. PlayerAnimalController is currently Node.
        # AnimalBaseController extends Node3D. A Node CAN parent a Node3D, but it's often better practice
        # for the parent to also be Node3D or for a dedicated Node3D anchor to be used.
        # The prompt sets self as default anchor. This will work but might have transform implications
        # if PlayerAnimalController itself is not positioned meaningfully in 3D space.
        # A warning or more robust handling might be needed in a full game.
        animal_anchor_node = self # Default to self if not set
        print("PlayerAnimalController: animal_anchor_node not set. Animal instances will be parented to PlayerAnimalController itself.")
    pass

func _unhandled_input(event: InputEvent):
    if not current_animal_data: return

    if event.is_action_pressed("ability_1"):
        try_activate_ability(0)
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("ability_2"):
        try_activate_ability(1)
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("ability_3"):
        try_activate_ability(2)
        get_viewport().set_input_as_handled()
    # Input for animal switching (e.g., "switch_animal_next")
    elif event.is_action_pressed("switch_animal_next"): # Assuming "switch_animal_next" is in Input Map
        handle_animal_switching()
        get_viewport().set_input_as_handled()


func _process(delta: float):
    var caster_context = current_animal_node if current_animal_node else self
    for ability in equipped_abilities:
        if ability: # and ability.is_active (tick might handle internal cooldowns too)
            ability.tick(delta, caster_context)


func initialize_player(start_animal_id: String):
    # ... (repository checks as before) ...
    if not animal_data_repository.has(start_animal_id):
        printerr("PAC: Animal ID '%s' not in animal_data_repository." % start_animal_id)
        return

    if not unlocked_animal_ids.has(start_animal_id): # Ensure starting animal is unlocked
        unlocked_animal_ids.append(start_animal_id) # Silently unlock, or use unlock_form for logging

    var success = switch_form(start_animal_id)
    if not success:
        printerr("PAC: Failed to initialize player with animal ID '%s'." % start_animal_id)
    else:
        print("PAC: Player initialized with animal '%s'." % start_animal_id)


func switch_form(target_animal_id: String) -> bool:
    if not unlocked_animal_ids.has(target_animal_id):
        print("PAC: Animal ID '%s' is not unlocked." % target_animal_id)
        return false
    # Check if already in the target form and the node is valid
    if current_animal_data and current_animal_data.animal_id == target_animal_id and current_animal_node and is_instance_valid(current_animal_node):
        print("PAC: Already in form '%s'." % target_animal_id)
        return true 

    if not animal_data_repository.has(target_animal_id):
        printerr("PAC: Animal ID '%s' not found in animal_data_repository." % target_animal_id)
        return false

    var new_animal_data: AnimalData = animal_data_repository[target_animal_id]
    if not new_animal_data:
        printerr("PAC: Failed to load AnimalData for ID '%s'." % target_animal_id)
        return false
    
    if new_animal_data.controller_script_path.is_empty():
        printerr("PAC: AnimalData for '%s' does not specify a controller_script_path." % target_animal_id)
        return false

    print("PAC: Switching to: %s" % new_animal_data.display_name)

    var previous_animal_data = current_animal_data # Store for potential revert

    # 1. Cleanup old animal node and abilities
    if current_animal_node and is_instance_valid(current_animal_node): # Check validity before cleanup
        current_animal_node.cleanup() 
        current_animal_node = null
    _clear_equipped_abilities()

    current_animal_data = new_animal_data

    # 2. Instantiate and setup new AnimalBaseController
    var controller_script = load(new_animal_data.controller_script_path)
    if not controller_script:
        printerr("PAC: Failed to load controller script from path: %s" % new_animal_data.controller_script_path)
        current_animal_data = previous_animal_data # Revert to previous data to maintain valid state
        return false
        
    var new_node_instance = controller_script.new() # Instantiate first
    if not new_node_instance is AnimalBaseController: # Type check after instantiation
        printerr("PAC: Instantiated script from %s is not an AnimalBaseController." % new_animal_data.controller_script_path)
        if new_node_instance and new_node_instance.has_method("queue_free"): new_node_instance.queue_free() # Cleanup invalid instance
        current_animal_data = previous_animal_data # Revert
        return false
    current_animal_node = new_node_instance as AnimalBaseController


    # Parent the new animal node. Use animal_anchor_node if set, otherwise self.
    var parent_node = animal_anchor_node if animal_anchor_node else self
    # Ensure parent_node can parent Node3D. AnimalBaseController extends Node3D.
    if not parent_node is Node: # Should always be true if self or a Node3D anchor
        printerr("PAC: Parent node for animal instance is invalid.")
        current_animal_data = previous_animal_data; current_animal_node.queue_free(); current_animal_node = null; return false

    parent_node.add_child(current_animal_node)
    current_animal_node.setup_animal(current_animal_data) # Call setup_animal AFTER parenting
    print("PAC: Instantiated and setup '%s' under '%s'." % [current_animal_node.name, parent_node.name])


    # 3. Update player's survival stats
    if player_survival_stats:
        player_survival_stats.set_animal_data(current_animal_data)
    else:
        printerr("PAC: PlayerSurvivalStats not set.")

    # 4. Equip new abilities
    _equip_abilities() 
    
    emit_signal("animal_form_switched", current_animal_data)
    print("PAC: Switched to %s." % current_animal_data.display_name)
    return true


func unlock_form(animal_id: String):
    # ... (as before) ...
    if not animal_id in unlocked_animal_ids:
        if not animal_data_repository.has(animal_id) and not animal_id.is_empty():
             printerr("PAC: Attempted to unlock non-existent Animal ID '%s'." % animal_id)
             return
        unlocked_animal_ids.append(animal_id)
        print("PAC: Animal form '%s' unlocked." % animal_id)
        # Potentially emit a signal for UI update or other systems
        # emit_signal("animal_unlocked", animal_id)
    else:
        print("PAC: Animal form '%s' was already unlocked." % animal_id)


func _equip_abilities():
    _clear_equipped_abilities()
    if not current_animal_data: return

    var caster_context = current_animal_node if current_animal_node else self

    for ability_id in current_animal_data.ability_ids:
        if ability_repository.has(ability_id):
            var ability_resource: AbilityBase = ability_repository[ability_id]
            var new_ability_instance = ability_resource.duplicate(true) if ability_resource else null # Ensure deep copy for resources
            if new_ability_instance:
                new_ability_instance.set_caster(caster_context)
                equipped_abilities.append(new_ability_instance)
                # print("PAC: Equipped ability: %s (ID: %s) with caster %s" % [new_ability_instance.display_name, ability_id, caster_context.name])
            else: printerr("PAC: Failed to load/duplicate ability for ID '%s'." % ability_id)
        else: printerr("PAC: Ability ID '%s' not in ability_repository." % ability_id)

func _clear_equipped_abilities():
    var caster_context = current_animal_node if current_animal_node else self
    for ability in equipped_abilities:
        if ability and ability.is_active: # Check ability is not null
             ability.deactivate(caster_context)
    equipped_abilities.clear()

func try_activate_ability(slot_index: int):
    if slot_index < 0 or slot_index >= equipped_abilities.size(): return

    var ability: AbilityBase = equipped_abilities[slot_index]
    if ability:
        var caster_context = current_animal_node if current_animal_node else self
        if not current_animal_node and caster_context == self:
             print_rich("[color=yellow]PAC Warning: current_animal_node is null. Ability might not function as expected. Using PAC as fallback caster.[/color]")

        var stats_comp = caster_context.get_player_survival_stats() if caster_context.has_method("get_player_survival_stats") else player_survival_stats
        
        if stats_comp:
            if ability.can_use(stats_comp): ability.execute(caster_context)
            # else: print("PAC: Cannot use ability '%s'." % ability.display_name)
        # else: printerr("PAC: Could not get PlayerSurvivalStats for ability check from caster %s." % caster_context.name)
    # else: printerr("PAC: No ability in slot %s." % slot_index)

# --- Animal Switching Input Handling ---
func handle_animal_switching():
    if unlocked_animal_ids.size() <= 1:
        print("PAC: No other forms unlocked to switch to.")
        return

    var current_id = current_animal_data.animal_id if current_animal_data else "" # Handle null current_animal_data
    var current_index = unlocked_animal_ids.find(current_id)

    var next_index: int
    if current_index == -1 and unlocked_animal_ids.size() > 0: # If current form not in list or no current form
        next_index = 0
    else:
        next_index = (current_index + 1) % unlocked_animal_ids.size()
    
    if next_index < 0 || next_index >= unlocked_animal_ids.size(): # Safety check
        printerr("PAC: Calculated invalid next_idx for animal switching.")
        return

    var next_animal_id = unlocked_animal_ids[next_index]
    
    if next_animal_id != current_id: # Ensure it's actually a different form
        print("PAC: Attempting to switch from '%s' to '%s'" % [current_id, next_animal_id])
        switch_form(next_animal_id)
    # else: print("PAC: Already in target form or only one form available.")


# (get_current_abilities, get_current_sensory_profile_id, repository helpers, proxy methods as before)
# ...
# Proxy methods (get_current_move_speed, set_current_move_speed, set_stealth_modifier) are now more relevant as current_animal_node is primary.
func get_current_move_speed() -> float:
    if current_animal_node and is_instance_valid(current_animal_node): # Check validity
        return current_animal_node.get_current_move_speed()
    # Fallback or error if no current_animal_node, though it should always exist after switch_form
    if current_animal_data and current_animal_data.base_stats: 
        return current_animal_data.base_stats.base_move_speed 
    return 0.0

func set_current_move_speed(new_speed: float):
    if current_animal_node and is_instance_valid(current_animal_node): # Check validity
        current_animal_node.set_current_move_speed(new_speed)
    # else: printerr("PAC: No current_animal_node to set speed on.")

func set_stealth_modifier(modifier: float):
    if current_animal_node and is_instance_valid(current_animal_node): # Check validity
        current_animal_node.set_stealth_modifier(modifier)
    # else: printerr("PAC: No current_animal_node to set stealth_modifier on.")
        
func get_player_survival_stats() -> PlayerSurvivalStats:
    return player_survival_stats

# --- Repository Helpers (already present from previous step) ---
func add_animal_data_to_repository(data: AnimalData):
    if data and data.animal_id != "":
        animal_data_repository[data.animal_id] = data
    else:
        printerr("PAC: Could not add invalid animal data to repository.")

func add_ability_to_repository(ability_res: AbilityBase):
    if ability_res and not ability_res.ability_id.is_empty():
        ability_repository[ability_res.ability_id] = ability_res
    else:
        printerr("PAC: Could not add invalid ability resource to repository.")
        
# Getter for current abilities (already present)
func get_current_abilities() -> Array[AbilityBase]:
    return equipped_abilities

# Getter for current sensory profile ID (already present)
func get_current_sensory_profile_id() -> String:
    if current_animal_data:
        return current_animal_data.sensory_profile_id
    return ""
```
