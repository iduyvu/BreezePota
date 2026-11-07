local M = {}
local SAVE_FILE_NAME = "cozy_street_food_save"

local DEFAULT_SAVE_DATA = {
    player_money = 50000,
    current_day = 1,
    max_grill_slots = 4,
    unlocked_items = {
        ["sweet_potato_honey"] = true,
        ["corn_glutinous"]     = true,
        ["corn_scallion"]      = false
    },
    settings = { bgm_volume = 0.8, sfx_volume = 1.0 }
}

M.save_data = nil

function M.clone_table(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[M.clone_table(k)] = M.clone_table(v) end
    return copy
end

function M.load_game()
    local path = sys.get_save_file("cozy_street_food", SAVE_FILE_NAME)
    local data = sys.load(path)
    if not data or next(data) == nil then
        M.save_data = M.clone_table(DEFAULT_SAVE_DATA)
        M.save_game()
    else
        M.save_data = data
    end
    return M.save_data
end

function M.save_game()
    if not M.save_data then return false end
    local path = sys.get_save_file("cozy_street_food", SAVE_FILE_NAME)
    return sys.save(path, M.save_data)
end

function M.add_money(amount) M.save_data.player_money = M.save_data.player_money + amount end

function M.spend_money(amount)
    if M.save_data.player_money >= amount then
        M.save_data.player_money = M.save_data.player_money - amount
        return true
    end
    return false
end

function M.unlock_item(item_id)
    M.save_data.unlocked_items[item_id] = true
    M.save_game()
end

function M.is_item_unlocked(item_id)
    return M.save_data.unlocked_items[item_id] == true
end

function M.advance_to_next_day()
    M.save_data.current_day = M.save_data.current_day + 1
    M.save_game()
end

return M