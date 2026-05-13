from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import requests
import json

app = FastAPI(title="Local SQL Optimizer Service")

OLLAMA_API_URL = "http://host.docker.internal:11434/api/generate"
MODEL_NAME = "qwen2.5-coder:14b"

class SQLRequest(BaseModel):
    sql: str
    context: str = ""

SYSTEM_PROMPT = """你是一个专业的数据库专家和 SQL 优化分析师。
你的任务是接收用户的 SQL 语句，并提供以下方面的分析和优化建议：
1. **潜在问题**：是否存在全表扫描、索引失效、子查询效率低下等。
2. **优化建议**：如何重写 SQL，建议增加哪些索引。
3. **优化后的 SQL**：提供一个优化后的版本。
4. **性能预估**：简述优化后的预期效果。

请使用 Markdown 格式回答，保持专业且易于理解。"""

@app.post("/optimize")
async def optimize_sql(request: SQLRequest):
    prompt = f"请分析并优化以下 SQL：\n\n```sql\n{request.sql}\n```\n\n上下文信息：{request.context}"
    
    payload = {
        "model": MODEL_NAME,
        "prompt": prompt,
        "system": SYSTEM_PROMPT,
        "stream": False
    }
    
    try:
        response = requests.post(OLLAMA_API_URL, json=payload)
        response.raise_for_status()
        result = response.json()
        return {"analysis": result.get("response", "未能生成分析结果")}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
