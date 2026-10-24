Dưới đây là bản **Tài liệu Thiết kế Game & Đặc tả Kỹ thuật (GDD & Technical Specification Document)** hoàn chỉnh, được viết theo chuẩn kỹ thuật phần mềm để bạn có thể copy trực tiếp làm **System Prompt / Context** giao cho AI Coding Agent (như Cursor, Claude Code, Windsurf, Copilot...) hoặc lưu thành file `SPECIFICATION.md` trong thư mục gốc của dự án.


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

1. **Build HTML5 Bundle bằng Defold CLI (`bob.jar`) hoặc Editor:**
    
      
    - Trên Defold Editor: Chọn `Project -> Bundle -> HTML5 Application...`
        
          
        
    - Bỏ tích `Debug` (chọn `Release` để tối ưu dung lượng `.wasm`), xuất ra thư mục `dist/web`.
        
          
        
2. **Triển khai lên Cloudflare Pages:**
    
      
    - Sử dụng Wrangler CLI: `npx wrangler pages deploy dist/web --project-name=cozy-street-grill`
        
          
        
    - Hoặc kết nối Git Repository với Cloudflare Pages (Build output directory: `dist/web`).
        
          
        
3. **Cấu hình MIME Types & Caching (Tự động bởi Cloudflare Pages):**
    
      
    - File `.wasm` được phân phối với `Content-Type: application/wasm` và nén Brotli tự động.
        
          
        

## 6. CHECKLIST NHIỆM VỤ CHO AI AGENT (AGENT EXECUTION TASKS)

Khi nhận tài liệu này, AI Agent cần thực hiện tuần tự các bước sau:

- [ ] **Task 1:** Khởi tạo cấu trúc file `game.project`, `/input/game.input_binding` và cây thư mục `main/data/`, `main/state/`.
    
- [ ] **Task 2:** Sinh toàn bộ các file Lua Module trong `main/data/` và `main/state/` theo đúng mã nguồn ở Mục 4.
    
- [ ] **Task 3:** Khởi tạo file văn bản định nghĩa `main/workstation.gui` (chứa đầy đủ các Box/Text/Particlefx Nodes ở Mục 3.1) và `main/workstation.gui_script` kết nối toàn bộ luồng sự kiện (bao gồm cả xử lý click vào `bowl_scallion` gọi `GrillState.apply_scallion_to_first_valid_corn()`).
    
- [ ] **Task 4:** Tạo `main/smoke.particlefx` và `main/main.collection` nhúng `workstation.gui` cùng `sound_bank` Game Object.
    
- [ ] **Task 5:** Kiểm tra tính toàn vẹn của đường dẫn `require(...)` và các Node ID trong `gui.get_node(...)` để đảm bảo game chạy ngay khi bấm `Ctrl + B` hoặc xuất bản HTML5.
    