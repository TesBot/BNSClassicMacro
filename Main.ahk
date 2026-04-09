; ============================== Main.ahk ==============================
; 卡刀鸡 - 剑灵怀旧服卡刀宏主程序
; ==============================

;@Ahk2Exe-SetName 卡刀鸡
;@Ahk2Exe-SetMainIcon favicon.ico

#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 2
SetWorkingDir A_ScriptDir

; ============================== 版本定义 ==============================
global AppVersion := "0.9.0"

; ============================== 引用模块 ==============================
; 图像处理库
#Include Lib\ImagePut.ahk

; 资源打包（所有FileInstall集中管理）
#Include Lib\Resources.ahk

; 职业/流派配置（必须在 GUI_Base 之前，因为 GUI_Base 使用了其中定义的函数）
#Include Config\JobConfig.ahk

; 核心公共库
#Include Lib\Core.ahk

; GUI基础框架
#Include Lib\GUI_Base.ahk

; 流派模块
#Include Flows\气功_1系推龙.ahk
#Include Flows\召唤_1系马蜂.ahk
; 添加新流派时在此处添加 #Include

; ============================== 初始化 ==============================
InitCore()

; 设置默认职业和流派
currentJob := "召唤"
currentFlowId := "召唤_1系马蜂"

; 加载血条配置
LoadBloodbarConfig()

; ============================== 全局热键 ==============================
; Ctrl+R - 重新加载脚本
^r:: {
    global startMainLoopButton, currentFlowId

    ; 获取当前流派模块
    local flowModule := GetFlowModuleById(currentFlowId)
    if (flowModule != "") {
        local oldHotkey := startMainLoopButton
        flowModule.InitConfig.Call()
        SwitchHotkey(startMainLoopButton, oldHotkey, flowModule.StartLoop)
    }

    MsgBox("配置已重新加载", "卡刀鸡")
    ToolTip
}

; Ctrl+P - 常规取色
^p:: {
    global currentFlowId

    local flowModule := GetFlowModuleById(currentFlowId)
    if (flowModule != "" && flowModule.HasOwnProp("PickColors")) {
        flowModule.PickColors.Call()
    } else {
        MsgBox("当前流派不支持取色", "提示")
    }
}

; Ctrl+Shift+P - 特殊取色（如召唤的压猫取色）
^+p:: {
    global currentFlowId

    local flowModule := GetFlowModuleById(currentFlowId)
    if (flowModule != "" && flowModule.HasOwnProp("PickColorsYamao")) {
        flowModule.PickColorsYamao.Call()
    } else {
        MsgBox("当前流派不支持特殊取色", "提示")
    }
}

; ============================== 启动GUI ==============================
CreateMainGui()