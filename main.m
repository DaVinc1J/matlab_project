function main()
	while true
		clc;
		fprintf('=== welcome to snake! ===\n');
		fprintf('1. play game\n');
		fprintf('2. view leaderboards\n');
		fprintf('3. quit\n');
		choice = input('Enter your choice -> ', 's');

		switch choice
		case '1'
			play_game();
		case '2'
			display_leaderboard();
			input('\npress enter to continue ->', 's');
		case '3'
			fprintf('\nthanks for playing :D\n');
			return;
		otherwise
			fprintf('\nnot valid, enter 1, 2, or 3\n');
			pause(1);
		end
	end
end

function play_game()
	score = snake_game();
	if score == 0
		return;
	end

	name = input('\nenter your name: ', 's');
	if isempty(name)
		name = 'anonymous';
	end
	save_to_leaderboard(name, score);

	fprintf('\n=== your score -> %d ===\n', score);
	display_leaderboard();

	again = input('\nwanna play again? (y/n): ', 's');
	if lower(again) == 'y'
		play_game();
	end
end

function save_to_leaderboard(name, score)
	entry = sprintf('%s - score -> %d', name, score);
	fid = fopen('leaderboard.txt', 'a');
	if fid == -1
		error('could not open leaderboard file');
	end
	fprintf(fid, '%s\n', entry);
	fclose(fid);
end

function display_leaderboard()
	clc;
	fprintf('=== top 5 leaderboards ===\n');

	if exist('leaderboard.txt', 'file') == 0
		fprintf('no leaderboard entries yet\n');
		return;
	end

	entries = {};
	try
		fid = fopen('leaderboard.txt', 'r');
		line = fgetl(fid);
		while ischar(line)
			entries{end+1} = line;
			line = fgetl(fid);
		end
		fclose(fid);
	catch
		fprintf('error reading leaderboard.\n');
		return;
	end

	scores = zeros(length(entries), 1);
	valid_entries = {};
	for i = 1:length(entries)
		tokens = regexp(entries{i}, 'score\s*->\s*(\d+)', 'tokens');
		if ~isempty(tokens)
			scores(i) = str2double(tokens{1}{1});
			valid_entries{end+1} = entries{i};
		end
	end

	[~, sorted_indices] = sort(scores, 'descend');
	num_valid = length(valid_entries);
	if num_valid == 0
		fprintf('no valid entries in leaderboard\n');
		return;
	end

	num_to_show = min(5, num_valid);
	for i = 1:num_to_show
		fprintf('%d. %s\n', i, valid_entries{sorted_indices(i)});
	end
end

function score = snake_game()
	[char, ui, user, keymap, colours] = setup();

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
	ui.game_timer = timer('ExecutionMode', 'fixedRate', 'Period', 0.02, 'TimerFcn', @game_tick);
	start(ui.game_timer);
	set(ui.fig, 'CloseRequestFcn', @(src, event) on_close(src, ui.game_timer));

	waitfor(ui.fig);
	score = user.snake.score;

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

	function check_key_state()
		keys = keypoll();
		pressed_keys = {};
		movement_keys = struct2cell(keymap);
		for i = 1:length(movement_keys)
			k = movement_keys{i};
			if isfield(keys, k) && keys.(k)
				pressed_keys{end+1} = k;
			end
		end
		if ~isempty(pressed_keys)
			key = pressed_keys{end};
			if strcmp(key, keymap.up)
				new_dir = 'up';
			elseif strcmp(key, keymap.down)
				new_dir = 'down';
			elseif strcmp(key, keymap.left)
				new_dir = 'left';
			elseif strcmp(key, keymap.right)
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

	function move_snake()
		if ~strcmp(user.snake.queued_dir, 'none')
			user.snake.next_dir = user.snake.queued_dir;
			user.snake.queued_dir = 'none';
		end
		user.snake.direction = user.snake.next_dir;
		head = user.snake.body(1,:);
		switch user.snake.direction
		case 'up',    new_head = [head(1) + 1, head(2)];
		case 'down',  new_head = [head(1) - 1, head(2)];
		case 'left',  new_head = [head(1), head(2) - 1];
		case 'right', new_head = [head(1), head(2) + 1];
		end
		if ~can_move_to(ui, user, new_head)
			user.quit = true;
			disp(['Game Over! Score: ', num2str(user.snake.score)]);
			return;
		end
		if isequal(new_head, ui.food_pos)
			user.snake.grow = true;
			user.snake.score = user.snake.score + 1;
			ui = spawn_food(ui, char, user);
			set(ui.fig, 'Name', ['Snake - Score: ' num2str(user.snake.score)]);
			score_str = sprintf('Score: %d', user.snake.score);
			len = length(score_str);
			available_space = ui.cols;
			if len > available_space
				score_str = score_str(1:available_space);
				len = available_space;
			end
			left_pad = max(0, floor((available_space - len)/2));
			right_pad = max(0, available_space - len - left_pad);
			padded_str = [repmat(' ', 1, left_pad), score_str, repmat(' ', 1, right_pad)];
			ui.map(1, :) = padded_str;
			top_row_positions = [ones(ui.cols, 1), (1:ui.cols)'];
			ui.updated_positions = [ui.updated_positions; top_row_positions];
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
		body_indices = sub2ind(size(ui.map), user.snake.body(:,1), user.snake.body(:,2));
		ui.map(body_indices) = char.player.body;
		ui.map(user.snake.body(1,1), user.snake.body(1,2)) = char.player.head;
		ui.updated_positions = [ui.updated_positions; user.snake.body];
		user.update_map = true;
	end

	function tf = can_change_dir(current, new)
		is_vertical_inversion = (strcmp(current, 'up') && strcmp(new, 'down')) || ...
		(strcmp(current, 'down') && strcmp(new, 'up'));
		is_horizontal_inversion = (strcmp(current, 'left') && strcmp(new, 'right')) || ...
		(strcmp(current, 'right') && strcmp(new, 'left'));
		tf = ~(is_vertical_inversion || is_horizontal_inversion);
	end

	function ui = spawn_food(ui, char, user)
		[empty_rows, empty_cols] = find(ui.map == char.passable.floor);
		valid_positions = setdiff([empty_rows, empty_cols], user.snake.body, 'rows');
		if isempty(valid_positions)
			error('No empty space for food!');
		end
		idx = randi(size(valid_positions, 1));
		ui.food_pos = valid_positions(idx,:);
		ui.map(ui.food_pos(1), ui.food_pos(2)) = char.player.food;
		ui.updated_positions = [ui.updated_positions; ui.food_pos];
	end

	function tf = can_move_to(ui, user, new_head)
		if any(new_head < 1) || new_head(1) > ui.rows || new_head(2) > ui.cols
			tf = false;
			return;
		end
		body_to_check = user.snake.body(1:end-1,:);
		if ismember(new_head, body_to_check, 'rows') || ...
			ui.map(new_head(1), new_head(2)) == char.impassable.wall
			tf = false;
		else
			tf = true;
		end
	end

	function update_map()
		color_map = containers.Map(...
		{char.player.head, char.player.body, char.player.food, ...
		char.impassable.wall, char.passable.floor}, ...
		{colours.player_head, colours.player_body, colours.food, colours.wall, colours.floor});
		for i = 1:size(ui.updated_positions, 1)
			pos = ui.updated_positions(i,:);
			row = pos(1);
			col = pos(2);
			idx = sub2ind(size(ui.map), row, col);
			current_char = ui.map(row, col);
			set(ui.text(idx), 'String', current_char);
			if isKey(color_map, current_char)
				set(ui.text(idx), 'Color', color_map(current_char));
			elseif isstrprop(current_char, 'digit')
				set(ui.text(idx), 'Color', colours.score);
			else
				set(ui.text(idx), 'Color', colours.floor);
			end
		end
		ui.updated_positions = [];
	end
end

function [char, ui, user, keymap, colours] = setup()
	[char, font, ui, user, keymap, colours] = init_structs();
	screen_size = get(0, 'ScreenSize');
	ui.window_size = [screen_size(3)/2, screen_size(4)/2];

	scale = 0.85;
	for i = 1:100
		ui.rows = round(ui.window_size(2) / (font.height * scale));
		ui.cols = round(ui.rows * (ui.window_size(1)/ui.window_size(2)));
		if mod(ui.rows,2) && mod(ui.cols,2), break; end
		scale = scale * 0.99;
	end
	[ui, user] = create_map(char, ui, user);
	ui = create_graphics(char, font, ui, colours);
	set(gcf, 'Renderer', 'painters');
end

function [char, font, ui, user, keymap, colours] = init_structs()
	char = struct(...
	'impassable', struct('wall', '#', 'empty', ' '), ...
	'passable', struct('floor', '-'), ...
	'player', struct('head', '%', 'body', 'O', 'food', '*'));

	font = struct(...
	'name', 'FiraCode Nerd Font', ...
	'size', 32);
	[font.width, font.height] = get_font_sizes(font.name, font.size);

	ui = struct(...
	'ax', [], 'fig', [], 'rows', 0, 'cols', 0, 'X', [], 'Y', [], ...
	'map', [], 'text', [], 'updated_positions', [], 'food_pos', [0 0], 'game_timer', []);

	user = struct(...
	'player_pos', [0 0], 'quit', false, 'update_map', true);

	keymap = struct(...
	'up', 'up', 'down', 'down', 'left', 'left', 'right', 'right');

	colours = struct(...
	'player_head', [0.13, 0.68, 0.08], ...
	'player_body', [0.19, 1, 0.12], ...
	'wall', [0.6, 0.6, 0.6], ...
	'floor', [0.5, 0.5, 0.5], ...
	'food', [0.81, 0.06, 0.06], ...
	'score', [1, 1, 0]);
end

function [width, height] = get_font_sizes(name, size)
	fig = figure('Visible', 'off');
	txt = text(0,0,'W', 'FontName', name, 'FontSize', size, ...
	'Units', 'pixels', 'Visible', 'off');
	extent = get(txt, 'Extent');
	delete(txt);
	close(fig);
	width = extent(3);
	height = extent(4);
end

function ui = create_graphics(char, font, ui, colours)
	ui.fig = figure('Name', 'Snake', 'NumberTitle', 'off', ...
	'MenuBar', 'none', 'ToolBar', 'none', 'Color', [0.1, 0.1, 0.1], ...
	'Position', [ui.window_size(1)/2, ui.window_size(2)/2, ...
	ui.window_size(1), ui.window_size(2)]);

	ui.ax = axes('Parent', ui.fig, ...
	'XColor', 'none', 'YColor', 'none', ...
	'Position', [0 0 1 1], ...
	'XLim', [0 ui.cols], 'YLim', [0 ui.rows], ...
	'Color', [0.1, 0.1, 0.1], 'DataAspectRatio', [1 1 1]);

	[ui.X, ui.Y] = meshgrid(1:ui.cols, 1:ui.rows);
	ui.text = gobjects(ui.rows, ui.cols);

	for r = 1:ui.rows
		for c = 1:ui.cols
			current_char = ui.map(r,c);
			if current_char == char.impassable.wall
				cell_colour = colours.wall;
			elseif current_char == char.passable.floor
				cell_colour = colours.floor;
			elseif current_char == char.player.body
				cell_colour = colours.player_body;
			elseif current_char == char.player.food
				cell_colour = colours.food;
			elseif current_char == char.player.head
				cell_colour = colours.player_head;
			else
				cell_colour = colours.wall;
			end
			ui.text(r,c) = text(ui.ax, c-0.5, r-0.5, current_char, ...
			'Color', cell_colour, 'FontName', font.name, ...
			'FontSize', font.size, 'HorizontalAlignment', 'center');
		end
	end
end

function [ui, user] = create_map(char, ui, user)
	ui.map = repmat(char.passable.floor, ui.rows, ui.cols);

	ui.map(2:end-1, 1) = char.impassable.wall;
	ui.map(2:end-1, end) = char.impassable.wall;
	ui.map(2, :) = char.impassable.wall;
	ui.map(end-1, :) = char.impassable.wall;

	score_str = 'Score: 0';
	len = length(score_str);
	available_space = ui.cols;
	if len > available_space
		score_str = score_str(1:available_space);
		len = available_space;
	end
	left_pad = max(0, floor((available_space - len)/2));
	right_pad = max(0, available_space - len - left_pad);
	padded_str = [repmat(' ', 1, left_pad), score_str, repmat(' ', 1, right_pad)];
	ui.map(1, :) = padded_str;

	snake_str = 'snake';
	len = length(snake_str);
	available_space = ui.cols;
	if len > available_space
		snake_str = snake_str(1:available_space);
		len = available_space;
	end
	left_pad = max(0, floor((available_space - len)/2));
	right_pad = max(0, available_space - len - left_pad);
	padded_snake = [repmat('=', 1, left_pad), snake_str, repmat('=', 1, right_pad)];
	ui.map(end, :) = padded_snake;

	user.player_pos = [ceil(ui.rows / 2), ceil(ui.cols / 2)];
	ui.map(user.player_pos(1), user.player_pos(2)) = char.player.head;
end

function on_close(fig, timerObj)
	if isvalid(timerObj)
		stop(timerObj);
		delete(timerObj);
	end
	delete(fig);
end
