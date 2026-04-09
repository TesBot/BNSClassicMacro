; ============================== Resources.ahk ==============================
; 资源打包配置文件 - 按流派分组管理所有FileInstall
; 编译时所有资源嵌入exe，运行时解压到临时目录
; ==============================

; 定义临时资源目录
global ResourceTempDir := A_Temp . "\KadaoMacro_Res"

; 确保临时目录存在
if !DirExist(ResourceTempDir)
    DirCreate(ResourceTempDir)

; ============================== 公共资源 ==============================
; 应用图标（需要真正的 .ico 格式，PNG 格式的 .ico 无法加载）
global AppIconPath := A_ScriptDir . "\favicon.ico"
FileInstall("favicon.ico", ResourceTempDir . "\favicon.ico", 1)
; 打包后使用临时目录的图标
if A_IsCompiled
    AppIconPath := ResourceTempDir . "\favicon.ico"

; 设置托盘图标（如果图标格式正确则使用，否则使用默认图标）
if FileExist(AppIconPath) {
    try {
        TraySetIcon(AppIconPath)
    } catch {
        TraySetIcon(A_AhkPath, 1)  ; 使用 AHK 默认图标作为备用
    }
} else {
    TraySetIcon(A_AhkPath, 1)
}

; 角色血条（所有职业共用）
FileInstall("pic\juesexuetiao.bmp", ResourceTempDir . "\juesexuetiao.bmp", 1)

; ============================== 气功流派 ==============================
; 1系推龙依赖图片
FileInstall("pic\qigong-huolianzhang-new.png", ResourceTempDir . "\qigong-huolianzhang-new.png", 1)
FileInstall("pic\qigong-hunyuanzhao-new.png", ResourceTempDir . "\qigong-hunyuanzhao-new.png", 1)

; 2系攻时依赖图片（待添加）
; FileInstall("pic\qigong-gongshi-xxx.bmp", ResourceTempDir . "\qigong-gongshi-xxx.bmp", 1)

; 3系冰河依赖图片（待添加）
; FileInstall("pic\qigong-binghe-xxx.bmp", ResourceTempDir . "\qigong-binghe-xxx.bmp", 1)

; ============================== 召唤流派 ==============================
; 1系马蜂依赖图片
FileInstall("pic\zhaohuan-qianniuhua.bmp", ResourceTempDir . "\zhaohuan-qianniuhua.bmp", 1)
FileInstall("pic\zhaohuan-qianniuhua-new.png", ResourceTempDir . "\zhaohuan-qianniuhua-new.png", 1)
FileInstall("pic\zhaohuan-jineng1-yemanshengzhang.bmp", ResourceTempDir . "\zhaohuan-jineng1-yemanshengzhang.bmp", 1)
FileInstall("pic\zhaohuan-jineng1-yemanshengzhang-new.png", ResourceTempDir . "\zhaohuan-jineng1-yemanshengzhang-new.png", 1)
FileInstall("pic\zhaohuan-jineng1-mangcizaibei.bmp", ResourceTempDir . "\zhaohuan-jineng1-mangcizaibei.bmp", 1)
FileInstall("pic\zhaohuan-jineng2-shequ.bmp", ResourceTempDir . "\zhaohuan-jineng2-shequ.bmp", 1)
FileInstall("pic\zhaohuan-jineng2-jingjiteng.bmp", ResourceTempDir . "\zhaohuan-jineng2-jingjiteng.bmp", 1)
FileInstall("pic\zhaohuan-yamao.bmp", ResourceTempDir . "\zhaohuan-yamao.bmp", 1)
FileInstall("pic\zhaohuan-naonao.bmp", ResourceTempDir . "\zhaohuan-naonao.bmp", 1)

; 3系向日葵依赖图片（待添加）
; FileInstall("pic\zhaohuan-xiangrikui-xxx.bmp", ResourceTempDir . "\zhaohuan-xiangrikui-xxx.bmp", 1)

; ============================== 剑士流派 ==============================
; 3系雷龙依赖图片（待添加）
; FileInstall("pic\jianshi-leilong-xxx.bmp", ResourceTempDir . "\jianshi-leilong-xxx.bmp", 1)

; ============================== 咒术流派 ==============================
; 2系黑龙依赖图片（待添加）
; FileInstall("pic\zhoushu-heilong-xxx.bmp", ResourceTempDir . "\zhoushu-heilong-xxx.bmp", 1)

; ============================== 资源管理辅助函数 ==============================
GetResourcePath(filename) {
    global ResourceTempDir
    return ResourceTempDir . "\" . filename
}