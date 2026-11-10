extends Node

var audio_player: AudioStreamPlayer

var pista_menu = "res://comun/sistema/musica_menu.mp3"
var pista_juego = "res://comun/sistema/musica_juego.mp3"

func _ready() -> void:
    call_deferred("_inicializar_audio")

func _inicializar_audio() -> void:
    audio_player = AudioStreamPlayer.new()
    get_tree().root.add_child(audio_player)
    audio_player.bus = "Master"

func reproducir_menu() -> void:
    if audio_player.stream and audio_player.stream.resource_path == pista_menu and audio_player.playing:
        return
    
    if ResourceLoader.exists(pista_menu):
        var archivo = ResourceLoader.load(pista_menu)
        if archivo is AudioStreamMP3:
            archivo.loop = true # Para que la música del menú se repita en bucle
        audio_player.stream = archivo
        audio_player.play()

func reproducir_juego() -> void:
    if audio_player.stream and audio_player.stream.resource_path == pista_juego and audio_player.playing:
        return
        
    if ResourceLoader.exists(pista_juego):
        var archivo = ResourceLoader.load(pista_juego)
        if archivo is AudioStreamMP3:
            archivo.loop = true # Para que la música de las zonas se repita en bucle
        audio_player.stream = archivo
        audio_player.play()