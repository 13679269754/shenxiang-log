
## Gitea 为例
### 从命令行创建一个新的仓库

```
touch README.md
git init
git checkout -b main
git add README.md
git commit -m "first commit"
git remote add origin http://172.29.105.240:3000/sxadmin/simpe-api.git
git push -u origin main
```
### 从命令行推送已经创建的仓库
```
git remote add origin http://172.29.105.240:3000/sxadmin/simpe-api.git
git push -u origin main
```

### 其他
```bash
# 如果之前已经有 `origin`，先删掉
git remote remove origin

```