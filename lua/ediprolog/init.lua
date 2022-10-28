local M = {
	prefix = "% ?- "
}

-- local Opts = {
-- 	system = 'string',
-- 	program = 'string', -- find executable scryer-prolog or swipl
-- 	program_switches = 'table',
-- 	prefix = 'string',
-- 	max_history = 'number'
-- }

function M.setup(opts)
	M.program = opts.program or "swipl"
end

function M.consult()
		vim.cmd'w'
		M.send('["'..vim.api.nvim_buf_get_name(0)..'"].')
end

function M.dwim()
	local line = vim.api.nvim_get_current_line()
	if line:sub(1, #M.prefix) == M.prefix then
		M.interactive_line = vim.api.nvim_win_get_cursor(0)[1]
		M.send(line:sub(#M.prefix + 1, #line)..'\n')
	else
		M.consult()
	end
end

function M.interact()
	local c = vim.fn.nr2char(vim.fn.getchar())
	if c == 'a' then
		M.send'a'
	elseif c == '\n' then
		M.send'\n'
	elseif c == ';' then
		M.send';'
	end
	-- vim.ui.input(
	-- 	{ prompt = 'Command: '},
	-- 	function(c)
	-- 		if c == 'a' then
	-- 			M.send'a'
	-- 		elseif c == '\n' then
	-- 			M.send''
	-- 		elseif c == ';' then
	-- 			M.send';'
	-- 		end
	-- 	end
	-- )
end

local function has_prompt(t)
	return type(t) == 'table' and t[#t] == '% ?- '
end

function M.run()
	if M.repl then return end
	M.job_id = vim.fn.jobstart(
		M.program, {
			on_stdout = function(_, data) -- on_stderr ignored cause of pty
				for i, value in ipairs(data) do
					data[i] = '% ' .. string.gsub(value, "\r", "")
				end
				if not M.interactive_line then return end
				if has_prompt(data) then
					table.remove(data)
					table.remove(data)
					vim.api.nvim_buf_set_lines(0, M.interactive_line, M.interactive_line, true, data)
					M.interactive_line = false
				else
					vim.api.nvim_buf_set_lines(0, M.interactive_line, M.interactive_line, true, data)
					M.interact()
				end
			end,
			on_exit = function(_, exit_code)
				vim.notify(('exited with exit code: %d'):format(exit_code), vim.log.levels.INFO)
			end,
			pty = true -- needed for prompt recognition
		}
	)
	if M.program == "swipl" then
		M.send'set_prolog_flag(color_term, false).\n'
	end
end

function M.send(s)
	vim.notify('sending: '..s, vim.log.levels.WARN)
	if type(s) ~= 'string' then
		vim.notify('You can send string only!', vim.log.levels.ERROR)
	end
	vim.fn.chansend(M.job_id, s)
end

return M
