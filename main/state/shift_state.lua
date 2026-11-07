local ShiftsConfig = require("main.data.shifts_config")
local CustomersCatalog = require("main.data.customers_catalog")
local ItemsCatalog = require("main.data.items_catalog")
local GrillState = require("main.state.grill_state")
local SaveManager = require("main.state.save_manager")

local M = {}

M.SESSION_STATUS = {
    WAITING_NEXT_CUSTOMER = "WAITING",
    CUSTOMER_ORDERING = "ORDERING",
    CUSTOMER_LEAVING = "LEAVING",
    SHIFT_ENDED = "SHIFT_ENDED"
}

M.current_shift = {
    day_number = 1,
    shift_type = ShiftsConfig.SHIFT_TYPES.MORNING,
    status = M.SESSION_STATUS.WAITING_NEXT_CUSTOMER,
    customers_served = 0,
    shift_revenue = 0,
    perfect_count = 0,
    spawn_timer = 2.0,
    active_customer = nil
}

function M.start_shift(day_num, shift_type)
    local cfg = ShiftsConfig.SHIFTS[shift_type]
    M.current_shift.day_number = day_num
    M.current_shift.shift_type = shift_type
    M.current_shift.status = M.SESSION_STATUS.WAITING_NEXT_CUSTOMER
    M.current_shift.customers_served = 0
    M.current_shift.shift_revenue = 0
    M.current_shift.perfect_count = 0
    M.current_shift.spawn_timer = cfg.spawn_delay_min
    M.current_shift.active_customer = nil
end

function M.spawn_customer()
    local shift_type = M.current_shift.shift_type
    local valid_ids = {}
    for id, data in pairs(CustomersCatalog.ARCHETYPES) do
        if data.allowed_shifts[shift_type] then table.insert(valid_ids, id) end
    end

    local chosen_id = valid_ids[math.random(#valid_ids)]
    local archetype = CustomersCatalog.ARCHETYPES[chosen_id]

    -- Lọc các món khách thích mà người chơi ĐÃ MỞ KHÓA
    local available_items = {}
    for _, item_id in ipairs(archetype.preferred_items) do
        if SaveManager.is_item_unlocked(item_id) then
            table.insert(available_items, item_id)
        end
    end
    local wanted_id = available_items[math.random(#available_items)]
    local greetings = archetype.dialogues[shift_type].greetings

    M.current_shift.active_customer = {
        archetype_id = chosen_id,
        wanted_item_id = wanted_id,
        wait_time = 0.0,
        current_dialogue = greetings[math.random(#greetings)]
    }
    M.current_shift.status = M.SESSION_STATUS.CUSTOMER_ORDERING
end

function M.serve_active_customer(finished_product)
    local cust = M.current_shift.active_customer
    if not cust or M.current_shift.status ~= M.SESSION_STATUS.CUSTOMER_ORDERING then
        return { success = false, reason = "NO_CUSTOMER" }
    end
    if finished_product.item_id ~= cust.wanted_item_id then
        return { success = false, reason = "WRONG_ITEM" }
    end

    local item_cfg = ItemsCatalog.ITEMS[finished_product.item_id]
    local shift_cfg = ShiftsConfig.SHIFTS[M.current_shift.shift_type]
    local archetype = CustomersCatalog.ARCHETYPES[cust.archetype_id]

    local total_pay = item_cfg.base_price
    local reaction_key = "GOOD"

    if finished_product.is_perfect and finished_product.modifier_ok then
        total_pay = total_pay + math.floor(item_cfg.perfect_bonus * shift_cfg.perfect_bonus_multiplier)
        reaction_key = "PERFECT"
        M.current_shift.perfect_count = M.current_shift.perfect_count + 1
    elseif finished_product.grade_a == GrillState.QUALITY_GRADE.CHARRED
        or finished_product.grade_b == GrillState.QUALITY_GRADE.CHARRED then
        reaction_key = "CHARRED"
    end

    local got_quick_tip = false
    if shift_cfg.quick_serve_threshold > 0 and cust.wait_time <= shift_cfg.quick_serve_threshold then
        total_pay = total_pay + shift_cfg.quick_tip_amount
        got_quick_tip = true
    end

    M.current_shift.shift_revenue = M.current_shift.shift_revenue + total_pay
    M.current_shift.customers_served = M.current_shift.customers_served + 1
    cust.current_dialogue = archetype.dialogues[M.current_shift.shift_type].reactions[reaction_key]
    M.current_shift.status = M.SESSION_STATUS.CUSTOMER_LEAVING

    return {
        success = true,
        earned = total_pay,
        reaction_type = reaction_key,
        quick_tip = got_quick_tip,
        dialogue = cust.current_dialogue
    }
end

return M