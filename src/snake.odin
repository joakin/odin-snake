package snake

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

WINDOW_SIZE :: 500
GRID_WIDTH :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_WIDTH * CELL_SIZE
TICK_RATE :: 0.13
MAX_SNAKE_LENGTH :: GRID_WIDTH * GRID_WIDTH

Vec2i :: [2]int

tick_timer: f32 = TICK_RATE
snake: [MAX_SNAKE_LENGTH]Vec2i
snake_length: int
move_direction: Vec2i
game_over: bool = false
food_pos: Vec2i
high_score: int = 0

place_food :: proc() {
	occupied: [GRID_WIDTH][GRID_WIDTH]bool

	for i in 0 ..< snake_length {
		occupied[snake[i].x][snake[i].y] = true
	}

	free_cells := make([dynamic]Vec2i, context.temp_allocator)
	for x in 0 ..< GRID_WIDTH {
		for y in 0 ..< GRID_WIDTH {
			if !occupied[x][y] {
				append(&free_cells, Vec2i{x, y})
			}
		}
	}

	if len(free_cells) > 0 {
		random_cell_index := rl.GetRandomValue(0, i32(len(free_cells) - 1))
		food_pos = free_cells[random_cell_index]
	}
}

restart :: proc() {
	start_head_position := Vec2i{GRID_WIDTH / 2, GRID_WIDTH / 2}
	snake[0] = start_head_position
	snake[1] = start_head_position + {0, -1}
	snake[2] = start_head_position + {0, -2}
	snake_length = 3
	move_direction = {0, 1}
	game_over = false
	place_food()
}

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Snake")
	rl.InitAudioDevice()

	restart()

	food_sprite := rl.LoadTexture("assets/food.png")
	head_sprite := rl.LoadTexture("assets/head.png")
	body_sprite := rl.LoadTexture("assets/body.png")
	tail_sprite := rl.LoadTexture("assets/tail.png")

	eat_sound := rl.LoadSound("assets/eat.wav")
	crash_sound := rl.LoadSound("assets/crash.wav")
	high_score_sound := rl.LoadSound("assets/high_score.wav")

	for !rl.WindowShouldClose() {
		if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
			move_direction = {0, -1}
		} else if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
			move_direction = {0, 1}
		} else if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
			move_direction = {-1, 0}
		} else if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
			move_direction = {1, 0}
		}
		if rl.IsKeyPressed(.ENTER) {
			restart()
		}

		if game_over {

		} else {
			tick_timer -= rl.GetFrameTime()
		}

		if tick_timer <= 0.0 {
			next_part_pos := snake[0]
			snake[0] += move_direction
			head_pos := snake[0]

			for i in 1 ..< snake_length {
				cur_pos := snake[i]

				if cur_pos == head_pos {
					game_over = true
					rl.PlaySound(crash_sound)
				}

				snake[i] = next_part_pos
				next_part_pos = cur_pos
			}

			if head_pos.x < 0 ||
			   head_pos.x >= GRID_WIDTH ||
			   head_pos.y < 0 ||
			   head_pos.y >= GRID_WIDTH {
				game_over = true
				rl.PlaySound(crash_sound)
			}

			if head_pos == food_pos {
				snake_length += 1
				snake[snake_length - 1] = next_part_pos
				place_food()
				rl.PlaySound(eat_sound)
			}


			tick_timer = TICK_RATE + tick_timer
		}

		rl.BeginDrawing()
		rl.ClearBackground({76, 53, 83, 255})

		camera := rl.Camera2D {
			zoom = f32(WINDOW_SIZE) / f32(CANVAS_SIZE),
		}

		rl.BeginMode2D(camera)

		rl.DrawTextureV(
			food_sprite,
			{f32(food_pos.x) * CELL_SIZE, f32(food_pos.y) * CELL_SIZE},
			rl.WHITE,
		)

		for s, i in snake {
			if i >= snake_length do break

			sprite := body_sprite
			dir: Vec2i

			if i == 0 {
				sprite = head_sprite
				dir = snake[i] - snake[i + 1]
			} else if i == snake_length - 1 {
				sprite = tail_sprite
				dir = snake[i - 1] - snake[i]
			} else {
				dir = snake[i - 1] - snake[i]
			}
			rot := math.atan2(f32(dir.y), f32(dir.x)) * math.DEG_PER_RAD

			source := rl.Rectangle {
				x      = 0,
				y      = 0,
				width  = CELL_SIZE,
				height = CELL_SIZE,
			}
			dest := rl.Rectangle {
				x      = f32(s.x) * CELL_SIZE + CELL_SIZE / 2.0,
				y      = f32(s.y) * CELL_SIZE + CELL_SIZE / 2.0,
				width  = CELL_SIZE,
				height = CELL_SIZE,
			}
			rl.DrawTexturePro(sprite, source, dest, {CELL_SIZE / 2, CELL_SIZE / 2}, rot, rl.WHITE)
		}

		if game_over {
			rl.DrawText("Game Over", 4, 4, 25, rl.RED)
			rl.DrawText("Press Enter to play again", 4, 30, 15, rl.BLACK)
		}

		score := snake_length - 3
		score_str := fmt.ctprintf("Score: %v", score)
		rl.DrawText(score_str, 4, CANVAS_SIZE - 14, 10, rl.GRAY)

		if score > high_score {
			high_score = score
			rl.PlaySound(high_score_sound)
		}

		high_score_str := fmt.ctprintf("High Score: %v", high_score)
		high_score_width := rl.MeasureText(high_score_str, 10)
		rl.DrawText(
			high_score_str,
			CANVAS_SIZE - high_score_width - 4,
			CANVAS_SIZE - 14,
			10,
			rl.WHITE,
		)

		rl.EndMode2D()
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}

	rl.UnloadTexture(food_sprite)
	rl.UnloadTexture(head_sprite)
	rl.UnloadTexture(body_sprite)
	rl.UnloadTexture(tail_sprite)

	rl.CloseAudioDevice()
	rl.CloseWindow()
}
