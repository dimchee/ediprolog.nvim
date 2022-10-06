local M = {
	prefix = "% ?- "
}

local Opts = {
	system = 'string',
	program = 'string', -- find executable scryer-prolog or swipl
	program_switches = 'table',
	prefix = 'string',
	max_history = 'number'
}

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
		M.send(line:sub(#M.prefix + 1, #line))
	else
		M.consult()
	end
end

function M.interact()
	local c = vim.fn.nr2char(vim.fn.getchar())
	if c == 'q' then
		M.is_toplevel = false
	elseif c == 'a' then
		M.send'a'
	elseif c == '\n' then
		M.send''
	elseif c == ';' then
		M.send';'
	end
end

function M.run()
	if M.repl then return end
	M.job_id = vim.fn.jobstart(
		M.program, {
			on_stdout = function(_, data) -- on_stderr ignored cause of pty
				if data == "" then return end
				if M.is_prompt(data) then
					M.seen_prompt = true
					return
				end
				vim.notify(vim.inspect(data))
				M.is_toplevel = true
				M.toplevel()
			end,
			on_exit = function(_, exit_code)
				vim.notify(('exited with exit code: %d'):format(exit_code), vim.log.levels.INFO)
			end,
			pty = true -- needed for prompt recognition
		}
	)
end

function M.send(s)
	if type(s) ~= 'string' then
		vim.notify('You can send string only!', vim.log.levels.ERROR)
	end
	M.seen_prompt = false
	vim.fn.chansend(M.job_id, s..'\n')
end

function M.toplevel()
	while not M.seen_prompt and M.is_toplevel do
		M.interact()
	end
end

function M.is_prompt(s)
	return s == "\r\27[0K?- \r\27[3C"
		or s == " ?- "
end

return M
