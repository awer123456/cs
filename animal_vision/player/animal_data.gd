# player/animal_data.gd
class_name AnimalData
extends Resource

# Nested class for base stats
class AnimalStats extends Resource:
    @export var max_health: float = 100.0
    @export var base_move_speed: float = 5.0
    @export var jump_height: float = 4.5 # Relevant if the animal can jump
    @export var stamina_max: float = 100.0
    @export var hunger_max: float = 100.0
    @export var thirst_max: float = 100.0 # Optional, as per doc

    func _init(p_max_health: float = 100.0, p_base_move_speed: float = 5.0, 
                p_jump_height: float = 4.5, p_stamina_max: float = 100.0, 
                p_hunger_max: float = 100.0, p_thirst_max: float = 100.0):
        max_health = p_max_health
        base_move_speed = p_base_move_speed
        jump_height = p_jump_height
        stamina_max = p_stamina_max
        hunger_max = p_hunger_max
        thirst_max = p_thirst_max

# AnimalData properties
@export var animal_id: String = ""  # Unique identifier, e.g., "Rabbit_01"
@export var display_name: String = "" # Name shown in game, e.g., "Rabbit"
@export_multiline var description: String = "" # Brief description

@export var base_stats: AnimalStats = AnimalStats.new()

@export var model_resource_path: String = "" # Path to 3D model
@export var animator_controller_path: String = "" # Path to AnimationTree or AnimationPlayer setup
@export var icon_path: String = "" # Path to texture for UI icon
@export var controller_script_path: String = "" # e.g., "res://player/animals/rabbit_controller.gd"

@export var first_person_camera_offset: Vector3 = Vector3.ZERO # Camera offset from head

@export var sensory_profile_id: String = "" # ID to link to SensoryProfile
@export var ability_ids: Array[String] = [] # IDs for abilities

@export var diet_type: Globals.DietType = Globals.DietType.HERBIVORE # Using the enum from Globals

@export var unlock_prerequisite: String = "" # animalID of prey needed to unlock this form (can be empty)
@export var hunger_rate_multiplier: float = 1.0


func _init(p_animal_id: String = "", p_display_name: String = "", p_description: String = "", 
            p_base_stats: AnimalStats = null, p_model_resource_path: String = "", 
            p_animator_controller_path: String = "", p_icon_path: String = "", p_controller_script_path: String = "",
            p_first_person_camera_offset: Vector3 = Vector3.ZERO,
            p_sensory_profile_id: String = "", p_ability_ids: Array[String] = [],
            p_diet_type: Globals.DietType = Globals.DietType.HERBIVORE, 
            p_unlock_prerequisite: String = "", p_hunger_rate_multiplier: float = 1.0):
    animal_id = p_animal_id
    display_name = p_display_name
    description = p_description
    base_stats = p_base_stats if p_base_stats != null else AnimalStats.new()
    model_resource_path = p_model_resource_path
    animator_controller_path = p_animator_controller_path
    icon_path = p_icon_path
    controller_script_path = p_controller_script_path
    first_person_camera_offset = p_first_person_camera_offset
    sensory_profile_id = p_sensory_profile_id
    ability_ids = p_ability_ids
    diet_type = p_diet_type
    unlock_prerequisite = p_unlock_prerequisite
    hunger_rate_multiplier = p_hunger_rate_multiplier

static func create(params: Dictionary):
    var data = AnimalData.new()
    # Ensure base_stats is handled correctly if it's a sub-dictionary
    var temp_base_stats_dict = null
    if params.has("base_stats") and params.base_stats is Dictionary:
        temp_base_stats_dict = params.base_stats
        params.erase("base_stats") # Remove to avoid type mismatch if set directly

    for key in params:
        if data.has_method("set_" + key): 
            data.call("set_" + key, params[key])
        elif data.has(key): 
            data.set(key, params[key])
    
    if temp_base_stats_dict != null : 
        var stats_obj = AnimalStats.new()
        for stat_key in temp_base_stats_dict:
            if stats_obj.has_method("set_" + stat_key):
                stats_obj.call("set_" + stat_key, temp_base_stats_dict[stat_key])
            elif stats_obj.has(stat_key):
                stats_obj.set(stat_key, temp_base_stats_dict[stat_key])
        data.base_stats = stats_obj
    elif not data.base_stats: 
        data.base_stats = AnimalStats.new()
        
    return data
```
