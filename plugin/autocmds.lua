local monsterpoon = require('monsterpoon')
local utils = require('utils')

--- Run the autocmd only if arglist has to be redrawn
local function notifyIfNeeded()
    local weWereInTheArglist = monsterpoon.weAreInArglist
    monsterpoon.weAreInArglist, monsterpoon.currentPosInArglist = utils.isCurrentBufferInArgs()

    -- Basically we always want to re render unless we went from a file not in the arglist to
    -- another file still not in the arglist
    if weWereInTheArglist or monsterpoon.weAreInArglist then
        monsterpoon:notify()
    end
end

--- NOTE: BufEnter alone is not enough to overcome netrw's weirdness. In particular:
--- Add file to arglist
--- Delete the file from netrw
--- Set new arglist (either via :args or the reloadArglist function)
--- => Results in opening the first file from the new arglist for no reason and trigger BufWinEnter
--- instead of BufEnter
local notifyOnEvents = {
    'VimEnter',
    'BufEnter',
    'BufWinEnter',
}

for _, event in ipairs(notifyOnEvents) do
    vim.api.nvim_create_autocmd(event, {
        group = vim.api.nvim_create_augroup('masar3141/masarpoon/' .. event, { clear = true }),
        callback = notifyIfNeeded
    })
end
