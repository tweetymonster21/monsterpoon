local monsterpoon = require('monsterpoon')

vim.api.nvim_create_autocmd({ 'VimEnter', 'BufEnter' }, {
    group = vim.api.nvim_create_augroup('tweetymonster21/masarpoon/update_and_notify', { clear = true }),
    callback = function()
        monsterpoon:updateAndNotify()
    end
})
