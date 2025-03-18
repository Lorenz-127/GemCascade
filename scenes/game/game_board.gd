class_name GameBoard
extends Node2D

# Component references
@onready var grid_manager: GridManager = $GridManager
@onready var gem_manager: GemManager = $GemManager
@onready var input_handler: InputHandler = $InputHandler
@onready var match_detector: MatchDetector = $MatchDetector
@onready var board_controller: BoardController = $BoardController
@onready var score_manager: ScoreManager = $ScoreManager

# Game state
var game_active: bool = false

func _ready():
	# Initialize all components in the correct order
	initialize_components()
	connect_signals()
	
func initialize_components():
	grid_manager.initialize()
	gem_manager.initialize(grid_manager)
	match_detector.initialize(grid_manager, gem_manager)
	input_handler.initialize(grid_manager, gem_manager)
	board_controller.initialize(grid_manager, gem_manager, match_detector)
	score_manager.initialize()
	
func connect_signals():
	# Connect all component signals

	# Add more signal connections
	pass
