function keypoll_test()
	fig = figure('Name', 'Key Viewer', ...
	'NumberTitle', 'off', ...
	'Color', 'black', ...
	'MenuBar', 'none', ...
	'ToolBar', 'none');

	ax = axes('Parent', fig, 'Position', [0 0 1 1], 'Color', 'black', ...
	'XColor', 'none', 'YColor', 'none');
	txt = text(0.5, 0.5, '', ...
	'Color', 'white', ...
	'FontSize', 18, ...
	'HorizontalAlignment', 'center', ...
	'VerticalAlignment', 'middle');

	txt.Interpreter = 'none';

	xlim([0 1]); ylim([0 1]);

	while ishandle(fig)
		keys = keypoll();

		held = {};
		flds = fieldnames(keys);
		for i = 1:numel(flds)
			if keys.(flds{i})
				held{end+1} = flds{i};
			end
		end

		if isfield(keys, 'escape') && keys.escape
			delete(fig);
			break;
		end

		if isempty(held)
			txt.String = 'no keys pressed';
		else
			txt.String = ['Held: ', strjoin(held, ', ')];
		end

		pause(0.015);
	end
end
