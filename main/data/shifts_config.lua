local M = {}

M.SHIFT_TYPES = {
    MORNING = "MORNING",
    NIGHT = "NIGHT"
}

M.SHIFTS = {
    [M.SHIFT_TYPES.MORNING] = {
        id = "MORNING",
        name = "Ca Sáng Sớm (6:00 - 8:00)",
        spawn_delay_min = 1.5,
        spawn_delay_max = 3.0,
        target_customers = 6,
        quick_serve_threshold = 6.0,
        quick_tip_amount = 4000,
        perfect_bonus_multiplier = 1.0
    },
    [M.SHIFT_TYPES.NIGHT] = {
        id = "NIGHT",
        name = "Ca Đêm Muộn (20:00 - 23:00)",
        spawn_delay_min = 4.0,
        spawn_delay_max = 6.5,
        target_customers = 5,
        quick_serve_threshold = 0.0,
        quick_tip_amount = 0,
        perfect_bonus_multiplier = 1.5
    }
}

return M