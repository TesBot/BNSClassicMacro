#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 2
SetWorkingDir A_ScriptDir

#Include ImagePut.ahk

; ============================== 提权 使用管理员权限启动 ==============================
if !A_IsAdmin
{
    try
    {
        Run '*RunAs "' A_ScriptFullPath '"'
        ExitApp
    }
}

; ============================== 全局变量 ==============================
global configPath := A_ScriptDir "\zhaohuan_gongxue_config.ini"
global skillConfig := {}
global isMainLoopPaused := false
global startMainLoopButton := "XButton1"
global skillEnable := {}          ; 技能释放开关

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

checkQianniuhua() {
    global skillEnable
    if !skillEnable.Qianniuhua
        return false
    return checkSkillAvailable("Qianniuhua")
}
checkYamao() {
    global skillEnable
    if !skillEnable.Yamao
        return false
    return checkSkillAvailable("Yamao")
}
checkJineng1() {
    global skillEnable
    if !skillEnable.Jineng1
        return false
    return checkSkillAvailable("jineng1")
}
checkJineng2() {
    global skillEnable
    if !skillEnable.Jineng2
        return false
    return checkSkillAvailable("jineng2")
}
checkNaonao() {
    return checkSkillAvailable("naonao")
}
checkMiaohuoliuxing() {
    return checkSkillAvailable("miaohuoliuxing")
}

; ============================== 技能释放函数 ==============================
setQianniuhuaReleaseTimer() {
    if checkQianniuhua() {
        ToolTip "宏运行中: 释放 向日葵", skillConfig.bloodbar.TargetX, skillConfig.bloodbar.TargetY - 30
        Loop 5 {
            pressKey("f")
            pressWaitAndRelease("f", skillConfig.Qianniuhua.pressHold)
        }
        ToolTip
    }
}

setJineng1ReleaseTimer() {
    if checkJineng1() {
        ToolTip "宏运行中: 释放 技能1", skillConfig.bloodbar.TargetX, skillConfig.bloodbar.TargetY - 30
        Loop 5 {
            pressKey("1")
            pressWaitAndRelease("1", skillConfig.jineng1.pressHold)
        }
        ToolTip
    }
}

setJineng2ReleaseTimer() {
    if checkJineng2() {
        ToolTip "宏运行中: 释放 技能2", skillConfig.bloodbar.TargetX, skillConfig.bloodbar.TargetY - 30
        Loop 5 {
            pressKey("2")
            pressWaitAndRelease("2", skillConfig.jineng2.pressHold)
        }
        ToolTip
    }
}

setYamaoReleaseTimer() {
    global isYamaoPressed := false
    if checkYamao() && !isYamaoPressed {
        ToolTip "宏运行中: 使用 压猫", skillConfig.bloodbar.TargetX, skillConfig.bloodbar.TargetY - 30
        isYamaoPressed := true
        pressKey("{Tab}")
        sleepa 1000

        ToolTip "宏运行中: 使用 挠挠", skillConfig.bloodbar.TargetX, skillConfig.bloodbar.TargetY - 30
        Loop 5 {
            pressKey("x")
            pressWaitAndRelease("x", skillConfig.naonao.pressHold)
        }
        sleepa skillConfig.naonao.xcxDelay

        ToolTip "宏运行中: 使用 喵火流星", skillConfig.bloodbar.TargetX, skillConfig.bloodbar.TargetY - 30
        Loop 10 {
            pressKey("c")
            pressWaitAndRelease("c", skillConfig.miaohuoliuxing.pressHold)
        }
        sleepa skillConfig.miaohuoliuxing.xcxDelay

        ToolTip "宏运行中: 使用 挠挠", skillConfig.bloodbar.TargetX, skillConfig.bloodbar.TargetY - 30
        Loop 10 {
            pressKey("x")
            pressWaitAndRelease("x", skillConfig.miaohuoliuxing.pressHold)
        }
        isYamaoPressed := false
        ToolTip
    }
}

setALLTimer(is_start) {
    if is_start == true {
        SetTimer setQianniuhuaReleaseTimer, skillConfig.Qianniuhua.checkTimer
        SetTimer setYamaoReleaseTimer, skillConfig.Yamao.checkTimer
        SetTimer setJineng1ReleaseTimer, skillConfig.jineng1.checkTimer
        SetTimer setJineng2ReleaseTimer, skillConfig.jineng2.checkTimer
    } else {
        SetTimer setQianniuhuaReleaseTimer, 0
        SetTimer setYamaoReleaseTimer, 0
        SetTimer setJineng1ReleaseTimer, 0
        SetTimer setJineng2ReleaseTimer, 0
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
pressDelay = 50

[SkillEnable]
; 技能释放开关，默认开启（1）, 关闭（0）
Qianniuhua =1
Yamao =1
Jineng1 =1
Jineng2 =1

; 技能取色配置 - 默认坐标在2K分辨率下
; 牵牛花（F键）配置
[Qianniuhua]
pressHold = 10
checkTimer = 250
colorRange = 20
TargetX1 =1602
TargetY1 =801
TargetColor1 =CAEA24
TargetX2 =1617
TargetY2 =795
TargetColor2 =3E6000

; 技能1键配置
[jineng1]
pressHold = 10
checkTimer = 1000
colorRange = 20
TargetX1 =1179
TargetY1 =1227
TargetColor1 =FFEC5F
TargetX2 =1195
TargetY2 =1222
TargetColor2 =F0C534

; 技能2键配置
[jineng2]
pressHold = 10
checkTimer = 1000
colorRange = 20
TargetX1 =1236
TargetY1 =1228
TargetColor1 =8D9D8C
TargetX2 =1251
TargetY2 =1222
TargetColor2 =015775

; 压猫（tab键）配置
[Yamao]
pressHold = 10
checkTimer =200
colorRange = 20
TargetX1 =1079
TargetY1 =1228
TargetColor1 =F8F7F7
TargetX2 =1092
TargetY2 =1223
TargetColor2 =4E3633

; 压猫后-(挠挠X) 技能
[naonao]
pressHold = 10
colorRange = 20
TargetX1 =1235
TargetY1 =1317
TargetColor1 =D7C6D6
TargetX2 =1252
TargetY2 =1312
TargetColor2 =4B074B
xcxDelay = 2200

; 压猫后-(喵火流星C) 技能
[miaohuoliuxing]
pressHold = 10
colorRange = 20
TargetX1 = 1606
TargetY1 = 804
TargetColor1 = 7E5284
TargetX2 = 1624
TargetY2 = 800
TargetColor2 = CEF312
xcxDelay = 1200

; 角色血条位置
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

    skillConfig.Qianniuhua := {
        TargetX1: IniRead(configPath, "Qianniuhua", "TargetX1", 0),
        TargetY1: IniRead(configPath, "Qianniuhua", "TargetY1", 0),
        TargetColor1: "0x" IniRead(configPath, "Qianniuhua", "TargetColor1", "FFFFFF"),
        TargetX2: IniRead(configPath, "Qianniuhua", "TargetX2", 0),
        TargetY2: IniRead(configPath, "Qianniuhua", "TargetY2", 0),
        TargetColor2: "0x" IniRead(configPath, "Qianniuhua", "TargetColor2", "FFFFFF"),
        colorRange: IniRead(configPath, "Qianniuhua", "colorRange", 0),
        pressHold: IniRead(configPath, "Qianniuhua", "pressHold", 0),
        checkTimer: IniRead(configPath, "Qianniuhua", "checkTimer", 0)
    }

    skillConfig.Yamao := {
        TargetX1: IniRead(configPath, "Yamao", "TargetX1", 0),
        TargetY1: IniRead(configPath, "Yamao", "TargetY1", 0),
        TargetColor1: "0x" IniRead(configPath, "Yamao", "TargetColor1", "FFFFFF"),
        TargetX2: IniRead(configPath, "Yamao", "TargetX2", 0),
        TargetY2: IniRead(configPath, "Yamao", "TargetY2", 0),
        TargetColor2: "0x" IniRead(configPath, "Yamao", "TargetColor2", "FFFFFF"),
        colorRange: IniRead(configPath, "Yamao", "colorRange", 0),
        pressHold: IniRead(configPath, "Yamao", "pressHold", 0),
        checkTimer: IniRead(configPath, "Yamao", "checkTimer", 0)
    }

    skillConfig.jineng1 := {
        TargetX1: IniRead(configPath, "jineng1", "TargetX1", 0),
        TargetY1: IniRead(configPath, "jineng1", "TargetY1", 0),
        TargetColor1: "0x" IniRead(configPath, "jineng1", "TargetColor1", "FFFFFF"),
        TargetX2: IniRead(configPath, "jineng1", "TargetX2", 0),
        TargetY2: IniRead(configPath, "jineng1", "TargetY2", 0),
        TargetColor2: "0x" IniRead(configPath, "jineng1", "TargetColor2", "FFFFFF"),
        colorRange: IniRead(configPath, "jineng1", "colorRange", 0),
        pressHold: IniRead(configPath, "jineng1", "pressHold", 0),
        checkTimer: IniRead(configPath, "jineng1", "checkTimer", 0)
    }

    skillConfig.jineng2 := {
        TargetX1: IniRead(configPath, "jineng2", "TargetX1", 0),
        TargetY1: IniRead(configPath, "jineng2", "TargetY1", 0),
        TargetColor1: "0x" IniRead(configPath, "jineng2", "TargetColor1", "FFFFFF"),
        TargetX2: IniRead(configPath, "jineng2", "TargetX2", 0),
        TargetY2: IniRead(configPath, "jineng2", "TargetY2", 0),
        TargetColor2: "0x" IniRead(configPath, "jineng2", "TargetColor2", "FFFFFF"),
        colorRange: IniRead(configPath, "jineng2", "colorRange", 0),
        pressHold: IniRead(configPath, "jineng2", "pressHold", 0),
        checkTimer: IniRead(configPath, "jineng2", "checkTimer", 0)
    }

    skillConfig.naonao := {
        TargetX1: IniRead(configPath, "naonao", "TargetX1", 0),
        TargetY1: IniRead(configPath, "naonao", "TargetY1", 0),
        TargetColor1: "0x" IniRead(configPath, "naonao", "TargetColor1", "FFFFFF"),
        TargetX2: IniRead(configPath, "naonao", "TargetX2", 0),
        TargetY2: IniRead(configPath, "naonao", "TargetY2", 0),
        TargetColor2: "0x" IniRead(configPath, "naonao", "TargetColor2", "FFFFFF"),
        colorRange: IniRead(configPath, "naonao", "colorRange", 0),
        pressHold: IniRead(configPath, "naonao", "pressHold", 0),
        checkTimer: IniRead(configPath, "naonao", "checkTimer", 0),
        xcxDelay: IniRead(configPath, "naonao", "xcxDelay", 0)
    }

    skillConfig.miaohuoliuxing := {
        TargetX1: IniRead(configPath, "miaohuoliuxing", "TargetX1", 0),
        TargetY1: IniRead(configPath, "miaohuoliuxing", "TargetY1", 0),
        TargetColor1: "0x" IniRead(configPath, "miaohuoliuxing", "TargetColor1", "FFFFFF"),
        TargetX2: IniRead(configPath, "miaohuoliuxing", "TargetX2", 0),
        TargetY2: IniRead(configPath, "miaohuoliuxing", "TargetY2", 0),
        TargetColor2: "0x" IniRead(configPath, "miaohuoliuxing", "TargetColor2", "FFFFFF"),
        colorRange: IniRead(configPath, "miaohuoliuxing", "colorRange", 0),
        pressHold: IniRead(configPath, "miaohuoliuxing", "pressHold", 0),
        checkTimer: IniRead(configPath, "miaohuoliuxing", "checkTimer", 0),
        xcxDelay: IniRead(configPath, "miaohuoliuxing", "xcxDelay", 0)
    }

    skillConfig.bloodbar := {
        TargetX: IniRead(configPath, "bloodbar", "TargetX", 0),
        TargetY: IniRead(configPath, "bloodbar", "TargetY", 0),
        TargetColor: "0x" IniRead(configPath, "bloodbar", "TargetColor", "FFFFFF"),
        colorRange: IniRead(configPath, "bloodbar", "colorRange", 0)
    }

    ; 读取技能释放开关，转换为数字 (1/0)
    val := IniRead(configPath, "SkillEnable", "Qianniuhua", "0")
    skillEnable.Qianniuhua := (val = "1" or val = "true") ? 1 : 0
    val := IniRead(configPath, "SkillEnable", "Yamao", "0")
    skillEnable.Yamao := (val = "1" or val = "true") ? 1 : 0
    val := IniRead(configPath, "SkillEnable", "Jineng1", "0")
    skillEnable.Jineng1 := (val = "1" or val = "true") ? 1 : 0
    val := IniRead(configPath, "SkillEnable", "Jineng2", "0")
    skillEnable.Jineng2 := (val = "1" or val = "true") ? 1 : 0

    skillConfig.pressDelay := IniRead(configPath, "Global", "pressDelay", 100)
    skillConfig.mainLoopDelay := IniRead(configPath, "Global", "mainLoopDelay", 100)
    skillConfig.startBotton := IniRead(configPath, "Global", "startBotton", "XButton1")
    startMainLoopButton := skillConfig.startBotton
}

; ============================== 主循环函数 ==============================
StartSkillLoop(ThisHotkey) {
    global isMainLoopPaused, startMainLoopButton

    ; 如果主循环已暂停，直接返回
    if isMainLoopPaused {
        setALLTimer(false)
        return
    }

    setALLTimer(true)

    Loop {
        ToolTip "宏运行中:", skillConfig.bloodbar.TargetX, skillConfig.bloodbar.TargetY - 30
        pressKey("r")
        pressKey("t")
        sleepa(skillConfig.mainLoopDelay)
    } Until not GetKeyState(ThisHotkey, "P")

    ToolTip
    setALLTimer(false)
}

; ============================== 调试热键 ==============================
^r::
{
    global startMainLoopButton, skillConfig, skillEnable
    InitConfig()
    Hotkey startMainLoopButton, StartSkillLoop

    configInfo := "===== 技能配置文件读取结果 =====`n`n"
    configInfo .= "【全局配置】`n"
    configInfo .= "主卡刀开关(startBotton)：" startMainLoopButton "`n"
    configInfo .= "卡到循环延迟(mainLoopDelay)：" skillConfig.mainLoopDelay " 毫秒`n"
    configInfo .= "全局按键延迟(pressDelay)：" skillConfig.pressDelay " 毫秒`n"
    configInfo .= "【技能释放开关】`n"
    configInfo .= "牵牛花(Qianniuhua)：" skillEnable.Qianniuhua "`n"
    configInfo .= "压猫(Yamao)：" skillEnable.Yamao "`n"
    configInfo .= "技能1(Jineng1)：" skillEnable.Jineng1 "`n"
    configInfo .= "技能2(Jineng2)：" skillEnable.Jineng2 "`n`n"

    configInfo .= "【牵牛花(Qianniuhua)配置】`n"
    configInfo .= "检测坐标1 X(TargetX1)：" skillConfig.Qianniuhua.TargetX1 "`n"
    configInfo .= "检测坐标1 Y(TargetY1)：" skillConfig.Qianniuhua.TargetY1 "`n"
    configInfo .= "目标颜色1(TargetColor1)：" skillConfig.Qianniuhua.TargetColor1 "`n"
    configInfo .= "检测坐标2 X(TargetX2)：" skillConfig.Qianniuhua.TargetX2 "`n"
    configInfo .= "检测坐标2 Y(TargetY2)：" skillConfig.Qianniuhua.TargetY2 "`n"
    configInfo .= "目标颜色2(TargetColor2)：" skillConfig.Qianniuhua.TargetColor2 "`n"
    configInfo .= "目标颜色容差值(colorRange)：" skillConfig.Qianniuhua.colorRange "`n"
    configInfo .= "按键按住时长(pressHold)：" skillConfig.Qianniuhua.pressHold " 毫秒`n"
    configInfo .= "检测定时器间隔(checkTimer)：" skillConfig.Qianniuhua.checkTimer " 毫秒`n`n"

    configInfo .= "【压猫(Yamao)配置】`n"
    configInfo .= "检测坐标1 X(TargetX1)：" skillConfig.Yamao.TargetX1 "`n"
    configInfo .= "检测坐标1 Y(TargetY1)：" skillConfig.Yamao.TargetY1 "`n"
    configInfo .= "目标颜色1(TargetColor1)：" skillConfig.Yamao.TargetColor1 "`n"
    configInfo .= "检测坐标2 X(TargetX2)：" skillConfig.Yamao.TargetX2 "`n"
    configInfo .= "检测坐标2 Y(TargetY2)：" skillConfig.Yamao.TargetY2 "`n"
    configInfo .= "目标颜色2(TargetColor2)：" skillConfig.Yamao.TargetColor2 "`n"
    configInfo .= "目标颜色容差值(colorRange)：" skillConfig.Yamao.colorRange "`n"
    configInfo .= "按键按住时长(pressHold)：" skillConfig.Yamao.pressHold " 毫秒`n"
    configInfo .= "检测定时器间隔(checkTimer)：" skillConfig.Yamao.checkTimer " 毫秒`n`n"

    configInfo .= "【挠挠(naonao)配置】`n"
    configInfo .= "检测坐标1 X(TargetX1)：" skillConfig.naonao.TargetX1 "`n"
    configInfo .= "检测坐标1 Y(TargetY1)：" skillConfig.naonao.TargetY1 "`n"
    configInfo .= "目标颜色1(TargetColor1)：" skillConfig.naonao.TargetColor1 "`n"
    configInfo .= "检测坐标2 X(TargetX2)：" skillConfig.naonao.TargetX2 "`n"
    configInfo .= "检测坐标2 Y(TargetY2)：" skillConfig.naonao.TargetY2 "`n"
    configInfo .= "目标颜色2(TargetColor2)：" skillConfig.naonao.TargetColor2 "`n"
    configInfo .= "目标颜色容差值(colorRange)：" skillConfig.naonao.colorRange "`n"
    configInfo .= "执行挠挠后CD(xcxDelay)：" skillConfig.naonao.xcxDelay " 毫秒`n`n"

    configInfo .= "【喵火流星(miaohuoliuxing)配置】`n"
    configInfo .= "检测坐标1 X(TargetX1)：" skillConfig.miaohuoliuxing.TargetX1 "`n"
    configInfo .= "检测坐标1 Y(TargetY1)：" skillConfig.miaohuoliuxing.TargetY1 "`n"
    configInfo .= "目标颜色1(TargetColor1)：" skillConfig.miaohuoliuxing.TargetColor1 "`n"
    configInfo .= "检测坐标2 X(TargetX2)：" skillConfig.miaohuoliuxing.TargetX2 "`n"
    configInfo .= "检测坐标2 Y(TargetY2)：" skillConfig.miaohuoliuxing.TargetY2 "`n"
    configInfo .= "目标颜色2(TargetColor2)：" skillConfig.miaohuoliuxing.TargetColor2 "`n"
    configInfo .= "目标颜色容差值(colorRange)：" skillConfig.miaohuoliuxing.colorRange "`n"
    configInfo .= "执行喵火流星C后CD(xcxDelay)：" skillConfig.miaohuoliuxing.xcxDelay " 毫秒`n`n"

    configInfo .= "【技能1(Jineng1)配置】`n"
    configInfo .= "检测坐标1 X(TargetX1)：" skillConfig.jineng1.TargetX1 "`n"
    configInfo .= "检测坐标1 Y(TargetY1)：" skillConfig.jineng1.TargetY1 "`n"
    configInfo .= "目标颜色1(TargetColor1)：" skillConfig.jineng1.TargetColor1 "`n"
    configInfo .= "检测坐标2 X(TargetX2)：" skillConfig.jineng1.TargetX2 "`n"
    configInfo .= "检测坐标2 Y(TargetY2)：" skillConfig.jineng1.TargetY2 "`n"
    configInfo .= "目标颜色2(TargetColor2)：" skillConfig.jineng1.TargetColor2 "`n"
    configInfo .= "目标颜色容差值(colorRange)：" skillConfig.jineng1.colorRange "`n"
    configInfo .= "按键按住时长(pressHold)：" skillConfig.jineng1.pressHold " 毫秒`n"
    configInfo .= "检测定时器间隔(checkTimer)：" skillConfig.jineng1.checkTimer " 毫秒`n`n"

    configInfo .= "【技能2(Jineng2)配置】`n"
    configInfo .= "检测坐标1 X(TargetX1)：" skillConfig.jineng2.TargetX1 "`n"
    configInfo .= "检测坐标1 Y(TargetY1)：" skillConfig.jineng2.TargetY1 "`n"
    configInfo .= "目标颜色1(TargetColor1)：" skillConfig.jineng2.TargetColor1 "`n"
    configInfo .= "检测坐标2 X(TargetX2)：" skillConfig.jineng2.TargetX2 "`n"
    configInfo .= "检测坐标2 Y(TargetY2)：" skillConfig.jineng2.TargetY2 "`n"
    configInfo .= "目标颜色2(TargetColor2)：" skillConfig.jineng2.TargetColor2 "`n"
    configInfo .= "目标颜色容差值(colorRange)：" skillConfig.jineng2.colorRange "`n"
    configInfo .= "按键按住时长(pressHold)：" skillConfig.jineng2.pressHold " 毫秒`n"
    configInfo .= "检测定时器间隔(checkTimer)：" skillConfig.jineng2.checkTimer " 毫秒`n`n"

    configInfo .= "===== 配置文件路径 =====`n"
    configInfo .= "配置文件路径：" configPath

    MsgBox configInfo, "配置读取结果", "Iconi"
    ToolTip
}

^p::
{
    global FoundX, FoundY, searchWidth, searchHeight, Q1CenterX, Q1CenterY, Q4CenterX, Q4CenterY, skillConfig

    ; ========== 角色血条位置取色 ==========
    pic := ImagePutBuffer(0)
    search := ImagePutBuffer(A_ScriptDir "\pic\juesexuetiao.bmp")
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

    ; ========== 牵牛花取色 ==========
    pic := ImagePutBuffer(0)
    search := ImagePutBuffer(A_ScriptDir "\pic\zhaohuan-qianniuhua.bmp")
    searchWidth := search.Width
    searchHeight := search.Height
    if xy := pic.ImageSearch(search) {
        FoundX := xy[1]
        FoundY := xy[2]
        Q1CenterX := Round(FoundX + searchWidth / 4)
        Q1CenterY := Round(FoundY + searchHeight / 4)
        Q4CenterX := Round(FoundX + searchWidth * 4 / 7)
        Q4CenterY := Round(FoundY + searchHeight * 1 / 7)
        skillConfig.Qianniuhua.TargetX1 := Q1CenterX
        skillConfig.Qianniuhua.TargetY1 := Q1CenterY
        skillConfig.Qianniuhua.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.Qianniuhua.TargetX2 := Q4CenterX
        skillConfig.Qianniuhua.TargetY2 := Q4CenterY
        skillConfig.Qianniuhua.TargetColor2 := GetColor(Q4CenterX, Q4CenterY)
        IniWrite(skillConfig.Qianniuhua.TargetX1, configPath, "Qianniuhua", "TargetX1")
        IniWrite(skillConfig.Qianniuhua.TargetY1, configPath, "Qianniuhua", "TargetY1")
        IniWrite(Format("{:06X}", skillConfig.Qianniuhua.TargetColor1), configPath, "Qianniuhua", "TargetColor1")
        IniWrite(skillConfig.Qianniuhua.TargetX2, configPath, "Qianniuhua", "TargetX2")
        IniWrite(skillConfig.Qianniuhua.TargetY2, configPath, "Qianniuhua", "TargetY2")
        IniWrite(Format("{:06X}", skillConfig.Qianniuhua.TargetColor2), configPath, "Qianniuhua", "TargetColor2")
    } else {
        MsgBox "查找 牵牛花 技能目标位置失败，将使用配置文件默认坐标值"
        sleepa 500
        Q1CenterX := skillConfig.Qianniuhua.TargetX1
        Q1CenterY := skillConfig.Qianniuhua.TargetY1
        Q4CenterX := skillConfig.Qianniuhua.TargetX2
        Q4CenterY := skillConfig.Qianniuhua.TargetY2
        newColor1 := GetColor(Q1CenterX, Q1CenterY)
        newColor2 := GetColor(Q4CenterX, Q4CenterY)
        IniWrite(Format("{:06X}", newColor1), configPath, "Qianniuhua", "TargetColor1")
        IniWrite(Format("{:06X}", newColor2), configPath, "Qianniuhua", "TargetColor2")
    }

    ; ========== 技能1取色 ==========
    pic := ImagePutBuffer(0)
    search := ImagePutBuffer(A_ScriptDir "\pic\zhaohuan-jineng1.bmp")
    searchWidth := search.Width
    searchHeight := search.Height
    if xy := pic.ImageSearch(search) {
        FoundX := xy[1]
        FoundY := xy[2]
        Q1CenterX := Round(FoundX + searchWidth / 4)
        Q1CenterY := Round(FoundY + searchHeight / 4)
        Q4CenterX := Round(FoundX + searchWidth * 4 / 7)
        Q4CenterY := Round(FoundY + searchHeight * 1 / 7)
        skillConfig.jineng1.TargetX1 := Q1CenterX
        skillConfig.jineng1.TargetY1 := Q1CenterY
        skillConfig.jineng1.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.jineng1.TargetX2 := Q4CenterX
        skillConfig.jineng1.TargetY2 := Q4CenterY
        skillConfig.jineng1.TargetColor2 := GetColor(Q4CenterX, Q4CenterY)
        IniWrite(skillConfig.jineng1.TargetX1, configPath, "jineng1", "TargetX1")
        IniWrite(skillConfig.jineng1.TargetY1, configPath, "jineng1", "TargetY1")
        IniWrite(Format("{:06X}", skillConfig.jineng1.TargetColor1), configPath, "jineng1", "TargetColor1")
        IniWrite(skillConfig.jineng1.TargetX2, configPath, "jineng1", "TargetX2")
        IniWrite(skillConfig.jineng1.TargetY2, configPath, "jineng1", "TargetY2")
        IniWrite(Format("{:06X}", skillConfig.jineng1.TargetColor2), configPath, "jineng1", "TargetColor2")
    } else {
        MsgBox "获取不到 1键 ，将使用配置文件默认坐标值"
        sleepa 500
        Q1CenterX := skillConfig.jineng1.TargetX1
        Q1CenterY := skillConfig.jineng1.TargetY1
        Q4CenterX := skillConfig.jineng1.TargetX2
        Q4CenterY := skillConfig.jineng1.TargetY2
        skillConfig.jineng1.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.jineng1.TargetColor2 := GetColor(Q4CenterX, Q4CenterY)
        IniWrite(Format("{:06X}", skillConfig.jineng1.TargetColor1), configPath, "jineng1", "TargetColor1")
        IniWrite(Format("{:06X}", skillConfig.jineng1.TargetColor2), configPath, "jineng1", "TargetColor2")
    }

    ; ========== 技能2取色 ==========
    pic := ImagePutBuffer(0)
    search := ImagePutBuffer(A_ScriptDir "\pic\zhaohuan-jineng2.bmp")
    searchWidth := search.Width
    searchHeight := search.Height
    if xy := pic.ImageSearch(search) {
        FoundX := xy[1]
        FoundY := xy[2]
        Q1CenterX := Round(FoundX + searchWidth / 4)
        Q1CenterY := Round(FoundY + searchHeight / 4)
        Q4CenterX := Round(FoundX + searchWidth * 4 / 7)
        Q4CenterY := Round(FoundY + searchHeight * 1 / 7)
        skillConfig.jineng2.TargetX1 := Q1CenterX
        skillConfig.jineng2.TargetY1 := Q1CenterY
        skillConfig.jineng2.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.jineng2.TargetX2 := Q4CenterX
        skillConfig.jineng2.TargetY2 := Q4CenterY
        skillConfig.jineng2.TargetColor2 := GetColor(Q4CenterX, Q4CenterY)
        IniWrite(skillConfig.jineng2.TargetX1, configPath, "jineng2", "TargetX1")
        IniWrite(skillConfig.jineng2.TargetY1, configPath, "jineng2", "TargetY1")
        IniWrite(Format("{:06X}", skillConfig.jineng2.TargetColor1), configPath, "jineng2", "TargetColor1")
        IniWrite(skillConfig.jineng2.TargetX2, configPath, "jineng2", "TargetX2")
        IniWrite(skillConfig.jineng2.TargetY2, configPath, "jineng2", "TargetY2")
        IniWrite(Format("{:06X}", skillConfig.jineng2.TargetColor2), configPath, "jineng2", "TargetColor2")
    } else {
        MsgBox "获取不到 2键 荆棘藤 技能目标位置，将使用配置文件默认坐标值"
        sleepa 500
        Q1CenterX := skillConfig.jineng2.TargetX1
        Q1CenterY := skillConfig.jineng2.TargetY1
        Q4CenterX := skillConfig.jineng2.TargetX2
        Q4CenterY := skillConfig.jineng2.TargetY2
        skillConfig.jineng2.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.jineng2.TargetColor2 := GetColor(Q4CenterX, Q4CenterY) 
        IniWrite(Format("{:06X}", skillConfig.jineng2.TargetColor1), configPath, "jineng2", "TargetColor1")
        IniWrite(Format("{:06X}", skillConfig.jineng2.TargetColor2), configPath, "jineng2", "TargetColor2")
    }

    InitConfig()
    MsgBox "取色+保存完成！"
}

^+p::
{
    global FoundX, FoundY, searchWidth, searchHeight, Q1CenterX, Q1CenterY, Q4CenterX, Q4CenterY

    ; ========== 压猫取色 ==========
    pic := ImagePutBuffer(0)
    search := ImagePutBuffer(A_ScriptDir "\pic\zhaohuan-yamao.bmp")
    searchWidth := search.Width
    searchHeight := search.Height
    if xy := pic.ImageSearch(search) {
        FoundX := xy[1]
        FoundY := xy[2]
        Q1CenterX := Round(FoundX + searchWidth / 4)
        Q1CenterY := Round(FoundY + searchHeight / 4)
        Q4CenterX := Round(FoundX + searchWidth * 4 / 7)
        Q4CenterY := Round(FoundY + searchHeight * 1 / 7)
        skillConfig.Yamao.TargetX1 := Q1CenterX
        skillConfig.Yamao.TargetY1 := Q1CenterY
        skillConfig.Yamao.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.Yamao.TargetX2 := Q4CenterX
        skillConfig.Yamao.TargetY2 := Q4CenterY
        skillConfig.Yamao.TargetColor2 := GetColor(Q4CenterX, Q4CenterY)
        IniWrite(skillConfig.Yamao.TargetX1, configPath, "Yamao", "TargetX1")
        IniWrite(skillConfig.Yamao.TargetY1, configPath, "Yamao", "TargetY1")
        IniWrite(Format("{:06X}", skillConfig.Yamao.TargetColor1), configPath, "Yamao", "TargetColor1")
        IniWrite(skillConfig.Yamao.TargetX2, configPath, "Yamao", "TargetX2")
        IniWrite(skillConfig.Yamao.TargetY2, configPath, "Yamao", "TargetY2")
        IniWrite(Format("{:06X}", skillConfig.Yamao.TargetColor2), configPath, "Yamao", "TargetColor2")
    } else {
        ToolTip "获取不到 压猫 技能目标位置，将使用配置文件默认坐标值" skillConfig.bloodbar.TargetX, skillConfig.bloodbar.TargetY - 30
        Q1CenterX := skillConfig.Yamao.TargetX1
        Q1CenterY := skillConfig.Yamao.TargetY1
        Q4CenterX := skillConfig.Yamao.TargetX2
        Q4CenterY := skillConfig.Yamao.TargetY2
        skillConfig.Yamao.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.Yamao.TargetColor2 := GetColor(Q4CenterX, Q4CenterY) 
        IniWrite(Format("{:06X}", skillConfig.Yamao.TargetColor1), configPath, "Yamao", "TargetColor1")
        IniWrite(Format("{:06X}", skillConfig.Yamao.TargetColor2), configPath, "Yamao", "TargetColor2")
    }

    pressKey("{Tab}")
    sleepa 1000

    ; ========== 挠挠取色 ==========
    pic := ImagePutBuffer(0)
    search := ImagePutBuffer(A_ScriptDir "\pic\zhaohuan-naonao.bmp")
    searchWidth := search.Width
    searchHeight := search.Height
    if xy := pic.ImageSearch(search) {
        FoundX := xy[1]
        FoundY := xy[2]
        Q1CenterX := Round(FoundX + searchWidth / 4)
        Q1CenterY := Round(FoundY + searchHeight / 4)
        Q4CenterX := Round(FoundX + searchWidth * 4 / 7)
        Q4CenterY := Round(FoundY + searchHeight * 1 / 7)
        skillConfig.naonao.TargetX1 := Q1CenterX
        skillConfig.naonao.TargetY1 := Q1CenterY
        skillConfig.naonao.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.naonao.TargetX2 := Q4CenterX
        skillConfig.naonao.TargetY2 := Q4CenterY
        skillConfig.naonao.TargetColor2 := GetColor(Q4CenterX, Q4CenterY)
        IniWrite(skillConfig.naonao.TargetX1, configPath, "naonao", "TargetX1")
        IniWrite(skillConfig.naonao.TargetY1, configPath, "naonao", "TargetY1")
        IniWrite(Format("{:06X}", skillConfig.naonao.TargetColor1), configPath, "naonao", "TargetColor1")
        IniWrite(skillConfig.naonao.TargetX2, configPath, "naonao", "TargetX2")
        IniWrite(skillConfig.naonao.TargetY2, configPath, "naonao", "TargetY2")
        IniWrite(Format("{:06X}", skillConfig.naonao.TargetColor2), configPath, "naonao", "TargetColor2")
    } else {
        ToolTip "获取不到 挠挠X 技能目标位置，将使用配置文件默认坐标值" skillConfig.bloodbar.TargetX, skillConfig.bloodbar.TargetY - 30
        Q1CenterX := skillConfig.naonao.TargetX1
        Q1CenterY := skillConfig.naonao.TargetY1
        Q4CenterX := skillConfig.naonao.TargetX2
        Q4CenterY := skillConfig.naonao.TargetY2
        skillConfig.naonao.TargetColor1 := GetColor(Q1CenterX, Q1CenterY)
        skillConfig.naonao.TargetColor2 := GetColor(Q4CenterX, Q4CenterY) 
        IniWrite(Format("{:06X}", skillConfig.naonao.TargetColor1), configPath, "naonao", "TargetColor1")
        IniWrite(Format("{:06X}", skillConfig.naonao.TargetColor2), configPath, "naonao", "TargetColor2")
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
    myGui := Gui("+MinSize -MaximizeBox", "召唤-功血 v0.9")
    myGui.SetFont("s9", "Microsoft YaHei")

    ; 启动热键（组合框）
    myGui.AddText("xm y+10", "启动摁键 (长摁启动卡刀):")
    hotkeyList := ["XButton1", "XButton2", "XButton3", "F1", "F2", "F3", "F4", "F5", "F6"]
    cboHotkey := myGui.AddComboBox("vSelectedHotkey w120", hotkeyList)
    cboHotkey.Text := startMainLoopButton

    ; 下一行：循环延迟（标签+输入框）
    myGui.AddText("xm y+5", "循环延迟(ms):")
    edMainLoopDelay := myGui.AddEdit("x+5 yp w30 Number vMainLoopDelay", skillConfig.mainLoopDelay)

    ; 技能开关
    myGui.AddText("xm y+15", "技能开关:")
    cbQianniuhua := myGui.AddCheckbox("vCbQianniuhua", "牵牛花 (F)")
    cbQianniuhua.Value := skillEnable.Qianniuhua
    cbYamao := myGui.AddCheckbox("vCbYamao", "压猫 (Tab)")
    cbYamao.Value := skillEnable.Yamao
    cbJineng1 := myGui.AddCheckbox("vCbJineng1", "技能1")
    cbJineng1.Value := skillEnable.Jineng1
    cbJineng2 := myGui.AddCheckbox("vCbJineng2", "技能2")
    cbJineng2.Value := skillEnable.Jineng2

    ; 保存按钮
    btnSave := myGui.AddButton("xm y+15 w80 Default", "保存设置")
    btnSave.OnEvent("Click", SaveSettings)

    ; 说明
    myGui.AddText("xm y+10", "说明：")
    myGui.AddText("xm", "1. 面对木桩摁下Ctrl+P进行取色")
    myGui.AddText("xm", "2. 压猫技能亮后Ctrl+Shift+P进行取色")
    myGui.AddText("xm y+10", "注意：")
    myGui.AddText("xm", "1. 默认屏幕分辨率为2560x1440")
    myGui.AddText("xm", "2. 配置变动后需要点击 <保存设置>")
    myGui.AddText("xm", "3. 参数配置文件修改后Ctrl+R重新加载")
    myGui.AddText("xm", "4. 关闭本窗口后程序仍会在右下角继续运行")

    ; 窗口事件：关闭/ESC 时隐藏，最小化时也隐藏
    myGui.OnEvent("Close", GuiClose)
    myGui.OnEvent("Escape", GuiClose)
    myGui.OnEvent("Size", GuiSize)

    ; 托盘菜单
    CreateTrayMenu()

    ; 显示窗口，设置初始宽度为 250，禁止最大化
    myGui.Show("w250")
}

SaveSettings(*)
{
    global myGui, configPath, startMainLoopButton, skillEnable, skillConfig
    saved := myGui.Submit(false)
    newHotkey := saved.SelectedHotkey
    newQ := saved.CbQianniuhua
    newY := saved.CbYamao
    new1 := saved.CbJineng1
    new2 := saved.CbJineng2
    newMainLoopDelay := saved.MainLoopDelay

    ; 写入配置文件
    IniWrite(newHotkey, configPath, "Global", "startBotton")
    IniWrite(newMainLoopDelay, configPath, "Global", "mainLoopDelay")
    IniWrite(newQ ? "1" : "0", configPath, "SkillEnable", "Qianniuhua")
    IniWrite(newY ? "1" : "0", configPath, "SkillEnable", "Yamao")
    IniWrite(new1 ? "1" : "0", configPath, "SkillEnable", "Jineng1")
    IniWrite(new2 ? "1" : "0", configPath, "SkillEnable", "Jineng2")

    ; 重新加载配置（更新 skillEnable 和 startMainLoopButton）
    oldHotkey := startMainLoopButton
    InitConfig()
    try Hotkey(oldHotkey, "Off")
    Hotkey(startMainLoopButton, StartSkillLoop)

    ; 更新控件显示
    myGui["SelectedHotkey"].Text := startMainLoopButton
    myGui["MainLoopDelay"].Text := skillConfig.mainLoopDelay
    myGui["CbQianniuhua"].Value := skillEnable.Qianniuhua
    myGui["CbYamao"].Value := skillEnable.Yamao
    myGui["CbJineng1"].Value := skillEnable.Jineng1
    myGui["CbJineng2"].Value := skillEnable.Jineng2

    MsgBox "设置已保存并生效。", "提示", "Iconi T2"
}

; ============================== 托盘菜单 ==============================
; 切换卡刀宏状态
ToggleMacro(*)
{
    global isMainLoopPaused
    isMainLoopPaused := !isMainLoopPaused
    ; 重建托盘菜单以更新文字
    CreateTrayMenu()
    if !isMainLoopPaused {
        TrayTip "卡刀宏已恢复运行", "召唤-功血", "Iconi Mute"
        sleepa(3000)
    } else {
        TrayTip "卡刀宏已停止运行", "召唤-功血", "Iconi Mute"
        sleepa(3000)
    }
    TrayTip
}

CreateTrayMenu()
{
    A_TrayMenu.Delete()
    A_TrayMenu.Add("显示窗口", TrayShow)
    A_TrayMenu.Add()  ; 分隔线
    ; 根据当前状态显示不同的文字
    itemText := isMainLoopPaused ? "恢复卡刀宏" : "停止卡刀宏"
    A_TrayMenu.Add(itemText, ToggleMacro)
    A_TrayMenu.Add()  ; 分隔线
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
    if (MinMax = -1)    ; 窗口被最小化
        thisGui.Hide()
}

; 启动 GUI
CreateGui()