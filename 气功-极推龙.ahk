#Requires AutoHotkey v2.0
#SingleInstance Force  ; 确保脚本只运行一个实例，避免冲突
#MaxThreadsPerHotkey 2 ; 允许热键重复触发，避免卡顿
SetWorkingDir A_ScriptDir

; ============================== 全局变量 ==============================
; 配置文件路径（同脚本目录）
global configPath := A_ScriptDir "\qigong_jituilong_config.ini"
; 存储从配置文件读取的参数
global skillConfig := {}

; ============================== 配置文件读取函数 ==============================
; 初始化读取配置文件，若文件不存在则提示并使用默认值兜底
InitConfig() {
    global configPath, skillConfig
    
    ; 检查配置文件是否存在
    if !FileExist(configPath) {
        CreateDefaultConfig() ; 创建默认配置文件
    }

    ; 读取火莲掌配置（新增pressHold读取）
    skillConfig.Huolianzhang := {
        TargetX: IniRead(configPath, "Huolianzhang", "TargetX", 1257),
        TargetY: IniRead(configPath, "Huolianzhang", "TargetY", 1338),
        TargetColor: "0x" IniRead(configPath, "Huolianzhang", "TargetColor", "FFFFBD"),
        pressHold: IniRead(configPath, "Huolianzhang", "pressHold", 30), ; 读取火莲掌按住时长
        checkTimer: IniRead(configPath, "Huolianzhang", "checkTimer", 200) 
    }

    ; 读取混元罩配置（新增pressHold读取）
    skillConfig.Hunyuanzhao := {
        TargetX1: IniRead(configPath, "Hunyuanzhao", "TargetX1", 0),
        TargetY1: IniRead(configPath, "Hunyuanzhao", "TargetY1", 0),
        TargetColor1: "0x" IniRead(configPath, "Hunyuanzhao", "TargetColor1", "FFFFFF"),
        TargetX2: IniRead(configPath, "Hunyuanzhao", "TargetX2", 0),
        TargetY2: IniRead(configPath, "Hunyuanzhao", "TargetY2", 0),
        TargetColor2: "0x" IniRead(configPath, "Hunyuanzhao", "TargetColor2", "FFFFFF"),
        colorRange: IniRead(configPath, "Hunyuanzhao", "colorRange", 30), ; 读取混元罩颜色范围
        pressHold: IniRead(configPath, "Hunyuanzhao", "pressHold", 50), ; 读取混元罩按住时长
        checkTimer: IniRead(configPath, "Hunyuanzhao", "checkTimer", 0)
    }

    ; 读取全局按键延迟（新增：无section的INI参数，section填空字符串）
    skillConfig.pressDelay := IniRead(configPath, "", "pressDelay", 5)
}

; 创建默认配置文件（当配置文件不存在时）
CreateDefaultConfig() {
    global configPath
    ; v2.0 正确的多行字符串写法：用反引号`换行，双引号包裹整体
    defaultConfig := "
    (LTrim Join`r`n
; 技能取色配置文件
; 火莲掌（X键）配置
[Huolianzhang]
pressHold = 50
checkTimer = 200
TargetX = 1257
TargetY = 1338
TargetColor = FFFFBD

; 混元罩（C键）配置
[Hunyuanzhao]
pressHold = 50
checkTimer = 0
colorRange = 30
TargetX1 = 1300
TargetY1 = 1325
TargetColor1 = F0FEFE
TargetX2 = 1320
TargetY2 = 1315
TargetColor2 = B2F5D

;全局按键延迟（毫秒）
pressDelay = 10
    )"
    ; 写入配置文件（UTF-8编码，确保中文/特殊字符正常）
    FileAppend(defaultConfig, configPath, "UTF-8") 
}

; ============================== 定义按键操作 ==============================
; 模拟按下并释放按键（修改：默认delay读取配置的全局pressDelay）
pressKey(key, delay:=skillConfig.pressDelay) {
    SendInput key
    sleepa(delay) 
}

; 按下并等待delay毫秒后松开
pressWaitAndRelease(keys, hold, delay:=skillConfig.pressDelay) {
    Send "{" keys " down}"  ; 按下指定按键（按住）
    sleepa(hold)                ; 按住
    Send "{" keys " up}"    ; 松开指定按键
    sleepa(delay)
}

sleepa(s) {
    DllCall("Winmm\timeBeginPeriod", "UInt", 1)
    DllCall("Sleep", "UInt", s)
    DllCall("Winmm\timeEndPeriod", "UInt", 1) ; 应该进行调用来让系统恢复正常.
}
; ============================== 定义按键操作 END ===========================

; ============================== 定义技能的取色检查 ============================
; 获取指定坐标的像素颜色值
GetColor(x, y) {
    color := PixelGetColor(x, y)  ; 获取像素颜色
    return color                  ; 返回颜色值
}

; 颜色范围判断函数（最终优化版）
; 参数说明：
;   color          - 实际获取的16进制颜色值（0xRRGGBB，如GetColor返回值）
;   targetColor    - 目标16进制颜色值（0xRRGGBB，传一个变量即可）
;   colorRange     - 允许的RGB偏差范围（正负N，默认10）
; 返回值：true=颜色匹配（RGB都在±colorRange内），false=不匹配
IsColorInRange(color, targetColor, colorRange := 10) {
    ; 拆分实际颜色的RGB分量
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF

    ; 拆分目标颜色的RGB分量（从传入的16进制变量中提取）
    targetR := (targetColor >> 16) & 0xFF
    targetG := (targetColor >> 8) & 0xFF
    targetB := targetColor & 0xFF

    ; 计算每个分量的允许范围（±colorRange，且限制在0-255有效区间）
    minR := Max(0, targetR - colorRange)
    maxR := Min(255, targetR + colorRange)
    minG := Max(0, targetG - colorRange)
    maxG := Min(255, targetG + colorRange)
    minB := Max(0, targetB - colorRange)
    maxB := Min(255, targetB + colorRange)

    ; 判断实际RGB是否都在允许范围内
    isMatch := (r >= minR && r <= maxR) 
        && (g >= minG && g <= maxG) 
        && (b >= minB && b <= maxB)
    
    return isMatch
}

; 取色检查 火莲掌X 是否可用（改用配置文件参数）
checkHuolianzhang(){
    global skillConfig
    huolianzhang_ready := false
    
    ; 从配置读取参数（替代硬编码）
    targetX := skillConfig.Huolianzhang.TargetX
    targetY := skillConfig.Huolianzhang.TargetY
    targetColor := skillConfig.Huolianzhang.TargetColor
    
    ; 获取实际颜色
    actualColor := GetColor(targetX, targetY)

    if (actualColor == targetColor) {
        huolianzhang_ready := true
    }
    return huolianzhang_ready
}

; 取色检查 混元罩C 是否可用（改用配置文件参数）
checkHunyuanzhao(){
    global skillConfig
    global hunyuanchao_cd := 0
    hunyuanzhao_ready := false

    ; 从配置读取参数
    colorRange := skillConfig.Hunyuanzhao.colorRange
    targetX1 := skillConfig.Hunyuanzhao.TargetX1
    targetY1 := skillConfig.Hunyuanzhao.TargetY1
    targetColor1 := skillConfig.Hunyuanzhao.TargetColor1
    targetX2 := skillConfig.Hunyuanzhao.TargetX2
    targetY2 := skillConfig.Hunyuanzhao.TargetY2
    targetColor2 := skillConfig.Hunyuanzhao.TargetColor2

    ; 获取两个坐标的颜色
    actualColor1 := GetColor(targetX1, targetY1)
    actualColor2 := GetColor(targetX2, targetY2)

    if IsColorInRange(actualColor1, targetColor1, colorRange) && IsColorInRange(actualColor2, targetColor2, colorRange) {
        hunyuanzhao_ready := true
    }
    return hunyuanzhao_ready
}

; ============================== 定义技能的取色值 END ============================

; ============================== 设置/停止技能释放 ==============================
setHuolianzhangReleaseTimer() {
    if checkHuolianzhang() {
        ; 修改：按住时长读取火莲掌的pressHold配置
        pressWaitAndRelease("x", skillConfig.Huolianzhang.pressHold)
    }
}

setHunyuanzhaoReleaseTimer() {
    if checkHunyuanzhao() {
        ToolTip "混元罩：可以释放！！！", 0, 60
        sleepa(150)
        Loop 2 {
            pressKey("t",50)
            pressWaitAndRelease("c", skillConfig.Hunyuanzhao.pressHold)
        }
    }
    ToolTip "混元罩：CD中......", 0, 60
}

setALLTimer(is_start) {
    if is_start == true {
        SetTimer setHuolianzhangReleaseTimer, skillConfig.Huolianzhang.checkTimer
        SetTimer setHunyuanzhaoReleaseTimer, skillConfig.Hunyuanzhao.checkTimer
    }
    else {
        SetTimer setHuolianzhangReleaseTimer, 0
        SetTimer setHunyuanzhaoReleaseTimer, 0
    }
}

checkAndStart(param, keys, checkFun, delay, skip_check := false) {
    if checkFun() or skip_check{
        Send "{" keys " down}"
        sleepa(delay)
        Send "{" keys " up}"
        return checkFun()
    }
}

; ============================== 设置/停止技能释放 END ==============================
InitConfig()

; 鼠标侧键XButton1：主触发按键，按下后启动自动技能释放
XButton1::
{   

    global isMainLoopPaused
    
    setALLTimer(true)  ; 启动长CD技能定时器
    
    ; 主循环：持续释放技能，直到松开F1键 
    Loop {   
        pressKey("2") 
        pressKey("r") 
        pressKey("t") 
        pressKey("f") 
    } Until not GetKeyState("XButton1", "P")  ; 循环终止条件：松开摁键
    
    setALLTimer(false)  ; 停止长CD技能定时器

    ; 恢复暂停标志，避免下次按时主循环卡住
    isMainLoopPaused := false
}

; -------------------------------------------调试取色代码-----------------------------------------------

; 初始化配置（ctrl+p）- 改造后：打印所有配置值
^p::
{
    ; 重新读取配置（确保获取最新值）
    InitConfig()
    
    ; 构建配置信息字符串（格式清晰，便于查看）
    configInfo := "===== 技能配置文件读取结果 =====`n`n"
    
    ; 1. 全局配置
    configInfo .= "【全局配置】`n"
    configInfo .= "全局按键延迟(pressDelay)：" skillConfig.pressDelay " 毫秒`n`n"
    
    ; 2. 火莲掌配置
    configInfo .= "【火莲掌(Huolianzhang)配置】`n"
    configInfo .= "检测坐标X(TargetX)：" skillConfig.Huolianzhang.TargetX "`n"
    configInfo .= "检测坐标Y(TargetY)：" skillConfig.Huolianzhang.TargetY "`n"
    configInfo .= "目标颜色(TargetColor)：" skillConfig.Huolianzhang.TargetColor "`n"
    configInfo .= "按键按住时长(pressHold)：" skillConfig.Huolianzhang.pressHold " 毫秒`n"
    configInfo .= "检测定时器间隔(checkTimer)：" skillConfig.Huolianzhang.checkTimer " 毫秒`n`n"
    
    ; 3. 混元罩配置
    configInfo .= "【混元罩(Hunyuanzhao)配置】`n"
    configInfo .= "检测坐标1 X(TargetX1)：" skillConfig.Hunyuanzhao.TargetX1 "`n"
    configInfo .= "检测坐标1 Y(TargetY1)：" skillConfig.Hunyuanzhao.TargetY1 "`n"
    configInfo .= "目标颜色1(TargetColor1)：" skillConfig.Hunyuanzhao.TargetColor1 "`n"
    configInfo .= "检测坐标2 X(TargetX2)：" skillConfig.Hunyuanzhao.TargetX2 "`n"
    configInfo .= "检测坐标2 Y(TargetY2)：" skillConfig.Hunyuanzhao.TargetY2 "`n"
    configInfo .= "目标颜色2(TargetColor2)：" skillConfig.Hunyuanzhao.TargetColor2 "`n"
    configInfo .= "按键按住时长(pressHold)：" skillConfig.Hunyuanzhao.pressHold " 毫秒`n"
    configInfo .= "检测定时器间隔(checkTimer)：" skillConfig.Hunyuanzhao.checkTimer " 毫秒`n`n"
    
    ; 4. 配置文件路径
    configInfo .= "===== 配置文件路径 =====`n"
    configInfo .= "配置文件路径：" configPath
    
    ; 显示所有配置信息（MsgBox支持换行，弹窗展示更清晰）
    MsgBox configInfo, "配置读取结果", "Iconi"
    
    ; 清空ToolTip（避免残留）
    ToolTip
}

xpos := 0
ypos := 0   
color:= 0x000000 

^q::    
{
    global xpos, ypos, color
    MouseGetPos &xpos, &ypos
    color := GetColor(xpos, ypos)
    A_Clipboard := "(" xpos "," ypos ")==" color ""
    ToolTip "记录到当前：X坐标=" xpos " | Y坐标=" ypos " | 取色值=" Format("0x{:X}", color), 0, 100
}

^w::
{
    global xpos, ypos, color
    color := GetColor(xpos, ypos)
    ToolTip "获取：X坐标=" xpos " | Y坐标=" ypos " | 取色值=" Format("0x{:X}", color), 0, 130
}

; ===== Ctrl+E 自动连续采样（5次，间隔100ms）=====
global isSampling := false  ; 标记是否正在采样中

CalcColorRange() {
    global colorSamples
    
    minR := 255, maxR := 0
    minG := 255, maxG := 0
    minB := 255, maxB := 0
    
    for index, sample in colorSamples {
        minR := Min(minR, sample.r), maxR := Max(maxR, sample.r)
        minG := Min(minG, sample.g), maxG := Max(maxG, sample.g)
        minB := Min(minB, sample.b), maxB := Max(maxB, sample.b)
    }
    
    rangeInfo := "===== 颜色样本RGB范围 =====`n"
    rangeInfo .= "样本总数：" colorSamples.Length "`n`n"
    rangeInfo .= "红色(R)范围：" minR " ~ " maxR "`n"
    rangeInfo .= "绿色(G)范围：" minG " ~ " maxG "`n"
    rangeInfo .= "蓝色(B)范围：" minB " ~ " maxB "`n`n"
    rangeInfo .= "直接复制到IsColorInRange的参数：`n"
    rangeInfo .= minR ", " maxR ", " minG ", " maxG ", " minB ", " maxB
    
    A_Clipboard := rangeInfo
    MsgBox rangeInfo, "RGB范围计算结果", "Iconi"
}

^e::
{
    global xpos, ypos, color, colorSamples, isSampling
    
    ; 1. 检查是否正在采样中，避免重复触发
    if (isSampling) {
        ToolTip "正在采样中，请稍等！", 0, 160
        Sleep 1000
        ToolTip
        return
    }
    
    ; 2. 检查是否已用Ctrl+Q选取坐标
    if (xpos == 0 && ypos == 0) {
        ToolTip "请先按Ctrl+Q选取要检测的坐标！", 0, 160
        Sleep 1500
        ToolTip
        return
    }
    
    ; 3. 初始化：清空旧样本，标记开始采样
    colorSamples := []
    isSampling := true
    totalSamples := 5  ; 总采样次数
    sampleInterval := 100  ; 采样间隔（毫秒）
    
    ; 4. 自动连续采样
    Loop totalSamples {
        index := A_Index
        ; 获取当前坐标的颜色
        color := GetColor(xpos, ypos)
        ; 拆分RGB并存储样本
        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF
        colorSamples.Push({
            hex: Format("0x{:X}", color),
            r: r,
            g: g,
            b: b
        })
        
        ; 实时提示采样进度
        ToolTip "正在采集第" index "/" totalSamples "个样本`n当前颜色：" Format("0x{:X}", color) " (R:{r} G:{g} B:{b})", 0, 160
        
        ; 最后一次采样不等待，避免多等100ms
        if (index < totalSamples) {
            Sleep sampleInterval
        }
    }
    
    ; 5. 采样完成：清空提示，计算RGB范围
    isSampling := false
    ToolTip "采样完成！共采集" totalSamples "个样本", 0, 160
    Sleep 500
    ToolTip
    CalcColorRange()  ; 自动计算并展示RGB范围
}