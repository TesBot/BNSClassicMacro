#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 10
SetWorkingDir A_ScriptDir

; Ahk2Exe-Include=ImagePut.ahk
#Include ImagePut.ahk

; ============================== 资源打包与路径映射 ==============================
global ResourceTempDir := A_Temp . "\KadaoMacro_Res"
if !DirExist(ResourceTempDir)
    DirCreate(ResourceTempDir)

; --- FileInstall 列表开始 ---
; 请确保编译前 pic 文件夹下有这些文件
FileInstall("pic\juesexuetiao.bmp", ResourceTempDir . "\juesexuetiao.bmp", 1)
FileInstall("pic\qigong-huolianzhang.bmp", ResourceTempDir . "\qigong-huolianzhang.bmp", 1)
FileInstall("pic\qigong-hunyuanzhao.bmp", ResourceTempDir . "\qigong-hunyuanzhao.bmp", 1)
; --- FileInstall 列表结束 ---


; ============================== 提权 ==============================
if !A_IsAdmin
{
    try
    {
        Run '*RunAs "' A_ScriptFullPath '"'
        ExitApp
    }
}

; ============================== 全局变量 ==============================
global configPath := A_ScriptDir "\qigong_zhuorelianpo_config.ini"
global skillConfig := {}
global isMainLoopPaused := false ; 用于托盘菜单暂停整个宏
global startMainLoopButton := "XButton1"
global skillEnable := {}         

; 【新增】技能释放互斥锁标志
; 当为 true 时，表示 SetTimer 正在执行技能释放，主循环必须等待
global isSkillReleasing := false 

; ============================== 基础辅助函数 ==============================
pressKey(key, delay:=skillConfig.pressDelay) {
    SendInput key
    sleepa(delay)
}

pressWaitAndRelease(keys, hold, delay:=skillConfig.pressDelay) {
    Send "{" keys " down}"
    sleepa(hold)
    Send "{" keys " up}"
    sleepa(delay)
}

sleepa(s) {
    DllCall("Winmm\timeBeginPeriod", "UInt", 1)
    DllCall("Sleep", "UInt", s)
    DllCall("Winmm\timeEndPeriod", "UInt", 1)
}

GetColor(x, y) {
    return PixelGetColor(x, y)
}

IsColorInRange(color, targetColor, colorRange := 10) {
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF

    targetR := (targetColor >> 16) & 0xFF
    targetG := (targetColor >> 8) & 0xFF
    targetB := targetColor & 0xFF

    minR := Max(0, targetR - colorRange)
    maxR := Min(255, targetR + colorRange)
    minG := Max(0, targetG - colorRange)
    maxG := Min(255, targetG + colorRange)
    minB := Max(0, targetB - colorRange)
    maxB := Min(255, targetB + colorRange)

    return (r >= minR && r <= maxR) && (g >= minG && g <= maxG) && (b >= minB && b <= maxB)
}

checkSkillAvailable(skillName) {
    skill := skillConfig.%skillName%
    colorRange := skill.colorRange
    actualColor1 := GetColor(skill.TargetX1, skill.TargetY1)
    actualColor2 := GetColor(skill.TargetX2, skill.TargetY2)
    return IsColorInRange(actualColor1, skill.TargetColor1, colorRange) 
        && IsColorInRange(actualColor2, skill.TargetColor2, colorRange)
}

checkHuolianzhang() {
    global skillEnable
    if !skillEnable.Huolianzhang {
        return false
    }
    return checkSkillAvailable("Huolianzhang")
}
checkHunyuanzhao() {
    global skillEnable
    if !skillEnable.Hunyuanzhao {
        return false
    }
    return checkSkillAvailable("Hunyuanzhao")
}

; ============================== 技能释放函数 (SetTimer 回调) ==============================
; 增加了 isSkillReleasing 标志位的控制
setHuolianzhangReleaseTimer() {
    global isSkillReleasing, isMainLoopPaused

    ; 如果主循环被用户暂停，或者正在释放其他技能，直接返回
    if isMainLoopPaused or isSkillReleasing {
        return
    }

    if checkHuolianzhang() {
        ; 1. 锁定：告诉主循环“我要开始放技能了，你暂停”
        isSkillReleasing := true
        try {
            ToolTip "宏运行中: 释放 火莲掌", skillConfig.bloodbar.TargetX, skillConfig.bloodbar.TargetY - 30
            
            ; 执行技能逻辑
            Loop 5 {
                pressKey("x")
                pressWaitAndRelease("x", skillConfig.Huolianzhang.pressHold)
            }
            
            ToolTip
        } finally {
            ; 2. 解锁：无论是否出错，都确保主循环可以继续
            isSkillReleasing := false
        }
    }
}

setHunyuanzhaoReleaseTimer() {
    global isSkillReleasing, isMainLoopPaused

    if isMainLoopPaused or isSkillReleasing {
        return
    }

    if checkHunyuanzhao() {
        ; 1. 锁定
        isSkillReleasing := true
        try {
            ToolTip "宏运行中: 使用 混元罩", skillConfig.bloodbar.TargetX, skillConfig.bloodbar.TargetY - 30
            
            Loop 5 {
                pressKey("c")
                pressWaitAndRelease("c", skillConfig.Hunyuanzhao.pressHold)
            }
            
            ToolTip
        } finally {
            ; 2. 解锁：无论是否出错，都确保主循环可以继续
            isSkillReleasing := false
        }
    }
}

setALLTimer(is_start) {
    if is_start == true {
        SetTimer setHuolianzhangReleaseTimer, skillConfig.Huolianzhang.checkTimer
        SetTimer setHunyuanzhaoReleaseTimer, skillConfig.Hunyuanzhao.checkTimer
    } else {
        SetTimer setHuolianzhangReleaseTimer, 0
        SetTimer setHunyuanzhaoReleaseTimer, 0
        isSkillReleasing := false ; 确保停止时锁被释放
    }
}

checkAndStart(param, keys, checkFun, delay, skip_check := false) {
    if checkFun() or skip_check {
        Send "{" keys " down}"
        sleepa(delay)
        Send "{" keys " up}"
        return checkFun()
    }
}

; ============================== 配置读写函数 ==============================
CreateDefaultConfig() {
    global configPath
    defaultConfig := "
    (LTrim Join`r`n
[Global]
; 自定义启动按键（XButton1:鼠标侧键1，XButton2:鼠标侧键2...等）
startBotton = XButton1
;召唤RT循环延迟（毫秒）
mainLoopDelay = 10
;全局按键延迟（毫秒）
pressDelay = 5

[SkillEnable]
; 技能释放开关，默认开启（1）, 关闭（0）
Huolianzhang =0
Hunyuanzhao =0

; 火莲掌（X键）配置
[Huolianzhang]
pressHold = 10
checkTimer = 100
colorRange = 20
TargetX1 =1602
TargetY1 =801
TargetColor1 =CAEA24
TargetX2 =1617
TargetY2 =795
TargetColor2 =3E6000

; 混元罩（C键）配置
[Hunyuanzhao]
pressHold = 10
checkTimer = 100
colorRange = 20
TargetX1 =1179
TargetY1 =1227
TargetColor1 =FFEC5F
TargetX2 =1195
TargetY2 =1222
TargetColor2 =F0C534

[bloodbar]
TargetX =1076
TargetY =1090
TargetColor =CD2525
    )"
    FileAppend(defaultConfig, configPath, "UTF-8")
}

InitConfig() {
    global configPath, skillConfig, startMainLoopButton, skillEnable
    if !FileExist(configPath) {
        CreateDefaultConfig()
    }

    skillConfig.Hunyuanzhao := {
        TargetX1: IniRead(configPath, "Hunyuanzhao", "TargetX1", 0),
        TargetY1: IniRead(configPath, "Hunyuanzhao", "TargetY1", 0),
        TargetColor1: "0x" IniRead(configPath, "Hunyuanzhao", "TargetColor1", "FFFFFF"),
        TargetX2: IniRead(configPath, "Hunyuanzhao", "TargetX2", 0),
        TargetY2: IniRead(configPath, "Hunyuanzhao", "TargetY2", 0),
        TargetColor2: "0x" IniRead(configPath, "Hunyuanzhao", "TargetColor2", "FFFFFF"),
        colorRange: IniRead(configPath, "Hunyuanzhao", "colorRange", 0),
        pressHold: IniRead(configPath, "Hunyuanzhao", "pressHold", 0),
        checkTimer: IniRead(configPath, "Hunyuanzhao", "checkTimer", 0)
    }

    skillConfig.Huolianzhang := {
        TargetX1: IniRead(configPath, "Huolianzhang", "TargetX1", 0),
        TargetY1: IniRead(configPath, "Huolianzhang", "TargetY1", 0),
        TargetColor1: "0x" IniRead(configPath, "Huolianzhang", "TargetColor1", "FFFFFF"),
        TargetX2: IniRead(configPath, "Huolianzhang", "TargetX2", 0),
        TargetY2: IniRead(configPath, "Huolianzhang", "TargetY2", 0),
        TargetColor2: "0x" IniRead(configPath, "Huolianzhang", "TargetColor2", "FFFFFF"),
        colorRange: IniRead(configPath, "Huolianzhang", "colorRange", 0),
        pressHold: IniRead(configPath, "Huolianzhang", "pressHold", 0),
        checkTimer: IniRead(configPath, "Huolianzhang", "checkTimer", 0)
    }

    skillConfig.bloodbar := {
        TargetX: IniRead(configPath, "bloodbar", "TargetX", 0),
        TargetY: IniRead(configPath, "bloodbar", "TargetY", 0),
        TargetColor: "0x" IniRead(configPath, "bloodbar", "TargetColor", "FFFFFF"),
        colorRange: IniRead(configPath, "bloodbar", "colorRange", 0)
    }

    val := IniRead(configPath, "SkillEnable", "Hunyuanzhao", "0")
    skillEnable.Hunyuanzhao := (val = "1" or val = "true") ? 1 : 0
    val := IniRead(configPath, "SkillEnable", "Huolianzhang", "0")
    skillEnable.Huolianzhang := (val = "1" or val = "true") ? 1 : 0

    skillConfig.pressDelay := IniRead(configPath, "Global", "pressDelay", 100)
    skillConfig.mainLoopDelay := IniRead(configPath, "Global", "mainLoopDelay", 100)
    skillConfig.startBotton := IniRead(configPath, "Global", "startBotton", "XButton1")
    startMainLoopButton := skillConfig.startBotton
}

; ============================== 主循环函数 (核心修改处) ==============================
StartSkillLoop(ThisHotkey) {
    global isMainLoopPaused, startMainLoopButton, isSkillReleasing    

    if isMainLoopPaused {
        setALLTimer(false)
        return
    }

    setALLTimer(true)

    Loop {
        ; 每轮开始先判断是否已经松开启动键，松开则直接退出主循环
        if !GetKeyState(ThisHotkey, "P") {
            break
        }

        ; 【关键修改】在每次循环开始前，检查是否正在释放技能
        ; 如果 isSkillReleasing 为 true，说明 SetTimer 线程正在占用键盘发送技能
        ; 此时主循环必须等待，否则会冲突
        ; 同时增加超时保护，防止因异常导致永久卡死
        if (isSkillReleasing) {
            waitStart := A_TickCount
            while (isSkillReleasing) {
                Sleepa 10 ; 短暂睡眠，避免死循环占满CPU，同时快速响应解锁
                if (A_TickCount - waitStart > 100) { ; 最多等 100 毫秒
                    ; 超时自动解锁，避免主循环永远卡死
                    isSkillReleasing := false
                    break
                }
            }
        }

        ; 再次检查主循环暂停状态（防止在等待技能释放期间用户暂停了宏）
        if (isMainLoopPaused) {
            break
        }

        ToolTip "宏运行中:", skillConfig.bloodbar.TargetX, skillConfig.bloodbar.TargetY - 30
        
        ; 执行卡刀循环
        pressKey("2")
        pressKey("r")
        pressKey("t")
        pressKey("f")
        
        sleepa(skillConfig.mainLoopDelay)
    }

    ToolTip
    setALLTimer(false)
    isSkillReleasing := false ; 确保退出循环时锁被释放
}

; ============================== 调试热键 ==============================
; (保持原有代码不变，仅展示部分结构)
^r::
{
    global startMainLoopButton, skillConfig, skillEnable
    oldHotkey := startMainLoopButton
    InitConfig()
    SwitchHotkey(startMainLoopButton, oldHotkey)
    
    ; ... (原有 MsgBox 代码) ...
    configInfo := "===== 技能配置文件读取结果 =====`n`n"
    configInfo .= "【全局配置】`n启动摁键：" startMainLoopButton "`n"
    configInfo .= "循环延迟：" skillConfig.mainLoopDelay " ms`n"
    configInfo .= "【状态】`n火莲掌开关：" skillEnable.Huolianzhang "`n"
    configInfo .= "混元罩开关：" skillEnable.Hunyuanzhao "`n"
    configInfo .= "当前是否正在释放技能：" (isSkillReleasing ? "是" : "否") "`n"
    configInfo .= "配置文件路径：" configPath
    MsgBox configInfo, "配置读取结果", "Iconi"
    ToolTip
}

^p::
{
    ; (原有取色代码保持不变)
    global FoundX, FoundY, searchWidth, searchHeight, Q1CenterX, Q1CenterY, Q4CenterX, Q4CenterY, skillConfig

    pic := ImagePutBuffer(0)
    search := ImagePutBuffer(ResourceTempDir . "\juesexuetiao.bmp")
    searchWidth := search.Width
    searchHeight := search.Height
    if xy := pic.ImageSearch(search) {
        FoundX := xy[1]
        FoundY := xy[2]
        skillConfig.bloodbar.TargetX := FoundX
        skillConfig.bloodbar.TargetY := FoundY
        skillConfig.bloodbar.TargetColor := GetColor((FoundX + searchWidth - 2), (FoundY + searchHeight / 2))
        IniWrite(skillConfig.bloodbar.TargetX, configPath, "bloodbar", "TargetX")
        IniWrite(skillConfig.bloodbar.TargetY, configPath, "bloodbar", "TargetY")
        IniWrite(Format("{:06X}", skillConfig.bloodbar.TargetColor), configPath, "bloodbar", "TargetColor")
    } else {
        MsgBox "查找角色血条位置失败，将使用配置文件默认坐标值"
        FoundX := skillConfig.bloodbar.TargetX
        FoundY := skillConfig.bloodbar.TargetY
        skillConfig.bloodbar.TargetColor := GetColor((FoundX + searchWidth - 2), (FoundY + searchHeight / 2))
        IniWrite(Format("{:06X}", skillConfig.bloodbar.TargetColor), configPath, "bloodbar", "TargetColor")
    }

    ; 火莲掌
    pic := ImagePutBuffer(0)
    search := ImagePutBuffer(ResourceTempDir . "\qigong-huolianzhang.bmp")
    searchWidth := search.Width
    searchHeight := search.Height
    if xy := pic.ImageSearch(search) {
        FoundX := xy[1]
        FoundY := xy[2]
        Q1CenterX := Round(FoundX + searchWidth / 4)
        Q1CenterY := Round(FoundY + searchHeight / 4)
        Q4CenterX := Round(FoundX + searchWidth * 4 / 7)
        Q4CenterY := Round(FoundY + searchHeight * 1 / 7)
        skillConfig.Huolianzhang.TargetX1 := Q1CenterX
        skillConfig.Huolianzhang.TargetY1 := Q1CenterY
        skillConfig.Huolianzhang.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.Huolianzhang.TargetX2 := Q4CenterX
        skillConfig.Huolianzhang.TargetY2 := Q4CenterY
        skillConfig.Huolianzhang.TargetColor2 := GetColor(Q4CenterX, Q4CenterY)
        IniWrite(skillConfig.Huolianzhang.TargetX1, configPath, "Huolianzhang", "TargetX1")
        IniWrite(skillConfig.Huolianzhang.TargetY1, configPath, "Huolianzhang", "TargetY1")
        IniWrite(Format("{:06X}", skillConfig.Huolianzhang.TargetColor1), configPath, "Huolianzhang", "TargetColor1")
        IniWrite(skillConfig.Huolianzhang.TargetX2, configPath, "Huolianzhang", "TargetX2")
        IniWrite(skillConfig.Huolianzhang.TargetY2, configPath, "Huolianzhang", "TargetY2")
        IniWrite(Format("{:06X}", skillConfig.Huolianzhang.TargetColor2), configPath, "Huolianzhang", "TargetColor2")
    } else {
        MsgBox "查找 火莲掌X 技能目标位置失败，将使用配置文件默认坐标值"
        sleepa 500
        Q1CenterX := skillConfig.Huolianzhang.TargetX1
        Q1CenterY := skillConfig.Huolianzhang.TargetY1
        Q4CenterX := skillConfig.Huolianzhang.TargetX2
        Q4CenterY := skillConfig.Huolianzhang.TargetY2
        newColor1 := GetColor(Q1CenterX, Q1CenterY)
        newColor2 := GetColor(Q4CenterX, Q4CenterY)
        IniWrite(Format("{:06X}", newColor1), configPath, "Huolianzhang", "TargetColor1")
        IniWrite(Format("{:06X}", newColor2), configPath, "Huolianzhang", "TargetColor2")
    }

    ; 混元罩
    pressKey("t") 
    sleepa 1000

    pic := ImagePutBuffer(0)
    search := ImagePutBuffer(ResourceTempDir . "\qigong-hunyuanzhao.bmp")
    searchWidth := search.Width
    searchHeight := search.Height
    if xy := pic.ImageSearch(search) {
        FoundX := xy[1]
        FoundY := xy[2]
        Q1CenterX := Round(FoundX + searchWidth / 4)
        Q1CenterY := Round(FoundY + searchHeight / 4)
        Q4CenterX := Round(FoundX + searchWidth * 4 / 7)
        Q4CenterY := Round(FoundY + searchHeight * 1 / 7)
        skillConfig.Hunyuanzhao.TargetX1 := Q1CenterX
        skillConfig.Hunyuanzhao.TargetY1 := Q1CenterY
        skillConfig.Hunyuanzhao.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.Hunyuanzhao.TargetX2 := Q4CenterX
        skillConfig.Hunyuanzhao.TargetY2 := Q4CenterY
        skillConfig.Hunyuanzhao.TargetColor2 := GetColor(Q4CenterX, Q4CenterY)
        IniWrite(skillConfig.Hunyuanzhao.TargetX1, configPath, "Hunyuanzhao", "TargetX1")
        IniWrite(skillConfig.Hunyuanzhao.TargetY1, configPath, "Hunyuanzhao", "TargetY1")
        IniWrite(Format("{:06X}", skillConfig.Hunyuanzhao.TargetColor1), configPath, "Hunyuanzhao", "TargetColor1")
        IniWrite(skillConfig.Hunyuanzhao.TargetX2, configPath, "Hunyuanzhao", "TargetX2")
        IniWrite(skillConfig.Hunyuanzhao.TargetY2, configPath, "Hunyuanzhao", "TargetY2")
        IniWrite(Format("{:06X}", skillConfig.Hunyuanzhao.TargetColor2), configPath, "Hunyuanzhao", "TargetColor2")
    } else {
        MsgBox "查找 混元罩C 技能目标位置失败，将使用配置文件默认坐标值"
        sleepa 500
        Q1CenterX := skillConfig.Hunyuanzhao.TargetX1
        Q1CenterY := skillConfig.Hunyuanzhao.TargetY1
        Q4CenterX := skillConfig.Huolianzhang.TargetX2 ; 注意这里原代码可能有误，应为 Hunyuanzhao
        Q4CenterY := skillConfig.Huolianzhang.TargetY2
        skillConfig.Hunyuanzhao.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.Hunyuanzhao.TargetColor2 := GetColor(Q4CenterX, Q4CenterY)
        IniWrite(Format("{:06X}", skillConfig.Hunyuanzhao.TargetColor1), configPath, "Hunyuanzhao", "TargetColor1")
        IniWrite(Format("{:06X}", skillConfig.Hunyuanzhao.TargetColor2), configPath, "Hunyuanzhao", "TargetColor2")
    }

    InitConfig()
    MsgBox "取色+保存完成！"
}

; ============================== 初始化 ==============================
InitConfig()
Hotkey startMainLoopButton, StartSkillLoop

; ============================== 图形界面 ==============================
global myGui := ""

CreateGui() {
    global myGui, skillEnable, startMainLoopButton, skillConfig, configPath
    myGui := Gui("+MinSize -MaximizeBox", "气功-卡刀 v0.9")
    myGui.SetFont("s9", "Microsoft YaHei")

    myGui.AddText("xm y+10", "流派：2系 - 灼热连破")
    myGui.AddText("xm y+10", "启动摁键 (长摁启动卡刀):")
    hotkeyList := ["XButton1", "XButton2", "XButton3", "F1", "F2", "F3", "F4", "F5", "F6"]
    cboHotkey := myGui.AddComboBox("vSelectedHotkey w120", hotkeyList)
    cboHotkey.Text := startMainLoopButton

    myGui.AddText("xm y+5", "循环延迟(ms):")
    edMainLoopDelay := myGui.AddEdit("x+5 yp w35 Number vMainLoopDelay", skillConfig.mainLoopDelay)

    myGui.AddText("xm y+15", "技能开关:")
    cbHuolianzhang := myGui.AddCheckbox("vCbHuolianzhang", "火莲掌 (X)")
    cbHuolianzhang.Value := skillEnable.Huolianzhang    
    cbHunyuanzhao := myGui.AddCheckbox("vCbHunyuanzhao", "混元罩 (C)")
    cbHunyuanzhao.Value := skillEnable.Hunyuanzhao  
    
    btnSave := myGui.AddButton("xm y+15 w80 Default", "保存设置")
    btnSave.OnEvent("Click", SaveSettings)

    gb2 := myGui.AddGroupBox("xm y+15 w240 h140", "说明")
    myGui.AddText("xs+2 yp+20", "1. 面对木桩摁下 Ctrl+P 进行取色")
    myGui.AddText("xs+2 yp+20", " 注意：")
    myGui.AddText("xs+2 yp+20", "1. 默认屏幕分辨率为 2560x1440")
    myGui.AddText("xs+2 yp+20", "2. 配置变动后需要点击 <保存设置>")
    myGui.AddText("xs+2 yp+20", "3. 参数配置文件修改后 Ctrl+R 重新加载")
    myGui.AddText("xs+2 yp+20", "4. 关闭本窗口后程序仍会在右下角继续运行")

    myGui.OnEvent("Close", GuiClose)
    myGui.OnEvent("Escape", GuiClose)
    myGui.OnEvent("Size", GuiSize)

    CreateTrayMenu()
    myGui.Show("w260")
}

SwitchHotkey(newHotkey, oldHotkey) {
    if (newHotkey = oldHotkey) {
        return
    }
    if (oldHotkey != "") {
        Hotkey oldHotkey, "Off"
        Sleep 50
    }
    try {
        Hotkey newHotkey, StartSkillLoop, "On"
    } catch as e {
        MsgBox "绑定热键 " newHotkey " 失败:`n"
    }
}

SaveSettings(*)
{
    global myGui, configPath, startMainLoopButton, skillEnable, skillConfig
    saved := myGui.Submit(false)
    newHotkey := saved.SelectedHotkey
    newHuo := saved.cbHuolianzhang
    newHun := saved.cbHunyuanzhao
    newMainLoopDelay := saved.MainLoopDelay

    IniWrite(newHotkey, configPath, "Global", "startBotton")
    IniWrite(newMainLoopDelay, configPath, "Global", "mainLoopDelay")
    IniWrite(newHuo ? "1" : "0", configPath, "SkillEnable", "Huolianzhang")
    IniWrite(newHun ? "1" : "0", configPath, "SkillEnable", "Hunyuanzhao")

    oldHotkey := startMainLoopButton
    InitConfig()
    SwitchHotkey(startMainLoopButton, oldHotkey)
    
    myGui["SelectedHotkey"].Text := startMainLoopButton
    myGui["MainLoopDelay"].Text := skillConfig.mainLoopDelay
    myGui["CbHuolianzhang"].Value := skillEnable.Huolianzhang
    myGui["CbHunyuanzhao"].Value := skillEnable.Hunyuanzhao 

    MsgBox "设置已保存并生效。", "提示", "Iconi T2"
}

; ============================== 托盘菜单 ==============================
ToggleMacro(*)
{
    global isMainLoopPaused
    isMainLoopPaused := !isMainLoopPaused
    CreateTrayMenu()
    if !isMainLoopPaused {
        TrayTip "卡刀宏已恢复运行", "石头 - 卡刀宏", "Iconi Mute"
        sleepa 2000
    } else {
        TrayTip "卡刀宏已停止运行", "石头 - 卡刀宏", "Iconi Mute"
        sleepa 2000
    }
    TrayTip
}

CreateTrayMenu()
{
    A_TrayMenu.Delete()
    A_TrayMenu.Add("显示窗口", TrayShow)
    A_TrayMenu.Add()
    itemText := isMainLoopPaused ? "恢复卡刀宏" : "停止卡刀宏"
    A_TrayMenu.Add(itemText, ToggleMacro)
    A_TrayMenu.Add()
    A_TrayMenu.Add("退出脚本", TrayExit)
    A_TrayMenu.Default := "显示窗口"
    TraySetIcon "shell32.dll", 44
}

TrayShow(*)
{
    global myGui
    myGui.Show()
}

TrayExit(*)
{
    ExitApp
}

GuiClose(*)
{
    global myGui
    myGui.Hide()
}

GuiSize(thisGui, MinMax, Width, Height)
{
    if (MinMax = -1)
        thisGui.Hide()
}

CreateGui()