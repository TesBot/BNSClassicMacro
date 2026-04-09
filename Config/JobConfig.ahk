; ============================== JobConfig.ahk ==============================
; 职业/流派映射配置 - 定义所有支持的职业和流派
; ==============================

; 职业/流派映射表
global JobFlowMap := Map()

; 召唤职业
JobFlowMap.Set("召唤", [
    {name: "1系马蜂", flowId: "召唤_1系马蜂"}
    ; {name: "3系向日葵", flowId: "召唤_3系向日葵"}  ; 待开发
])

; 气功职业
JobFlowMap.Set("气功", [
    {name: "1系推龙", flowId: "气功_1系推龙"}
    ; {name: "2系攻时", flowId: "气功_2系攻时"}  ; 待开发
    ; {name: "3系冰河", flowId: "气功_3系冰河"}  ; 待开发
])

; 剑士职业（待开发）
; JobFlowMap.Set("剑士", [
;     {name: "3系雷龙", flowId: "剑士_3系雷龙"}
; ])

; 咒术职业（待开发）
; JobFlowMap.Set("咒术", [
;     {name: "2系黑龙", flowId: "咒术_2系黑龙"}
; ])

; ============================== 流派状态定义 ==============================
; 每个流派的状态标记（已实现/待开发）
global FlowStatus := Map()
FlowStatus.Set("召唤_1系马蜂", "已实现")
FlowStatus.Set("气功_1系推龙", "已实现")
; FlowStatus.Set("召唤_3系向日葵", "待开发")
; FlowStatus.Set("气功_2系攻时", "待开发")
; FlowStatus.Set("气功_3系冰河", "待开发")
; FlowStatus.Set("剑士_3系雷龙", "待开发")
; FlowStatus.Set("咒术_2系黑龙", "待开发")

; ============================== 辅助函数 ==============================
; 获取职业列表
GetJobList() {
    global JobFlowMap
    local jobs := []
    for job, flows in JobFlowMap {
        jobs.Push(job)
    }
    return jobs
}

; 获取职业的流派列表
GetFlowList(job) {
    global JobFlowMap
    return JobFlowMap.Get(job, [])
}

; 检查流派是否已实现
IsFlowImplemented(flowId) {
    global FlowStatus
    return FlowStatus.Get(flowId, "待开发") = "已实现"
}

; 获取流派状态描述
GetFlowStatusDesc(flowId) {
    global FlowStatus
    return FlowStatus.Get(flowId, "待开发")
}