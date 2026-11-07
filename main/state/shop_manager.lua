local ShopCatalog = require("main.data.shop_catalog")
local SaveManager = require("main.state.save_manager")
local M = {}

function M.is_upgrade_purchased(upgrade_id)
    local upg = ShopCatalog.ITEMS[upgrade_id]
    if not upg then return false end
    if upg.type == ShopCatalog.UPGRADE_TYPES.UNLOCK_ITEM then
        return SaveManager.is_item_unlocked(upg.target_id)
    elseif upg.type == ShopCatalog.UPGRADE_TYPES.GRILL_SLOT then
        return SaveManager.save_data.max_grill_slots >= upg.target_slot_count
    end
    return false
end

function M.buy_upgrade(upgrade_id)
    local upg = ShopCatalog.ITEMS[upgrade_id]
    if not upg then return { success = false, reason = "INVALID_UPGRADE" } end
    if M.is_upgrade_purchased(upgrade_id) then return { success = false, reason = "ALREADY_OWNED" } end
    if not SaveManager.spend_money(upg.cost) then return { success = false, reason = "NOT_ENOUGH_MONEY" } end

    if upg.type == ShopCatalog.UPGRADE_TYPES.UNLOCK_ITEM then
        SaveManager.unlock_item(upg.target_id)
    elseif upg.type == ShopCatalog.UPGRADE_TYPES.GRILL_SLOT then
        SaveManager.save_data.max_grill_slots = upg.target_slot_count
        SaveManager.save_game()
    end
    return { success = true, new_balance = SaveManager.save_data.player_money }
end

return M