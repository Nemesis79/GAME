extends Control

const WORLD_SCENE_PATH: String = "res://world.tscn"

@onready var status_label: Label = $CenterContainer/Content/StatusLabel
@onready var progress_bar: ProgressBar = $CenterContainer/Content/ProgressBar


func _ready() -> void:
	var request_error := ResourceLoader.load_threaded_request(WORLD_SCENE_PATH)
	if request_error != OK:
		status_label.text = "โหลดฉากไม่สำเร็จ"
		push_error("Could not start loading %s: %s" % [WORLD_SCENE_PATH, error_string(request_error)])
		set_process(false)


func _process(_delta: float) -> void:
	var progress: Array = []
	var load_status := ResourceLoader.load_threaded_get_status(WORLD_SCENE_PATH, progress)

	if not progress.is_empty():
		progress_bar.value = progress[0] * 100.0

	match load_status:
		ResourceLoader.THREAD_LOAD_LOADED:
			var packed_scene := ResourceLoader.load_threaded_get(WORLD_SCENE_PATH) as PackedScene
			if packed_scene == null:
				status_label.text = "โหลดฉากไม่สำเร็จ"
				push_error("Loaded world resource is not a PackedScene.")
				set_process(false)
				return
			get_tree().change_scene_to_packed(packed_scene)
			set_process(false)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			status_label.text = "โหลดฉากไม่สำเร็จ"
			push_error("Could not load %s." % WORLD_SCENE_PATH)
			set_process(false)
