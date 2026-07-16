local M = {}

--- Wrapper around argv that is 1 indexed
--- @param n number
--- @return string The path of the nth file in the arglist
function M.getArgAt(n)
    local f = vim.fn.argv(n - 1) --- @cast f string
    return f
end

--- Check if the currently opened buffer is in the arglist
--- @return boolean
--- @return number The position of the current buffer in the arglist if found. Else -1
function M.isCurrentBufferInArgs()
    local currentBufferPath = vim.fn.expand('%')
    local found = false
    local at = -1

    local i = 1
    while i <= vim.fn.argc() and not found do
        found = M.getArgAt(i) == currentBufferPath
        i = i + 1
    end

    if found then at = i - 1 end
    return found, at
end

return M
