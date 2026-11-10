extends Node

var color_rect: ColorRect
var audio_player: AudioStreamPlayer

func _ready() -> void:
    call_deferred("_inicializar_transicion")

func _inicializar_transicion() -> void:
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
    
    var ruta_audio = "res://comun/sistema/cambio_zona.wav"
    if ResourceLoader.exists(ruta_audio):
        audio_player.stream = load(ruta_audio)

func cambiar_escena(ruta_siguiente: String) -> void:
    if not color_rect:
        get_tree().change_scene_to_file(ruta_siguiente)
        return
        
    color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
    
    # 1. Silenciar la música de fondo al iniciar la transición
    if Engine.has_singleton("MusicaGlobal") or get_node_or_null("/root/MusicaGlobal"):
        MusicaGlobal.detener() # O puedes pausarla / bajar volumen si prefieres
    
    # 2. Reproducir el sonido WAV de la transición
    if audio_player and audio_player.stream:
        audio_player.play()
    
    # Fundido a negro (0.5 segundos)
    var tween = create_tween()
    tween.tween_property(color_rect, "color:a", 1.0, 0.5)
    await tween.finished
    
    # Cambio oficial de escena
    get_tree().change_scene_to_file(ruta_siguiente)
    
    # 3. Reactivar la música de juego al entrar en la nueva zona
    if Engine.has_singleton("MusicaGlobal") or get_node_or_null("/root/MusicaGlobal"):
        MusicaGlobal.reproducir_juego()
    
    # Aclarar la pantalla (0.5 segundos) -> Total: 1 segundo de transición
    var tween_in = create_tween()
    tween_in.tween_property(color_rect, "color:a", 0.0, 0.5)
    await tween_in.finished
    
    color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE