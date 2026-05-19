# OpenCode 配置一键恢复脚本
# 每次更新 OpenCode 后运行此脚本恢复插件、MCP 和三供应商配置

Write-Host "====== OpenCode 配置恢复工具 ======" -ForegroundColor Cyan
Write-Host ""

# 恢复 opencode.jsonc
$BackupFile = "$PSScriptRoot\opencode-backup.jsonc"
$ConfigDir = "$env:USERPROFILE\.config\opencode"
$ConfigFile = "$ConfigDir\opencode.jsonc"

if (!(Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}

if (Test-Path $BackupFile) {
    Copy-Item -Path $BackupFile -Destination $ConfigFile -Force
    Write-Host "✅ opencode.jsonc 已恢复" -ForegroundColor Green
} else {
    Write-Host "❌ 未找到 $BackupFile" -ForegroundColor Red
}

# 恢复 oh-my-openagent.json（三供应商配置）
$AgentConfigFile = "$ConfigDir\oh-my-openagent.json"
$AgentBackupFile = "$PSScriptRoot\oh-my-openagent.json"

if (Test-Path $AgentBackupFile) {
    Copy-Item -Path $AgentBackupFile -Destination $AgentConfigFile -Force
    Write-Host "✅ oh-my-openagent.json 已恢复（三供应商配置）" -ForegroundColor Green
} else {
    Write-Host "❌ 未找到 $AgentBackupFile" -ForegroundColor Red
}

# 校验结果
Write-Host ""
Write-Host "====== 当前配置概览 ======" -ForegroundColor Cyan
Write-Host "供应商:" -ForegroundColor Yellow
Write-Host "  • OpenCode Go    — 高阶任务（deepseek-v4-pro, qwen3.6-plus）"
Write-Host "  • OpenCode Zen   — 免费/快速任务（deepseek-v4-flash-free, gemini-3-flash）"
Write-Host "  • Ollama（本地） — 轻量任务（qwen2.5-coder:14b）"
Write-Host "MCP:" -ForegroundColor Yellow
Write-Host "  • filesystem — 桌面文件访问（npx @modelcontextprotocol/server-filesystem）"
Write-Host ""

Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
