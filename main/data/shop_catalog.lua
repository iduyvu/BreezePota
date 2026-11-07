local M = {}

M.UPGRADE_TYPES = {
    UNLOCK_ITEM = "UNLOCK_ITEM",
    GRILL_SLOT = "GRILL_SLOT"
}

M.ITEMS = {
    ["upgrade_corn_scallion"] = {
        id = "upgrade_corn_scallion",
        name = "Công thức: Bắp Nướng Mỡ Hành",
        cost = 35000,
        type = M.UPGRADE_TYPES.UNLOCK_ITEM,
        target_id = "corn_scallion"
    },
    ["upgrade_slot_5"] = {
        id = "upgrade_slot_5",
        name = "Mở rộng Vỉ Nướng (Ô số 5)",
        cost = 50000,
        type = M.UPGRADE_TYPES.GRILL_SLOT,
        target_slot_count = 5
    },
    ["upgrade_slot_6"] = {
        id = "upgrade_slot_6",
        name = "Nâng cấp Vỉ Nướng Tối Đa (Ô số 6)",
        cost = 100000,
        type = M.UPGRADE_TYPES.GRILL_SLOT,
        target_slot_count = 6
    }
}

return M