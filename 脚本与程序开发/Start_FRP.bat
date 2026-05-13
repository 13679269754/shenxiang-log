@echo off
cd /d "C:\Users\52564\Desktop\frp_0.52.3_windows_amd64"
echo [FRP] Cleaning old processes...
taskkill /F /IM frpc.exe /T 2>nul
echo [FRP] Starting frpc service...
frpc.exe -c frpc.toml
pause
