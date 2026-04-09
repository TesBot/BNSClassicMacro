; ============================== 气功_1系推龙.ahk ==============================
; 气功职业 1系推龙 流派卡刀模块
; 依赖图片: juesexuetiao.bmp(公共), qigong-huolianzhang-new.png, qigong-hunyuanzhao-new.png
; ==============================

; ============================== 流派信息 ==============================
global FlowInfo_Qigong1 := {
    name: "气功-1系推龙",
    flowId: "气功_1系推龙",
    job: "气功",
    description: "核心循环: 2→R→T→F, 技能检测: 火莲掌(X)、混元罩(C)"
}

; 混元罩CD计时（45秒）
global lastHunyuanzhaoReleaseTime := 0

; 火莲掌CD计时（24秒）
global lastHuolianzhangReleaseTime := 0

; ============================== 流派配置初始化 ==============================
InitFlowConfig_Qigong1() {
    global skillConfig, skillEnable, startMainLoopButton
    local configPath := GetFlowConfigPath("气功_1系推龙")

    if !FileExist(configPath) {
        CreateDefaultFlowConfig_Qigong1(configPath)
    }

    ; 加载全局配置
    skillConfig.pressDelay := ReadConfigInt(configPath, "Global", "pressDelay", 5)
    skillConfig.mainLoopDelay := ReadConfigInt(configPath, "Global", "mainLoopDelay", 5)
    skillConfig.startButton := ReadConfigStr(configPath, "Global", "startButton", "XButton1")

    ; 加载技能开关
    skillEnable.Huolianzhang := ReadConfigInt(configPath, "SkillEnable", "Huolianzhang", 0)
    skillEnable.Hunyuanzhao := ReadConfigInt(configPath, "SkillEnable", "Hunyuanzhao", 0)

    ; 加载手动技能暂停配置
    skillConfig.ManualPause1 := ReadConfigInt(configPath, "ManualPause", "Key1", 100)
    skillConfig.ManualPause3 := ReadConfigInt(configPath, "ManualPause", "Key3", 100)
    skillConfig.ManualPauseQ := ReadConfigInt(configPath, "ManualPause", "KeyQ", 100)
    skillConfig.ManualPauseE := ReadConfigInt(configPath, "ManualPause", "KeyE", 100)

    ; 加载火莲掌配置
    skillConfig.Huolianzhang := {
        TargetX1: ReadConfigInt(configPath, "Huolianzhang", "TargetX1", 1602),
        TargetY1: ReadConfigInt(configPath, "Huolianzhang", "TargetY1", 801),
        TargetColor1: ReadConfigColor(configPath, "Huolianzhang", "TargetColor1", "CAEA24"),
        TargetX2: ReadConfigInt(configPath, "Huolianzhang", "TargetX2", 1617),
        TargetY2: ReadConfigInt(configPath, "Huolianzhang", "TargetY2", 795),
        TargetColor2: ReadConfigColor(configPath, "Huolianzhang", "TargetColor2", "3E6000"),
        colorRange: ReadConfigInt(configPath, "Huolianzhang", "colorRange", 20),
        pressHold: ReadConfigInt(configPath, "Huolianzhang", "pressHold", 10),
        checkTimer: ReadConfigInt(configPath, "Huolianzhang", "checkTimer", 25000),
        activateDelay: ReadConfigInt(configPath, "Huolianzhang", "activateDelay", 200)
    }

    ; 加载混元罩配置
    skillConfig.Hunyuanzhao := {
        TargetX1: ReadConfigInt(configPath, "Hunyuanzhao", "TargetX1", 1179),
        TargetY1: ReadConfigInt(configPath, "Hunyuanzhao", "TargetY1", 1227),
        TargetColor1: ReadConfigColor(configPath, "Hunyuanzhao", "TargetColor1", "FFEC5F"),
        TargetX2: ReadConfigInt(configPath, "Hunyuanzhao", "TargetX2", 1195),
        TargetY2: ReadConfigInt(configPath, "Hunyuanzhao", "TargetY2", 1222),
        TargetColor2: ReadConfigColor(configPath, "Hunyuanzhao", "TargetColor2", "F0C534"),
        colorRange: ReadConfigInt(configPath, "Hunyuanzhao", "colorRange", 20),
        pressHold: ReadConfigInt(configPath, "Hunyuanzhao", "pressHold", 10),
        checkTimer: ReadConfigInt(configPath, "Hunyuanzhao", "checkTimer", 46000),
        activateDelay: ReadConfigInt(configPath, "Hunyuanzhao", "activateDelay", 300)
    }

    ; 更新启动按键
    startMainLoopButton := skillConfig.startButton
}

CreateDefaultFlowConfig_Qigong1(configPath) {
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
Huolianzhang = 0
Hunyuanzhao = 0

[ManualPause]
; 手动按键暂停时间配置（毫秒）
Key1 = 100
Key3 = 100
KeyQ = 100
KeyE = 100

; 火莲掌（X键）配置
[Huolianzhang]
pressHold = 10
; 技能CD时间（毫秒），24秒=24000
checkTimer = 25000
; 激活等待延时（毫秒）
activateDelay = 200
colorRange = 20
TargetX1 = 1602
TargetY1 = 801
TargetColor1 = CAEA24
TargetX2 = 1617
TargetY2 = 795
TargetColor2 = 3E6000

; 混元罩（C键）配置
[Hunyuanzhao]
pressHold = 10
; 技能CD时间（毫秒），45秒=45000
checkTimer = 46000
; 激活等待延时（毫秒）
activateDelay = 300
colorRange = 20
TargetX1 = 1179
TargetY1 = 1227
TargetColor1 = FFEC5F
TargetX2 = 1195
TargetY2 = 1222
TargetColor2 = F0C534
    )"
    FileAppend(defaultConfig, configPath, "UTF-8")
}

; ============================== 技能检测函数 ==============================
checkHuolianzhang_Qigong1() {
    global skillEnable
    if !skillEnable.Huolianzhang
        return false
    return checkSkillAvailable("Huolianzhang")
}

checkHunyuanzhao_Qigong1() {
    global skillEnable
    if !skillEnable.Hunyuanzhao
        return false
    return checkSkillAvailable("Hunyuanzhao")
}

; ============================== 技能释放函数 ==============================
releaseHuolianzhang_Qigong1() {
    global isMacroRunning, skillConfig, bloodbarConfig
    if !isMacroRunning
        return

    ToolTip "宏运行中: 释放 火莲掌", bloodbarConfig.TargetX, bloodbarConfig.TargetY - 30

    ; 先按R激活火莲掌
    pressWaitAndRelease("r", skillConfig.Huolianzhang.pressHold)
    DllCall("Sleep", "UInt", skillConfig.Huolianzhang.activateDelay)  ; 等待激活

    ; 再按X释放火莲掌
    Loop 3 {
        if !isMacroRunning
            break
        pressWaitAndRelease("x", skillConfig.Huolianzhang.pressHold)
    }
}

releaseHunyuanzhao_Qigong1() {
    global isMacroRunning, skillConfig, bloodbarConfig
    if !isMacroRunning
        return

    ToolTip "宏运行中: 使用 混元罩", bloodbarConfig.TargetX, bloodbarConfig.TargetY - 30

    ; 先按T激活混元罩
    pressWaitAndRelease("t", skillConfig.Hunyuanzhao.pressHold)
    DllCall("Sleep", "UInt", skillConfig.Hunyuanzhao.activateDelay)  ; 等待激活

    ; 再按C释放混元罩
    Loop 3 {
        if !isMacroRunning
            break
        pressWaitAndRelease("c", skillConfig.Hunyuanzhao.pressHold)
    }
}

; ============================== 手动技能暂停热键 ==============================
; 不使用热键拦截，在卡刀循环中检测按键状态
; 这样可以实现"暂停在前"：循环检测到按键后先暂停，按键自然透传到游戏
RegisterManualSkillHotkeys_Qigong1() {
    ; 空函数，不注册热键
}

UnregisterManualSkillHotkeys_Qigong1() {
    ; 空函数，不解绑热键
}

; ============================== 卡刀主循环 ==============================
StartSkillLoop_Qigong1(ThisHotkey) {
    global isMainLoopPaused, skillConfig, isMacroRunning, bloodbarConfig, lastHuolianzhangReleaseTime, lastHunyuanzhaoReleaseTime, skillEnable

    if isMainLoopPaused {
        isMacroRunning := false
        return
    }

    isMacroRunning := true

    ; 显示初始状态
    ToolTip "宏运行中", bloodbarConfig.TargetX, bloodbarConfig.TargetY - 30

    local currentTime := 0
    local delayRemaining := 0

    Loop {
        if not GetKeyState(ThisHotkey, "P")
            break

        ; ===== 手动按键检测（暂停在前）=====
        ; 检测1、3、q、e按键，按下时先暂停循环，等待后发送按键
        local manualKey := ""
        local waitTime := 0
        if GetKeyState("1", "P") {
            manualKey := "1"
            waitTime := skillConfig.ManualPause1
        } else if GetKeyState("3", "P") {
            manualKey := "3"
            waitTime := skillConfig.ManualPause3
        } else if GetKeyState("q", "P") {
            manualKey := "q"
            waitTime := skillConfig.ManualPauseQ
        } else if GetKeyState("e", "P") {
            manualKey := "e"
            waitTime := skillConfig.ManualPauseE
        }

        if (manualKey != "") {
            ; 1. 先暂停循环
            isMacroRunning := false

            ; 2. 等待对应的技能时间（让当前循环按键输出完成）
            DllCall("Sleep", "UInt", waitTime)

            ; 3. 发送按键到游戏
            SendEvent("{" manualKey "}")

            ; 4. 恢复循环
            isMacroRunning := true
            continue  ; 跳过本次循环，重新检测
        }

        currentTime := A_TickCount

        ; 火莲掌CD释放（使用配置中的checkTimer作为CD时间）
        if skillEnable.Huolianzhang {
            if (currentTime - lastHuolianzhangReleaseTime >= (skillConfig.Huolianzhang.checkTimer)+500) {
                releaseHuolianzhang_Qigong1()
                lastHuolianzhangReleaseTime := currentTime
            }
        }

        if not GetKeyState(ThisHotkey, "P")
            break

        ; 混元罩CD释放（使用配置中的checkTimer作为CD时间）
        if skillEnable.Hunyuanzhao {
            if (A_TickCount - lastHunyuanzhaoReleaseTime >= (skillConfig.Hunyuanzhao.checkTimer)+500) {
                releaseHunyuanzhao_Qigong1()
                lastHunyuanzhaoReleaseTime := A_TickCount
            }
        }

        if not GetKeyState(ThisHotkey, "P")
            break

        ToolTip "宏运行中", bloodbarConfig.TargetX, bloodbarConfig.TargetY - 30
        SendEvent("{2}")
        DllCall("Sleep", "UInt", skillConfig.pressDelay)

        if not GetKeyState(ThisHotkey, "P")
            break

        SendEvent("{r}")
        DllCall("Sleep", "UInt", skillConfig.pressDelay)

        if not GetKeyState(ThisHotkey, "P")
            break

        SendEvent("{t}")
        DllCall("Sleep", "UInt", skillConfig.pressDelay)

        if not GetKeyState(ThisHotkey, "P")
            break

        SendEvent("{f}")
        DllCall("Sleep", "UInt", skillConfig.pressDelay)

        ; 循环延时（同时检测手动按键）
        delayRemaining := skillConfig.mainLoopDelay
        while (delayRemaining > 0 && GetKeyState(ThisHotkey, "P")) {
            ; 在延时期间检测手动按键
            local delayManualKey := ""
            local delayWaitTime := 0
            if GetKeyState("1", "P") {
                delayManualKey := "1"
                delayWaitTime := skillConfig.ManualPause1
            } else if GetKeyState("3", "P") {
                delayManualKey := "3"
                delayWaitTime := skillConfig.ManualPause3
            } else if GetKeyState("q", "P") {
                delayManualKey := "q"
                delayWaitTime := skillConfig.ManualPauseQ
            } else if GetKeyState("e", "P") {
                delayManualKey := "e"
                delayWaitTime := skillConfig.ManualPauseE
            }

            if (delayManualKey != "") {
                ; 检测到手动按键，立即处理
                isMacroRunning := false
                DllCall("Sleep", "UInt", delayWaitTime)
                SendEvent("{" delayManualKey "}")
                isMacroRunning := true
                ; 重置延时计数，开始新的循环检测
                delayRemaining := 0
                break
            }

            DllCall("Sleep", "UInt", 1)
            delayRemaining -= 1
        }
    }

    ; 清除 ToolTip
    ToolTip
    isMacroRunning := false
}

; ============================== 取色函数 ==============================
PickColors_Qigong1() {
    MsgBox("气功-1系推龙无需取色", "卡刀鸡")
}

; ============================== UI创建函数 ==============================
GetFlowUI_Qigong1(guiObj) {
    global skillEnable, skillConfig, startMainLoopButton

    ; 流派标题
    guiObj.AddText("xm y+10", "流派: 气功 - 1系推龙")

    ; 启动按键选择
    guiObj.AddText("xm y+5", "启动按键:")
    local hotkeyList := ["XButton1", "XButton2", "XButton3", "F1", "F2", "F3", "F4", "F5", "F6"]
    local cboHotkey := guiObj.AddComboBox("x+5 yp w80 vSelectedHotkey_Qigong1", hotkeyList)
    cboHotkey.Text := startMainLoopButton

    ; 循环延迟
    guiObj.AddText("xm y+5", "循环延迟(ms):")
    local edMainLoopDelay := guiObj.AddEdit("x+5 yp w35 Number vMainLoopDelay_Qigong1", skillConfig.mainLoopDelay)

    ; 技能开关
    guiObj.AddText("xm y+15", "技能开关:")
    local cbHuolianzhang := guiObj.AddCheckbox("vCbHuolianzhang_Qigong1", "火莲掌 (X) [需锁冰X]")
    cbHuolianzhang.Value := skillEnable.Huolianzhang

    ; 火莲掌延时输入框（单位毫秒）
    guiObj.AddText("xm+15 y+3", "延时(ms):")
    local edHuoDelay := guiObj.AddEdit("x+5 yp w40 Number vHuolianzhangDelay_Qigong1", skillConfig.Huolianzhang.activateDelay)

    local cbHunyuanzhao := guiObj.AddCheckbox("xm y+5 vCbHunyuanzhao_Qigong1", "混元罩 (C) [需锁火C]")
    cbHunyuanzhao.Value := skillEnable.Hunyuanzhao

    ; 混元罩延时输入框（单位毫秒）
    guiObj.AddText("xm+15 y+3", "延时(ms):")
    local edHunDelay := guiObj.AddEdit("x+5 yp w40 Number vHunyuanzhaoDelay_Qigong1", skillConfig.Hunyuanzhao.activateDelay)

    ; 保存按钮
    local btnSave := guiObj.AddButton("xm y+15 w190 Default", "保存设置")
    btnSave.OnEvent("Click", SaveFlowSettings_Qigong1)
}

; ============================== 保存设置函数 ==============================
SaveFlowSettings_Qigong1(*) {
    global myGui, skillEnable, skillConfig, startMainLoopButton
    local configPath := GetFlowConfigPath("气功_1系推龙")

    local saved := myGui.Submit(false)

    ; 获取新值
    local newHotkey := saved.SelectedHotkey_Qigong1
    local newHuo := saved.CbHuolianzhang_Qigong1
    local newHun := saved.CbHunyuanzhao_Qigong1
    local newMainLoopDelay := saved.MainLoopDelay_Qigong1
    local newHuoDelay := saved.HuolianzhangDelay_Qigong1
    local newHunDelay := saved.HunyuanzhaoDelay_Qigong1

    ; 写入配置文件
    IniWrite(newHotkey, configPath, "Global", "startButton")
    IniWrite(newMainLoopDelay, configPath, "Global", "mainLoopDelay")
    IniWrite(newHuo ? "1" : "0", configPath, "SkillEnable", "Huolianzhang")
    IniWrite(newHun ? "1" : "0", configPath, "SkillEnable", "Hunyuanzhao")
    IniWrite(newHuoDelay, configPath, "Huolianzhang", "activateDelay")
    IniWrite(newHunDelay, configPath, "Hunyuanzhao", "activateDelay")

    ; 重新加载配置并切换热键
    local oldHotkey := startMainLoopButton
    InitFlowConfig_Qigong1()
    SwitchHotkey(startMainLoopButton, oldHotkey, StartSkillLoop_Qigong1)

    ; 更新控件显示
    myGui["SelectedHotkey_Qigong1"].Text := startMainLoopButton
    myGui["MainLoopDelay_Qigong1"].Text := skillConfig.mainLoopDelay
    myGui["CbHuolianzhang_Qigong1"].Value := skillEnable.Huolianzhang
    myGui["HuolianzhangDelay_Qigong1"].Text := skillConfig.Huolianzhang.activateDelay
    myGui["CbHunyuanzhao_Qigong1"].Value := skillEnable.Hunyuanzhao
    myGui["HunyuanzhaoDelay_Qigong1"].Text := skillConfig.Hunyuanzhao.activateDelay

    MsgBox("气功-1系设置已保存并生效。", "卡刀鸡")
}

; ============================== 模块导出接口 ==============================
; 供主程序调用的标准接口函数
GetFlowModule_Qigong1() {
    return {
        name: "气功-1系推龙",
        flowId: "气功_1系推龙",
        job: "气功",
        InitConfig: InitFlowConfig_Qigong1,
        GetUI: GetFlowUI_Qigong1,
        StartLoop: StartSkillLoop_Qigong1,
        PickColors: PickColors_Qigong1,
        SaveSettings: SaveFlowSettings_Qigong1,
        RegisterManualHotkeys: RegisterManualSkillHotkeys_Qigong1,
        UnregisterManualHotkeys: UnregisterManualSkillHotkeys_Qigong1
    }
}