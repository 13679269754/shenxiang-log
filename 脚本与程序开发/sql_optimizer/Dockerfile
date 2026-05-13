FROM m.daocloud.io/docker.io/library/python:3.9-slim

WORKDIR /app

# 安装必要依赖
RUN pip install --no-cache-dir fastapi uvicorn requests pydantic -i https://pypi.tuna.tsinghua.edu.cn/simple

# 拷贝代码
COPY . .

# 暴露接口端口
EXPOSE 8001

# 启动命令
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
