# npc/npc_animal_ai_controller.gd
class_name NPCAnimalAIController
extends Node3D # Changed from Node to Node3D

# --- Configuration ---
@export var animal_data_path: String = "" # Path to AnimalData .tres file for this NPC type
var animal_data: AnimalData = null

# Perception Parameters (as per section 3.1.1)
@export_group("Perception")
@export var vision_cone_angle: float = 90.0 # Degrees
@export var vision_range: float = 20.0    # Meters
@export var hearing_range: float = 30.0   # Meters
@export var threat_tags: Array[String] = ["Player", "Predator_Wolf"] # Tags that trigger Flee state
@export var food_tags: Array[String] = ["Food_Plant", "WaterSource"] # Tags for Foraging

# --- State Machine ---
var states: Dictionary = {} # Stores state instances, e.g., {"idle": IdleState.new()}
var current_state: NPCStateBase = null
@export var initial_state_key: String = "idle" # Key for the first state to enter

# --- NPC Components (Simplified) ---
# In a real game, might have separate nodes for health, model, etc.
var current_health: float = 100.0 
# Add other relevant stats if NPC needs them (e.g. hunger for foraging motivation)

# Pathfinding/Movement related (very simplified)
var navigation_agent: NavigationAgent3D # For Godot's navigation system
var current_target_position: Vector3

func _init():
    # Ensure NavigationAgent3D is available
    navigation_agent = NavigationAgent3D.new()
    add_child(navigation_agent)
    navigation_agent.set_navigation_map(get_world_3d().navigation_map) # Use default map

func _ready():
    # Load AnimalData
    if not animal_data_path.is_empty():
        animal_data = load(animal_data_path)
        if animal_data:
            current_health = animal_data.base_stats.max_health
            # Apply other relevant stats from animal_data if needed
            print("%s: Loaded AnimalData: %s" % [name, animal_data.display_name])
        else:
            printerr("%s: Failed to load AnimalData from %s" % [name, animal_data_path])
    else:
        printerr("%s: animal_data_path not set." % name)

    # Initialize states (children nodes or instantiated scenes)
    # For simplicity, let's assume states are added as child nodes in the editor
    # or we can instantiate them here if they are script classes.
    _initialize_states_from_children() # Look for state nodes as children
    
    if states.is_empty():
         _initialize_states_programmatically() # Fallback to create from scripts

    if states.has(initial_state_key):
        change_state(initial_state_key)
    elif not states.is_empty():
        # Fallback to the first available state if initial_state_key is invalid
        change_state(states.keys()[0])
        printerr("%s: Initial state '%s' not found. Defaulting to '%s'." % [name, initial_state_key, current_state.state_key if current_state else "None"])
    else:
        printerr("%s: No states found or initialized for NPC AI!" % name)

func _initialize_states_from_children():
    for child in get_children():
        if child is NPCStateBase:
            var state_key = child.name.to_lower() # Use node name as key
            if child.has_method("set_state_key"): # If NPCStateBase has this method
                child.set_state_key(state_key)
            child.npc_controller = self # Give state a reference back to this AI controller
            states[state_key] = child
            print("%s: Found and initialized state from child: %s" % [name, state_key])

func _initialize_states_programmatically():
    # This is a fallback if states are not child nodes.
    # Requires states to have unique class_names if loaded by script path.
    # Or, if they are just scripts, instantiate them.
    # Example: states["idle"] = IdleState.new() etc. This assumes scripts are loaded.
    # For this subtask, we'll rely on the structure from initial file creation.
    var state_scripts = {
        "idle": IdleState, "wander": WanderState, "flee": FleeState,
        "forage": ForageState, "eating": EatingState
    }
    for key in state_scripts:
        var state_instance = state_scripts[key].new()
        state_instance.name = key.capitalize() + "State" # Give it a name
        if state_instance.has_method("set_state_key"):
            state_instance.set_state_key(key)
        state_instance.npc_controller = self
        states[key] = state_instance
        # add_child(state_instance) # Optionally add as child if not already
        print("%s: Programmatically initialized state: %s" % [name, key])


func _physics_process(delta):
    if current_state:
        current_state.execute(delta) # Call current state's execute logic

    # Simplified movement towards target_position using NavigationAgent3D
    if navigation_agent.is_target_reached():
        return

    var current_location = global_transform.origin
    var next_path_position = navigation_agent.get_next_path_position()
    var new_velocity = (next_path_position - current_location).normalized() * get_effective_move_speed()
    
    # This part needs a CharacterBody3D typically.
    # For Node3D, we just update position. This won't handle collisions.
    # If this node was a CharacterBody3D:
    # velocity = new_velocity
    # move_and_slide()
    global_translate(new_velocity * delta) # Simple move for Node3D
    if new_velocity.length_squared() > 0: # Basic look_at
        look_at(next_path_position, Vector3.UP)


func change_state(new_state_key: String):
    if not states.has(new_state_key):
        printerr("%s: Cannot change to unknown state '%s'." % [name, new_state_key])
        return

    if current_state:
        print("%s: Exiting state: %s" % [name, current_state.name])
        current_state.exit()

    current_state = states[new_state_key]
    print("%s: Entering state: %s" % [name, current_state.name])
    current_state.enter()

# --- Perception Methods (Simplified Placeholders) ---
func can_see_target(target_node: Node3D) -> bool:
    if not target_node: return false
    var direction_to_target = (target_node.global_transform.origin - global_transform.origin)
    if direction_to_target.length() > vision_range:
        return false # Out of range
    if direction_to_target.normalized().dot(global_transform.basis.z.normalized()) < cos(deg_to_rad(vision_cone_angle / 2.0)):
        return false # Outside vision cone
    
    # Add raycast check for obstacles
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(global_transform.origin, target_node.global_transform.origin)
    # query.exclude = [self] # Exclude self if collider is present
    var result = space_state.intersect_ray(query)
    if result and result.collider == target_node:
        return true # Can see if ray hits target
        
    return false # Blocked or no direct line of sight

func can_hear_target(target_node: Node3D, sound_intensity: float = 1.0) -> bool: # sound_intensity is a multiplier
    if not target_node: return false
    var distance_to_target = (target_node.global_transform.origin - global_transform.origin).length()
    if distance_to_target < (hearing_range * sound_intensity):
        return true
    return false

func find_closest_target_with_tag(tag: String, search_radius: float) -> Node3D:
    # Placeholder: would search for nodes with the given tag within the radius
    # Example: iterate through nodes in a group "FoodSources" or "Threats"
    # For now, returns null.
    return null

func take_damage(amount: float):
    current_health -= amount
    print("%s took %s damage, health is now %s" % [name, amount, current_health])
    if current_health <= 0:
        _die()

func _die():
    print("%s has died." % name)
    # Placeholder: could drop items, play death animation, then queue_free()
    # For now, just stop processing and maybe hide.
    set_physics_process(false)
    hide() 
    # To allow respawn or proper removal, a manager might handle this.
    # Or after a delay: queue_free()

func get_effective_move_speed() -> float:
    if animal_data:
        return animal_data.base_stats.base_move_speed
    return 3.0 # Default speed
```
