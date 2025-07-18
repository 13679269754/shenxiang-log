| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-3月-25 | 2025-3月-25  |
| ... | ... | ... |
---
# docker 导出导入

[toc]

## container导出导入

### 导出容器
使用 docker export 命令能将运行中的 Docker 容器导出为一个 tar 文件。这一操作会把容器的文件系统打包成一个 tar 文件，但不会保存容器的元数据（如历史记录、层信息等）。
```bash
docker export -o <输出文件路径> <容器 ID 或名称>
```
示例:   
若有一个名为 my_nginx_container 的容器，要将其导出到当前目录下的 my_nginx_container.tar文件中，可以使用以下命令：
```bash
docker export -o my_nginx_container.tar my_nginx_container
```

### 导入容器
使用 docker import 命令可以将导出的 tar 文件导入为一个新的 Docker 镜像。

```bash
docker import <输入文件路径> <新镜像名称:标签>
```

示例：  
若要将之前导出的 my_nginx_container.tar 文件导入为一个名为 my_nginx_imported:latest 的新镜像，可以使用以下命令：

```bash
docker import my_nginx_container.tar my_nginx_imported:latest
```

## 镜像的导入导出

### 导出镜像

可以使用 docker save 命令将 Docker 镜像导出为一个 tar 文件，之后就能在其他环境中使用该文件重新加载镜像。

```bash
docker save -o <输出文件路径> <镜像名称:标签>
```

示例：  
假设你有一个名为 nginx:latest 的镜像，要将其导出到当前目录下的 nginx_image.tar 文件中，可以使用以下命令：

```bash
docker save -o nginx_image.tar nginx:latest
```

### 导入镜像

使用 docker load 命令可以将之前导出的 tar 文件重新加载为 Docker 镜像。
```bash
docker load -i <输入文件路径>
```

示例：  
若要导入之前导出的 nginx_image.tar 文件，可以使用以下命令：
```bash
docker load -i nginx_image.tar
```