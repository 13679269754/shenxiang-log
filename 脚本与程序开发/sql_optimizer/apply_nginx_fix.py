import paramiko

def update_nginx():
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect('114.215.175.120', username='root', password='Sx1204180109!', timeout=15)
        
        # 完整的配置文件内容
        new_conf = """server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name _;

    ssl_certificate     /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;

    # ---------------- 全局优化配置 ----------------
    proxy_buffers 16 16k;  
    proxy_buffer_size 32k;
    proxy_read_timeout 300s;
    proxy_connect_timeout 75s;
    proxy_send_timeout 300s;

    # 1. Vaultwarden
    location /vault/ {
        proxy_pass http://127.0.0.1:8081/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # 2. Portainer
    location /portainer/ {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_pass http://127.0.0.1:9000/;
    }

    # 3. SQL Optimizer API (v1)
    location /v1/ {
        proxy_pass http://127.0.0.1:8000/;  # 指向 frp 隧道端口
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        
        # AI 流式输出优化
        proxy_buffering off;
        proxy_cache off;
        proxy_http_version 1.1;
        chunked_transfer_encoding on;
        tcp_nopush on;
        tcp_nodelay on;
        keepalive_timeout 65;
    }
}
"""
        # 使用 sftp 上传临时文件
        sftp = client.open_sftp()
        f = sftp.open('/root/docker/nginx/conf/conf.d/mystation.conf', 'w')
        f.write(new_conf)
        f.close()
        sftp.close()
        
        # 重启 nginx 容器
        stdin, stdout, stderr = client.exec_command('docker restart nginx-web')
        print("RESTART_OUT:", stdout.read().decode())
        print("RESTART_ERR:", stderr.read().decode())
        
        client.close()
        print("SUCCESS")
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == '__main__':
    update_nginx()
