# systems/sensory_profile.gd
class_name SensoryProfile
extends Resource

# Properties from section 2.3.1
@export var profile_id: String = "" # Unique ID for this profile

# Visual Parameters
@export_group("Visual Parameters")
@export var field_of_view: float = 75.0 # Default FOV
@export var color_saturation: float = 1.0 # 0 (grayscale) to 1 (normal)
@export var night_vision_threshold: float = 0.1 # Ambient light level to activate night vision
@export var post_process_shader_path: String = "" # Path to a post-processing shader .gdshader or .tres (ShaderMaterial)
# Example of a more specific visual parameter from AI prompt (2.3.1)
@export var visual_night_vision_intensity: float = 1.0 

# Audio Parameters
@export_group("Audio Parameters")
@export var hearing_range_multiplier: float = 1.0
@export var focus_sounds: Array[String] = [] # Tags or names of sounds to amplify or highlight

# Olfactory Parameters (Smell)
@export_group("Olfactory Parameters")
@export var detection_radius: float = 0.0 # 0 means no smell sense
@export var tracked_tags: Array[String] = [] # Tags like "Food_Plant", "Predator_Wolf"
@export var trail_display_duration: float = 5.0 # How long smell trails are visible

func _init(p_id: String = "", p_fov: float = 75.0, p_color_saturation: float = 1.0, 
            p_night_vision_threshold: float = 0.1, p_post_process_shader_path: String = "",
            p_visual_night_vision_intensity: float = 1.0, p_hearing_range_multiplier: float = 1.0,
            p_focus_sounds: Array[String] = [], p_detection_radius: float = 0.0,
            p_tracked_tags: Array[String] = [], p_trail_display_duration: float = 5.0): # Original more complete _init params
    profile_id = p_id
    field_of_view = p_fov
    # Initialize other defaults if necessary - as per subtask, only p_id and p_fov are in signature
    # However, the export vars already define defaults. This _init will override those if values are passed.
    # To strictly match the subtask's _init signature:
    # func _init(p_id: String = "", p_fov: float = 75.0):
    #    profile_id = p_id
    #    field_of_view = p_fov
    # The rest of the properties will take their default values as defined by @export.
    # For clarity and to keep the more complete initialization available if needed (commented out):
    # color_saturation = p_color_saturation
    # night_vision_threshold = p_night_vision_threshold
    # post_process_shader_path = p_post_process_shader_path
    # visual_night_vision_intensity = p_visual_night_vision_intensity
    # hearing_range_multiplier = p_hearing_range_multiplier
    # focus_sounds = p_focus_sounds
    # detection_radius = p_detection_radius
    # tracked_tags = p_tracked_tags
    # trail_display_duration = p_trail_display_duration

# Corrected _init based on the subtask's GDScript snippet for SensoryProfile
func _init(p_id: String = "", p_fov: float = 75.0):
    profile_id = p_id
    field_of_view = p_fov
    # Other properties will use their @export default values unless set otherwise after instantiation.
