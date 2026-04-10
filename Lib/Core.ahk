; ============================== Core.ahk ==============================
; 公共函数库 - 卡刀宏核心功能
; 包含: 全局变量、辅助函数、配置管理、托盘菜单、热键管理
; ==============================

; ============================== 全局变量 ==============================
; ResourceTempDir 在 Resources.ahk 中定义
global isMainLoopPaused := false
global isMacroRunning := false
global startMainLoopButton := "XButton1"
global currentFlowId := ""        ; 当前激活的流派ID
global currentFlowModule := ""    ; 当前流派模块对象
global skillConfig := {}          ; 当前流派技能配置
global skillEnable := {}          ; 当前流派技能开关
global bloodbarConfig := {}       ; 当前职业血条配置（共享）
global currentJob := ""           ; 当前职业名称
global triggerMode := 0           ; 触发模式：0=长按模式，1=开关模式
global isToggleLoopActive := false ; 开关模式下的循环激活状态
global toggleLock := false        ; 开关模式互斥锁，防止多线程竞争

; ============================== 初始化函数 ==============================
InitCore() {
    ; 设置系统时钟精度为1ms
    DllCall("Winmm\timeBeginPeriod", "UInt", 1)

    ; 确保临时资源目录存在
    if !DirExist(ResourceTempDir)
        DirCreate(ResourceTempDir)

    ; 管理员提权
    if !A_IsAdmin {
        try {
            Run '*RunAs "' A_ScriptFullPath '"'
            ExitApp
        }
    }
}

; ============================== 公共辅助函数 ==============================
; 按键按下并释放
pressKey(key, delay := 5) {
    SendEvent("{" key "}")
    sleepa(delay)
}

; 按键按住后释放
pressWaitAndRelease(keys, hold, delay := 5) {
    SendEvent("{" keys " down}")
    DllCall("Sleep", "UInt", hold)
    SendEvent("{" keys " up}")
    DllCall("Sleep", "UInt", delay)
}

; 精确延时函数（系统时钟精度已在启动时设置为1ms）
sleepa(s) {
    DllCall("Sleep", "UInt", s)
}

; 获取指定坐标的颜色值
GetColor(x, y) {
    return PixelGetColor(x, y)
}

; 检查颜色是否在目标颜色范围内
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

; 检查技能是否可用（通用版本）
checkSkillAvailable(skillName) {
    skill := skillConfig.%skillName%
    colorRange := skill.colorRange
    actualColor1 := GetColor(skill.TargetX1, skill.TargetY1)
    actualColor2 := GetColor(skill.TargetX2, skill.TargetY2)
    return IsColorInRange(actualColor1, skill.TargetColor1, colorRange)
        && IsColorInRange(actualColor2, skill.TargetColor2, colorRange)
}

; ============================== 配置管理函数 ==============================
; 获取配置文件路径
GetFlowConfigPath(flowId) {
    return A_ScriptDir "\Config\flow_" flowId ".ini"
}

GetBloodbarConfigPath() {
    return A_ScriptDir "\Config\bloodbar.ini"
}

; 读取配置项（带默认值）
ReadConfigInt(path, section, key, default := 0) {
    return Integer(IniRead(path, section, key, String(default)))
}

ReadConfigStr(path, section, key, default := "") {
    return IniRead(path, section, key, default)
}

ReadConfigColor(path, section, key, default := "FFFFFF") {
    return "0x" IniRead(path, section, key, default)
}

; 写入配置项
WriteConfig(path, section, key, value) {
    ; 先删除该键，确保不会在末尾创建重复section
    try {
        IniDelete(path, section, key)
    }
    IniWrite(value, path, section, key)
}

WriteConfigColor(path, section, key, color) {
    IniWrite(Format("{:06X}", color), path, section, key)
}

; ============================== 血条配置管理（公共配置） ==============================
LoadBloodbarConfig() {
    global bloodbarConfig, ResourceTempDir
    local path := GetBloodbarConfigPath()

    if !FileExist(path) {
        ; 创建默认血条配置
        CreateDefaultBloodbarConfig()
    }

    bloodbarConfig := {
        TargetX: ReadConfigInt(path, "bloodbar", "TargetX", 1076),
        TargetY: ReadConfigInt(path, "bloodbar", "TargetY", 1090),
        TargetColor: ReadConfigColor(path, "bloodbar", "TargetColor", "CD2525"),
        colorRange: ReadConfigInt(path, "bloodbar", "colorRange", 0)
    }
}

CreateDefaultBloodbarConfig() {
    local path := GetBloodbarConfigPath()
    local configDir := A_ScriptDir "\Config"

    ; 确保Config目录存在
    if !DirExist(configDir)
        DirCreate(configDir)

    local defaultConfig := "
    (LTrim Join`r`n
[bloodbar]
TargetX = 1076
TargetY = 1090
TargetColor = CD2525
colorRange = 0
    )"
    FileAppend(defaultConfig, path, "UTF-8")
}

; 血条取色函数
PickBloodbarColor() {
    global bloodbarConfig, ResourceTempDir, currentJob
    local path := GetBloodbarConfigPath()

    pic := ImagePutBuffer(0)
    search := ImagePutBuffer(ResourceTempDir . "\juesexuetiao.bmp")

    if xy := pic.ImageSearch(search) {
        local FoundX := xy[1]
        local FoundY := xy[2]
        local searchWidth := search.Width
        local searchHeight := search.Height

        bloodbarConfig.TargetX := FoundX
        bloodbarConfig.TargetY := FoundY
        bloodbarConfig.TargetColor := GetColor((FoundX + searchWidth - 2), (FoundY + searchHeight / 2))

        WriteConfig(path, "bloodbar", "TargetX", bloodbarConfig.TargetX)
        WriteConfig(path, "bloodbar", "TargetY", bloodbarConfig.TargetY)
        WriteConfigColor(path, "bloodbar", "TargetColor", bloodbarConfig.TargetColor)

        return true
    } else {
        MsgBox("查找角色血条位置失败，将使用配置文件默认坐标值", "卡刀鸡 - 提示")
        bloodbarConfig.TargetColor := GetColor(bloodbarConfig.TargetX, bloodbarConfig.TargetY)
        WriteConfigColor(path, "bloodbar", "TargetColor", bloodbarConfig.TargetColor)
        return false
    }
}

; ============================== 热键管理 ==============================
; 注册热键
RegisterHotkey(hotkeyName, callback) {
    try {
        Hotkey hotkeyName, callback, "On"
        return true
    } catch as e {
        MsgBox("绑定热键 " hotkeyName " 失败:`n" e.Message, "卡刀鸡 - 错误")
        return false
    }
}

; 解绑热键
UnregisterHotkey(hotkeyName) {
    try {
        Hotkey hotkeyName, "Off"
        return true
    } catch {
        return false
    }
}

; 切换热键
SwitchHotkey(newHotkey, oldHotkey, callback) {
    if (newHotkey = oldHotkey)
        return

    if (oldHotkey != "") {
        UnregisterHotkey(oldHotkey)
        Sleep(50)
    }

    if (newHotkey != "") {
        RegisterHotkey(newHotkey, callback)
    }
}

; ============================== 托盘菜单管理 ==============================
CreateTrayMenu() {
    global isMainLoopPaused
    A_TrayMenu.Delete()
    A_TrayMenu.Add("显示窗口", TrayShow)
    A_TrayMenu.Add()
    local itemText := isMainLoopPaused ? "恢复卡刀宏" : "停止卡刀宏"
    A_TrayMenu.Add(itemText, ToggleMacro)
    A_TrayMenu.Add()
    A_TrayMenu.Add("退出脚本", TrayExit)
    A_TrayMenu.Default := "显示窗口"
}

ToggleMacro(*) {
    global isMainLoopPaused
    isMainLoopPaused := !isMainLoopPaused
    CreateTrayMenu()

    local msg := isMainLoopPaused ? "卡刀宏已停止运行" : "卡刀宏已恢复运行"
    TrayTip("卡刀宏", msg, "Iconi Mute")
    Sleep(2000)
    TrayTip()
}

TrayShow(*) {
    global myGui
    if (myGui != "") {
        myGui.Show()
        WinRestore(myGui.Hwnd)
    }
}

TrayExit(*) {
    global ResourceTempDir
    try {
        if DirExist(ResourceTempDir) {
            DirDelete(ResourceTempDir, true)
        }
    }
    DllCall("Winmm\timeEndPeriod", "UInt", 1)
    ExitApp
}

; ============================== 窗口事件处理 ==============================
GuiClose(*) {
    global myGui
    if (myGui != "") {
        myGui.Hide()
    }
}

GuiSize(thisGui, MinMax, Width, Height) {
    if (MinMax = -1)
        thisGui.Hide()
}