local monsterpoon = require('monsterpoon')

local notifyOnEvents = {
    'VimEnter',
    'BufEnter',
}

for _, event in ipairs(notifyOnEvents) do
    vim.api.nvim_create_autocmd(event, {
        group = vim.api.nvim_create_augroup('masar3141/masarpoon/' .. event, { clear = true }),
        callback = function() monsterpoon:updateAndNotify() end
    })
end
