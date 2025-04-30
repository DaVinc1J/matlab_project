function test2()
	[font, ui, user, keymap] = setup();
	key_tracker = key_handler();

	set(gcf, 'Renderer', 'painters');

	set(ui.fig, 'KeyPressFcn', @(~, event) key_callback(event, key_tracker));

	while isvalid(ui.fig)
		ui.key_press = key_tracker.key;
		key_tracker.key = '';

		[user, ui] = check_key_press(user, ui, keymap);

		if user.update_map
			ui = update_map_display(ui);
			user.update_map = false;
		end

		pause(0);

		if user.quit
			close(ui.fig);
			break;
		end
	end

end

function [user, ui] = check_key_press(user, ui, keymap)

	if ~isempty(ui.key_press)
		user.old_pos = user.character_pos;

		switch ui.key_press
		case keymap.up
			user.character_pos(1) = min(ui.rows, user.character_pos(1) + 1);
		case keymap.down
			user.character_pos(1) = max(1, user.character_pos(1) - 1);
		case keymap.left
			user.character_pos(2) = max(1, user.character_pos(2) - 1);
		case keymap.right
			user.character_pos(2) = min(ui.cols, user.character_pos(2) + 1);
		case 'escape'
			user.quit = true;
			return;
		end

		if ~isequal(user.old_pos, user.character_pos)
			ui.map(user.old_pos(1), user.old_pos(2)) = '-';
			ui.map(user.character_pos(1), user.character_pos(2)) = '@';
			user.update_map = true;
			ui.updated_positions = [ui.updated_positions; user.old_pos; user.character_pos];
		end
	end
end

function key_callback(event, tracker)
	tracker.key = event.Key;
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

function ui = update_map_display(ui)
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

function [font, ui, user, keymap] = setup()

	char = struct(...
	'empty', ' ', ...
	'floor', '-', ...
	'character', '@', ...
	'background', '󰝤', ...
	'wall', '#' ...
	);

	font = struct(...
	'name', 'VictorMono Nerd Font', ...
	'size', 14, ...
	'width', '', ...
	'height', '' ...
	);
	[font.width, font.height] = get_font_sizes(font.name, font.size);

	ui = struct(...
	'ax', 0, ...
	'screen_size', zeros(1, 4), ...
	'window_size', zeros(1, 2), ...
	'fig', 0, ...
	'rows', 0, ...
	'cols', 0, ...
	'X', 0, ...
	'Y', 0, ...
	'map', 0, ...
	'updated_positions', [] ...
	);

	user = struct(...
	'character_pos', 0, ...
	'old_pos', NaN, ...
	'quit', false, ...
	'update_map', true, ...
	'key_press', "" ...
	);

	keymap = struct(...
	'up', 'w', ...
	'left', 'a', ...
	'down', 's', ...
	'right', 'd' ...
	);

	screen_size = get(0, 'ScreenSize');  

	ui.window_size(1) = screen_size(3) / 2;
	ui.window_size(2) = screen_size(4) / 2;

	ui.rows = round((ui.window_size(1) / (font.height + 8)));
	ui.cols = round( 2.1 * (ui.window_size(2) / (font.height + 3)));

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

	ui.map = repmat(char.floor, ui.rows, ui.cols);
	user.character_pos = [ceil(ui.rows/2), ceil(ui.cols/2)];
	ui.map(user.character_pos(1), user.character_pos(2)) = char.character;
	[ui.X, ui.Y] = meshgrid(1:ui.cols, 1:ui.rows);
	ui.X = ui.X - 0.5;
	ui.Y = ui.Y - 0.5;

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
