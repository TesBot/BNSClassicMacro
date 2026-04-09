; ============================== 召唤_1系马蜂.ahk ==============================
; 召唤职业 1系马蜂 流派卡刀模块
; 依赖图片: juesexuetiao.bmp(公共), zhaohuan-qianniuhua*.bmp/png, zhaohuan-yamao.bmp, zhaohuan-naonao.bmp, zhaohuan-jineng*.bmp/png
; ==============================

; ============================== 流派信息 ==============================
global FlowInfo_Zhaohuan1 := {
    name: "召唤-1系马蜂",
    flowId: "召唤_1系马蜂",
    job: "召唤",
    description: "核心循环: R→T, 技能检测: 牵牛花(F)、压猫(Tab)、生长/芒刺(1)、摄取/荆棘藤(2), 压猫序列: 挠挠→喵火流星→挠挠"
}

; ============================== 流派状态变量 ==============================
global isYamaoPressed_Zhaohuan1 := false

; ============================== 流派配置初始化 ==============================
InitFlowConfig_Zhaohuan1() {
    global skillConfig, skillEnable, startMainLoopButton
    local configPath := GetFlowConfigPath("召唤_1系马蜂")

    if !FileExist(configPath) {
        CreateDefaultFlowConfig_Zhaohuan1(configPath)
    }

    ; 加载全局配置
    skillConfig.pressDelay := ReadConfigInt(configPath, "Global", "pressDelay", 5)
    skillConfig.mainLoopDelay := ReadConfigInt(configPath, "Global", "mainLoopDelay", 5)
    skillConfig.startButton := ReadConfigStr(configPath, "Global", "startButton", "XButton1")

    ; 加载技能开关
    skillEnable.Qianniuhua := ReadConfigInt(configPath, "SkillEnable", "Qianniuhua", 1)
    skillEnable.Yamao := ReadConfigInt(configPath, "SkillEnable", "Yamao", 1)
    skillEnable.XCX := ReadConfigInt(configPath, "SkillEnable", "XCX", 1)
    skillEnable.Jineng1 := ReadConfigInt(configPath, "SkillEnable", "Jineng1", 0)
    skillEnable.Jineng2 := ReadConfigInt(configPath, "SkillEnable", "Jineng2", 0)

    ; 加载牵牛花配置
    skillConfig.Qianniuhua := {
        TargetX1: ReadConfigInt(configPath, "Qianniuhua", "TargetX1", 1602),
        TargetY1: ReadConfigInt(configPath, "Qianniuhua", "TargetY1", 801),
        TargetColor1: ReadConfigColor(configPath, "Qianniuhua", "TargetColor1", "FFFFFF"),
        TargetX2: ReadConfigInt(configPath, "Qianniuhua", "TargetX2", 1617),
        TargetY2: ReadConfigInt(configPath, "Qianniuhua", "TargetY2", 795),
        TargetColor2: ReadConfigColor(configPath, "Qianniuhua", "TargetColor2", "FFFFFF"),
        colorRange: ReadConfigInt(configPath, "Qianniuhua", "colorRange", 20),
        pressHold: ReadConfigInt(configPath, "Qianniuhua", "pressHold", 8),
        checkTimer: ReadConfigInt(configPath, "Qianniuhua", "checkTimer", 250)
    }

    ; 加载压猫配置
    skillConfig.Yamao := {
        TargetX1: ReadConfigInt(configPath, "Yamao", "TargetX1", 1079),
        TargetY1: ReadConfigInt(configPath, "Yamao", "TargetY1", 1228),
        TargetColor1: ReadConfigColor(configPath, "Yamao", "TargetColor1", "F8F7F7"),
        TargetX2: ReadConfigInt(configPath, "Yamao", "TargetX2", 1092),
        TargetY2: ReadConfigInt(configPath, "Yamao", "TargetY2", 1223),
        TargetColor2: ReadConfigColor(configPath, "Yamao", "TargetColor2", "4E3633"),
        colorRange: ReadConfigInt(configPath, "Yamao", "colorRange", 20),
        pressHold: ReadConfigInt(configPath, "Yamao", "pressHold", 8),
        checkTimer: ReadConfigInt(configPath, "Yamao", "checkTimer", 200)
    }

    ; 加载技能1配置
    skillConfig.Jineng1 := {
        TargetX1: ReadConfigInt(configPath, "Jineng1", "TargetX1", 1179),
        TargetY1: ReadConfigInt(configPath, "Jineng1", "TargetY1", 1227),
        TargetColor1: ReadConfigColor(configPath, "Jineng1", "TargetColor1", "FFFFFF"),
        TargetX2: ReadConfigInt(configPath, "Jineng1", "TargetX2", 1195),
        TargetY2: ReadConfigInt(configPath, "Jineng1", "TargetY2", 1222),
        TargetColor2: ReadConfigColor(configPath, "Jineng1", "TargetColor2", "FFFFFF"),
        colorRange: ReadConfigInt(configPath, "Jineng1", "colorRange", 20),
        pressHold: ReadConfigInt(configPath, "Jineng1", "pressHold", 8),
        checkTimer: ReadConfigInt(configPath, "Jineng1", "checkTimer", 1000)
    }

    ; 加载技能2配置
    skillConfig.Jineng2 := {
        TargetX1: ReadConfigInt(configPath, "Jineng2", "TargetX1", 1236),
        TargetY1: ReadConfigInt(configPath, "Jineng2", "TargetY1", 1228),
        TargetColor1: ReadConfigColor(configPath, "Jineng2", "TargetColor1", "FFFFFF"),
        TargetX2: ReadConfigInt(configPath, "Jineng2", "TargetX2", 1251),
        TargetY2: ReadConfigInt(configPath, "Jineng2", "TargetY2", 1222),
        TargetColor2: ReadConfigColor(configPath, "Jineng2", "TargetColor2", "FFFFFF"),
        colorRange: ReadConfigInt(configPath, "Jineng2", "colorRange", 20),
        pressHold: ReadConfigInt(configPath, "Jineng2", "pressHold", 8),
        checkTimer: ReadConfigInt(configPath, "Jineng2", "checkTimer", 1000)
    }

    ; 加载挠挠配置（压猫后序列）
    skillConfig.Naonao := {
        TargetX1: ReadConfigInt(configPath, "Naonao", "TargetX1", 1235),
        TargetY1: ReadConfigInt(configPath, "Naonao", "TargetY1", 1317),
        TargetColor1: ReadConfigColor(configPath, "Naonao", "TargetColor1", "D7C6D6"),
        TargetX2: ReadConfigInt(configPath, "Naonao", "TargetX2", 1252),
        TargetY2: ReadConfigInt(configPath, "Naonao", "TargetY2", 1312),
        TargetColor2: ReadConfigColor(configPath, "Naonao", "TargetColor2", "4B074B"),
        colorRange: ReadConfigInt(configPath, "Naonao", "colorRange", 20),
        pressHold: ReadConfigInt(configPath, "Naonao", "pressHold", 10),
        xcxDelay: ReadConfigInt(configPath, "Naonao", "xcxDelay", 2200)
    }

    ; 加载喵火流星配置（压猫后序列）
    skillConfig.Miaohuoliuxing := {
        TargetX1: ReadConfigInt(configPath, "Miaohuoliuxing", "TargetX1", 1606),
        TargetY1: ReadConfigInt(configPath, "Miaohuoliuxing", "TargetY1", 804),
        TargetColor1: ReadConfigColor(configPath, "Miaohuoliuxing", "TargetColor1", "7E5284"),
        TargetX2: ReadConfigInt(configPath, "Miaohuoliuxing", "TargetX2", 1624),
        TargetY2: ReadConfigInt(configPath, "Miaohuoliuxing", "TargetY2", 800),
        TargetColor2: ReadConfigColor(configPath, "Miaohuoliuxing", "TargetColor2", "CEF312"),
        colorRange: ReadConfigInt(configPath, "Miaohuoliuxing", "colorRange", 20),
        pressHold: ReadConfigInt(configPath, "Miaohuoliuxing", "pressHold", 10),
        xcxDelay: ReadConfigInt(configPath, "Miaohuoliuxing", "xcxDelay", 1200)
    }

    ; 更新启动按键
    startMainLoopButton := skillConfig.startButton
}

CreateDefaultFlowConfig_Zhaohuan1(configPath) {
    ; 确保Config目录存在
    local configDir := A_ScriptDir "\Config"
    if !DirExist(configDir)
        DirCreate(configDir)

    local defaultConfig := "
    (LTrim

[Global]
; 自定义启动按键（XButton1:鼠标侧键1，XButton2:鼠标侧键2...等）
startButton = XButton1
; 卡刀循环延迟（毫秒）
mainLoopDelay = 5
; 全局按键延迟（毫秒）
pressDelay = 5

[SkillEnable]
; 技能释放开关，默认开启（1），关闭（0）
Qianniuhua = 1
Yamao = 1
XCX = 0
Jineng1 = 0
Jineng2 = 0

; 牵牛花（F键）配置
[Qianniuhua]
pressHold = 8
checkTimer = 250
colorRange = 20
TargetX1 = 1602
TargetY1 = 801
TargetColor1 = FFFFFF
TargetX2 = 1617
TargetY2 = 795
TargetColor2 = FFFFFF

; 压猫（Tab键）配置
[Yamao]
pressHold = 8
checkTimer = 200
colorRange = 20
TargetX1 = 1079
TargetY1 = 1228
TargetColor1 = F8F7F7
TargetX2 = 1092
TargetY2 = 1223
TargetColor2 = 4E3633

; 技能1键配置
[Jineng1]
pressHold = 8
checkTimer = 1000
colorRange = 20
TargetX1 = 1179
TargetY1 = 1227
TargetColor1 = FFFFFF
TargetX2 = 1195
TargetY2 = 1222
TargetColor2 = FFFFFF

; 技能2键配置
[Jineng2]
pressHold = 8
checkTimer = 1000
colorRange = 20
TargetX1 = 1236
TargetY1 = 1228
TargetColor1 = FFFFFF
TargetX2 = 1251
TargetY2 = 1222
TargetColor2 = FFFFFF

; 挠挠（X键）配置 - 压猫后序列
[Naonao]
pressHold = 10
colorRange = 20
TargetX1 = 1235
TargetY1 = 1317
TargetColor1 = D7C6D6
TargetX2 = 1252
TargetY2 = 1312
TargetColor2 = 4B074B
xcxDelay = 2200

; 喵火流星（C键）配置 - 压猫后序列
[Miaohuoliuxing]
pressHold = 10
colorRange = 20
TargetX1 = 1606
TargetY1 = 804
TargetColor1 = 7E5284
TargetX2 = 1624
TargetY2 = 800
TargetColor2 = CEF312
xcxDelay = 1200
    )"
    FileAppend(defaultConfig, configPath, "UTF-8")
}

; ============================== 技能检测函数 ==============================
checkQianniuhua_Zhaohuan1() {
    global skillEnable
    if !skillEnable.Qianniuhua
        return false
    return checkSkillAvailable("Qianniuhua")
}

checkYamao_Zhaohuan1() {
    global skillEnable, isYamaoPressed_Zhaohuan1
    if !skillEnable.Yamao
        return false
    if isYamaoPressed_Zhaohuan1
        return false
    return checkSkillAvailable("Yamao")
}

checkJineng1_Zhaohuan1() {
    global skillEnable
    if !skillEnable.Jineng1
        return false
    return checkSkillAvailable("Jineng1")
}

checkJineng2_Zhaohuan1() {
    global skillEnable
    if !skillEnable.Jineng2
        return false
    return checkSkillAvailable("Jineng2")
}

; ============================== 技能释放函数 ==============================
releaseQianniuhua_Zhaohuan1() {
    global isMacroRunning, skillConfig, bloodbarConfig
    if !isMacroRunning
        return

    ToolTip "宏运行中: 释放 牵牛花", bloodbarConfig.TargetX, bloodbarConfig.TargetY - 30
    pressWaitAndRelease("f", skillConfig.Qianniuhua.pressHold)
}

releaseJineng1_Zhaohuan1() {
    global isMacroRunning, skillConfig, bloodbarConfig
    if !isMacroRunning
        return

    ToolTip "宏运行中: 释放 技能1", bloodbarConfig.TargetX, bloodbarConfig.TargetY - 30
    pressWaitAndRelease("1", skillConfig.Jineng1.pressHold)
}

releaseJineng2_Zhaohuan1() {
    global isMacroRunning, skillConfig, bloodbarConfig
    if !isMacroRunning
        return

    ToolTip "宏运行中: 释放 技能2", bloodbarConfig.TargetX, bloodbarConfig.TargetY - 30
    pressWaitAndRelease("2", skillConfig.Jineng2.pressHold)
}

; 压猫释放（仅执行压猫）
releaseYamao_Zhaohuan1() {
    global isMacroRunning, skillConfig, bloodbarConfig

    ToolTip "宏运行中: 压猫", bloodbarConfig.TargetX, bloodbarConfig.TargetY - 30
    pressKey("Tab")
    sleepa(1000)
}

; XCX序列释放（压猫后自动执行）
releaseXCX_Zhaohuan1() {
    global isMacroRunning, skillConfig, bloodbarConfig

    ; 挠挠（按5次确保释放）
    ToolTip "宏运行中: 挠挠", bloodbarConfig.TargetX, bloodbarConfig.TargetY - 30
    Loop 5 {
        if !isMacroRunning
            break
        pressWaitAndRelease("x", skillConfig.Naonao.pressHold)
    }

    if !isMacroRunning
        return
    sleepa(skillConfig.Naonao.xcxDelay)

    ; 喵火流星
    ToolTip "宏运行中: 喵火流星", bloodbarConfig.TargetX, bloodbarConfig.TargetY - 30
    Loop 5 {
        if !isMacroRunning
            break
        pressWaitAndRelease("c", skillConfig.Miaohuoliuxing.pressHold)
    }

    if !isMacroRunning
        return
    sleepa(skillConfig.Miaohuoliuxing.xcxDelay)

    ; 挠挠（再次）
    ToolTip "宏运行中: 挠挠", bloodbarConfig.TargetX, bloodbarConfig.TargetY - 30
    Loop 5 {
        if !isMacroRunning
            break
        pressWaitAndRelease("x", skillConfig.Naonao.pressHold)
    }
}

; ============================== 卡刀主循环 ==============================
StartSkillLoop_Zhaohuan1(ThisHotkey) {
    global isMainLoopPaused, skillConfig, isMacroRunning, bloodbarConfig

    if isMainLoopPaused {
        isMacroRunning := false
        return
    }

    isMacroRunning := true
    isYamaoPressed_Zhaohuan1 := false

    ; 显示初始状态
    ToolTip "宏运行中", bloodbarConfig.TargetX, bloodbarConfig.TargetY - 30

    local lastQianniuhuaCheck := 0
    local lastYamaoCheck := 0
    local lastJineng1Check := 0
    local lastJineng2Check := 0
    local currentTime := 0
    local delayRemaining := 0

    Loop {
        if not GetKeyState(ThisHotkey, "P")
            break

        currentTime := A_TickCount

        ; 牵牛花检测
        if (currentTime - lastQianniuhuaCheck >= skillConfig.Qianniuhua.checkTimer) {
            lastQianniuhuaCheck := currentTime
            if checkQianniuhua_Zhaohuan1() {
                releaseQianniuhua_Zhaohuan1()
            }
        }

        if not GetKeyState(ThisHotkey, "P")
            break

        ; 压猫检测
        if (currentTime - lastYamaoCheck >= skillConfig.Yamao.checkTimer && !isYamaoPressed_Zhaohuan1) {
            lastYamaoCheck := currentTime
            if checkYamao_Zhaohuan1() {
                isYamaoPressed_Zhaohuan1 := true  ; 设置标志防止重复触发
                releaseYamao_Zhaohuan1()
                ; 压猫后根据XCX开关判断是否执行XCX序列（需同时开启压猫和XCX）
                if (skillEnable.XCX && skillEnable.Yamao && isMacroRunning) {
                    releaseXCX_Zhaohuan1()
                }
                isYamaoPressed_Zhaohuan1 := false  ; 清除标志
            }
        }

        if not GetKeyState(ThisHotkey, "P")
            break

        ; 技能1检测
        if (currentTime - lastJineng1Check >= skillConfig.Jineng1.checkTimer) {
            lastJineng1Check := currentTime
            if checkJineng1_Zhaohuan1() {
                releaseJineng1_Zhaohuan1()
            }
        }

        if not GetKeyState(ThisHotkey, "P")
            break

        ; 技能2检测
        if (currentTime - lastJineng2Check >= skillConfig.Jineng2.checkTimer) {
            lastJineng2Check := currentTime
            if checkJineng2_Zhaohuan1() {
                releaseJineng2_Zhaohuan1()
            }
        }

        if not GetKeyState(ThisHotkey, "P")
            break

        ToolTip "宏运行中", bloodbarConfig.TargetX, bloodbarConfig.TargetY - 30
        SendEvent("{r}")
        DllCall("Sleep", "UInt", skillConfig.pressDelay)

        if not GetKeyState(ThisHotkey, "P")
            break

        SendEvent("{t}")
        DllCall("Sleep", "UInt", skillConfig.pressDelay)

        ; 循环延时
        delayRemaining := skillConfig.mainLoopDelay
        while (delayRemaining > 0 && GetKeyState(ThisHotkey, "P")) {
            DllCall("Sleep", "UInt", 1)
            delayRemaining -= 1
        }
    }

    ; 清除 ToolTip
    ToolTip
    isMacroRunning := false
}

; ============================== 取色函数 ==============================
PickColors_Zhaohuan1() {
    global skillConfig, ResourceTempDir, bloodbarConfig
    local configPath := GetFlowConfigPath("召唤_1系马蜂")

    ; 血条取色（公共）
    PickBloodbarColor()

    ; 牵牛花取色
    local pic := ImagePutBuffer(0)
    local search := ImagePutBuffer(ResourceTempDir . "\zhaohuan-qianniuhua-new.png")
    local searchWidth := search.Width
    local searchHeight := search.Height

    if xy := pic.ImageSearch(search) {
        local FoundX := xy[1]
        local FoundY := xy[2]
        local Q1CenterX := Round(FoundX + searchWidth / 4)
        local Q1CenterY := Round(FoundY + searchHeight / 4)
        local Q4CenterX := Round(FoundX + searchWidth * 4 / 7)
        local Q4CenterY := Round(FoundY + searchHeight * 1 / 7)

        skillConfig.Qianniuhua.TargetX1 := Q1CenterX
        skillConfig.Qianniuhua.TargetY1 := Q1CenterY
        skillConfig.Qianniuhua.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.Qianniuhua.TargetX2 := Q4CenterX
        skillConfig.Qianniuhua.TargetY2 := Q4CenterY
        skillConfig.Qianniuhua.TargetColor2 := GetColor(Q4CenterX, Q4CenterY)

        WriteConfig(configPath, "Qianniuhua", "TargetX1", Q1CenterX)
        WriteConfig(configPath, "Qianniuhua", "TargetY1", Q1CenterY)
        WriteConfigColor(configPath, "Qianniuhua", "TargetColor1", skillConfig.Qianniuhua.TargetColor1)
        WriteConfig(configPath, "Qianniuhua", "TargetX2", Q4CenterX)
        WriteConfig(configPath, "Qianniuhua", "TargetY2", Q4CenterY)
        WriteConfigColor(configPath, "Qianniuhua", "TargetColor2", skillConfig.Qianniuhua.TargetColor2)
    } else {
        MsgBox("查找牵牛花技能位置失败，将使用配置文件默认坐标值", "卡刀鸡 - 提示")
    }

    ; 技能1取色（支持多种图标）
    pic := ImagePutBuffer(0)
    local search1 := ImagePutBuffer(ResourceTempDir . "\zhaohuan-jineng1-yemanshengzhang-new.png")
    local search2 := ImagePutBuffer(ResourceTempDir . "\zhaohuan-jineng1-mangcizaibei.bmp")

    if xy := pic.ImageSearch(search1) || xy := pic.ImageSearch(search2) {
        searchWidth := search.Width
        searchHeight := search.Height
        FoundX := xy[1]
        FoundY := xy[2]
        Q1CenterX := Round(FoundX + searchWidth / 4)
        Q1CenterY := Round(FoundY + searchHeight / 4)
        Q4CenterX := Round(FoundX + searchWidth * 4 / 7)
        Q4CenterY := Round(FoundY + searchHeight * 1 / 7)

        skillConfig.Jineng1.TargetX1 := Q1CenterX
        skillConfig.Jineng1.TargetY1 := Q1CenterY
        skillConfig.Jineng1.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.Jineng1.TargetX2 := Q4CenterX
        skillConfig.Jineng1.TargetY2 := Q4CenterY
        skillConfig.Jineng1.TargetColor2 := GetColor(Q4CenterX, Q4CenterY)

        WriteConfig(configPath, "Jineng1", "TargetX1", Q1CenterX)
        WriteConfig(configPath, "Jineng1", "TargetY1", Q1CenterY)
        WriteConfigColor(configPath, "Jineng1", "TargetColor1", skillConfig.Jineng1.TargetColor1)
        WriteConfig(configPath, "Jineng1", "TargetX2", Q4CenterX)
        WriteConfig(configPath, "Jineng1", "TargetY2", Q4CenterY)
        WriteConfigColor(configPath, "Jineng1", "TargetColor2", skillConfig.Jineng1.TargetColor2)
    } else {
        MsgBox("查找技能1位置失败，将使用配置文件默认坐标值", "卡刀鸡 - 提示")
    }

    ; 技能2取色
    pic := ImagePutBuffer(0)
    search1 := ImagePutBuffer(ResourceTempDir . "\zhaohuan-jineng2-shequ.bmp")
    search2 := ImagePutBuffer(ResourceTempDir . "\zhaohuan-jineng2-jingjiteng.bmp")

    if xy := pic.ImageSearch(search1) || xy := pic.ImageSearch(search2) {
        searchWidth := search.Width
        searchHeight := search.Height
        FoundX := xy[1]
        FoundY := xy[2]
        Q1CenterX := Round(FoundX + searchWidth / 4)
        Q1CenterY := Round(FoundY + searchHeight / 4)
        Q4CenterX := Round(FoundX + searchWidth * 4 / 7)
        Q4CenterY := Round(FoundY + searchHeight * 1 / 7)

        skillConfig.Jineng2.TargetX1 := Q1CenterX
        skillConfig.Jineng2.TargetY1 := Q1CenterY
        skillConfig.Jineng2.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.Jineng2.TargetX2 := Q4CenterX
        skillConfig.Jineng2.TargetY2 := Q4CenterY
        skillConfig.Jineng2.TargetColor2 := GetColor(Q4CenterX, Q4CenterY)

        WriteConfig(configPath, "Jineng2", "TargetX1", Q1CenterX)
        WriteConfig(configPath, "Jineng2", "TargetY1", Q1CenterY)
        WriteConfigColor(configPath, "Jineng2", "TargetColor1", skillConfig.Jineng2.TargetColor1)
        WriteConfig(configPath, "Jineng2", "TargetX2", Q4CenterX)
        WriteConfig(configPath, "Jineng2", "TargetY2", Q4CenterY)
        WriteConfigColor(configPath, "Jineng2", "TargetColor2", skillConfig.Jineng2.TargetColor2)
    } else {
        MsgBox("查找技能2位置失败，将使用配置文件默认坐标值", "卡刀鸡 - 提示")
    }

    MsgBox("召唤-1系取色完成！请按 Ctrl+Shift+P 进行压猫取色", "卡刀鸡")
}

; 压猫取色（需要单独进行）
PickColorsYamao_Zhaohuan1() {
    global skillConfig, ResourceTempDir, bloodbarConfig
    local configPath := GetFlowConfigPath("召唤_1系马蜂")

    ; 压猫取色
    local pic := ImagePutBuffer(0)
    local search := ImagePutBuffer(ResourceTempDir . "\zhaohuan-yamao.bmp")
    local searchWidth := search.Width
    local searchHeight := search.Height

    if xy := pic.ImageSearch(search) {
        local FoundX := xy[1]
        local FoundY := xy[2]
        local Q1CenterX := Round(FoundX + searchWidth / 4)
        local Q1CenterY := Round(FoundY + searchHeight / 4)
        local Q4CenterX := Round(FoundX + searchWidth * 4 / 7)
        local Q4CenterY := Round(FoundY + searchHeight * 1 / 7)

        skillConfig.Yamao.TargetX1 := Q1CenterX
        skillConfig.Yamao.TargetY1 := Q1CenterY
        skillConfig.Yamao.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.Yamao.TargetX2 := Q4CenterX
        skillConfig.Yamao.TargetY2 := Q4CenterY
        skillConfig.Yamao.TargetColor2 := GetColor(Q4CenterX, Q4CenterY)

        WriteConfig(configPath, "Yamao", "TargetX1", Q1CenterX)
        WriteConfig(configPath, "Yamao", "TargetY1", Q1CenterY)
        WriteConfigColor(configPath, "Yamao", "TargetColor1", skillConfig.Yamao.TargetColor1)
        WriteConfig(configPath, "Yamao", "TargetX2", Q4CenterX)
        WriteConfig(configPath, "Yamao", "TargetY2", Q4CenterY)
        WriteConfigColor(configPath, "Yamao", "TargetColor2", skillConfig.Yamao.TargetColor2)
    } else {
        MsgBox("查找压猫技能位置失败，请确保压猫技能图标已亮起", "卡刀鸡 - 提示")
    }

    ; 按Tab激活压猫状态
    pressKey("Tab")
    sleepa(1000)

    ; 挠挠取色
    pic := ImagePutBuffer(0)
    search := ImagePutBuffer(ResourceTempDir . "\zhaohuan-naonao.bmp")
    searchWidth := search.Width
    searchHeight := search.Height

    if xy := pic.ImageSearch(search) {
        FoundX := xy[1]
        FoundY := xy[2]
        Q1CenterX := Round(FoundX + searchWidth / 4)
        Q1CenterY := Round(FoundY + searchHeight / 4)
        Q4CenterX := Round(FoundX + searchWidth * 4 / 7)
        Q4CenterY := Round(FoundY + searchHeight * 1 / 7)

        skillConfig.Naonao.TargetX1 := Q1CenterX
        skillConfig.Naonao.TargetY1 := Q1CenterY
        skillConfig.Naonao.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.Naonao.TargetX2 := Q4CenterX
        skillConfig.Naonao.TargetY2 := Q4CenterY
        skillConfig.Naonao.TargetColor2 := GetColor(Q4CenterX, Q4CenterY)

        WriteConfig(configPath, "Naonao", "TargetX1", Q1CenterX)
        WriteConfig(configPath, "Naonao", "TargetY1", Q1CenterY)
        WriteConfigColor(configPath, "Naonao", "TargetColor1", skillConfig.Naonao.TargetColor1)
        WriteConfig(configPath, "Naonao", "TargetX2", Q4CenterX)
        WriteConfig(configPath, "Naonao", "TargetY2", Q4CenterY)
        WriteConfigColor(configPath, "Naonao", "TargetColor2", skillConfig.Naonao.TargetColor2)
    } else {
        MsgBox("查找挠挠技能位置失败", "卡刀鸡 - 提示")
    }

    MsgBox("召唤-1系压猫取色完成！", "卡刀鸡")
}

; ============================== UI创建函数 ==============================
GetFlowUI_Zhaohuan1(guiObj) {
    global skillEnable, skillConfig, startMainLoopButton

    ; 流派标题
    guiObj.AddText("xm y+10", "流派: 召唤 - 1系马蜂")

    ; 启动按键选择
    guiObj.AddText("xm y+5", "启动按键:")
    local hotkeyList := ["XButton1", "XButton2", "XButton3", "F1", "F2", "F3", "F4", "F5", "F6"]
    local cboHotkey := guiObj.AddComboBox("x+5 yp w80 vSelectedHotkey_Zhaohuan1", hotkeyList)
    cboHotkey.Text := startMainLoopButton

    ; 循环延迟
    guiObj.AddText("xm y+5", "循环延迟(ms):")
    local edMainLoopDelay := guiObj.AddEdit("x+5 yp w35 Number vMainLoopDelay_Zhaohuan1", skillConfig.mainLoopDelay)

    ; 技能开关
    guiObj.AddText("xm y+15", "技能开关:")
    local cbQianniuhua := guiObj.AddCheckbox("vCbQianniuhua_Zhaohuan1", "牵牛花 (F)")
    cbQianniuhua.Value := skillEnable.Qianniuhua
    local cbYamao := guiObj.AddCheckbox("vCbYamao_Zhaohuan1", "压猫 (Tab)")
    cbYamao.Value := skillEnable.Yamao
    local cbXCX := guiObj.AddCheckbox("vCbXCX_Zhaohuan1", "自动 XCX")
    cbXCX.Value := skillEnable.XCX

    ; XCX延迟配置（放在XCX选项下方）
    guiObj.AddText("xm y+3", "摁下C后延迟(ms):")
    local edNaonaoDelay := guiObj.AddEdit("x+5 yp w45 Number vNaonaoDelay_Zhaohuan1", skillConfig.Naonao.xcxDelay)
    guiObj.AddText("xm y+3", "摁下X后延迟(ms):")
    local edMiaohuoDelay := guiObj.AddEdit("x+5 yp w45 Number vMiaohuoDelay_Zhaohuan1", skillConfig.Miaohuoliuxing.xcxDelay)

    local cbJineng1 := guiObj.AddCheckbox("xm y+5 vCbJineng1_Zhaohuan1", "生长/芒刺 (1)")
    cbJineng1.Value := skillEnable.Jineng1
    local cbJineng2 := guiObj.AddCheckbox("xm y+5 vCbJineng2_Zhaohuan1", "摄取/荆棘藤 (2)")
    cbJineng2.Value := skillEnable.Jineng2

    ; 保存按钮
    local btnSave := guiObj.AddButton("xm y+15 w190 Default", "保存设置")
    btnSave.OnEvent("Click", SaveFlowSettings_Zhaohuan1)
}

; ============================== 保存设置函数 ==============================
SaveFlowSettings_Zhaohuan1(*) {
    global myGui, skillEnable, skillConfig, startMainLoopButton
    local configPath := GetFlowConfigPath("召唤_1系马蜂")

    local saved := myGui.Submit(false)

    ; 获取新值
    local newHotkey := saved.SelectedHotkey_Zhaohuan1
    local newQnn := saved.CbQianniuhua_Zhaohuan1
    local newYm := saved.CbYamao_Zhaohuan1
    local newXCX := saved.CbXCX_Zhaohuan1
    local newJ1 := saved.CbJineng1_Zhaohuan1
    local newJ2 := saved.CbJineng2_Zhaohuan1
    local newMainLoopDelay := saved.MainLoopDelay_Zhaohuan1
    local newNaonaoDelay := saved.NaonaoDelay_Zhaohuan1
    local newMiaohuoDelay := saved.MiaohuoDelay_Zhaohuan1

    ; 验证XCX依赖压猫
    if (newXCX && !newYm) {
        MsgBox("XCX功能依赖压猫开关，请先开启压猫！", "卡刀鸡 - 提示")
        return
    }

    ; 关闭压猫时自动关闭XCX（保持配置一致性）
    if !newYm
        newXCX := false

    ; 写入配置文件
    IniWrite(newHotkey, configPath, "Global", "startButton")
    IniWrite(newMainLoopDelay, configPath, "Global", "mainLoopDelay")
    IniWrite(newQnn ? "1" : "0", configPath, "SkillEnable", "Qianniuhua")
    IniWrite(newYm ? "1" : "0", configPath, "SkillEnable", "Yamao")
    IniWrite(newXCX ? "1" : "0", configPath, "SkillEnable", "XCX")
    IniWrite(newJ1 ? "1" : "0", configPath, "SkillEnable", "Jineng1")
    IniWrite(newJ2 ? "1" : "0", configPath, "SkillEnable", "Jineng2")
    IniWrite(newNaonaoDelay, configPath, "Naonao", "xcxDelay")
    IniWrite(newMiaohuoDelay, configPath, "Miaohuoliuxing", "xcxDelay")

    ; 重新加载配置并切换热键
    local oldHotkey := startMainLoopButton
    InitFlowConfig_Zhaohuan1()
    SwitchHotkey(startMainLoopButton, oldHotkey, StartSkillLoop_Zhaohuan1)

    ; 更新控件显示
    myGui["SelectedHotkey_Zhaohuan1"].Text := startMainLoopButton
    myGui["MainLoopDelay_Zhaohuan1"].Text := skillConfig.mainLoopDelay
    myGui["CbQianniuhua_Zhaohuan1"].Value := skillEnable.Qianniuhua
    myGui["CbYamao_Zhaohuan1"].Value := skillEnable.Yamao
    myGui["CbXCX_Zhaohuan1"].Value := skillEnable.XCX
    myGui["CbJineng1_Zhaohuan1"].Value := skillEnable.Jineng1
    myGui["CbJineng2_Zhaohuan1"].Value := skillEnable.Jineng2
    myGui["NaonaoDelay_Zhaohuan1"].Text := skillConfig.Naonao.xcxDelay
    myGui["MiaohuoDelay_Zhaohuan1"].Text := skillConfig.Miaohuoliuxing.xcxDelay

    MsgBox("召唤-1系设置已保存并生效。", "卡刀鸡")
}

; ============================== 模块导出接口 ==============================
GetFlowModule_Zhaohuan1() {
    return {
        name: "召唤-1系马蜂",
        flowId: "召唤_1系马蜂",
        job: "召唤",
        InitConfig: InitFlowConfig_Zhaohuan1,
        GetUI: GetFlowUI_Zhaohuan1,
        StartLoop: StartSkillLoop_Zhaohuan1,
        PickColors: PickColors_Zhaohuan1,
        PickColorsYamao: PickColorsYamao_Zhaohuan1,
        SaveSettings: SaveFlowSettings_Zhaohuan1
    }
}