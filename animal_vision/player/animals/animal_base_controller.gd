# player/animals/animal_base_controller.gd
class_name AnimalBaseController
extends Node3D # Changed from Node to Node3D to manage a 3D model

var animal_data: AnimalData = null
var model_node: Node3D = null # The instantiated 3D model of the animal
var animation_player: AnimationPlayer = null # Reference to an AnimationPlayer

# Movement properties - these might be controlled by PlayerAnimalController or a dedicated movement component
var current_move_speed: float = 0.0 

# Stealth properties
var stealth_modifier: float = 1.0 # 1.0 = normal visibility

func _init():
    pass

# Called by PlayerAnimalController when this animal form is activated
func setup_animal(p_animal_data: AnimalData):
    animal_data = p_animal_data
    if not animal_data:
        printerr("%s: AnimalData is null during setup." % self.name)
        return

    current_move_speed = animal_data.base_stats.base_move_speed
    print("%s: Setting up with AnimalData: %s" % [self.name, animal_data.display_name])
    
    # Load model
    _load_model()
    # Setup animator
    _setup_animator()
    # Setup sensory profile (delegated or handled by SensoryManager based on AnimalData)
    _setup_sensory_profile()
    # Setup abilities (delegated or handled by AbilityManager based on AnimalData)
    _setup_abilities()


func _load_model():
    if not animal_data or animal_data.model_resource_path.is_empty():
        # print("%s: No model resource path specified in AnimalData." % self.name)
        return

    if model_node: # Clear previous model if any
        model_node.queue_free()
        model_node = null

    var model_scene = load(animal_data.model_resource_path)
    if model_scene:
        model_node = model_scene.instantiate()
        add_child(model_node) # Add the model as a child of this controller node
        print("%s: Model loaded from %s" % [self.name, animal_data.model_resource_path])
    else:
        printerr("%s: Failed to load model from %s" % [self.name, animal_data.model_resource_path])

func _setup_animator():
    if not model_node:
        # print("%s: Model node not available to setup animator." % self.name)
        return
    
    # Try to find an AnimationPlayer node within the instantiated model
    # This assumes a certain structure for the animal model scene.
    animation_player = model_node.find_child("AnimationPlayer", true, false) # Recursive search, don't include internal children
    
    if animation_player:
        print("%s: AnimationPlayer found in model." % self.name)
        # If an animator_controller_path is specified in AnimalData (e.g. for an AnimationTree)
        # you might load and assign it here. For now, just finding AnimationPlayer.
        if not animal_data.animator_controller_path.is_empty():
            print("  Animator controller path specified (needs specific handling): %s" % animal_data.animator_controller_path)
    else:
        print("%s: AnimationPlayer node not found in the model." % self.name)


# These methods are for specific animal types to override
func _setup_sensory_profile():
    # Base implementation can be empty or log.
    # SensoryManager will use animal_data.sensory_profile_id
    if animal_data:
        print("%s: Sensory profile ID for SensoryManager: %s" % [self.name, animal_data.sensory_profile_id])
    pass

func _setup_abilities():
    # Base implementation can be empty or log.
    # AbilityManager will use animal_data.ability_ids
    if animal_data:
        print("%s: Ability IDs for AbilityManager: %s" % [self.name, str(animal_data.ability_ids)])
    pass

# --- Example methods needed by abilities ---
# These are placeholders and would need to be connected to actual movement/character controller logic.
func get_current_move_speed() -> float:
    return current_move_speed

func set_current_move_speed(new_speed: float):
    current_move_speed = new_speed
    # print("%s: Move speed set to %s" % [self.name, new_speed])
    # If this node is a CharacterBody3D, you'd update its velocity or speed property.
    # Example: if self is CharacterBody3D: self.velocity.x = ... (depending on movement direction)

func set_stealth_modifier(modifier: float):
    stealth_modifier = modifier
    print("%s: Stealth modifier set to %s" % [self.name, modifier])
    # This value would then be used by NPC perception systems.

func get_player_survival_stats() -> PlayerSurvivalStats:
    # Abilities might need access to this. PlayerAnimalController should probably pass this.
    # This is a bit of a workaround. Ideally, abilities get stats from their direct caster.
    # A common pattern is for PlayerAnimalController to be the parent of AnimalBaseController.
    if get_parent() and get_parent().has_node("PlayerSurvivalStats"):
         return get_parent().get_node("PlayerSurvivalStats") # Assumes PlayerSurvivalStats is a sibling of this node, under PlayerAnimalController
    if get_parent() and get_parent().get_parent() and get_parent().get_parent().has_node("PlayerSurvivalStats"): # If this is child of Player, and Player is child of GameNodeWithStats
         return get_parent().get_parent().get_node("PlayerSurvivalStats")
    
    # Fallback: check if PlayerAnimalController itself has player_survival_stats property (as per current design)
    if get_parent() and get_parent().has_meta("player_animal_controller_ref"): # If parent has a ref to PlayerAnimalController
        var pac = get_parent().get_meta("player_animal_controller_ref")
        if pac and pac.has_property("player_survival_stats") and pac.player_survival_stats is PlayerSurvivalStats:
            return pac.player_survival_stats

    # If PlayerAnimalController is a globally accessible singleton (e.g. Autoload)
    if Engine.has_singleton("PlayerAnimalController"):
        var global_pac = Engine.get_singleton("PlayerAnimalController")
        if global_pac and global_pac.has_property("player_survival_stats") and global_pac.player_survival_stats is PlayerSurvivalStats:
            return global_pac.player_survival_stats
            
    printerr("%s: Could not find PlayerSurvivalStats." % self.name)
    return null

# To be called when this animal form is deactivated by PlayerAnimalController
func cleanup():
    print("%s: Cleaning up." % self.name)
    if model_node:
        model_node.queue_free()
        model_node = null
    # Any other cleanup specific to this animal controller
    queue_free() # Remove self from scene if this controller is dynamically added/removed
