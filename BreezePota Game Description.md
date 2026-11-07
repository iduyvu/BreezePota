Dưới đây là bản **Tài liệu Thiết kế Game & Đặc tả Kỹ thuật (GDD & Technical Specification Document)** hoàn chỉnh, được viết theo chuẩn kỹ thuật phần mềm.


Markdown

````
# TECHNICAL SPECIFICATION & GAME DESIGN DOCUMENT (GDD)
**Project Name:** Cozy Street Grill (Xe Khoai & Bắp Nướng Vỉa Hè)  
**Target Engine:** Defold Engine (2D, Lua 5.1/LuaJIT, HTML5/WebAssembly Target)  
**Resolution & Aspect Ratio:** 1280 x 720 (16:9 Landscape, Scale Mode: `Fit`)  
**Input Method:** 100% Single-Pointer (Mouse Click / Mobile Touch - Action ID: `touch`)  
**Hosting & Deployment:** Static WebApp on Cloudflare Pages  

---

## 1. TỔNG QUAN DỰ ÁN & TRIẾT LÝ THIẾT KẾ (PROJECT OVERVIEW)

### 1.1. Concept cốt lõi
Tựa game mô phỏng bán đồ nướng đường phố Việt Nam (khoai lang mật, bắp nếp nướng, bắp nướng mỡ hành) theo phong cách **Cozy / Chill Reflex Simulation**. Người chơi đứng sau một chiếc xe đẩy vỉa hè cố định, lắng nghe những mẩu chuyện đời thường của khách qua đường và căn chỉnh nhịp lửa để nướng ra những mẻ khoai/bắp thơm ngon nhất.

### 1.2. Nguyên tắc "Cozy Reflex" (Phản xạ Không Áp Lực)
- **Thao tác chế biến có tính nhịp điệu (Timing-based):** Mỗi món nướng có 2 mặt (Mặt A và Mặt B). Người chơi cần quan sát tín hiệu thị giác/khói để click **Lật mặt (Flip)** và **Gắp ra (Harvest)** đúng vào **Vùng Hoàn Hảo (Sweet Spot: 75% – 92%)**.
- **Không trừng phạt nặng nề (Zero-Punishment):** Khách hàng không bao giờ bỏ đi vì chờ lâu. Món nướng quá lửa (>115%) chỉ chuyển sang trạng thái *"Hơi xém cạnh"* (`CHARRED`) — vẫn bán được giá gốc, chỉ mất khoản tiền thưởng hoàn hảo (`perfect_bonus`).

### 1.3. Nhịp điệu 2 Ca Bán Hàng (Dual-Shift Pacing)
Mỗi ngày (`Day`) gồm 2 ca bán hàng với bầu không khí và cơ chế thưởng đối lập:
1. **Ca Sáng Sớm (`MORNING` - 6:00 - 8:00):** Khách đi làm/đi học vội vã, xuất hiện dồn dập (`1.5s - 3.0s`). Nếu giao món trong vòng `6.0s` kể từ lúc khách gọi, người chơi nhận được **Tiền Thưởng Nhanh (`Quick Tip`)**.
2. **Ca Đêm Muộn (`NIGHT` - 20:00 - 23:00):** Phố lên đèn, khách thưa và thong thả (`4.5s - 7.5s`), lời thoại mang chiều sâu tâm lý. Tắt thưởng tốc độ, nhưng **nhân 1.5 lần Tiền Thưởng Hoàn Hảo (`Perfect Bonus Multiplier = 1.5x`)**.

---

## 2. KIẾN TRÚC HỆ THỐNG & CẤU TRÚC THƯ MỤC (SYSTEM ARCHITECTURE)

Hệ thống áp dụng kiến trúc **Data-Driven State Machine**, tách biệt hoàn toàn dữ liệu cấu hình tĩnh (`data/`), máy trạng thái động thuần Lua (`state/`), và lớp hiển thị/tương tác của Defold (`GUI / GO`).

```text
project_root/
├── game.project                   # Cấu hình Display (1280x720), HTML5 Scale Mode (Fit)
├── input/
│   └── game.input_binding         # Map MOUSE_BUTTON_1 -> Action: "touch"
└── main/
    ├── main.collection            # Bootstrap Collection chứa GUI & Sound Bank GO
    ├── workstation.gui            # Toàn bộ Layout màn hình chơi, HUD & Shop Popup
    ├── workstation.gui_script     # Controller kết nối Input, GUI Nodes và State Modules
    ├── smoke.particlefx           # Hiệu ứng khói bay lên trên từng ô nướng
    ├── sounds/                    # Chứa bgm_morning.ogg, bgm_night.ogg, sfx_sizzle.wav, sfx_coin.wav
    ├── data/                      # TẦNG DỮ LIỆU TĨNH (READ-ONLY CONFIGS)
    │   ├── items_catalog.lua      # Thông số nhiệt học, ngưỡng chín, giá bán của từng món
    │   ├── shifts_config.lua      # Cấu hình nhịp độ, màu sắc, hệ số thưởng Ca Sáng/Tối
    │   ├── customers_catalog.lua  # Hồ sơ khách hàng & kịch bản hội thoại phân nhánh
    │   └── shop_catalog.lua       # Danh mục nâng cấp vỉ nướng & công thức mới
    └── state/                     # TẦNG TRẠNG THÁI ĐỘNG (PURE LUA STATE MACHINES)
        ├── grill_state.lua        # Quản lý tiến trình nhiệt độ 6 ô nướng & chấm điểm
        ├── shift_state.lua        # Quản lý hàng đợi khách, giao dịch & chuyển ca
        ├── save_manager.lua       # Đọc/ghi dữ liệu bền vững qua sys.save / LocalStorage
        ├── shop_manager.lua       # Xử lý giao dịch mua nâng cấp
        └── audio_manager.lua      # Điều phối BGM/SFX & mở khóa WebAudio Autoplay
````

## 3. ĐẶC TẢ BỐ CỤC GIAO DIỆN (GUI WIREFRAME & NODE HIERARCHY)

File `main/workstation.gui` sử dụng độ phân giải `1280x720`, chia làm 3 phân vùng không gian và 1 lớp Popup:
### 3.1. Danh sách Nodes trong `workstation.gui`

_(Lưu ý cho Agent: Mọi Node loại `Text` phải gán `font: "vn_font"` hỗ trợ UTF-8 tiếng Việt và bật `line_break: true`)_

  
|**Node ID**|**Parent Node**|**Type**|**Position (X, Y)**|**Size (W, H)**|**Mô tả & Chức năng**|
|---|---|---|---|---|---|
|`street_bg`|_(Root)_|Box|`640, 540`|`1280, 360`|Nền đường phố nửa trên màn hình|
|`table_bg`|_(Root)_|Box|`640, 180`|`1280, 360`|Mặt bàn gỗ xe đẩy nửa dưới màn hình|
|`hud_info_text`|_(Root)_|Text|`640, 690`|`1200, 40`|Hiển thị Ngày, Ca, Số khách, Doanh thu, Tổng ví|
|`status_text`|_(Root)_|Text|`640, 645`|`1000, 36`|Thông báo phản hồi thao tác tức thời|
|`customer_box`|_(Root)_|Box|`640, 450`|`120, 180`|Khối hiển thị Khách hàng đứng trước quầy|
|`dialogue_bg`|_(Root)_|Box|`640, 580`|`680, 90`|Khung bong bóng hội thoại của khách|
|`dialogue_text`|`dialogue_bg`|Text|`0, 0`|`650, 80`|Lời thoại khách + Món khách đang gọi|
|`basket_potato`|_(Root)_|Box|`150, 260`|`160, 85`|Rổ Khoai Lang Mật (`sweet_potato_honey`)|
|`basket_corn`|_(Root)_|Box|`150, 155`|`160, 85`|Rổ Bắp Nếp (`corn_glutinous`)|
|`bowl_scallion`|_(Root)_|Box|`1110, 200`|`150, 100`|Chén Mỡ Hành (Click để quết lên Bắp ở Mặt B)|
|`grill_base`|_(Root)_|Box|`640, 195`|`540, 250`|Khung bếp than hồng chứa 6 ô nướng|
|`slot_1` .. `slot_3`|_(Root)_|Box|`X: 480, 640, 800` / `Y: 250`|`135, 90`|Hàng trên của vỉ nướng (Ô 1, 2, 3)|
|`slot_4` .. `slot_6`|_(Root)_|Box|`X: 480, 640, 800` / `Y: 140`|`135, 90`|Hàng dưới của vỉ nướng (Ô 4, 5, 6)|
|`slot_[1..6]_text`|`slot_[1..6]`|Text|`0, 0`|`130, 85`|Hiển thị Tên món, Mặt A/B, % nhiệt độ|
|`slot_[1..6]_smoke`|`slot_[1..6]`|Particlefx|`0, 15`|`-`|Gắn `smoke.particlefx`|
|`warming_tray`|_(Root)_|Box|`640, 42`|`260, 56`|Khay giữ ấm 1 món đã chín|
|`warming_text`|`warming_tray`|Text|`0, 0`|`240, 50`|Trạng thái món trong Khay giữ ấm|
|`summary_popup`|_(Root)_|Box|`640, 360`|`760, 520`|Popup Tổng kết & Cửa hàng cuối ca|
|`summary_title`|`summary_popup`|Text|`0, 210`|`700, 40`|Tiêu đề bảng tổng kết|
|`summary_stats`|`summary_popup`|Text|`0, 125`|`680, 110`|Thống kê doanh thu ca & tổng tiền|
|`btn_buy_slot5`|`summary_popup`|Box|`0, 25`|`620, 55`|Nút mua Ô nướng số 5 (chứa `txt_buy_slot5`)|
|`btn_buy_slot6`|`summary_popup`|Box|`0, -45`|`620, 55`|Nút mua Ô nướng số 6 (chứa `txt_buy_slot6`)|
|`btn_buy_scallion`|`summary_popup`|Box|`0, -115`|`620, 55`|Nút mua Công thức Bắp Mỡ Hành (chứa `txt_buy_scallion`)|
|`btn_next_shift`|`summary_popup`|Box|`0, -200`|`340, 60`|Nút qua Ca tiếp theo (chứa `txt_next_shift`)|

## 4. MÃ NGUỒN CHUẨN CỦA CÁC MODULE (REFERENCE IMPLEMENTATION)

### 4.1. Danh mục Món nướng (`main/data/items_catalog.lua`)

Lua

```
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
```

### 4.2. Cấu hình Ca Sáng / Ca Tối (`main/data/shifts_config.lua`)

Lua

```
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
```

### 4.3. Hồ sơ Khách hàng & Hội thoại (`main/data/customers_catalog.lua`)

Lua

```
local Shifts = require("main.data.shifts_config")
local M = {}

M.ARCHETYPES = {
    ["office_worker"] = {
        id = "office_worker",
        name = "Nhân viên văn phòng",
        allowed_shifts = { [Shifts.SHIFT_TYPES.MORNING] = true, [Shifts.SHIFT_TYPES.NIGHT] = true },
        preferred_items = { "sweet_potato_honey", "corn_glutinous", "corn_scallion" },
        dialogues = {
            [Shifts.SHIFT_TYPES.MORNING] = {
                greetings = {
                    "Cho mình một phần nhanh nhé, sắp tới giờ chấm công rồi!",
                    "Sáng đi ngang mùi khoai thơm quá không kìm lòng được..."
                },
                reactions = {
                    PERFECT = "Nóng hổi xuất sắc! Cảm ơn bác, ngày mới có năng lượng hẳn!",
                    GOOD = "Cảm ơn nhé, mình chạy lên văn phòng đây!",
                    CHARRED = "Hơi xém một chút nhưng không sao, mình đang vội!"
                }
            },
            [Shifts.SHIFT_TYPES.NIGHT] = {
                greetings = {
                    "Nay tăng ca về muộn quá, còn củ khoai nào nóng không bác?",
                    "Cả ngày nhìn màn hình mỏi mắt thật, đứng cạnh bếp than của bác dễ chịu ghê."
                },
                reactions = {
                    PERFECT = "Mật khoai ngọt lịm... Đúng thứ mình cần sau một ngày dài. Gửi bác thêm tiền tip nhé!",
                    GOOD = "Ấm bụng rồi, cảm ơn bác, chúc bác dọn hàng sớm nhé.",
                    CHARRED = "Mùi hơi khét nhẹ nhưng ăn đêm vẫn ngon chán, cảm ơn bác!"
                }
            }
        }
    },
    ["night_student"] = {
        id = "night_student",
        name = "Cô bé học sinh",
        allowed_shifts = { [Shifts.SHIFT_TYPES.NIGHT] = true },
        preferred_items = { "corn_scallion", "sweet_potato_honey" },
        dialogues = {
            [Shifts.SHIFT_TYPES.NIGHT] = {
                greetings = {
                    "Bác ơi, nướng cho cháu một phần thật thơm nhé, cháu vừa tan ca học thêm...",
                    "Trời se lạnh thế này chỉ mong xe hàng của bác vẫn còn sáng đèn."
                },
                reactions = {
                    PERFECT = "Oa, thơm nức mũi luôn! Bác nướng khéo số một phố này đấy ạ!",
                    GOOD = "Dạ cháu cảm ơn bác, cháu về kẻo mẹ mong!",
                    CHARRED = "Hihi hơi cháy xíu nhưng phần ruột vẫn ngọt lắm ạ!"
                }
            }
        }
    }
}

return M
```

### 4.4. Danh mục Cửa hàng Nâng cấp (`main/data/shop_catalog.lua`)

Lua

```
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
```

### 4.5. Máy Trạng thái Lò Nướng (`main/state/grill_state.lua`)

_(Hỗ trợ cả thao tác quết mỡ hành để biến `corn_glutinous` đang nướng ở Mặt B thành `corn_scallion`)_
  
Lua

```
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
```

### 4.6. Quản lý Lưu trữ & Cửa hàng (`main/state/save_manager.lua` & `shop_manager.lua`)

Lua

```
-- File: main/state/save_manager.lua
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
```

Lua

```
-- File: main/state/shop_manager.lua
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
```

### 4.7. Điều phối Ca bán hàng (`main/state/shift_state.lua`)

_(Chỉ cho phép khách gọi những món đã được mở khóa trong `SaveManager`)_

  

Lua

```
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
```

## 5. QUY TRÌNH ĐÓNG GÓI & DEPLOY LÊN CLOUDFLARE PAGES (DEPLOYMENT PIPELINE)

## 6. CÁC FILE CẤU HÌNH GAME VÀ VĂN BẢN CHUẨN :
--> File cấu hình tổng: game.project (Đặt ở thư mục gốc /)
Lua
```
[bootstrap]
main_collection = /main/main.collectionc

[script]
shared_state = 1

[display]
width = 1280
height = 720
high_dpi = 1

[android]
input_method = HiddenInputField

[project]
title = Cozy Street Grill
version = 1.0.0

[html5]
scale_mode = fit
show_fullscreen_button = 0
show_made_with_defold = 0
cssfile = /builtins/manifests/web/dark_theme.css

[input]
game_binding = /input/game.input_bindingc
use_accelerometer = 0
```

--> File cấu hình Chuột & Cảm ứng: input/game.input_binding
Lua
```
mouse_trigger {
  input: MOUSE_BUTTON_1
  action: "touch"
}
touch_trigger {
  input: TOUCH_MULTI
  action: "touch"
}
```

--> File Màn chơi gốc: main/main.collection
Lua
```
name: "main"
scale_along_z: 0
embedded_instances {
  id: "workstation_go"
  data: "components {\n"
  "  id: \"gui\"\n"
  "  component: \"/main/workstation.gui\"\n"
  "  position {\n"
  "    x: 0.0\n"
  "    y: 0.0\n"
  "    z: 0.0\n"
  "  }\n"
  "  rotation {\n"
  "    x: 0.0\n"
  "    y: 0.0\n"
  "    z: 0.0\n"
  "    w: 1.0\n"
  "  }\n"
  "}\n"
  ""
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
  scale3 {
    x: 1.0
    y: 1.0
    z: 1.0
  }
}
```

--> Bonus: Nội dung văn bản chuẩn của main/smoke.particlefx

Lua
```
emitters {
  id: "emitter"
  mode: PLAY_MODE_LOOP
  space: EMISSION_SPACE_WORLD
  type: EMITTER_TYPE_2DCONE
  max_particle_count: 64
  material: "/builtins/materials/gui.material"
  tile_source: "/builtins/graphics/particle_blob.tilesource"
  animation: "anim"
  blend_mode: BLEND_MODE_ALPHA
  duration: 1.0
  start_delay: 0.0
  size_mode: SIZE_MODE_MANUAL
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
  properties {
    key: "PROPERTY_TYPE_SPAWN_RATE"
    points {
      x: 0.0
      y: 6.0
      t_x: 1.0
      t_y: 0.0
    }
    spread: 1.0
  }
  properties {
    key: "PROPERTY_TYPE_PARTICLE_LIFE_TIME"
    points {
      x: 0.0
      y: 1.5
      t_x: 1.0
      t_y: 0.0
    }
    spread: 0.2
  }
  properties {
    key: "PROPERTY_TYPE_INITIAL_SPEED"
    points {
      x: 0.0
      y: 45.0
      t_x: 1.0
      t_y: 0.0
    }
    spread: 10.0
  }
  properties {
    key: "PROPERTY_TYPE_INITIAL_SIZE"
    points {
      x: 0.0
      y: 25.0
      t_x: 1.0
      t_y: 0.0
    }
    spread: 5.0
  }
  properties {
    key: "PROPERTY_TYPE_EMITTER_SIZE_X"
    points {
      x: 0.0
      y: 70.0
      t_x: 1.0
      t_y: 0.0
    }
    spread: 0.0
  }
  properties {
    key: "PROPERTY_TYPE_EMITTER_SIZE_Y"
    points {
      x: 0.0
      y: 15.0
      t_x: 1.0
      t_y: 0.0
    }
    spread: 0.0
  }
  particle_properties {
    key: "PARTICLE_PROPERTY_TYPE_COLOR_R"
    points {
      x: 0.0
      y: 0.9
      t_x: 1.0
      t_y: 0.0
    }
  }
  particle_properties {
    key: "PARTICLE_PROPERTY_TYPE_COLOR_G"
    points {
      x: 0.0
      y: 0.9
      t_x: 1.0
      t_y: 0.0
    }
  }
  particle_properties {
    key: "PARTICLE_PROPERTY_TYPE_COLOR_B"
    points {
      x: 0.0
      y: 0.9
      t_x: 1.0
      t_y: 0.0
    }
  }
  particle_properties {
    key: "PARTICLE_PROPERTY_TYPE_COLOR_A"
    points {
      x: 0.0
      y: 0.45
      t_x: 1.0
      t_y: -0.45
    }
    points {
      x: 1.0
      y: 0.0
      t_x: 1.0
      t_y: 0.0
    }
  }
}
```

--> Nội dung văn bản chuẩn của main/workstation.gui
Lua
```
script: "/main/workstation.gui_script"
fonts {
  name: "default"
  font: "/builtins/fonts/default.font"
}
particlefxs {
  name: "smoke"
  particlefx: "/main/smoke.particlefx"
}
nodes {
  position { x: 640.0 y: 540.0 }
  size { x: 1280.0 y: 360.0 }
  color { x: 0.15 y: 0.17 z: 0.27 }
  type: TYPE_BOX
  id: "street_bg"
  inherit_alpha: true
}
nodes {
  position { x: 640.0 y: 180.0 }
  size { x: 1280.0 y: 360.0 }
  color { x: 0.36 y: 0.25 z: 0.2 }
  type: TYPE_BOX
  id: "table_bg"
  inherit_alpha: true
}
nodes {
  position { x: 640.0 y: 690.0 }
  size { x: 1200.0 y: 40.0 }
  color { x: 1.0 y: 0.84 z: 0.0 }
  type: TYPE_TEXT
  text: "[Ngày 1 - Ca Sáng]"
  font: "default"
  id: "hud_info_text"
  inherit_alpha: true
}
nodes {
  position { x: 640.0 y: 645.0 }
  size { x: 1100.0 y: 36.0 }
  type: TYPE_TEXT
  text: "Bếp đã đỏ lửa!"
  font: "default"
  id: "status_text"
  inherit_alpha: true
}
nodes {
  position { x: 640.0 y: 450.0 }
  size { x: 120.0 y: 180.0 }
  color { x: 0.2 y: 0.6 z: 0.86 }
  type: TYPE_BOX
  id: "customer_box"
  inherit_alpha: true
}
nodes {
  position { x: 640.0 y: 580.0 }
  size { x: 680.0 y: 90.0 }
  color { x: 0.98 y: 0.98 z: 0.98 }
  type: TYPE_BOX
  id: "dialogue_bg"
  inherit_alpha: true
}
nodes {
  size { x: 650.0 y: 80.0 }
  color { x: 0.1 y: 0.15 z: 0.2 }
  type: TYPE_TEXT
  text: "Lời thoại khách hàng..."
  line_break: true
  font: "default"
  id: "dialogue_text"
  parent: "dialogue_bg"
  inherit_alpha: true
}
nodes {
  position { x: 150.0 y: 260.0 }
  size { x: 170.0 y: 85.0 }
  color { x: 0.56 y: 0.27 z: 0.68 }
  type: TYPE_BOX
  id: "basket_potato"
  inherit_alpha: true
}
nodes {
  size { x: 160.0 y: 75.0 }
  type: TYPE_TEXT
  text: "RỔ KHOAI MẬT\n(Click đặt lên vỉ)"
  line_break: true
  font: "default"
  id: "txt_basket_potato"
  parent: "basket_potato"
  inherit_alpha: true
}
nodes {
  position { x: 150.0 y: 145.0 }
  size { x: 170.0 y: 85.0 }
  color { x: 0.85 y: 0.65 z: 0.1 }
  type: TYPE_BOX
  id: "basket_corn"
  inherit_alpha: true
}
nodes {
  size { x: 160.0 y: 75.0 }
  type: TYPE_TEXT
  text: "RỔ BẮP NẾP\n(Click đặt lên vỉ)"
  line_break: true
  font: "default"
  id: "txt_basket_corn"
  parent: "basket_corn"
  inherit_alpha: true
}
nodes {
  position { x: 1110.0 y: 200.0 }
  size { x: 170.0 y: 105.0 }
  color { x: 0.18 y: 0.55 z: 0.34 }
  type: TYPE_BOX
  id: "bowl_scallion"
  inherit_alpha: true
}
nodes {
  size { x: 160.0 y: 95.0 }
  type: TYPE_TEXT
  text: "CHÉN MỠ HÀNH\n[Chưa mở khóa]"
  line_break: true
  font: "default"
  id: "bowl_scallion_text"
  parent: "bowl_scallion"
  inherit_alpha: true
}
nodes {
  position { x: 640.0 y: 195.0 }
  size { x: 540.0 y: 250.0 }
  color { x: 0.5 y: 0.1 z: 0.1 }
  type: TYPE_BOX
  id: "grill_base"
  inherit_alpha: true
}
nodes {
  position { x: 480.0 y: 250.0 }
  size { x: 135.0 y: 90.0 }
  color { x: 0.2 y: 0.2 z: 0.2 }
  type: TYPE_BOX
  id: "slot_1"
  inherit_alpha: true
}
nodes {
  size { x: 130.0 y: 85.0 }
  type: TYPE_TEXT
  text: "Ô 1\n[Trống]"
  line_break: true
  font: "default"
  id: "slot_1_text"
  parent: "slot_1"
  inherit_alpha: true
}
nodes {
  position { x: 0.0 y: 15.0 }
  type: TYPE_PARTICLEFX
  id: "slot_1_smoke"
  parent: "slot_1"
  inherit_alpha: true
  particlefx: "smoke"
}
nodes {
  position { x: 640.0 y: 250.0 }
  size { x: 135.0 y: 90.0 }
  color { x: 0.2 y: 0.2 z: 0.2 }
  type: TYPE_BOX
  id: "slot_2"
  inherit_alpha: true
}
nodes {
  size { x: 130.0 y: 85.0 }
  type: TYPE_TEXT
  text: "Ô 2\n[Trống]"
  line_break: true
  font: "default"
  id: "slot_2_text"
  parent: "slot_2"
  inherit_alpha: true
}
nodes {
  position { x: 0.0 y: 15.0 }
  type: TYPE_PARTICLEFX
  id: "slot_2_smoke"
  parent: "slot_2"
  inherit_alpha: true
  particlefx: "smoke"
}
nodes {
  position { x: 800.0 y: 250.0 }
  size { x: 135.0 y: 90.0 }
  color { x: 0.2 y: 0.2 z: 0.2 }
  type: TYPE_BOX
  id: "slot_3"
  inherit_alpha: true
}
nodes {
  size { x: 130.0 y: 85.0 }
  type: TYPE_TEXT
  text: "Ô 3\n[Trống]"
  line_break: true
  font: "default"
  id: "slot_3_text"
  parent: "slot_3"
  inherit_alpha: true
}
nodes {
  position { x: 0.0 y: 15.0 }
  type: TYPE_PARTICLEFX
  id: "slot_3_smoke"
  parent: "slot_3"
  inherit_alpha: true
  particlefx: "smoke"
}
nodes {
  position { x: 480.0 y: 140.0 }
  size { x: 135.0 y: 90.0 }
  color { x: 0.2 y: 0.2 z: 0.2 }
  type: TYPE_BOX
  id: "slot_4"
  inherit_alpha: true
}
nodes {
  size { x: 130.0 y: 85.0 }
  type: TYPE_TEXT
  text: "Ô 4\n[Trống]"
  line_break: true
  font: "default"
  id: "slot_4_text"
  parent: "slot_4"
  inherit_alpha: true
}
nodes {
  position { x: 0.0 y: 15.0 }
  type: TYPE_PARTICLEFX
  id: "slot_4_smoke"
  parent: "slot_4"
  inherit_alpha: true
  particlefx: "smoke"
}
nodes {
  position { x: 640.0 y: 140.0 }
  size { x: 135.0 y: 90.0 }
  color { x: 0.12 y: 0.12 z: 0.12 }
  type: TYPE_BOX
  id: "slot_5"
  inherit_alpha: true
}
nodes {
  size { x: 130.0 y: 85.0 }
  type: TYPE_TEXT
  text: "Ô 5\n[Khóa]"
  line_break: true
  font: "default"
  id: "slot_5_text"
  parent: "slot_5"
  inherit_alpha: true
}
nodes {
  position { x: 0.0 y: 15.0 }
  type: TYPE_PARTICLEFX
  id: "slot_5_smoke"
  parent: "slot_5"
  inherit_alpha: true
  particlefx: "smoke"
}
nodes {
  position { x: 800.0 y: 140.0 }
  size { x: 135.0 y: 90.0 }
  color { x: 0.12 y: 0.12 z: 0.12 }
  type: TYPE_BOX
  id: "slot_6"
  inherit_alpha: true
}
nodes {
  size { x: 130.0 y: 85.0 }
  type: TYPE_TEXT
  text: "Ô 6\n[Khóa]"
  line_break: true
  font: "default"
  id: "slot_6_text"
  parent: "slot_6"
  inherit_alpha: true
}
nodes {
  position { x: 0.0 y: 15.0 }
  type: TYPE_PARTICLEFX
  id: "slot_6_smoke"
  parent: "slot_6"
  inherit_alpha: true
  particlefx: "smoke"
}
nodes {
  position { x: 640.0 y: 40.0 }
  size { x: 280.0 y: 56.0 }
  color { x: 0.63 y: 0.32 z: 0.18 }
  type: TYPE_BOX
  id: "warming_tray"
  inherit_alpha: true
}
nodes {
  size { x: 270.0 y: 50.0 }
  type: TYPE_TEXT
  text: "Khay Giữ Ấm: [Trống]"
  line_break: true
  font: "default"
  id: "warming_text"
  parent: "warming_tray"
  inherit_alpha: true
}
nodes {
  position { x: 640.0 y: 360.0 }
  size { x: 760.0 y: 520.0 }
  color { x: 0.17 y: 0.12 z: 0.1 }
  type: TYPE_BOX
  id: "summary_popup"
  inherit_alpha: true
}
nodes {
  position { x: 0.0 y: 210.0 }
  size { x: 700.0 y: 40.0 }
  color { x: 0.95 y: 0.77 z: 0.06 }
  type: TYPE_TEXT
  text: "TỔNG KẾT CA BÁN HÀNG"
  font: "default"
  id: "summary_title"
  parent: "summary_popup"
  inherit_alpha: true
}
nodes {
  position { x: 0.0 y: 125.0 }
  size { x: 680.0 y: 110.0 }
  type: TYPE_TEXT
  text: "Thống kê doanh thu..."
  line_break: true
  font: "default"
  id: "summary_stats"
  parent: "summary_popup"
  inherit_alpha: true
}
nodes {
  position { x: 0.0 y: 25.0 }
  size { x: 620.0 y: 55.0 }
  color { x: 0.15 y: 0.68 z: 0.38 }
  type: TYPE_BOX
  id: "btn_buy_slot5"
  parent: "summary_popup"
  inherit_alpha: true
}
nodes {
  size { x: 600.0 y: 40.0 }
  type: TYPE_TEXT
  text: "Mở rộng Vỉ Nướng (Ô số 5)"
  font: "default"
  id: "txt_buy_slot5"
  parent: "btn_buy_slot5"
  inherit_alpha: true
}
nodes {
  position { x: 0.0 y: -45.0 }
  size { x: 620.0 y: 55.0 }
  color { x: 0.15 y: 0.68 z: 0.38 }
  type: TYPE_BOX
  id: "btn_buy_slot6"
  parent: "summary_popup"
  inherit_alpha: true
}
nodes {
  size { x: 600.0 y: 40.0 }
  type: TYPE_TEXT
  text: "Nâng cấp Vỉ Nướng Tối Đa (Ô số 6)"
  font: "default"
  id: "txt_buy_slot6"
  parent: "btn_buy_slot6"
  inherit_alpha: true
}
nodes {
  position { x: 0.0 y: -115.0 }
  size { x: 620.0 y: 55.0 }
  color { x: 0.15 y: 0.68 z: 0.38 }
  type: TYPE_BOX
  id: "btn_buy_scallion"
  parent: "summary_popup"
  inherit_alpha: true
}
nodes {
  size { x: 600.0 y: 40.0 }
  type: TYPE_TEXT
  text: "Công thức: Bắp Nướng Mỡ Hành"
  font: "default"
  id: "txt_buy_scallion"
  parent: "btn_buy_scallion"
  inherit_alpha: true
}
nodes {
  position { x: 0.0 y: -200.0 }
  size { x: 340.0 y: 60.0 }
  color { x: 0.9 y: 0.49 z: 0.13 }
  type: TYPE_BOX
  id: "btn_next_shift"
  parent: "summary_popup"
  inherit_alpha: true
}
nodes {
  size { x: 320.0 y: 40.0 }
  type: TYPE_TEXT
  text: "Qua Ca Tiếp Theo >>"
  font: "default"
  id: "txt_next_shift"
  parent: "btn_next_shift"
  inherit_alpha: true
}
material: "/builtins/materials/gui.material"
adjust_reference: ADJUST_REFERENCE_PARENT
```

--> Mã nguồn hoàn chỉnh của main/workstation.gui_script
Lua
```
local ItemsCatalog = require("main.data.items_catalog")
local ShiftsConfig = require("main.data.shifts_config")
local CustomersCatalog = require("main.data.customers_catalog")
local ShopCatalog = require("main.data.shop_catalog")
local GrillState = require("main.state.grill_state")
local ShiftState = require("main.state.shift_state")
local SaveManager = require("main.state.save_manager")
local ShopManager = require("main.state.shop_manager")
local ok_audio, AudioManager = pcall(require, "main.state.audio_manager")

local COLORS = {
    EMPTY        = vmath.vector4(0.2, 0.2, 0.2, 1.0),
    LOCKED       = vmath.vector4(0.12, 0.12, 0.12, 0.6),
    RAW          = vmath.vector4(0.4, 0.7, 0.3, 1.0),
    WARM         = vmath.vector4(0.9, 0.8, 0.2, 1.0),
    SWEET_SPOT   = vmath.vector4(1.0, 0.45, 0.0, 1.0),
    CHARRED      = vmath.vector4(0.15, 0.1, 0.1, 1.0),
    MORNING_BG   = vmath.vector4(0.55, 0.68, 0.78, 1.0),
    NIGHT_BG     = vmath.vector4(0.15, 0.17, 0.27, 1.0),
    BTN_BUYABLE  = vmath.vector4(0.15, 0.68, 0.38, 1.0),
    BTN_DISABLED = vmath.vector4(0.35, 0.35, 0.35, 1.0),
    BOWL_ACTIVE  = vmath.vector4(0.18, 0.65, 0.34, 1.0)
}

-- Hàm gọi âm thanh an toàn (Không báo lỗi nếu chưa gắn file .ogg/.wav vào sound_bank)
local function safe_audio(method_name, ...)
    if ok_audio and AudioManager and AudioManager[method_name] then
        pcall(AudioManager[method_name], ...)
    end
end

-- 1. Cập nhật HUD, Màu nền Sáng/Tối và Trạng thái Chén Mỡ Hành
local function refresh_hud_and_theme(self)
    local st = ShiftState.current_shift
    local cfg = ShiftsConfig.SHIFTS[st.shift_type]
    local wallet = SaveManager.save_data.player_money
    
    local hud_str = string.format(
        "[Ngày %d - %s]  |  Khách: %d/%d  |  Doanh thu ca: %d đ  |  Tổng ví: %d đ",
        st.day_number, cfg.name, st.customers_served, cfg.target_customers, st.shift_revenue, wallet
    )
    gui.set_text(self.hud_info_text, hud_str)
    
    if st.shift_type == ShiftsConfig.SHIFT_TYPES.MORNING then
        gui.set_color(self.street_bg, COLORS.MORNING_BG)
    else
        gui.set_color(self.street_bg, COLORS.NIGHT_BG)
    end
    
    -- Cập nhật hiển thị Chén Mỡ Hành theo trạng thái đã mua trong Shop hay chưa
    if SaveManager.is_item_unlocked("corn_scallion") then
        gui.set_color(self.bowl_scallion, COLORS.BOWL_ACTIVE)
        gui.set_text(self.bowl_scallion_text, "CHÉN MỠ HÀNH\n(Click quết Bắp Mặt B)")
    else
        gui.set_color(self.bowl_scallion, COLORS.BTN_DISABLED)
        gui.set_text(self.bowl_scallion_text, "CHÉN MỠ HÀNH\n🔒 [Mở ở Shop]")
    end
    
    safe_audio("play_shift_bgm", st.shift_type)
end

-- 2. Cập nhật Khách hàng & Bong bóng hội thoại
local function refresh_customer_ui(self)
    local st = ShiftState.current_shift
    local cust = st.active_customer
    
    if not cust or st.status == ShiftState.SESSION_STATUS.WAITING_NEXT_CUSTOMER 
                or st.status == ShiftState.SESSION_STATUS.SHIFT_ENDED then
        gui.set_enabled(self.customer_box, false)
        gui.set_enabled(self.dialogue_bg, false)
        return
    end
    
    gui.set_enabled(self.customer_box, true)
    gui.set_enabled(self.dialogue_bg, true)
    
    local arch = CustomersCatalog.ARCHETYPES[cust.archetype_id]
    local wanted_item = ItemsCatalog.ITEMS[cust.wanted_item_id]
    
    if st.status == ShiftState.SESSION_STATUS.CUSTOMER_ORDERING then
        local text = string.format("%s: \"%s\"\n-> [Muốn mua: %s]", arch.name, cust.current_dialogue, wanted_item.name)
        gui.set_text(self.dialogue_text, text)
    elseif st.status == ShiftState.SESSION_STATUS.CUSTOMER_LEAVING then
        local text = string.format("%s: \"%s\"", arch.name, cust.current_dialogue)
        gui.set_text(self.dialogue_text, text)
    end
end

-- 3. Cập nhật Khay Giữ Ấm
local function refresh_warming_tray_ui(self)
    if self.warming_item then
        local item_cfg = ItemsCatalog.ITEMS[self.warming_item.item_id]
        local tag = self.warming_item.is_perfect and " (Hoàn hảo *)" or ""
        gui.set_text(self.warming_text, "Khay ấm: " .. item_cfg.name .. tag .. "\n(Click để giao khách)")
    else
        gui.set_text(self.warming_text, "Khay Giữ Ấm: [Trống]")
    end
end

-- 4. Cập nhật nội dung Popup Tổng kết & Cửa hàng
local function refresh_summary_popup_ui(self)
    local st = ShiftState.current_shift
    local cfg = ShiftsConfig.SHIFTS[st.shift_type]
    local wallet = SaveManager.save_data.player_money
    
    gui.set_text(self.summary_title, "TỔNG KẾT " .. string.upper(cfg.name))
    
    local stats_str = string.format(
        "- Khách đã phục vụ: %d người (Món nướng Hoàn Hảo: %d)\n" ..
        "- Doanh thu trong ca: +%d đ\n" ..
        "- Tổng tiền trong ví hiện tại: %d đ",
        st.customers_served, st.perfect_count, st.shift_revenue, wallet
    )
    gui.set_text(self.summary_stats, stats_str)
    
    for _, btn_info in ipairs(self.shop_buttons) do
        local upg = ShopCatalog.ITEMS[btn_info.id]
        local owned = ShopManager.is_upgrade_purchased(btn_info.id)
        
        if owned then
            gui.set_text(btn_info.txt, "[ĐÃ SỞ HỮU] " .. upg.name)
            gui.set_color(btn_info.box, COLORS.BTN_DISABLED)
        else
            gui.set_text(btn_info.txt, string.format("MUA: %s — Giá: %d đ", upg.name, upg.cost))
            if wallet >= upg.cost then
                gui.set_color(btn_info.box, COLORS.BTN_BUYABLE)
            else
                gui.set_color(btn_info.box, COLORS.BTN_DISABLED)
            end
        end
    end
    
    if st.shift_type == ShiftsConfig.SHIFT_TYPES.MORNING then
        gui.set_text(self.txt_next_shift, "Bắt đầu Ca Đêm >>")
    else
        gui.set_text(self.txt_next_shift, "Sang Ngày " .. (st.day_number + 1) .. " >>")
    end
end

local function open_summary_popup(self)
    SaveManager.add_money(ShiftState.current_shift.shift_revenue)
    SaveManager.save_game()
    
    refresh_hud_and_theme(self)
    refresh_summary_popup_ui(self)
    
    gui.set_enabled(self.summary_popup, true)
    gui.set_position(self.summary_popup, vmath.vector3(640, 850, 0))
    gui.animate(self.summary_popup, gui.PROP_POSITION, vmath.vector3(640, 360, 0), gui.EASING_OUTBACK, 0.4)
end

local function try_serve_or_store(self, finished_product, from_warming_tray)
    local res = ShiftState.serve_active_customer(finished_product)
    
    if res.success then
        safe_audio("play_coin")
        local tip_msg = res.quick_tip and " (+Thưởng Nhanh Ca Sáng!)" or ""
        gui.set_text(self.status_text, string.format("Đã bán thành công! Thu về +%d đ%s", res.earned, tip_msg))
        
        self.leaving_timer = 2.0
        gui.set_scale(self.customer_box, vmath.vector3(1.15, 1.15, 1))
        gui.animate(self.customer_box, gui.PROP_SCALE, vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.3)
        
        if from_warming_tray then
            self.warming_item = nil
            refresh_warming_tray_ui(self)
        end
        refresh_hud_and_theme(self)
        refresh_customer_ui(self)
        return true
    else
        if not from_warming_tray then
            self.warming_item = finished_product
            refresh_warming_tray_ui(self)
            local item_name = ItemsCatalog.ITEMS[finished_product.item_id].name
            gui.set_text(self.status_text, "Chưa khớp món khách gọi -> Đã cất [" .. item_name .. "] xuống Khay Giữ Ấm!")
        else
            gui.set_text(self.status_text, "Khách hiện tại không gọi món trong Khay Giữ Ấm!")
        end
        return false
    end
end

function init(self)
    msg.post(".", "acquire_input_focus")
    math.randomseed(os.time())
    
    local save = SaveManager.load_game()
    if not save.max_grill_slots then save.max_grill_slots = 4 end
    
    self.street_bg          = gui.get_node("street_bg")
    self.hud_info_text      = gui.get_node("hud_info_text")
    self.status_text        = gui.get_node("status_text")
    self.customer_box       = gui.get_node("customer_box")
    self.dialogue_bg        = gui.get_node("dialogue_bg")
    self.dialogue_text      = gui.get_node("dialogue_text")
    self.warming_tray       = gui.get_node("warming_tray")
    self.warming_text       = gui.get_node("warming_text")
    self.basket_potato      = gui.get_node("basket_potato")
    self.basket_corn        = gui.get_node("basket_corn")
    self.bowl_scallion      = gui.get_node("bowl_scallion")
    self.bowl_scallion_text = gui.get_node("bowl_scallion_text")
    
    self.slot_nodes, self.slot_texts, self.slot_smokes, self.smoke_playing = {}, {}, {}, {}
    for i = 1, 6 do
        self.slot_nodes[i]    = gui.get_node("slot_" .. i)
        self.slot_texts[i]    = gui.get_node("slot_" .. i .. "_text")
        self.slot_smokes[i]   = gui.get_node("slot_" .. i .. "_smoke")
        self.smoke_playing[i] = false
    end
    
    self.summary_popup  = gui.get_node("summary_popup")
    self.summary_title  = gui.get_node("summary_title")
    self.summary_stats  = gui.get_node("summary_stats")
    self.btn_next_shift = gui.get_node("btn_next_shift")
    self.txt_next_shift = gui.get_node("txt_next_shift")
    
    self.shop_buttons = {
        { id = "upgrade_slot_5",        box = gui.get_node("btn_buy_slot5"),    txt = gui.get_node("txt_buy_slot5") },
        { id = "upgrade_slot_6",        box = gui.get_node("btn_buy_slot6"),    txt = gui.get_node("txt_buy_slot6") },
        { id = "upgrade_corn_scallion", box = gui.get_node("btn_buy_scallion"), txt = gui.get_node("txt_buy_scallion") }
    }
    
    gui.set_enabled(self.summary_popup, false)
    self.warming_item = nil
    self.leaving_timer = 0
    
    GrillState.init_grill(save.max_grill_slots)
    ShiftState.start_shift(save.current_day, ShiftsConfig.SHIFT_TYPES.MORNING)
    
    refresh_hud_and_theme(self)
    refresh_customer_ui(self)
    refresh_warming_tray_ui(self)
    gui.set_text(self.status_text, "Bắt đầu Ngày " .. save.current_day .. "! Click Rổ Khoai hoặc Bắp để nhóm bếp.")
end

local function place_in_first_empty_slot(self, item_id)
    for i = 1, GrillState.grill.max_slots do
        if GrillState.place_item(i, item_id) then
            safe_audio("play_sizzle", false)
            local item_name = ItemsCatalog.ITEMS[item_id].name
            gui.set_text(self.status_text, "Đã đặt " .. item_name .. " lên Ô số " .. i .. " (Mặt A)")
            return
        end
    end
    gui.set_text(self.status_text, "Tất cả các ô đã mở khóa đều đang kín chỗ!")
end

function update(self, dt)
    GrillState.update_grill(dt)
    local unlocked_slots = GrillState.grill.max_slots
    
    for i = 1, 6 do
        local node = self.slot_nodes[i]
        local txt_node = self.slot_texts[i]
        local smoke_node = self.slot_smokes[i]
        
        if i > unlocked_slots then
            gui.set_color(node, COLORS.LOCKED)
            gui.set_text(txt_node, "Ô " .. i .. "\n[Khóa]")
            if self.smoke_playing[i] then
                gui.stop_particlefx(smoke_node)
                self.smoke_playing[i] = false
            end
        else
            local slot = GrillState.grill.slots[i]
            if slot.status == GrillState.SLOT_STATUS.EMPTY then
                gui.set_color(node, COLORS.EMPTY)
                gui.set_text(txt_node, "Ô " .. i .. "\n[Trống]")
                if self.smoke_playing[i] then
                    gui.stop_particlefx(smoke_node)
                    self.smoke_playing[i] = false
                end
            else
                local cfg = ItemsCatalog.ITEMS[slot.item_id]
                local is_side_a = (slot.status == GrillState.SLOT_STATUS.COOKING_SIDE_A)
                local p = is_side_a and slot.side_a.progress or slot.side_b.progress
                local side_label = is_side_a and "Mặt A" or "Mặt B"
                local action_hint = ""
                
                if p < cfg.thresholds.warm then
                    gui.set_color(node, COLORS.RAW)
                    action_hint = string.format("(%d%%)", math.floor(p * 100))
                elseif p >= cfg.thresholds.sweet_spot_min and p <= cfg.thresholds.sweet_spot_max then
                    gui.set_color(node, COLORS.SWEET_SPOT)
                    action_hint = is_side_a and "[LẬT NGAY!]" or "[GẮP RA!]"
                elseif p > cfg.thresholds.charred then
                    gui.set_color(node, COLORS.CHARRED)
                    action_hint = "[Hơi xém]"
                else
                    gui.set_color(node, COLORS.WARM)
                    action_hint = string.format("(%d%%)", math.floor(p * 100))
                end
                
                gui.set_text(txt_node, string.format("%s\n%s %s", cfg.name, side_label, action_hint))
                
                if p >= cfg.thresholds.warm and not self.smoke_playing[i] then
                    gui.play_particlefx(smoke_node)
                    self.smoke_playing[i] = true
                end
            end
        end
    end
    
    local st = ShiftState.current_shift
    local shift_cfg = ShiftsConfig.SHIFTS[st.shift_type]
    
    if st.status == ShiftState.SESSION_STATUS.WAITING_NEXT_CUSTOMER then
        st.spawn_timer = st.spawn_timer - dt
        if st.spawn_timer <= 0 then
            ShiftState.spawn_customer()
            gui.set_position(self.customer_box, vmath.vector3(450, 450, 0))
            gui.animate(self.customer_box, gui.PROP_POSITION, vmath.vector3(640, 450, 0), gui.EASING_OUTQUAD, 0.35)
            refresh_customer_ui(self)
        end
    elseif st.status == ShiftState.SESSION_STATUS.CUSTOMER_ORDERING then
        st.active_customer.wait_time = st.active_customer.wait_time + dt
    elseif st.status == ShiftState.SESSION_STATUS.CUSTOMER_LEAVING then
        self.leaving_timer = self.leaving_timer - dt
        if self.leaving_timer <= 0 then
            if st.customers_served >= shift_cfg.target_customers then
                st.status = ShiftState.SESSION_STATUS.SHIFT_ENDED
                refresh_customer_ui(self)
                open_summary_popup(self)
            else
                st.status = ShiftState.SESSION_STATUS.WAITING_NEXT_CUSTOMER
                st.spawn_timer = math.random() * (shift_cfg.spawn_delay_max - shift_cfg.spawn_delay_min) + shift_cfg.spawn_delay_min
                refresh_customer_ui(self)
            end
        end
    end
end

function on_input(self, action_id, action)
    if action_id == hash("touch") and action.pressed then
        safe_audio("unlock_web_audio")
        local st = ShiftState.current_shift
        
        -- TRƯỜNG HỢP A: Đang mở Popup Tổng kết & Shop
        if st.status == ShiftState.SESSION_STATUS.SHIFT_ENDED then
            for _, btn_info in ipairs(self.shop_buttons) do
                if gui.pick_node(btn_info.box, action.x, action.y) then
                    local res = ShopManager.buy_upgrade(btn_info.id)
                    if res.success then
                        safe_audio("play_coin")
                        GrillState.init_grill(SaveManager.save_data.max_grill_slots)
                        gui.set_text(self.status_text, "Mua nâng cấp thành công! Đã tự động lưu vào trình duyệt.")
                        gui.set_scale(btn_info.box, vmath.vector3(1.08, 1.08, 1))
                        gui.animate(btn_info.box, gui.PROP_SCALE, vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.25)
                        refresh_hud_and_theme(self)
                        refresh_summary_popup_ui(self)
                    elseif res.reason == "ALREADY_OWNED" then
                        gui.set_text(self.status_text, "Bạn đã sở hữu nâng cấp này rồi!")
                    elseif res.reason == "NOT_ENOUGH_MONEY" then
                        gui.set_text(self.status_text, "Chưa đủ tiền trong ví! Hãy bán thêm vài ca nữa nhé.")
                    end
                    return true
                end
            end
            
            if gui.pick_node(self.btn_next_shift, action.x, action.y) then
                gui.set_enabled(self.summary_popup, false)
                GrillState.init_grill(SaveManager.save_data.max_grill_slots)
                
                if st.shift_type == ShiftsConfig.SHIFT_TYPES.MORNING then
                    ShiftState.start_shift(st.day_number, ShiftsConfig.SHIFT_TYPES.NIGHT)
                    gui.set_text(self.status_text, "Đã lên đèn Ca Đêm! Thưởng nướng Hoàn Hảo x1.5!")
                else
                    SaveManager.advance_to_next_day()
                    ShiftState.start_shift(SaveManager.save_data.current_day, ShiftsConfig.SHIFT_TYPES.MORNING)
                    gui.set_text(self.status_text, "Chào buổi sáng Ngày " .. SaveManager.save_data.current_day .. "!")
                end
                refresh_hud_and_theme(self)
                refresh_customer_ui(self)
                return true
            end
            return true
        end
        
        -- TRƯỜNG HỢP B: Đang trong ca bán hàng
        -- 1. Click Rổ Khoai / Rổ Bắp
        if gui.pick_node(self.basket_potato, action.x, action.y) then
            place_in_first_empty_slot(self, "sweet_potato_honey")
            return true
        elseif gui.pick_node(self.basket_corn, action.x, action.y) then
            place_in_first_empty_slot(self, "corn_glutinous")
            return true
        end
        
        -- 2. Click Chén Mỡ Hành để quết lên Bắp đang ở Mặt B
        if gui.pick_node(self.bowl_scallion, action.x, action.y) then
            if not SaveManager.is_item_unlocked("corn_scallion") then
                gui.set_text(self.status_text, "Chén Mỡ Hành chưa mở khóa! Hãy mua Công thức ở cuối ca nhé.")
            else
                local applied_slot = GrillState.apply_scallion_to_first_valid_corn()
                if applied_slot then
                    safe_audio("play_sizzle", true)
                    gui.set_text(self.status_text, "Đã quết mỡ hành thơm phức lên Bắp ở Ô số " .. applied_slot .. "!")
                    gui.set_scale(self.bowl_scallion, vmath.vector3(1.15, 1.15, 1))
                    gui.animate(self.bowl_scallion, gui.PROP_SCALE, vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.25)
                else
                    gui.set_text(self.status_text, "Cần có Bắp Nếp đang nướng ở Mặt B trên vỉ mới quết mỡ hành được!")
                end
            end
            return true
        end
        
        -- 3. Click Khay Giữ Ấm
        if gui.pick_node(self.warming_tray, action.x, action.y) and self.warming_item then
            try_serve_or_store(self, self.warming_item, true)
            return true
        end
        
        -- 4. Click vào các Ô nướng đã mở khóa
        for i = 1, GrillState.grill.max_slots do
            if gui.pick_node(self.slot_nodes[i], action.x, action.y) then
                local res = GrillState.interact_slot(i)
                if res then
                    if res.action == "FLIPPED" then
                        safe_audio("play_sizzle", res.grade_a == "PERFECT")
                        gui.set_text(self.status_text, "Ô " .. i .. ": Đã lật sang Mặt B! (Mặt A: " .. res.grade_a .. ")")
                        gui.set_scale(self.slot_nodes[i], vmath.vector3(1.15, 1.15, 1))
                        gui.animate(self.slot_nodes[i], gui.PROP_SCALE, vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.25)
                    elseif res.action == "HARVESTED" then
                        try_serve_or_store(self, res.product, false)
                    end
                end
                return true
            end
        end
    end
end
'
```


Khi nhận tài liệu này, AI Agent cần thực hiện tuần tự các bước sau:

- [ ] **Task 1:** Khởi tạo cấu trúc file `game.project`, `/input/game.input_binding` và cây thư mục `main/data/`, `main/state/`.
    
- [ ] **Task 2:** Sinh toàn bộ các file Lua Module trong `main/data/` và `main/state/` theo đúng mã nguồn ở Mục 4.
    
- [ ] **Task 3:** Khởi tạo file văn bản định nghĩa `main/workstation.gui` (chứa đầy đủ các Box/Text/Particlefx Nodes ở Mục 3.1) và `main/workstation.gui_script` kết nối toàn bộ luồng sự kiện (bao gồm cả xử lý click vào `bowl_scallion` gọi `GrillState.apply_scallion_to_first_valid_corn()`).
    
- [ ] **Task 4:** Tạo `main/smoke.particlefx` và `main/main.collection` nhúng `workstation.gui` cùng `sound_bank` Game Object.
    
- [ ] **Task 5:** Kiểm tra tính toàn vẹn của đường dẫn `require(...)` và các Node ID trong `gui.get_node(...)` để đảm bảo game chạy ngay khi bấm `Ctrl + B` hoặc xuất bản HTML5.
    
