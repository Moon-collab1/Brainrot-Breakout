extends ColorRect

var current_mode = 0

func _unhandled_input(event):
    if event is InputEventKey and event.pressed and event.keycode == KEY_L:
        current_mode = (current_mode + 1) % 4
        var mat = material as ShaderMaterial
        if mat:
            mat.set_shader_parameter("mode", current_mode)
            print("Filtro de daltonismo cambiado al modo: ", current_mode)