
要解决 `rsync` 因 SSH 断开导致任务中断、且后台执行无法输入密码的问题，核心思路是 **免密 SSH 登录（根本解决密码输入问题）+ 后台执行/断线重连（防止 SSH 断开中断任务）**，以下是分步落地方案：

### 一、第一步：配置 SSH 免密登录（核心解决密码输入问题）
这是后台执行 `rsync` 的前提（无需手动输密码），只需配置一次永久生效：
#### 1. 生成 SSH 密钥对（在执行 rsync 的本地机器操作）
```bash
# 一路回车（无需设置密钥密码，否则后台仍需输密码）
ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
```
- `-t rsa`：加密算法；`-b 4096`：密钥长度（更安全）；`-N ""`：空密码；`-f`：指定密钥保存路径。

#### 2. 将公钥拷贝到目标服务器（172.30.1.40）
```bash
# 手动输入一次目标服务器密码（仅这一次）
ssh-copy-id root@172.30.1.40
# 若目标 SSH 端口非22，加 -p 参数：ssh-copy-id -p 端口 root@172.30.1.40
```
- 验证免密：执行 `ssh root@172.30.1.40`，若无需密码直接登录，说明配置成功。

### 二、第二步：后台执行 rsync + 防 SSH 断开（3 种方案）
免密配置完成后，任选以下一种方式执行 `rsync`，即使 SSH 断开，任务也会在后台继续运行：

#### 方案 1：nohup + &（最简单，适合单次任务）
```bash
# nohup 让进程脱离终端，& 后台执行，输出日志到 nohup.out
nohup rsync -avzP --compress-level=9  localssd 172.30.1.40:/data/064_dzj_msql_1.0/prod > rsync_log.log 2>&1 &

# 查看任务状态（确认是否在运行）
ps -ef | grep rsync
# 查看日志（监控进度/报错）
tail -f rsync_log.log
```
- `> rsync_log.log 2>&1`：将标准输出和错误输出写入日志文件，方便排查问题；
- 即使关闭 SSH 终端，`nohup` 会让 `rsync` 继续运行。

#### 方案 2：screen/tmux（推荐，支持断线重连+实时看进度）
适合大文件传输（可随时断开 SSH，重新连接后恢复会话看进度）：
```bash
# 1. 安装 screen（CentOS/RHEL）
yum install -y screen

# 2. 创建新的 screen 会话（命名为 rsync_task）
screen -S rsync_task

# 3. 在 screen 会话内执行 rsync（此时可正常免密执行，无需输密码）
rsync -avzP --compress-level=9  localssd 172.30.1.40:/data/064_dzj_msql_1.0/prod

# 4. 断开 SSH 不影响任务：按 Ctrl+A 再按 D（脱离 screen 会话）
# 5. 重新连接服务器后，恢复 screen 会话看进度：
screen -r rsync_task

# 若忘记会话名，查看所有 screen 会话：
screen -ls
```

#### 方案 3：nohup + rsync --partial（断点续传，适合超大文件）
若传输中意外中断，可续传未完成的文件（无需重新传）：
```bash
nohup rsync -avzP --compress-level=9 --partial --append localssd 172.30.1.40:/data/064_dzj_msql_1.0/prod > rsync_log.log 2>&1 &
```
- `--partial`：保留未传输完成的临时文件；
- `--append`：续传时追加到临时文件末尾（避免重复传输）。

### 三、额外优化：防止 SSH 连接超时（辅助减少断开概率）
结合之前配置的 SSH 保活，在本地机器 `/etc/ssh/ssh_config` 或 `~/.ssh/config` 加以下配置，减少 SSH 连接断开：
```bash
# 编辑配置文件
vim ~/.ssh/config

# 添加（针对目标服务器）
Host 172.30.1.40
  ServerAliveInterval 30
  ServerAliveCountMax 1000
  TCPKeepAlive yes

# 保存后无需重启，下次 SSH/rsync 自动生效
```

### 四、完整执行流程（总结）
1. 配置 SSH 免密登录 → 解决后台输密码问题；
2. 用 `screen -S rsync_task` 创建会话 → 执行 `rsync` 命令 → 按 `Ctrl+A+D` 脱离会话；
3. 即使关闭 SSH 终端，`rsync` 仍在后台运行，重新登录后用 `screen -r rsync_task` 查看进度。

### 常见问题排查
1. **ssh-copy-id 失败**：检查目标服务器 22 端口是否开放，或执行 `ssh root@172.30.1.40 "mkdir -p ~/.ssh && chmod 700 ~/.ssh"` 手动创建目录；
2. **rsync 权限不足**：确保目标服务器 `/data/064_dzj_msql_1.0/prod` 目录有 `root` 写入权限（`chmod 755 /data/064_dzj_msql_1.0/prod`）；
3. **nohup 日志显示权限错误**：检查本地 `localssd` 目录是否有读权限（`chmod -R 755 localssd`）。