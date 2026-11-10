extends ColorRect

var current_mode = 0

func _unhandled_input(event):
    if event is InputEventKey and event.pressed and event.keycode == KEY_C:
        current_mode = (current_mode + 1) % 4
        var mat = material as ShaderMaterial
        if mat:
            mat.set_shader_parameter("mode", current_mode)
            print("Cambiado a filtro de daltonismo modo: ", current_mode)