-- ContractRegistry (2026-10-05, Claude): shared server state between ContractService and SnowFieldService.
-- Fields[player][fieldId] = {def = {Id, Width, Depth, SnowPerPhase, Style, Stage}, origin, maxHP, tough, s = {phases, hp, pending}, onTile}
-- Contract fields are personal snow fields of one player; SnowFieldService clears them with the real blade footprint and never regrows them.
-- 2026-10-05 (arena): ContractService fills HasJob(player) / Cancel(player) so the Bumper Arena can end a job through the normal cancellation.
return {Fields = {}, HasJob = function() return false end, Cancel = function() return false end}
