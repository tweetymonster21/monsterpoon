local sess = require("monstersess")
local poon = require("monsterpoon")

sess:scheduleAfterSessionLoads(function() poon:updateAndNotify() end)
