-- PlowClientApi (2026-10-05, Claude): tiny bridge between the client scripts of the snowplow loop.
-- PlowShopClient fills in the functions and the state; PlowGarageClient (the garage place) calls them.
local Api = {State = nil}
Api.Changed = Instance.new("BindableEvent")
Api.OpenCard = function() end   -- (slotKey) open the offer card for pedestal "1" / "2" / "3" or "Reserved"
Api.Roll = function() end       -- (slotKey) roll / reroll that pedestal
Api.OpenBuild = function() end  -- toggle the build (garage) window
Api.Go = function() end         -- teleport to the garage / back to the lobby
Api.Revealed = function() end   -- (slotKey, rank) a roll finished on that pedestal: the garage plays the reveal in the world
Api.CardTarget = function() return nil end -- which offer card is open ("1" / "2" / "3" / "Reserved"), or nil
Api.CloseCard = function() end
Api.Toast = function() end      -- (text, colour)
return Api
