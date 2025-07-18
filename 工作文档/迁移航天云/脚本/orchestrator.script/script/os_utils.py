import socket
import json
import logging as log
import sys

def aligns(strings,length=20):
    string= str(strings)
    difference = length - len(string)  # 计算限定长度为20时需要补齐多少个空格
    if difference == 0:  # 若差值为0则不需要补
        return string
    elif difference < 0:
        print('错误：限定的对齐长度小于字符串长度!')
        return None
    new_string = string
    space = ' '
    return new_string + space*(difference)  # 返回补齐空格后的字符串

def message_format(info, col=None):
    r = ''
    for line in info:
        if not col:
            cols = range(0,len(line.items()))
        else:
            cols = col
        for index in cols:
            value = line.get(list(line.keys())[index])
            r = r + aligns(value)
        r = r + '\n'
    return r

def write_json(filename, json_to_write):
    # Serializing json
    json_object = json.dumps(json_to_write, indent=4)

    # Writing to sample.json
    try:
        with open(filename, "w") as outfile:
            outfile.write(json_object)
    except Exception as e:
        log.exception(str(e))


def read_json(filename):
    try:
        with open(filename) as infile:
            json_read = json.load(infile)
        return json_read
    except Exception as e:
        log.exception(str(e))


def get_host_ip():
    """
    查询本机ip地址
    :return: ip
    """
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    finally:
        s.close()

    return ip


def convert_to_sql(table, column_dict):
    columns = ', '.join("`" + str(x).replace('/', '_') + "`" for x in column_dict.keys())
    values = ', '.join("'" + str(x).replace('/', '_') + "'" for x in column_dict.values())
    sql_convert = "INSERT INTO %s ( %s ) VALUES ( %s );" % (table, columns, values)
    return sql_convert


def main():
    json_to_write = [
        {'hostgroup_id': '3', 'hostname': '10.200.11.25', 'port': '4001', 'gtid_port': '0', 'status': 'ONLINE',
         'weight': '1', 'compression': '0', 'max_connections': '1000', 'max_replication_lag': '0', 'use_ssl': '0',
         'max_latency_ms': '0', 'comment': ''}]
    write_json(filename='./hehe.json', json_to_write=json_to_write)
    json_read = read_json(filename='./hehe.json')
    print(json_read)


if __name__ == "__main__":
    main()
