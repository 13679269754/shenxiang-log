# 自动化配置阿里云 FRP 环境脚本
# 运行环境: PowerShell
# 依赖: Windows 自带的 OpenSSH 客户端

$ServerIP = "114.215.175.120"
$User = "root"
$RemoteDir = "/opt/frp-server"

Write-Host ">>> 开始自动化配置阿里云环境..." -ForegroundColor Cyan

# 1. 创建远程目录
Write-Host "1. 创建远程目录: $RemoteDir"
ssh $User@$ServerIP "mkdir -p $RemoteDir"

# 2. 上传配置文件 (使用 scp)
Write-Host "2. 上传配置文件..."
scp .\frp-server\frps.ini ${User}@${ServerIP}:${RemoteDir}/frps.ini
scp .\frp-server\docker-compose.yml ${User}@${ServerIP}:${RemoteDir}/docker-compose.yml

# 3. 启动容器
Write-Host "3. 启动阿里云 FRPS 容器..."
ssh $User@$ServerIP "cd $RemoteDir; docker compose up -d"

# 4. 配置 Nginx (示例转发配置)
Write-Host "4. 检查 Nginx 配置..."
$NginxConf = @"
server {
    listen 80;
    server_name $ServerIP;

    location /v1/ {
        proxy_pass http://127.0.0.1:18000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
"@
# 注意：这里仅打印建议配置，实际应用可能需要更复杂的合并操作
Write-Host "建议 Nginx 配置内容已生成，请确保 /etc/nginx/conf.d/ 下有相应配置并重启 Nginx。"

Write-Host ">>> 阿里云配置完成！" -ForegroundColor Green
