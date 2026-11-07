local M = {}

M.MODIFIER_TYPES = {
    NONE = "NONE",
    SCALLION_OIL = "SCALLION_OIL"
}

M.ITEMS = {
    ["sweet_potato_honey"] = {
        id = "sweet_potato_honey",
        name = "Khoai Lang Mật",
        base_price = 15000,
        perfect_bonus = 5000,
        cook_duration_per_side = 8.0,
        thresholds = { warm = 0.40, sweet_spot_min = 0.75, sweet_spot_max = 0.92, charred = 1.15 },
        required_modifier = M.MODIFIER_TYPES.NONE
    },
    ["corn_glutinous"] = {
        id = "corn_glutinous",
        name = "Bắp Nếp Nướng",
        base_price = 12000,
        perfect_bonus = 4000,
        cook_duration_per_side = 5.5,
        thresholds = { warm = 0.35, sweet_spot_min = 0.78, sweet_spot_max = 0.90, charred = 1.10 },
        required_modifier = M.MODIFIER_TYPES.NONE
    },
    ["corn_scallion"] = {
        id = "corn_scallion",
        name = "Bắp Nướng Mỡ Hành",
        base_price = 18000,
        perfect_bonus = 6000,
        cook_duration_per_side = 5.5,
        thresholds = { warm = 0.35, sweet_spot_min = 0.78, sweet_spot_max = 0.90, charred = 1.10 },
        required_modifier = M.MODIFIER_TYPES.SCALLION_OIL
    }
}

return M