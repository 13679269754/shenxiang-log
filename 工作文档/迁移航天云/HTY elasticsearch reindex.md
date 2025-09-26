| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-7月-21 | 2025-7月-21  |
| ... | ... | ... |
---
# HTY elasticsearch reindex

[toc]

```json

# 删除 video_idx_20250410234921 索引及所有文档
DELETE /video_idx_20250410234921

# 删除 popular_science_idx_20250410234933 索引及所有文档
DELETE /popular_science_idx_20250410234933

# 删除 news_idx_20250410234916 索引及所有文档
DELETE /news_idx_20250410234916

# 删除 doctor_info_idx_20250410234929 索引及所有文档
DELETE /doctor_info_idx_20250410234929

# 删除 disease_info_idx_20250410234925 索引及所有文档
DELETE /disease_info_idx_20250410234925

# 删除 case_info_idx_20250410234942 索引及所有文档
DELETE /case_info_idx_20250410234942

# 删除 article_idx_20250410234938 索引及所有文档
DELETE /article_idx_20250410234938

# 删除 academician_idx_20250410234946 索引及所有文档
DELETE /academician_idx_20250410234946

# 删除 knowledge_library_index-20250529194609 索引及所有文档
DELETE /knowledge_library_index-20250529194609

# 删除 open_api_log_index 索引及所有文档
DELETE /open_api_log_index

post _reindex
{
  "source": {
    "remote": {
      "host": "https://10.159.65.129:9200",
      "username": "elastic",
      "password": "qRYIcUELwfkOUL570JO4",
      "socket_timeout": "1m",
      "connect_timeout": "60s"
    },
    "index": "video_idx_20250410234921",
    "size": 1000
  },
  "dest": {
    "index": "video_idx_20250410234921",
    "op_type": "index",
    "routing": "=cat"
  }
}




post _reindex
{
  "source": {
    "remote": {
      "host": "https://10.159.65.129:9200",
      "username": "elastic",
      "password": "qRYIcUELwfkOUL570JO4",
      "socket_timeout": "1m",
      "connect_timeout": "60s"
    },
    "index": "popular_science_idx_20250410234933",
    "size": 1000
  },
  "dest": {
    "index": "popular_science_idx_20250410234933",
    "op_type": "index",
    "routing": "=cat"
  }
}




post _reindex
{
  "source": {
    "remote": {
      "host": "https://10.159.65.129:9200",
      "username": "elastic",
      "password": "qRYIcUELwfkOUL570JO4",
      "socket_timeout": "1m",
      "connect_timeout": "60s"
    },
    "index": "news_idx_20250410234916",
    "size": 1000
  },
  "dest": {
    "index": "news_idx_20250410234916",
    "op_type": "index",
    "routing": "=cat"
  }
}





post _reindex
{
  "source": {
    "remote": {
      "host": "https://10.159.65.129:9200",
      "username": "elastic",
      "password": "qRYIcUELwfkOUL570JO4",
      "socket_timeout": "1m",
      "connect_timeout": "60s"
    },
    "index": "doctor_info_idx_20250410234929",
    "size": 1000
  },
  "dest": {
    "index": "doctor_info_idx_20250410234929",
    "op_type": "index",
    "routing": "=cat"
  }
}




post _reindex
{
  "source": {
    "remote": {
      "host": "https://10.159.65.129:9200",
      "username": "elastic",
      "password": "qRYIcUELwfkOUL570JO4",
      "socket_timeout": "1m",
      "connect_timeout": "60s"
    },
    "index": "disease_info_idx_20250410234925",
    "size": 1000
  },
  "dest": {
    "index": "disease_info_idx_20250410234925",
    "op_type": "index",
    "routing": "=cat"
  }
}




post _reindex
{
  "source": {
    "remote": {
      "host": "https://10.159.65.129:9200",
      "username": "elastic",
      "password": "qRYIcUELwfkOUL570JO4",
      "socket_timeout": "1m",
      "connect_timeout": "60s"
    },
    "index": "case_info_idx_20250410234942",
    "size": 1000
  },
  "dest": {
    "index": "case_info_idx_20250410234942",
    "op_type": "index",
    "routing": "=cat"
  }
}






post _reindex
{
  "source": {
    "remote": {
      "host": "https://10.159.65.129:9200",
      "username": "elastic",
      "password": "qRYIcUELwfkOUL570JO4",
      "socket_timeout": "1m",
      "connect_timeout": "60s"
    },
    "index": "article_idx_20250410234938",
    "size": 1000
  },
  "dest": {
    "index": "article_idx_20250410234938",
    "op_type": "index",
    "routing": "=cat"
  }
}





post _reindex
{
  "source": {
    "remote": {
      "host": "https://10.159.65.129:9200",
      "username": "elastic",
      "password": "qRYIcUELwfkOUL570JO4",
      "socket_timeout": "1m",
      "connect_timeout": "60s"
    },
    "index": "academician_idx_20250410234946",
    "size": 1000
  },
  "dest": {
    "index": "academician_idx_20250410234946",
    "op_type": "index",
    "routing": "=cat"
  }
}







post _reindex
{
  "source": {
    "remote": {
      "host": "https://10.159.65.129:9200",
      "username": "elastic",
      "password": "qRYIcUELwfkOUL570JO4",
      "socket_timeout": "1m",
      "connect_timeout": "60s"
    },
    "index": "knowledge_library_index-20250529194609",
    "size": 1000
  },
  "dest": {
    "index": "knowledge_library_index-20250529194609",
    "op_type": "index",
    "routing": "=cat"
  }
}


post _reindex
{
  "source": {
    "remote": {
      "host": "https://10.159.65.129:9200",
      "username": "elastic",
      "password": "qRYIcUELwfkOUL570JO4",
      "socket_timeout": "1m",
      "connect_timeout": "60s"
    },
    "index": "open_api_log_index",
    "size": 1000
  },
  "dest": {
    "index": "open_api_log_index",
    "op_type": "index",
    "routing": "=cat"
  }
}

```