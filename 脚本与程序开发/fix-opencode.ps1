# OpenCode 配置一键恢复脚本
# 每次更新 OpenCode 后运行此脚本恢复插件和 MCP 配置

$BackupFile = "$PSScriptRoot\opencode-backup.jsonc"
$ConfigDir = "$env:USERPROFILE\.config\opencode"
$ConfigFile = "$ConfigDir\opencode.jsonc"

if (!(Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}

if (Test-Path $BackupFile) {
    Copy-Item -Path $BackupFile -Destination $ConfigFile -Force
    Write-Host "✅ OpenCode 配置已恢复！" -ForegroundColor Green
    Write-Host ""
    Write-Host "当前配置内容:" -ForegroundColor Cyan
    Get-Content $ConfigFile
} else {
    Write-Host "❌ 备份文件不存在！" -ForegroundColor Red
    Write-Host "请从其他正常机器复制 opencode.jsonc 到: $BackupFile"
}

Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
