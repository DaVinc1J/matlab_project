function test6()
	[char, ui, user, keymap] = setup();

user.snake = struct(...
    'body', [user.player_pos], ...
    'direction', 'right', ...
    'next_dir', 'right', ...
    'queued_dir', 'none', ...
    'grow', false, ...
    'score', 0, ...
    'move_counter', 0, ...
    'move_interval_ticks', 4 ...
);

	ui = spawn_food(ui, char, user);

	ui.game_timer = timer('ExecutionMode', 'fixedRate', ...
	'Period', 0.02, ...
	'TimerFcn', @game_tick);

	start(ui.game_timer);
	set(ui.fig, 'CloseRequestFcn', @(src, event) on_close(src, ui.game_timer));

	function game_tick(~, ~)
    if ~isvalid(ui.fig) || user.quit
        stop(ui.game_timer);
        delete(ui.game_timer);
        close(ui.fig);
        return;
    end

    check_key_state();

    user.snake.move_counter = user.snake.move_counter + 1;
    if user.snake.move_counter >= user.snake.move_interval_ticks
        move_snake();
        user.snake.move_counter = 0;
    end

    if user.update_map
        update_map();
        user.update_map = false;
    end
end

	function move_snake()
    
		if ~strcmp(user.snake.queued_dir, 'none')
        user.snake.next_dir = user.snake.queued_dir;
        user.snake.queued_dir = 'none';
    end
    
    user.snake.direction = user.snake.next_dir;
		head = user.snake.body(1,:);

		switch user.snake.direction
		case 'up'
			new_head = [head(1) + 1, head(2)];
		case 'down'
			new_head = [head(1) - 1, head(2)];
		case 'left'
			new_head = [head(1), head(2) - 1];
		case 'right'
			new_head = [head(1), head(2) + 1];
		end

		if ~can_move_to(ui, user, char, new_head)
			user.quit = true;
			disp(['Game Over! Score: ', num2str(user.snake.score)]);
			return;
		end

		if isequal(new_head, ui.food_pos)
			user.snake.grow = true;
			user.snake.score = user.snake.score + 1;
			ui = spawn_food(ui, char, user);
			set(ui.fig, 'Name', ['Snake - Score: ' num2str(user.snake.score)]);
		end

		user.snake.body = [new_head; user.snake.body];
		if ~user.snake.grow
			tail = user.snake.body(end,:);
			ui.map(tail(1), tail(2)) = char.passable.floor;
			user.snake.body(end,:) = [];
			ui.updated_positions = [ui.updated_positions; tail];
		else
			user.snake.grow = false;
		end

		ui.map(user.snake.body(:,1), user.snake.body(:,2)) = char.player.player;
		ui.updated_positions = [ui.updated_positions; user.snake.body];
		user.update_map = true;
	end

function check_key_state()
    keys = keypoll();
    pressed_dirs = {};

    dir_map = {keymap.up, keymap.down, keymap.left, keymap.right};
    for i = 1:length(dir_map)
        if keys.(dir_map{i})
            pressed_dirs{end+1} = dir_map{i};
        end
    end
    
    if ~isempty(pressed_dirs)
        latest_key = pressed_dirs{end};
        
        if strcmp(latest_key, keymap.up)
            new_dir = 'up';
        elseif strcmp(latest_key, keymap.down)
            new_dir = 'down';
        elseif strcmp(latest_key, keymap.left)
            new_dir = 'left';
        elseif strcmp(latest_key, keymap.right)
            new_dir = 'right';
        end
        
        if can_change_dir(user.snake.direction, new_dir)
            user.snake.queued_dir = new_dir;
        end
    end
    
    if isfield(keys, 'escape') && keys.escape
        user.quit = true;
    end
end

function valid = can_change_dir(current, new)
    valid = true;
    if (strcmp(current, 'up') && strcmp(new, 'down')) || ...
       (strcmp(current, 'down') && strcmp(new, 'up')) || ...
       (strcmp(current, 'left') && strcmp(new, 'right')) || ...
       (strcmp(current, 'right') && strcmp(new, 'left'))
        valid = false;
    end
end

	function ui = spawn_food(ui, char, user)
		[empty_rows, empty_cols] = find(ui.map == char.passable.floor);
		valid_positions = [empty_rows, empty_cols];

		valid_positions = setdiff(valid_positions, user.snake.body, 'rows');

		if ~isempty(valid_positions)
			idx = randi(size(valid_positions, 1));
			ui.food_pos = valid_positions(idx,:);
			ui.map(ui.food_pos(1), ui.food_pos(2)) = char.player.food;
			ui.updated_positions = [ui.updated_positions; ui.food_pos];
		else
			error('No empty space for food!');
		end
	end

function tf = can_move_to(ui, user, char, new_head)
    if any(new_head < 1) || new_head(1) > ui.rows || new_head(2) > ui.cols
        fprintf("boundary collision\n");
        tf = false;
        return;
    end

    is_food = isequal(new_head, ui.food_pos);
    if is_food
        body_to_check = user.snake.body;
    else
        body_to_check = user.snake.body(1:end-1, :);
    end

    if ismember(new_head, body_to_check, 'rows')
        fprintf("self-collision\n");
        tf = false;
        return;
    end

    target = ui.map(new_head(1), new_head(2));
    tf = (target ~= char.impassable.wall);
    if ~tf
        fprintf("wall collision\n");
    end
end

	function on_close(fig, timerObj)
		if isvalid(timerObj)
			stop(timerObj);
			delete(timerObj);
		end
		delete(fig);
	end

	function update_map()
		for i = 1:size(ui.updated_positions, 1)
			pos = ui.updated_positions(i, :);
			index = sub2ind(size(ui.map), pos(1), pos(2));
			current_string = get(ui.text(index), 'String');
			new_string = ui.map(pos(1), pos(2));
			if ~strcmp(current_string, new_string)
				set(ui.text(index), 'String', new_string);
			end
		end
		ui.updated_positions = [];
	end
end

function [ui, user] = create_map(char, ui, user)
	ui.map = repmat(char.passable.floor, ui.rows, ui.cols);

	ui.map([1 end], :) = char.impassable.wall;
	ui.map(:, [1 end]) = char.impassable.wall;

	user.player_pos = [ceil(ui.rows/2), ceil(ui.cols/2)];
	ui.map(user.player_pos(1), user.player_pos(2)) = char.player.player;

	[ui.X, ui.Y] = meshgrid(1:ui.cols, 1:ui.rows);
	ui.X = ui.X - 0.5;
	ui.Y = ui.Y - 0.5;
end

function [char, ui, user, keymap] = setup()
	[char, font, ui, user, keymap] = init_structs();

	screen_size = get(0, 'ScreenSize');  
	ui.window_size(1) = screen_size(3) / 2;
	ui.window_size(2) = screen_size(4) / 2;

	MIN_SCALE = 1;
	MAX_SCALE = 5;
	scale = 0.9;
	step = 0.001;

	for i = MIN_SCALE:MAX_SCALE
		ui.rows = round(ui.window_size(2) / (font.height * scale));
		ui.cols = round(ui.rows * (ui.window_size(1) / ui.window_size(2)));
		if mod(ui.rows, 2) == 1 && mod(ui.cols, 2) == 1
			break;
		end
		scale = scale + step;
	end

	[ui, user] = create_map(char, ui, user);
	ui = create_graphics(font, ui);
	set(gcf, 'Renderer', 'painters');
end

function [char, font, ui, user, keymap] = init_structs()
	char = struct(...
	'impassable', struct('wall', '#'), ...
	'passable', struct('floor', '-'), ...
	'player', struct('player', '@', 'food', 'E') ...
	);

	font = struct(...
	'name', 'Courier New', ...
	'size', 26, ...
	'width', '', 'height', '' ...
	);
	[font.width, font.height] = get_font_sizes(font.name, font.size);

	ui = struct(...
	'ax', 0, 'screen_size', zeros(1,4), 'window_size', zeros(1,2), ...
	'game_timer', 0, 'fig', 0, 'rows', 0, 'cols', 0, ...
	'X', 0, 'Y', 0, 'map', 0, 'updated_positions', [], 'food_pos', [0 0] ...
	);

	user = struct(...
	'player_pos', [0 0], 'quit', false, 'update_map', true ...
	);

	keymap = struct(...
	'up', 'up', ...
	'left', 'left', ...
	'down', 'down', ...
	'right', 'right' ...
	);
end

function [width, height] = get_font_sizes(name, size)

	fig = figure('Visible', 'off');

	temp_text = text(0, 0, 'A', 'FontName', name, 'FontSize', size, 'Units', 'pixels', 'Visible', 'off');

	extent = get(temp_text, 'Extent');

	width = extent(3);
	height = extent(4);

	delete(temp_text);
	close(fig);

end

function [ui] = create_graphics(font, ui)
	ui.fig = figure('Name', 'test', ...
	'NumberTitle', 'off', ...
	'MenuBar', 'none', ...
	'ToolBar', 'none', ...
	'Color', 'black', ...
	'Position', [ui.window_size(1) / 2, ui.window_size(2) / 2, ui.window_size(1), ui.window_size(2)]);

	ui.ax = axes('Parent', ui.fig, ...
	'XColor', 'none', 'YColor', 'none', ...
	'Position', [0, 0, 1, 1], ...
	'XLim', [0, ui.cols], 'YLim', [0, ui.rows], ...
	'Color', 'black', ...
	'DataAspectRatio', [1 1 1], ...
	'XTick', [], 'YTick', []);

	for r = 1:ui.rows
		for c = 1:ui.cols
			ui.text(r, c) = text(ui.ax, ...
			ui.X(r, c), ...
			ui.Y(r, c), ...
			ui.map(r, c), ...
			'Color', 'white', ...
			'FontName', font.name, ...
			'FontSize', font.size, ...
			'HorizontalAlignment', 'center', ...
			'VerticalAlignment', 'middle');
		end
	end
end
