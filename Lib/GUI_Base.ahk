; ============================== GUI_Base.ahk ==============================
; GUI基础框架 - 主界面创建与管理
; 包含: 职业选择、流派选择、流派界面动态加载
; ==============================

; ============================== 全局变量 ==============================
global myGui := ""
global currentFlowUIControls := []  ; 当前流派UI控件列表（用于销毁）

; ============================== 主界面创建 ==============================
CreateMainGui() {
    global myGui, JobFlowMap, currentFlowId, AppVersion, AppIconPath

    ; 如果已存在，先销毁
    if (myGui != "") {
        myGui.Destroy()
        myGui := ""
    }

    ; 创建主窗口（只保留关闭按钮，去掉最小化和最大化）
    myGui := Gui("-MinimizeBox -MaximizeBox +LastFound", "卡刀鸡 v" . AppVersion)
    myGui.SetFont("s9", "Microsoft YaHei")

    ; 创建菜单栏
    CreateMenuBar(myGui)

    ; ========== 职业与流派选择区域 ==========
    local gbSelect := myGui.AddGroupBox("xm yp+6 w190 h75", "职业选择")

    ; 第一行：职业下拉框
    myGui.AddText("xp+6 yp+18", "职业:")
    local jobList := GetJobList()
    local cboJob := myGui.AddComboBox("x+5 yp w85 vSelectedJob", jobList)
    cboJob.Text := jobList[1]

    ; 第二行：流派下拉框 + 确认按钮
    myGui.AddText("xm+6 y+6", "流派:")
    local cboFlow := myGui.AddComboBox("x+5 yp w85 vSelectedFlow")

    ; 初始化流派选项
    UpdateFlowOptions(cboJob, cboFlow)
    cboJob.OnEvent("Change", (*) => UpdateFlowOptions(cboJob, cboFlow))

    ; 确认按钮（紧跟流派下拉框）
    myGui.SetFont("s8")
    local btnConfirm := myGui.AddButton("x+5 yp w45", "确认")
    myGui.SetFont("s9")
    btnConfirm.OnEvent("Click", ConfirmFlowSelection)
    btnConfirm.ToolTip := "加载选中流派的卡刀配置"

    ; ========== 流派界面区域（动态加载） ==========
    ; 根据 currentFlowId 加载对应流派，如果没有则加载默认
    if (currentFlowId != "") {
        ; 已有流派ID，加载指定流派
        local targetJob := ""
        local targetFlowName := ""

        ; 查找流派对应的职业和名称
        for jobName, flowList in JobFlowMap {
            for flow in flowList {
                if (flow.flowId = currentFlowId) {
                    targetJob := jobName
                    targetFlowName := flow.name
                    break
                }
            }
            if (targetJob != "")
                break
        }

        ; 设置下拉框显示正确的职业和流派
        if (targetJob != "") {
            cboJob.Text := targetJob
            UpdateFlowOptions(cboJob, cboFlow)
            cboFlow.Text := targetFlowName
        }

        ; 加载流派UI
        LoadFlowUI(currentFlowId)
    } else {
        ; 没有流派ID，加载默认流派
        local firstJob := jobList[1]
        local flows := GetFlowList(firstJob)
        if (flows.Length > 0) {
            ; 查找第一个已实现的流派
            local foundFlowId := ""
            for index, flow in flows {
                if (IsFlowImplemented(flow.flowId)) {
                    foundFlowId := flow.flowId
                    break
                }
            }
            if (foundFlowId != "") {
                currentFlowId := foundFlowId
                LoadFlowUI(currentFlowId)
            }
        }
    }

    ; ========== 窗口事件绑定 ==========
    myGui.OnEvent("Close", GuiClose)
    myGui.OnEvent("Escape", GuiClose)
    myGui.OnEvent("Size", GuiSize)

    ; 创建托盘菜单
    CreateTrayMenu()

    ; 显示窗口
    myGui.Show("w210")
}

; ============================== 菜单栏创建 ==============================
CreateMenuBar(guiObj) {
    local helpSubMenu := Menu()
    helpSubMenu.Add("使用说明", ShowHelp)
    helpSubMenu.Add("注意事项", ShowNotes)

    local aboutSubMenu := Menu()
    aboutSubMenu.Add("版本信息", ShowAbout)

    local mainMenuBar := MenuBar()
    mainMenuBar.Add("帮助(&H)", helpSubMenu)
    mainMenuBar.Add("关于(&A)", aboutSubMenu)

    guiObj.MenuBar := mainMenuBar
}

; ============================== 帮助功能函数 ==============================
ShowHelp(*) {
    local helpText := "【使用说明】`n`n"
    . "1. 选择职业和流派后点击「确认」`n"
    . "2. 取色按键：Ctrl+P 按照说明进行取色操作`n"
    . "3. 每次调整参数后都需要点击「保存设置」按钮`n"
    . "4. 长按启动按键开始卡刀循环`n`n"
    . "操作提示：`n"
    . "- 确保游戏窗口处于激活状态`n"
    . "- 默认屏幕分辨率 2560x1440"

    MsgBox(helpText, "卡刀鸡 - 使用说明")
}

ShowNotes(*) {
    local notesText := "【注意事项】`n`n"
    . "1. 默认屏幕分辨率为 2560x1440`n"
    . "   其他分辨率暂不支持`n`n"
    . "2. 配置变动后需要点击界面下方的「保存设置」按钮`n`n"
    . "3. 参数配置文件 (ini) 手动修改后，需按 Ctrl+R 重新加载脚本`n`n"
    . "4. 关闭本设置窗口后，程序仍会在右下角托盘区继续运行`n"
    . "   如需完全退出，请右键托盘图标选择「退出脚本」"

    MsgBox(notesText, "卡刀鸡 - 注意事项")
}

ShowAbout(*) {
    global AppVersion
    local aboutText := "卡刀鸡 剑灵怀旧服卡刀宏`n"
    . "已实现流派：`n"
    . "- 气功：1系推龙`n"
    . "- 召唤：1系马蜂`n`n"
    . "© Version " . AppVersion

    MsgBox(aboutText, "卡刀鸡 - 关于")
}

; ============================== 流派选择联动更新 ==============================
UpdateFlowOptions(cboJob, cboFlow) {
    global JobFlowMap, FlowStatus

    cboFlow.Delete()
    local selectedJob := cboJob.Text
    local flowList := GetFlowList(selectedJob)

    if (flowList.Length = 0) {
        cboFlow.Add(["暂未配置"])
    } else {
        for index, flow in flowList {
            local status := GetFlowStatusDesc(flow.flowId)
            if (status = "已实现") {
                cboFlow.Add([flow.name])
            } else {
                cboFlow.Add([flow.name . " (待开发)"])
            }
        }
        cboFlow.Text := flowList[1].name
    }
}

; ============================== 确认流派选择 ==============================
ConfirmFlowSelection(*) {
    global myGui, currentFlowId

    try {
        local submittedData := myGui.Submit(false)
        local job := submittedData.SelectedJob
        local flowName := submittedData.SelectedFlow

        ; 解析流派名称（去掉状态后缀）
        if (InStr(flowName, " (待开发)")) {
            MsgBox("该流派正在开发中，敬请期待！", "卡刀鸡 - 提示")
            return
        }

        ; 获取流派ID
        local flowList := GetFlowList(job)
        local flowId := ""
        for index, flow in flowList {
            if (flow.name = flowName) {
                flowId := flow.flowId
                break
            }
        }

        if (flowId = "") {
            MsgBox("无法识别流派: " flowName, "卡刀鸡 - 错误")
            return
        }

        if (flowId = currentFlowId) {
            return  ; 相同流派，不做切换
        }

        ; 切换流派
        SwitchFlow(job, flowId)

    } catch as e {
        MsgBox("切换流派失败: " e.Message, "错误")
    }
}

; ============================== 流派切换核心逻辑 ==============================
SwitchFlow(job, flowId) {
    global currentFlowId, currentJob, startMainLoopButton, isMacroRunning, myGui

    try {
        ; 检查流派是否已实现
        if !IsFlowImplemented(flowId) {
            MsgBox("该流派正在开发中，敬请期待！", "卡刀鸡 - 提示")
            return
        }

        ; 1. 停止当前卡刀循环
        isMacroRunning := false

        ; 2. 解绑当前热键
        if (startMainLoopButton != "") {
            UnregisterHotkey(startMainLoopButton)
        }

        ; 解绑手动技能热键（如果当前流派支持）
        local oldFlowModule := GetFlowModuleById(currentFlowId)
        if (oldFlowModule && oldFlowModule.HasOwnProp("UnregisterManualHotkeys")) {
            oldFlowModule.UnregisterManualHotkeys.Call()
        }

        ; 3. 更新当前职业和流派（CreateMainGui会根据这些值加载正确的UI）
        currentJob := job
        currentFlowId := flowId

        ; 4. 重新创建整个GUI（内部会加载流派UI、初始化配置、绑定热键）
        CreateMainGui()

        ; 5. 更新托盘菜单
        CreateTrayMenu()

        ; 获取流派模块名称用于提示
        local flowModule := GetFlowModuleById(flowId)
        MsgBox("已切换到: " (flowModule ? flowModule.name : flowId), "卡刀鸡 - 流派切换")

    } catch as e {
        MsgBox("切换流派失败: " e.Message "`n`n文件: " e.File "`n行号: " e.Line, "卡刀鸡 - 错误")
    }
}

; ============================== 获取流派模块 ==============================
GetFlowModuleById(flowId) {
    switch flowId {
        case "气功_1系推龙":
            return GetFlowModule_Qigong1()
        case "召唤_1系马蜂":
            return GetFlowModule_Zhaohuan1()
        ; 添加更多流派...
        default:
            return ""
    }
}

; ============================== 销毁流派UI ==============================
DestroyFlowUI() {
    global myGui, currentFlowUIControls

    ; 销毁之前创建的流派UI控件
    try {
        for index, ctrl in currentFlowUIControls {
            try {
                ctrl.Destroy()
            } catch {
                ; 忽略销毁失败
            }
        }
    }

    currentFlowUIControls := []

    ; 更彻底的方法：重新创建整个GUI
    ; 这里采用简单方式，让流派模块自己管理控件
}

; ============================== 加载流派UI ==============================
LoadFlowUI(flowId) {
    global myGui, currentJob, startMainLoopButton

    ; 检查流派是否已实现
    if !IsFlowImplemented(flowId) {
        MsgBox("该流派正在开发中，敬请期待！", "卡刀鸡 - 提示")
        return false
    }

    ; 加载血条配置
    LoadBloodbarConfig()

    ; 获取流派模块
    local flowModule := GetFlowModuleById(flowId)
    if (flowModule = "") {
        MsgBox("流派模块加载失败: " flowId, "卡刀鸡 - 错误")
        return false
    }

    ; 初始化配置
    flowModule.InitConfig.Call()

    ; 创建UI
    flowModule.GetUI.Call(myGui)

    ; 绑定热键
    RegisterHotkey(startMainLoopButton, flowModule.StartLoop)

    ; 注册手动技能暂停热键（如果流派支持）
    if (flowModule.HasOwnProp("RegisterManualHotkeys")) {
        flowModule.RegisterManualHotkeys.Call()
    }

    return true
}