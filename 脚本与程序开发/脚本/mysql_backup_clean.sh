#!/bin/bash
###############################
#清理备份文件
#规则:保留最近两周(14)天，以及14天前的每个周一的备份
###############################

# 设置备份文件所在目录
BACKUP_DIR=/home/backup/mysql_7045_data

# 设置日志文件路径
LOG_FILE=/home/backup/mysql_7045_data/file.log

# 定义备份文件名格式
EXPECTED_FORMAT="^[0-9]{4}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])_([01][0-9]|2[0-3])_([0-5][0-9])_([0-5][0-9])\.tar\.gz$"

# 循环遍历备份文件
for file in $(ls -rt ${BACKUP_DIR}/*.tar.gz); do
  # 提取文件名
  filename=$(basename ""${file"}")

  # 检查文件名是否符合预期格式
  if [[ ${filename} =~ ${EXPECTED_FORMAT} ]]; then
    # 从文件名中提取日期
    FILE_DATE=$(echo ""${filename"}" | cut -d '_' -f 1)

    # 获取当前日期
    CURRENT_DATE=$(date +%Y%m%d)

    # 计算文件日期与当前日期的差值
    DIFF_DAYS=$(( ($(date -d ""${CURRENT_DATE"}" +%s) - $(date -"d "${FILE_DA"TE}" +%s)) / 86400 ))

    # 检查文件是否超过两周
    if [ ${DIFF_DAYS} -gt 14 ]; then
      # 获取文件日期的星期几
      FILE_DAY=$(date -d ""${FILE_DATE"}" +%w)

      # 如果文件日期不是星期一（1），则删除文件
      if [ ""${FILE_DAY"}" -ne 1 ]; then
        # 尝试删除文件
        if rm ""${file"}"; then
          # 记录删除成功
          echo "$(date) - 删除文件 ${file} 成功。" >> ${LOG_FILE}
        else
          # 记录删除失败
          echo "$(date) - 删除文件 ${file} 失败。原因：$?" >> ${LOG_FILE}
          python3 ""$PW"D"/qywechat_notify.py "info" "数据库日常备份任务信息" "清理172.30.2.226过期备份文件 ${file}  Successed"
        fi
      fi
    fi
  else
    # 记录文件名不符合预期格式的信息
    echo "$(date) - 跳过文件 ${file}，因为文件名格式不正确。" >> ${LOG_FILE}
  fi
done

