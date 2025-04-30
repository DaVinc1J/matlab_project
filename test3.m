function test3()
	[char, ui, user, keymap] = setup();

	ui.game_timer = timer('ExecutionMode', 'fixedRate', 'Period', 0.02, ...
	'TimerFcn', @(~, ~) game_tick());

	start(ui.game_timer);

	set(ui.fig, 'CloseRequestFcn', @(src, ~) on_close(src, ui.game_timer));

	function game_tick()
		if ~isvalid(ui.fig) || user.quit
			stop(ui.game_timer);
			delete(ui.game_timer);
			close(ui.fig);
			return;
		end

		check_key_state();

		if user.update_map
			ui = update_map(ui);
			ui = update_viewport(ui, user, char);
			user.update_map = false;
		end
	end

	function check_key_state()
		user.old_pos = user.player_pos;

		keys = keypoll();

		pressed_keys = {};
		movement_keys = struct2cell(keymap);
		for i = 1:length(movement_keys)
			k = movement_keys{i};
			if isfield(keys, k) && keys.(k)
				pressed_keys{end+1} = k;
			end
		end

		for i = 1:length(pressed_keys)
			key = pressed_keys{i};

			if strcmp(key, keymap.up) && can_move_to(ui, user, char, 'up')
				user.player_pos(1) = min(ui.map_rows, user.player_pos(1) + 1);

			elseif strcmp(key, keymap.down) && can_move_to(ui, user, char, 'down')
				user.player_pos(1) = max(1, user.player_pos(1) - 1);

			elseif strcmp(key, keymap.left) && can_move_to(ui, user, char, 'left')
				user.player_pos(2) = max(1, user.player_pos(2) - 1);

			elseif strcmp(key, keymap.right) && can_move_to(ui, user, char, 'right')
				user.player_pos(2) = min(ui.map_cols, user.player_pos(2) + 1);
			end
		end

		if isfield(keys, 'escape') && keys.escape
			user.quit = true;
			return;
		end

		if ~isequal(user.old_pos, user.player_pos)
			ui.map(user.old_pos(1), user.old_pos(2)) = '-';
			ui.map(user.player_pos(1), user.player_pos(2)) = '@';
			user.update_map = true;
			ui.updated_positions = [ui.updated_positions; user.old_pos; user.player_pos];
		end
	end
end

function tf = can_move_to(ui, user, char, direction)
	row = user.player_pos(1);
	col = user.player_pos(2);

	switch direction
	case 'up'
		row = row + 1;
	case 'down'
		row = row - 1;
	case 'left'
		col = col - 1;
	case 'right'
		col = col + 1;
	end

	if row < 1 || row > ui.map_rows || col < 1 || col > ui.map_cols
		tf = false;
		return;
	end

	target = ui.map(row, col);
	passables = struct2cell(char.passable);
	tf = any(cellfun(@(c) c == target, passables));
end

function on_close(fig, timerObj)
	if isvalid(timerObj)
		stop(timerObj);
		delete(timerObj);
	end
	delete(fig);
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

function ui = update_viewport(ui, user, char)
	ui.viewport = repmat(char.empty, ui.view_rows, ui.view_cols);

	map_rows = size(ui.map, 1);
	map_cols = size(ui.map, 2);

	vert_view_copy_dist = floor(ui.view_rows / 2);
	horz_view_copy_dist  = floor(ui.view_cols / 2);

	pl_row_y = user.player_pos(1);
	pl_col_x = user.player_pos(2);

	abv_row_copy_dist = vert_view_copy_dist;
	bot_row_copy_dist = vert_view_copy_dist;
	lft_col_copy_dist = horz_view_copy_dist;
	rgt_col_copy_dist = horz_view_copy_dist;

	if pl_row_y - vert_view_copy_dist < 1, abv_row_copy_dist = pl_row_y - 1; end
	if pl_col_x - horz_view_copy_dist < 1, lft_col_copy_dist = pl_col_x - 1; end
	if pl_row_y + vert_view_copy_dist > map_rows, bot_row_copy_dist = map_rows - pl_row_y; end
	if pl_col_x + horz_view_copy_dist > map_cols, rgt_col_copy_dist = map_cols - pl_col_x; end

	src_row_start = pl_row_y - abv_row_copy_dist + 1;
	src_row_end   = pl_row_y + bot_row_copy_dist;
	src_col_start = pl_col_x - lft_col_copy_dist + 1;
	src_col_end   = pl_col_x + rgt_col_copy_dist;

	dst_row_start = vert_view_copy_dist - abv_row_copy_dist + 1;
	dst_row_end   = dst_row_start + (src_row_end - src_row_start);
	dst_col_start = horz_view_copy_dist - lft_col_copy_dist + 1;
	dst_col_end   = dst_col_start + (src_col_end - src_col_start);

	ui.viewport(dst_row_start:dst_row_end, dst_col_start:dst_col_end) = ...
	ui.map(src_row_start:src_row_end, src_col_start:src_col_end);

end

function ui = update_map(ui)
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

function [ui, user] = create_map(char, ui, user)
	ui.map_rows = 100;
	ui.map_cols = 100;
	ui.map = repmat(char.passable.floor, ui.map_rows, ui.map_cols);

	user.player_pos = [ceil(ui.map_rows / 2), ceil(ui.map_cols / 2)];
	ui.map(user.player_pos(1), user.player_pos(2)) = char.player.player;

	total_cells = ui.map_rows * ui.map_cols;
	num_walls = round(0.3 * total_cells);

	wall_indices = randperm(total_cells, num_walls);

	[wall_rows, wall_cols] = ind2sub([ui.map_rows, ui.map_cols], wall_indices);

	for i = 1:num_walls
		if ~(wall_rows(i) == user.player_pos(1) && wall_cols(i) == user.player_pos(2))
			ui.map(wall_rows(i), wall_cols(i)) = char.impassable.wall;
		end
	end

	[ui.X, ui.Y] = meshgrid(1:ui.view_cols, 1:ui.view_rows);
	ui.X = ui.X - 0.5;
	ui.Y = ui.Y - 0.5;

	ui = update_viewport(ui, user, char);
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
	'XLim', [0, ui.view_cols], 'YLim', [0, ui.view_rows], ...
	'Color', 'black', ...
	'DataAspectRatio', [1 1 1], ...
	'XTick', [], 'YTick', []);

	for r = 1:ui.view_rows
		for c = 1:ui.view_cols
			ui.text(r, c) = text(ui.ax, ...
			ui.X(r, c), ...
			ui.Y(r, c), ...
			ui.viewport(r, c), ...
			'Color', 'white', ...
			'FontName', font.name, ...
			'FontSize', font.size, ...
			'HorizontalAlignment', 'center', ...
			'VerticalAlignment', 'middle');
		end
	end
end

function [char, ui, user, keymap] = setup()
	[char, font, ui, user, keymap] = init_structs();

	screen_size = get(0, 'ScreenSize');  

	ui.window_size(1) = screen_size(3) / 2;
	ui.window_size(2) = screen_size(4) / 2;

	MIN_SCALE = 1;
	MAX_SCALE = 5;

	scale = 1.0;
	step = 0.001;

	for i = MIN_SCALE:MAX_SCALE
		ui.view_rows = round(ui.window_size(2) / (font.height * scale));
		ui.view_cols = round(ui.view_rows * (ui.window_size(1) / ui.window_size(2)));
		if mod(ui.view_rows, 2) == 1 && mod(ui.view_cols, 2) == 1
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
	'impassable', struct(...
	'wall', '#' , ...
	'water', '~' ...
	), ...
	'passable', struct(...
	'floor', '-' ...
	), ...
	'player', struct(...
	'player', '@', ...
	'enemy', 'E' ...
	), ...
	'empty', ' ' ...
	);

	font = struct(...
	'name', 'VictorMono Nerd Font', ...
	'size', 18, ...
	'width', '', ...
	'height', '' ...
	);
	[font.width, font.height] = get_font_sizes(font.name, font.size);

	ui = struct(...
	'ax', 0, ...
	'screen_size', zeros(1, 4), ...
	'window_size', zeros(1, 2), ...
	'game_timer', 0, ...
	'fig', 0, ...
	'view_rows', 0, ...
	'view_cols', 0, ...
	'map_rows', 0, ...
	'map_cols', 0, ...
	'X', 0, ...
	'Y', 0, ...
	'map', 0, ...
	'viewport', 0, ...
	'updated_positions', [] ...
	);

	user = struct(...
	'player_pos', 0, ...
	'old_pos', NaN, ...
	'quit', false, ...
	'update_map', true ...
	);

	keymap = struct(...
	'up', 'w', ...
	'left', 'a', ...
	'down', 's', ...
	'right', 'd' ...
	);

end
