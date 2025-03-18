class_name GemManager
extends Node

# References
var game_board
var grid_manager

# Gem types
var possible_gems = []
var gem_pool = []

func _ready():
	game_board = get_parent()
	
func initialize(grid_mgr):
	grid_manager = grid_mgr
	load_gem_resources()
	
func load_gem_resources():
	# Load gem scene resources
	possible_gems = [
		preload("res://assets/components/GemManager/gems/blue_tile.svg"),
		preload("res://assets/components/GemManager/gems/green_tile.svg"),
		preload("res://assets/components/GemManager/gems/purple_tile.svg"),
		preload("res://assets/components/GemManager/gems/red_tile.svg"),
		preload("res://assets/components/GemManager/gems/teal_tile.svg"),
		preload("res://assets/components/GemManager/gems/yellow_tile.svg")
	]
