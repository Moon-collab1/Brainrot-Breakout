extends Node

var color_rect: ColorRect
var audio_player: AudioStreamPlayer

func _ready() -> void:
    # Creamos una capa persistente en tiempo de ejecución para no modificar cada escena a mano
    var canvas = CanvasLayer.new()
    canvas.layer = 100
    get_tree().root.add_child(canvas)
    
    color_rect = ColorRect.new()
    color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    color_rect.color = Color(0, 0, 0, 0)
    color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(color_rect)
    
    audio_player = AudioStreamPlayer.new()
    canvas.add_child(audio_player)
    
    # Intenta cargar un sonido si lo tienes guardado, si no, omitirá el audio sin crashear
    if ResourceLoader.exists("res://comun/sistema/cambio_zona.wav"):
        audio_player.stream = load("res://comun/sistema/cambio_zona.wav")

func cambiar_escena(ruta_siguiente: String) -> void:
    color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
    
    if audio_player.stream:
        audio_player.play()
    
    # Animación de fundido a negro (Fade Out)
    var tween = create_tween()
    tween.tween_property(color_rect, "color:a", 1.0, 0.5)
    await tween.finished
    
    # Cambiar de escena
    get_tree().change_scene_to_file(ruta_siguiente)
    
    # Animación para aparecer de nuevo (Fade In)
    var tween_in = create_tween()
    tween_in.tween_property(color_rect, "color:a", 0.0, 0.5)
    await tween_in.finished
    
    color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE