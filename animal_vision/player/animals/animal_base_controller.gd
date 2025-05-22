# player/animals/animal_base_controller.gd
class_name AnimalBaseController
extends CharacterBody3D # MODIFIED: Was Node3D

var animal_data: AnimalData = null
var model_node: Node3D = null
var animation_player: AnimationPlayer = null

# Movement properties
var current_move_speed: float = 0.0 
var target_velocity: Vector3 = Vector3.ZERO # Target velocity, usually set by input or AI

# Stealth properties
var stealth_modifier: float = 1.0

# Gravity (standard Godot practice for CharacterBody3D)
const GRAVITY = 9.8 
var current_vertical_speed: float = 0.0


func _init():
    pass

func _physics_process(delta):
    # Apply gravity
    if not is_on_floor():
        current_vertical_speed -= GRAVITY * delta
    else:
        current_vertical_speed = -0.1 # Small downward force to keep grounded, or 0

    # Combine horizontal movement (from target_velocity) with vertical movement (gravity)
    # target_velocity would be set by player input or AI logic.
    # For this base class, we'll just apply it.
    velocity.x = target_velocity.x
    velocity.z = target_velocity.z
    velocity.y = current_vertical_speed
    
    move_and_slide()
    
    # Update current_vertical_speed based on actual movement (e.g., if move_and_slide hit a ceiling)
    # This is important if you want jump to behave correctly after hitting something.
    current_vertical_speed = velocity.y


func setup_animal(p_animal_data: AnimalData):
    animal_data = p_animal_data
    if not animal_data:
        printerr("%s: AnimalData is null during setup." % self.name)
        return

    current_move_speed = animal_data.base_stats.base_move_speed
    # Reset velocity and vertical speed when setting up a new animal
    target_velocity = Vector3.ZERO
    current_vertical_speed = 0.0
    velocity = Vector3.ZERO # Reset internal velocity of CharacterBody3D

    print("%s: Setting up with AnimalData: %s. Initial speed: %s" % [self.name, animal_data.display_name, current_move_speed])
    
    _load_model()
    _setup_animator()
    _setup_sensory_profile()
    _setup_abilities()


func _load_model():
    if not animal_data or animal_data.model_resource_path.is_empty():
        # print("%s: No model resource path specified for model loading." % self.name)
        if model_node: # Clear previous model if any
            model_node.queue_free()
            model_node = null
        # Create a placeholder if no path, as per future task for primitive meshes:
        # model_node = MeshInstance3D.new()
        # model_node.mesh = CapsuleMesh.new() # Default placeholder
        # add_child(model_node)
        # print("%s: No model resource path. Placeholder could be created here." % self.name)
        return 

    if model_node: # If changing forms, old model needs to be removed
        model_node.queue_free()
        model_node = null

    var model_scene_resource = load(animal_data.model_resource_path)
    if model_scene_resource:
        model_node = model_scene_resource.instantiate()
        add_child(model_node)
        print("%s: Model loaded from %s" % [self.name, animal_data.model_resource_path])
    else:
        printerr("%s: Failed to load model from %s" % [self.name, animal_data.model_resource_path])


func _setup_animator():
    if not model_node:
        # print("%s: Model node not available to setup animator." % self.name)
        return
    
    animation_player = model_node.find_child("AnimationPlayer", true, false)
    
    if animation_player:
        print("%s: AnimationPlayer found in model." % self.name)
        if not animal_data.animator_controller_path.is_empty():
            print("  Animator controller path specified (needs specific handling): %s" % animal_data.animator_controller_path)
    # else:
        # print("%s: AnimationPlayer node not found in the model." % self.name)


func _setup_sensory_profile():
    if animal_data:
        # print("%s: Sensory profile ID for SensoryManager: %s" % [self.name, animal_data.sensory_profile_id])
        pass

func _setup_abilities():
    if animal_data:
        # print("%s: Ability IDs for AbilityManager: %s" % [self.name, str(animal_data.ability_ids)])
        pass

# --- Movement and Ability Interaction Methods ---
func get_current_move_speed() -> float:
    return current_move_speed

# This method now primarily updates the base speed. Actual velocity direction comes from elsewhere.
func set_current_move_speed(new_speed: float):
    current_move_speed = new_speed
    # print("%s: Base move speed set to %s" % [self.name, new_speed])
    # Example of how target_velocity would be updated if direction is known:
    # target_velocity = target_velocity.normalized() * current_move_speed if target_velocity.length_squared() > 0 else Vector3.ZERO

# Call this from PlayerInput or AI to set the desired movement direction and speed factor
func set_movement_input(direction: Vector3, speed_factor: float = 1.0):
    target_velocity = direction.normalized() * (current_move_speed * speed_factor)
    # Look where you're going (simple version, might need smoothing or y-axis lock)
    if direction.length_squared() > 0.01: # Check for non-zero direction
        # Ensure the animal node itself is what looks, not the model_node directly if model has offset
        var look_target_position = global_position + direction 
        look_at(look_target_position, Vector3.UP)


func set_stealth_modifier(modifier: float):
    stealth_modifier = modifier
    # print("%s: Stealth modifier set to %s" % [self.name, modifier])

func get_player_survival_stats() -> PlayerSurvivalStats:
    # This method assumes a specific scene structure where PlayerAnimalController is the parent,
    # and PlayerAnimalController might have PlayerSurvivalStats as a child or on a specific node.
    # The prompt mentions 'PlayerRig' and 'PlayerSurvivalStatsNode'. This needs careful wiring.
    
    # Attempt to get from parent (PlayerAnimalController) if it has a direct reference or a known child node
    var parent_controller = get_parent()
    if parent_controller:
        # Case 1: Parent (PlayerAnimalController) has player_survival_stats property (as per current PAC design)
        if parent_controller.has_meta("player_survival_stats_ref_on_pac"): # Hypothetical meta field if PAC stores it
            var pss_on_pac = parent_controller.get("player_survival_stats") # Directly get if it's a property
            if pss_on_pac is PlayerSurvivalStats: return pss_on_pac

        # Case 2: PlayerSurvivalStats is on a child node of parent_controller (e.g. "PlayerSurvivalStatsNode")
        var stats_node = parent_controller.get_node_or_null("PlayerSurvivalStatsNode") # As per prompt's hint
        if stats_node is PlayerSurvivalStats:
            return stats_node
            
        # Case 3: PlayerAnimalController itself has the player_survival_stats property (current setup)
        if parent_controller.has_property("player_survival_stats") and parent_controller.player_survival_stats is PlayerSurvivalStats:
            return parent_controller.player_survival_stats


    # Fallback: check if PlayerAnimalController is a globally accessible singleton (e.g. Autoload)
    # This is less ideal for direct coupling but can be a last resort.
    if Engine.has_singleton("PlayerAnimalController"): # Assuming PAC is an autoload singleton named "PlayerAnimalController"
        var global_pac = Engine.get_singleton("PlayerAnimalController")
        if global_pac and global_pac.has_property("player_survival_stats") and global_pac.player_survival_stats is PlayerSurvivalStats:
            return global_pac.player_survival_stats
            
    printerr("%s: Could not find PlayerSurvivalStats through parent or global singleton." % self.name)
    return null


func cleanup():
    print("%s: Cleaning up CharacterBody3D." % self.name)
    if model_node and is_instance_valid(model_node): # Check if model_node is valid before queue_free
        model_node.queue_free()
        model_node = null
    queue_free()
```
