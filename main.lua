local Directions = {
	Up = "up",
	Down = "down",
	Left = "left",
	Right = "right"
}

local DIRECTION_DELTA_LUT = {
	[Directions.Up] = {0, -1},
	[Directions.Down] = {0, 1},
	[Directions.Left] = {-1, 0},
	[Directions.Right] = {1, 0}
}

local KEY_TO_DIRECTION_LUT = {
	["up"] = Directions.Up,
	["down"] = Directions.Down,
	["left"] = Directions.Left,
	["right"] = Directions.Right,

	["w"] = Directions.Up,
	["s"] = Directions.Down,
	["a"] = Directions.Left,
	["d"] = Directions.Right
}

local INVERSE_DIRECTION_LUT = {
	[Directions.Up] = Directions.Down,
	[Directions.Down] = Directions.Up,
	[Directions.Left] = Directions.Right,
	[Directions.Right] = Directions.Left
}

local SQUARE_SIZE = 15
local GRID_WIDTH = 31
local GRID_HEIGHT = 31

local TURN_TIME = 0.1
local SNAKE_COLOR = {255, 0, 0}
local FRUIT_COLOR = {0, 0, 255}
local TEXT_COLOR = {0, 255, 0}

local FRUIT_LENGTH_BONUS = 3

local snakeSquares = {{14, 15}, {15, 15}, {16, 15}}
local snakeDirection = Directions.Left
-- just initialise the new direction with the current direction
-- it will definitely change from this though
local newSnakeDirection = snakeDirection

local fruitPosition = {7, 7}
local squaresToBeAdded = 0

local timeAccumulator = 0

-- this method could get stuck forever if the PRNG keeps giving an invalid
-- position. but i'm sure that since there'll probably always be room on the
-- board that it'll never take too long.
function moveFruit()
	fruitPosition = nil

	while fruitPosition == nil do
		local newFruitPosition = {math.random(0, GRID_WIDTH - 1), math.random(0, GRID_HEIGHT - 1)}

		local failed = false
		for _, square in pairs(snakeSquares) do
			if newFruitPosition[1] == square[1] and newFruitPosition[2] == square[2] then
				failed = true
			end
		end

		if not failed then
			fruitPosition = newFruitPosition
		end
	end
end

function love.load()
	love.window.setMode(SQUARE_SIZE * GRID_WIDTH, SQUARE_SIZE * GRID_HEIGHT, { })

	moveFruit()
end

function love.keypressed(key)
	newSnakeDirection = KEY_TO_DIRECTION_LUT[key]

	-- newSnakeDirection is nil if the key does not exist in the LUT
	-- don't allow the player to make the snake turn in the opposite direction
	-- to the direction it's already going
	if newSnakeDirection == nil or newSnakeDirection == INVERSE_DIRECTION_LUT[snakeDirection] then
		newSnakeDirection = snakeDirection
	end
end

function moveSnake()
	snakeDirection = newSnakeDirection

	local directionDelta = DIRECTION_DELTA_LUT[snakeDirection]

	-- pop last square, unless there's squares to be added
	if squaresToBeAdded == 0 then
		table.remove(snakeSquares)
	else
		squaresToBeAdded = squaresToBeAdded - 1
	end

	-- add new square at beginning of snake in the snake's direction
	local headPosition = snakeSquares[1]
	local newSnakeSquares = {{headPosition[1] + directionDelta[1], headPosition[2] + directionDelta[2]}}

	for _, square in pairs(snakeSquares) do
		table.insert(newSnakeSquares, square)
	end

	snakeSquares = newSnakeSquares
end

-- check if head is off the board, the head has collided with body at all, 
-- or if the snake has collected a fruity thing
function checkSnake()
	local headPosition = snakeSquares[1]

	if headPosition[1] < 0 or headPosition[1] >= GRID_WIDTH or headPosition[2] < 0 or headPosition[2] >= GRID_HEIGHT then
		print("You lose :(")
		love.event.quit()
	end

	local collided = false
	for i = 2, #snakeSquares do
		local testPosition = snakeSquares[i]

		if testPosition[1] == headPosition[1] and testPosition[2] == headPosition[2] then
			collided = true
			break
		end
	end

	if collided then
		print("You lose :(")
		love.event.quit()
	end

	if headPosition[1] == fruitPosition[1] and headPosition[2] == fruitPosition[2] then
		squaresToBeAdded = FRUIT_LENGTH_BONUS

		moveFruit()
	end
end

function love.update(dt)
	timeAccumulator = timeAccumulator + dt

	if timeAccumulator >= TURN_TIME then
		timeAccumulator = 0

		moveSnake()
		checkSnake()
	end
end

function drawSquare(x, y, color)
	love.graphics.setColor(color)
	love.graphics.rectangle("fill", x * SQUARE_SIZE, y * SQUARE_SIZE, SQUARE_SIZE, SQUARE_SIZE)
end

function love.draw()
	for _, square in pairs(snakeSquares) do
		drawSquare(square[1], square[2], SNAKE_COLOR)
	end

	drawSquare(fruitPosition[1], fruitPosition[2], FRUIT_COLOR)
	
	local score = #snakeSquares - 3

	love.graphics.setColor(TEXT_COLOR)
	love.graphics.print("Score: " .. score, 20, SQUARE_SIZE * GRID_HEIGHT - 30)
end
