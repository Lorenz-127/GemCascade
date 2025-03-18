class_name GameBoard
extends Node2D

# References to components
@onready var grid_manager: GridManager = $GridManager
@onready var gem_manager: GemManager = $GridManager/GemManager
@onready var input_handler: InputHandler = $InputHandler
@onready var match_detector: MatchDetector = $MatchDetector
@onready var board_controller: BoardController = $BoardController
@onready var score_manager: ScoreManager = $ScoreManager

func _ready():
	# Initialize in the correct order
	initialize_components()
	
	# Connect signals
	connect_signals()
	
	# Initialize the game board
	initialize_board()

# Initialize all components in the right order
func initialize_components():
	# Grid manager must be first as other components depend on it
	grid_manager.initialize()
	
	# GemManager now gets reference to its parent instead of grid_manager
	gem_manager.initialize()
	
	# For other components, access gem_manager through grid_manager if needed
	match_detector.initialize(grid_manager, grid_manager.get_node("GemManager"))
	input_handler.initialize(grid_manager, grid_manager.get_node("GemManager"))
	board_controller.initialize(grid_manager, grid_manager.get_node("GemManager"), match_detector)
	score_manager.initialize()

# Connect all signals between components
func connect_signals():
	# InputHandler signals
	input_handler.connect("swap_attempted", board_controller.process_player_move)
	
	# BoardController signals
	board_controller.connect("game_state_changed", _on_game_state_changed)
	board_controller.connect("board_processing_complete", _on_board_processing_complete)
	
	# MatchDetector signals
	match_detector.connect("matches_found", _on_matches_found)

# Initialize the game board
func initialize_board():
	# Clear any existing gems
	# Grid is already set up by the GridManager
	
	# Fill the grid with gems that don't create initial matches
	populate_initial_board()
	
	# Check if the board has valid moves
	if !board_controller.check_for_valid_moves():
		# If not, reinitialize
		initialize_board()

# Populate the board with initial gems
func populate_initial_board():
	var dims = grid_manager.get_grid_dimensions()
	for i in range(dims.x):
		for j in range(dims.y):
			gem_manager.create_gem_no_match(i, j)

# Signal handlers
func _on_game_state_changed(state):
	# Handle game state changes
	match state:
		BoardController.GameState.WAITING_INPUT:
			input_handler.enable_input()
		BoardController.GameState.PROCESSING:
			input_handler.disable_input()
		BoardController.GameState.GAME_OVER:
			# Handle game over state
			pass

func _on_board_processing_complete():
	# Check if there are any valid moves
	if !board_controller.check_for_valid_moves():
		# No more valid moves - game over
		board_controller.change_state(BoardController.GameState.GAME_OVER)

func _on_matches_found(matches):
	# Process score update when matches are found
	var matched_gems_count = 0
	
	# Count all matched gems
	for match_info in matches:
		matched_gems_count += match_info.positions.size()
	
	# Update score based on matches and chain level
	if matched_gems_count >= 3:
		var chain_level = board_controller.chain_count
		score_manager.update_score_for_matches(matched_gems_count, chain_level)
