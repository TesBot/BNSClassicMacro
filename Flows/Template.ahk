; ============================== Template.ahk ==============================
; 新流派开发模板 - 复制此文件并修改
; ==============================

; ============================== 使用说明 ==============================
; 1. 复制此文件到 Flows/ 目录，重命名为 [职业]_[流派].ahk
; 2. 替换所有 "Template" 为实际流派名称
; 3. 实现 GetFlowModule_Template() 返回的各个函数
; 4. 在 Config/JobConfig.ahk 中添加流派映射
; 5. 在 Lib/Resources.ahk 中添加流派图片资源
; ==============================

; ============================== 流派信息 ==============================
global FlowInfo_Template := {
    name: "职业-流派名称",
    flowId: "职业_流派ID",
    job: "职业名称",
    description: "核心循环: X→Y→Z, 技能检测: 技能A、技能B"
}

; ============================== 流派配置初始化 ==============================
InitFlowConfig_Template() {
    global skillConfig, skillEnable, startMainLoopButton
    local configPath := GetFlowConfigPath("职业_流派ID")

    if !FileExist(configPath) {
        CreateDefaultFlowConfig_Template(configPath)
    }

    ; TODO: 加载全局配置
    skillConfig.pressDelay := ReadConfigInt(configPath, "Global", "pressDelay", 5)
    skillConfig.mainLoopDelay := ReadConfigInt(configPath, "Global", "mainLoopDelay", 5)
    skillConfig.startButton := ReadConfigStr(configPath, "Global", "startButton", "XButton1")

    ; TODO: 加载技能开关
    ; skillEnable.SkillA := ReadConfigInt(configPath, "SkillEnable", "SkillA", 1)

    ; TODO: 加载技能配置
    ; skillConfig.SkillA := { ... }

    startMainLoopButton := skillConfig.startButton
}

CreateDefaultFlowConfig_Template(configPath) {
    local defaultConfig := "
    (LTrim Join`r`n
[Global]
startButton = XButton1
mainLoopDelay = 5
pressDelay = 5

[SkillEnable]
; 技能开关配置

; 技能A配置
[SkillA]
pressHold = 10
checkTimer = 100
colorRange = 20
TargetX1 = 0
TargetY1 = 0
TargetColor1 = FFFFFF
TargetX2 = 0
TargetY2 = 0
TargetColor2 = FFFFFF
    )"
    FileAppend(defaultConfig, configPath, "UTF-8")
}

; ============================== 技能检测函数 ==============================
; 模板：检测技能是否可用
checkSkillA_Template() {
    global skillEnable
    if !skillEnable.SkillA
        return false
    return checkSkillAvailable("SkillA")
}

; ============================== 技能释放函数 ==============================
releaseSkillA_Template() {
    global isMacroRunning, skillConfig, bloodbarConfig
    if !isMacroRunning
        return

    ToolTip "宏运行中: 释放 技能A", bloodbarConfig.TargetX, bloodbarConfig.TargetY - 30
    ; TODO: 实现技能释放逻辑
    pressWaitAndRelease("x", skillConfig.SkillA.pressHold)

    if isMacroRunning
        ToolTip
}

; ============================== 卡刀主循环 ==============================
StartSkillLoop_Template(ThisHotkey) {
    global isMainLoopPaused, skillConfig, isMacroRunning

    if isMainLoopPaused {
        isMacroRunning := false
        return
    }

    isMacroRunning := true

    ; TODO: 初始化计时器
    local lastSkillACheck := 0
    local currentTime := 0
    local delayRemaining := 0

    Loop {
        if not GetKeyState(ThisHotkey, "P")
            break

        currentTime := A_TickCount

        ; TODO: 技能检测与释放
        ; if (currentTime - lastSkillACheck >= skillConfig.SkillA.checkTimer) {
        ;     lastSkillACheck := currentTime
        ;     if checkSkillA_Template() {
        ;         releaseSkillA_Template()
        ;     }
        ; }

        if not GetKeyState(ThisHotkey, "P")
            break

        ; TODO: 核心卡刀序列
        ; SendEvent "{r}"
        ; DllCall("Sleep", "UInt", skillConfig.pressDelay)

        ; 循环延时
        delayRemaining := skillConfig.mainLoopDelay
        while (delayRemaining > 0 && GetKeyState(ThisHotkey, "P")) {
            DllCall("Sleep", "UInt", 1)
            delayRemaining -= 1
        }
    }

    isMacroRunning := false
}

; ============================== 取色函数 ==============================
PickColors_Template() {
    global skillConfig, ResourceTempDir, bloodbarConfig
    local configPath := GetFlowConfigPath("职业_流派ID")

    ; 血条取色（公共）
    PickBloodbarColor()

    ; TODO: 技能图标取色
    ; local pic := ImagePutBuffer(0)
    ; local search := ImagePutBuffer(ResourceTempDir . "\xxx.bmp")
    ; if xy := pic.ImageSearch(search) {
    ;     ; 取色逻辑
    ; }

    MsgBox("取色完成！")
}

; ============================== UI创建函数 ==============================
GetFlowUI_Template(guiObj) {
    global skillEnable, skillConfig, startMainLoopButton

    ; 流派标题
    guiObj.AddText("xm y+10", "流派: 职业 - 流派名称")

    ; 启动按键选择
    guiObj.AddText("xm y+5", "启动按键 (长按启动卡刀):")
    local hotkeyList := ["XButton1", "XButton2", "XButton3", "F1", "F2", "F3", "F4", "F5", "F6"]
    local cboHotkey := guiObj.AddComboBox("vSelectedHotkey_Template w120", hotkeyList)
    cboHotkey.Text := startMainLoopButton

    ; 循环延迟
    guiObj.AddText("xm y+5", "循环延迟(ms):")
    local edMainLoopDelay := guiObj.AddEdit("x+5 yp w35 Number vMainLoopDelay_Template", skillConfig.mainLoopDelay)

    ; TODO: 技能开关
    ; guiObj.AddText("xm y+15", "技能开关:")
    ; local cbSkillA := guiObj.AddCheckbox("vCbSkillA_Template", "技能A (X)")
    ; cbSkillA.Value := skillEnable.SkillA

    ; 保存按钮
    local btnSave := guiObj.AddButton("xm y+15 w80 Default", "保存设置")
    btnSave.OnEvent("Click", SaveFlowSettings_Template)

    ; 说明GroupBox
    local gbInfo := guiObj.AddGroupBox("xm y+15 w240 h120", "说明")
    guiObj.AddText("xs+6 yp+20", "1. 取色说明...")
    guiObj.AddText("xs+6 yp+20", "注意:")
    guiObj.AddText("xs+6 yp+20", "1. 默认屏幕分辨率 2560x1440")
    guiObj.AddText("xs+6 yp+20", "2. 配置变动后点击 <保存设置>")
}

; ============================== 保存设置函数 ==============================
SaveFlowSettings_Template(*) {
    global myGui, skillEnable, skillConfig, startMainLoopButton
    local configPath := GetFlowConfigPath("职业_流派ID")

    local saved := myGui.Submit(false)

    ; TODO: 获取并保存配置
    ; local newHotkey := saved.SelectedHotkey_Template
    ; WriteConfig(configPath, "Global", "startButton", newHotkey)

    ; 重新加载配置并切换热键
    local oldHotkey := startMainLoopButton
    InitFlowConfig_Template()
    SwitchHotkey(startMainLoopButton, oldHotkey, StartSkillLoop_Template)

    MsgBox("设置已保存并生效。")
}

; ============================== 模块导出接口 ==============================
GetFlowModule_Template() {
    return {
        name: "职业-流派名称",
        flowId: "职业_流派ID",
        job: "职业名称",
        InitConfig: InitFlowConfig_Template,
        GetUI: GetFlowUI_Template,
        StartLoop: StartSkillLoop_Template,
        PickColors: PickColors_Template,
        SaveSettings: SaveFlowSettings_Template
    }
}

; ============================== 开发检查清单 ==============================
; [ ] 1. 修改 FlowInfo_Template 为实际流派信息
; [ ] 2. 实现 InitFlowConfig_Template 加载配置
; [ ] 3. 实现 CreateDefaultFlowConfig_Template 默认配置
; [ ] 4. 实现技能检测函数 checkSkillX_Template
; [ ] 5. 实现技能释放函数 releaseSkillX_Template
; [ ] 6. 实现卡刀主循环 StartSkillLoop_Template
; [ ] 7. 实现取色函数 PickColors_Template
; [ ] 8. 实现UI函数 GetFlowUI_Template
; [ ] 9. 实现保存函数 SaveFlowSettings_Template
; [ ] 10. 更新 Config/JobConfig.ahk 添加流派映射
; [ ] 11. 更新 Lib/Resources.ahk 添加图片资源
; [ ] 12. 更新 Main.ahk #Include 新流派文件