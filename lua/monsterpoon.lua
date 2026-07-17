local utils = require('utils')

--- @class M
--- @field weAreInArglist boolean
--- @field currentPosInArglist number
--- @field pattern string - The pattern to listen to in an autocmd
--- @field isArgeditOpen boolean
--- @field argeditBufId number
local M = {
    weAreInArglist = false,
    currentPosInArglist = -1,
    pattern = 'Monsterpoon',

    isArgeditOpen = false,
    argeditBufId = -1,
    argeditWinId = -1,
}
M.__index = M

local defaults = {
    hiActive = "StatusLine",   -- Highlight group for active file
    hiInactive = "StatusLine", -- Highlight group for active file

    activeFormat = '[%s]',     -- printf formatting for the current file of the arglist
    sep = '  ',                -- Separation between two files in the arglist
}

function M:setup(opts)
    defaults = vim.tbl_deep_extend("force", defaults, opts or {})
end

--- Run the autocmds everytime the arglist has changed in a way that it needs to be redrawn
function M:notify()
    vim.api.nvim_exec_autocmds('User', {
        pattern = self.pattern
    })
end

--- Run the autocmd only if arglist has to be redrawn
function M:updateAndNotify()
    local weWereInTheArglist = self.weAreInArglist
    self.weAreInArglist, self.currentPosInArglist = utils.isCurrentBufferInArgs()

    -- Basically we always want to re render unless we went from a file not in the arglist to
    -- another file still not in the arglist
    if weWereInTheArglist or self.weAreInArglist then
        self:notify()
    end
end

--- Append the current file to the arglist
function M:appendCurrent()
    vim.cmd("$arga")
    vim.cmd "argded"
    self:updateAndNotify()
end

--- Removes the current file to the arglist
--- NOTE: When we are not in the arglist, the arglist considers we are on its first file.
--- I need to check if we are in the arglist before running removeCurrent() otherwise it would
--- remove the first file from the arglist when we are not in the arglist
function M:removeCurrent()
    if self.weAreInArglist then
        vim.cmd "argd"
        self:updateAndNotify()
    end
end

--- Go to the nth buffer
--- @param n number - 1-indexed position in the arglist
function M:goToFile(n)
    if n >= 1 and n <= vim.fn.argc() and n ~= self.currentPosInArglist then
        vim.cmd("argu " .. n)
        self:updateAndNotify()
    end
end

--- Removes files from the arglist that no longer exist
function M:reloadArglist()
    -- @type string[]
    local newArgs = {}
    for i = 1, vim.fn.argc() do
        local arg = utils.getArgAt(i)
        if vim.uv.fs_stat(arg) ~= nil then
            table.insert(newArgs, arg)
        end
    end
    vim.cmd("%argd")
    for _, arg in ipairs(newArgs) do
        vim.cmd("arga " .. arg)
    end
    vim.cmd("argded")
    self:updateAndNotify()
end

--- Create a new arg list for the window
function M:newLocalArglist()
    vim.cmd "argl"
    vim.cmd "argd *"
    self:updateAndNotify()
end

--- Use the global arglist
--- Deletes the existing local arglist if any
function M:useGlobalArglist()
    vim.cmd "argglobal"
    self:updateAndNotify()
end

function M:openArgedit()
    if M.isArgeditOpen then
        self:closeArgeditWindow() -- This DOES trigger WinClosed
        self:updateAndNotify()
        return
    end

    self.argeditBufId = vim.api.nvim_create_buf(false, false)
    M.isArgeditOpen = true
    self.argeditWinId = vim.api.nvim_open_win(self.argeditBufId, true, {
        height = math.floor(vim.o.lines * 0.25),
        split = 'below'
    })
    vim.api.nvim_buf_set_name(self.argeditBufId, "Monsterpoon")
    vim.api.nvim_set_option_value("buftype", "acwrite", { buf = self.argeditBufId })

    local content = vim.fn.argv(-1) --- @cast content string[]
    vim.api.nvim_buf_set_lines(self.argeditBufId, 0, -1, false, content)

    vim.keymap.set('n', '<CR>', function()
        local file = vim.fn.getline(".")
        self:closeArgeditWindow() -- This DOES trigger WinClosed
        self:updateAndNotify()
        vim.cmd.e(file)
    end, { buf = self.argeditBufId })

    vim.api.nvim_create_autocmd('BufWriteCmd', {
        group = vim.api.nvim_create_augroup('tweetymonster21/monsterpoon/writeArgEdit', { clear = true }),
        buffer = self.argeditBufId,
        callback = function()
            local newArgs = vim.api.nvim_buf_get_lines(0, 0, -1, true)

            self:closeArgeditWindow() -- This does NOT trigger WinClosed
            self:cleanupArgeditBuffer()
            self:updateAndNotify()

            -- Don't call args file1 file2 ...
            -- Because this will navigate to file1
            vim.cmd("%argd")
            for _, arg in ipairs(newArgs) do
                vim.cmd("arga " .. arg)
            end
            vim.cmd("argded")
            vim.bo.modified = false
        end
    })

    vim.api.nvim_create_autocmd('WinClosed', {
        pattern = tostring(self.argeditWinId),
        group = vim.api.nvim_create_augroup('tweetymonster21/monsterpoon/winClosedArgEdit', { clear = true }),
        callback = function()
            self.isArgeditOpen = false
            self:cleanupArgeditBuffer()
            self:updateAndNotify()
        end
    })
end

function M:closeArgeditWindow()
    vim.api.nvim_win_close(self.argeditWinId, true)
    self.argeditWinId = -1
    self.isArgeditOpen = false
end

function M:cleanupArgeditBuffer()
    vim.api.nvim_buf_delete(self.argeditBufId, { force = true })
    self.argeditBufId = -1
end

--- Returns the formatted string of the arglist
--- @return string
function M:renderArgs()
    local s = ""

    for i = 1, vim.fn.argc() do
        local withPath = utils.getArgAt(i)
        local fname = vim.fn.fnamemodify(withPath, ':t')

        -- @type string
        local displayFName
        if i == self.currentPosInArglist then
            displayFName = "%#" .. defaults.hiActive .. "#" .. vim.fn.printf(defaults.activeFormat, fname)
        else
            displayFName = fname
        end

        s = s .. displayFName .. "%#" .. defaults.hiInactive .. "#"
        if i ~= vim.fn.argc() then
            s = s .. defaults.sep
        end
    end


    return s
end

return M
