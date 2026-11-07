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