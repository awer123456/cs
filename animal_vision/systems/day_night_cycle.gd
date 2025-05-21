# systems/day_night_cycle.gd
class_name DayNightCycle
extends Node

# --- Configuration ---
@export var sun_light: DirectionalLight3D # Assign the main DirectionalLight3D node here
@export var cycle_duration_seconds: float = 240.0 # How long a full 24-hour cycle takes in real seconds (e.g., 240s = 4 minutes)
@export var start_time_hours: float = 6.0 # Game time in hours (0-24) when the game starts

# Sun/Moon properties
@export var sun_intensity_max: float = 1.5
@export var moon_intensity_max: float = 0.3
@export var sun_color_day: Color = Color(1.0, 1.0, 0.85) # Whitish yellow
@export var sun_color_sunset: Color = Color(1.0, 0.6, 0.4) # Orangey
@export var moon_color: Color = Color(0.5, 0.6, 0.8)  # Bluish white

@export var environment: WorldEnvironment # Optional: for changing skybox or ambient light

# --- State ---
var current_time_hours: float = 0.0 # Current game time in hours (0-24)
var time_of_day_normalized: float = 0.0 # Current time normalized (0 for midnight, 0.25 for sunrise, 0.5 for noon, 0.75 for sunset)

# --- Signals (already defined in the initial script) ---
signal sunrise
signal sunset
signal midnight

# --- Time Thresholds (Normalized 0-1) ---
# These can be adjusted to control when signals are emitted and colors change
const SUNRISE_THRESHOLD_START: float = 0.23 # e.g., 5:30 AM
const SUNRISE_THRESHOLD_END: float = 0.27   # e.g., 6:30 AM
const DAY_THRESHOLD_START: float = SUNRISE_THRESHOLD_END
const DAY_THRESHOLD_END: float = 0.73     # e.g., 5:30 PM
const SUNSET_THRESHOLD_START: float = DAY_THRESHOLD_END
const SUNSET_THRESHOLD_END: float = 0.77  # e.g., 6:30 PM
const NIGHT_THRESHOLD_START: float = SUNSET_THRESHOLD_END 
# Midnight is at 0 or 1

var sunrise_emitted_today: bool = false
var sunset_emitted_today: bool = false
var midnight_emitted_today: bool = false


func _ready():
    if not sun_light:
        # Try to find a DirectionalLight3D in the scene if not assigned
        for child_idx in get_tree().root.get_child_count(): # Search top-level nodes
            var child = get_tree().root.get_child(child_idx)
            if child is DirectionalLight3D:
                sun_light = child
                print("DayNightCycle: Found DirectionalLight3D: %s" % sun_light.name)
                break
        if not sun_light: # Still not found
            printerr("DayNightCycle: Sun Light (DirectionalLight3D) not assigned and not found!")
            set_process(false) # Disable processing if no light
            return
            
    current_time_hours = start_time_hours
    _update_cycle(0) # Initial update


func _process(delta: float):
    _update_cycle(delta)

func _update_cycle(delta: float):
    if not sun_light:
        return

    # Increment game time
    var time_increment_hours = (24.0 / cycle_duration_seconds) * delta
    current_time_hours += time_increment_hours
    
    # Reset day flags if current_time_hours wraps around
    if current_time_hours >= 24.0:
        current_time_hours = fmod(current_time_hours, 24.0)
        sunrise_emitted_today = false
        sunset_emitted_today = false
        midnight_emitted_today = false

    # Calculate normalized time of day (0.0 to 1.0)
    time_of_day_normalized = current_time_hours / 24.0

    # --- Update Light Rotation (Sun/Moon position) ---
    # Rotate light around X-axis for sunrise/sunset effect, and optionally Y for east-west travel
    # Simple rotation: -90 (sunrise) to 0 (noon) to +90 (sunset) on X-axis
    # Sun path is more complex, but this is a basic approximation.
    var x_rotation_degrees = lerp(-90.0, 270.0, time_of_day_normalized) # -90 up, 90 down, 270 up again
    sun_light.rotation_degrees.x = x_rotation_degrees
    # Optional: Y-axis rotation for east-west movement
    # sun_light.rotation_degrees.y = lerp(0.0, 360.0, time_of_day_normalized) 


    # --- Update Light Color and Intensity ---
    var current_intensity: float
    var current_color: Color

    if time_of_day_normalized >= SUNRISE_THRESHOLD_START and time_of_day_normalized < DAY_THRESHOLD_END: # Daytime (including sunrise/sunset transitions)
        if time_of_day_normalized < DAY_THRESHOLD_START: # Sunrise transition
            var sunrise_progress = range_lerp(time_of_day_normalized, SUNRISE_THRESHOLD_START, DAY_THRESHOLD_START, 0.0, 1.0)
            current_intensity = lerp(moon_intensity_max, sun_intensity_max, sunrise_progress)
            current_color = moon_color.lerp(sun_color_day, sunrise_progress)
        elif time_of_day_normalized >= SUNSET_THRESHOLD_START: # Sunset transition
            var sunset_progress = range_lerp(time_of_day_normalized, SUNSET_THRESHOLD_START, SUNSET_THRESHOLD_END, 0.0, 1.0)
            current_intensity = lerp(sun_intensity_max, moon_intensity_max, sunset_progress)
            current_color = sun_color_day.lerp(sun_color_sunset, sunset_progress).lerp(moon_color, sunset_progress) # Day -> Sunset -> Moon
        else: # Full Day
            current_intensity = sun_intensity_max
            current_color = sun_color_day
    else: # Night time
        current_intensity = moon_intensity_max
        current_color = moon_color
        # Could add more complex logic for moon phases or very dark nights

    sun_light.light_energy = current_intensity
    sun_light.light_color = current_color
    
    # --- Update Environment (Optional) ---
    if environment and is_instance_valid(environment) and environment.environment: # Check environment and its sub-property
        # Example: could change skybox shader parameters or ambient light
        environment.environment.ambient_light_energy = current_intensity * 0.2 # Tie ambient to sun/moon
        # if environment.environment.sky and environment.environment.sky.sky_material:
        #    environment.environment.sky.sky_material.set_shader_parameter("time_of_day", time_of_day_normalized)
        pass

    # --- Emit Signals ---
    # Sunrise
    if time_of_day_normalized >= SUNRISE_THRESHOLD_START and time_of_day_normalized < SUNRISE_THRESHOLD_END:
        if not sunrise_emitted_today:
            emit_signal("sunrise")
            sunrise_emitted_today = true
            # print("DayNightCycle: Sunrise event emitted at %.2f hours." % current_time_hours)
    # Sunset
    elif time_of_day_normalized >= SUNSET_THRESHOLD_START and time_of_day_normalized < SUNSET_THRESHOLD_END:
        if not sunset_emitted_today:
            emit_signal("sunset")
            sunset_emitted_today = true
            # print("DayNightCycle: Sunset event emitted at %.2f hours." % current_time_hours)
    # Midnight (approximately, when normalized time wraps or is near 0/1 during night)
    elif (time_of_day_normalized < SUNRISE_THRESHOLD_START or time_of_day_normalized >= NIGHT_THRESHOLD_START): # It's night
        if (current_time_hours >= 23.9 || current_time_hours < 0.1): # Close to midnight
            if not midnight_emitted_today:
                # Check if it's closer to 0/24 than to previous signal emission to avoid double trigger
                # Simplified check for midnight:
                if (abs(time_of_day_normalized - 0.0) < 0.01 || abs(time_of_day_normalized - 1.0) < 0.01):
                    emit_signal("midnight")
                    midnight_emitted_today = true
                    # print("DayNightCycle: Midnight event emitted at %.2f hours." % current_time_hours)
```
