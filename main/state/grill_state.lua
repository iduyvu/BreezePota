local Catalog = require("main.data.items_catalog")
local M = {}

M.SLOT_STATUS = { EMPTY = "EMPTY", COOKING_SIDE_A = "SIDE_A", COOKING_SIDE_B = "SIDE_B" }
M.QUALITY_GRADE = { UNDERCOOKED = "UNDERCOOKED", GOOD = "GOOD", PERFECT = "PERFECT", CHARRED = "CHARRED" }

M.grill = { coal_heat_multiplier = 1.0, max_slots = 4, slots = {} }

local function create_empty_slot(idx)
    return {
        index = idx,
        status = M.SLOT_STATUS.EMPTY,
        item_id = nil,
        side_a = { progress = 0.0, locked_grade = nil },
        side_b = { progress = 0.0, locked_grade = nil },
        modifier_applied = false
    }
end

function M.init_grill(num_slots)
    M.grill.max_slots = num_slots or 4
    M.grill.slots = {}
    for i = 1, M.grill.max_slots do
        M.grill.slots[i] = create_empty_slot(i)
    end
end

local function evaluate_grade(progress, thresholds)
    if progress < thresholds.warm then return M.QUALITY_GRADE.UNDERCOOKED
    elseif progress >= thresholds.sweet_spot_min and progress <= thresholds.sweet_spot_max then return M.QUALITY_GRADE.PERFECT
    elseif progress > thresholds.charred then return M.QUALITY_GRADE.CHARRED
    else return M.QUALITY_GRADE.GOOD end
end

function M.place_item(slot_index, item_id)
    local slot = M.grill.slots[slot_index]
    if slot and slot.status == M.SLOT_STATUS.EMPTY then
        slot.status = M.SLOT_STATUS.COOKING_SIDE_A
        slot.item_id = item_id
        slot.side_a.progress = 0.0
        slot.side_b.progress = 0.0
        slot.modifier_applied = false
        return true
    end
    return false
end

-- Quết mỡ hành vào ô đầu tiên đang nướng Bắp ở Mặt B
function M.apply_scallion_to_first_valid_corn()
    for i = 1, M.grill.max_slots do
        local slot = M.grill.slots[i]
        if slot.status == M.SLOT_STATUS.COOKING_SIDE_B and slot.item_id == "corn_glutinous" and not slot.modifier_applied then
            slot.item_id = "corn_scallion"
            slot.modifier_applied = true
            return i
        end
    end
    return nil
end

function M.update_grill(dt)
    local heat = M.grill.coal_heat_multiplier
    for i = 1, M.grill.max_slots do
        local slot = M.grill.slots[i]
        if slot.status ~= M.SLOT_STATUS.EMPTY then
            local cfg = Catalog.ITEMS[slot.item_id]
            local delta = (dt * heat) / cfg.cook_duration_per_side
            if slot.status == M.SLOT_STATUS.COOKING_SIDE_A then
                slot.side_a.progress = slot.side_a.progress + delta
            elseif slot.status == M.SLOT_STATUS.COOKING_SIDE_B then
                slot.side_b.progress = slot.side_b.progress + delta
            end
        end
    end
end

function M.interact_slot(slot_index)
    local slot = M.grill.slots[slot_index]
    if not slot or slot.status == M.SLOT_STATUS.EMPTY then return nil end
    local cfg = Catalog.ITEMS[slot.item_id]

    if slot.status == M.SLOT_STATUS.COOKING_SIDE_A then
        slot.side_a.locked_grade = evaluate_grade(slot.side_a.progress, cfg.thresholds)
        slot.status = M.SLOT_STATUS.COOKING_SIDE_B
        return { action = "FLIPPED", grade_a = slot.side_a.locked_grade }
    elseif slot.status == M.SLOT_STATUS.COOKING_SIDE_B then
        slot.side_b.locked_grade = evaluate_grade(slot.side_b.progress, cfg.thresholds)
        local product = {
            item_id = slot.item_id,
            grade_a = slot.side_a.locked_grade,
            grade_b = slot.side_b.locked_grade,
            is_perfect = (slot.side_a.locked_grade == M.QUALITY_GRADE.PERFECT and slot.side_b.locked_grade == M.QUALITY_GRADE.PERFECT),
            modifier_ok = (cfg.required_modifier == Catalog.MODIFIER_TYPES.NONE) or slot.modifier_applied
        }
        M.grill.slots[slot_index] = create_empty_slot(slot_index)
        return { action = "HARVESTED", product = product }
    end
end

return M