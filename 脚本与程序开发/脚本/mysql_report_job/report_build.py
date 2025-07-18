#!/usr/bin/env python
# -*- coding:utf-8 -*-
import datetime

import pandas as pd

from bs4 import BeautifulSoup

def format_html(html):
    soup = BeautifulSoup(html, 'html.parser')
    formatted_html = soup.prettify()
    return formatted_html


html_head = \
    """
    <head>
    <meta charset="utf-8">
        <STYLE TYPE="text/css" MEDIA=screen>
                .modal {
                display: none;
                position: fixed;
                z-index: 1;
                left: 0;
                top: 0;
                width: 100%;
                height: 100%;
                overflow: auto;
                background-color: rgba(0,0,0,0.4);
            }
        
            .modal-content {
                background-color: #fefefe;
                margin: 15% auto;
                padding: 20px;
                border: 1px solid #888;
                width: 80%;
            }
        
            .close {
                color: #aaa;
                float: right;
                font-size: 28px;
                font-weight: bold;
            }
            .scroll-top-btn {
                position: fixed;
                bottom: 20px;
                right: 20px;
                background-color: #007bff;
                color: white;
                padding: 10px 20px;
                border-radius: 5px;
                cursor: pointer;
            }
            .scroll-btn {
                bottom: 2px;
                right: 2px;
                background-color: #007bff;
                color: white;
                padding: 2px 2px;
                border-radius: 3px;
                cursor: pointer;
                font-size: 8px;
            }
            
            table.dataframe {
                border-collapse: collapse;
                border: 2px solid #a19da2;
                /*居中显示整个表格*/
                margin: auto;
            }
            a.info:hover {background:#eee;color:#000000; position:relative;}
            a.info span {display: none; }
            a.info:hover span {font-size:11px!important; color:#000000; display:block;position:absolute;top:30px;left:40px;width:150px;border:1px solid #ff0000; background:#FFFF00; padding:1px 1px;text-align:left;word-wrap: break-word; white-space: pre-wrap;}
            table.dataframe {
                font-family: Consolas;
                color: Black;
                background: #FFFFCC;
                padding: 1px;
                margin: 0px 0px 0px 0px;
                border-collapse: collapse;
            }
            table.dataframe th {
                font: bold 11px Consolas;
                color: White;
                background: #0066cc;
                padding: 2px;
                white-space: nowrap;
            }
            table.dataframe td {
                font-family: Consolas;
                word-wrap: break-word;
                white-space: nowrap;
                font-size: 0.6em;
                padding: 2px;
            }
            table.dataframe tr:nth-child(odd) {
                background: White;
            }
            table.dataframe tr:hover {
                background-color: yellow;
            }
            body {
                font-family: 宋体;
            }
            h1 {
                color: #5db446
                text-align: left;
            }
            div.header h2 {
                color: #0002e3;
                font-family: 黑体;
                text-align: left;
                background-color: yellow;
            }
            div.content h2 {
                text-align: left;
                font-size: 28px;
                text-shadow: 2px 2px 1px #de4040;
                color: #fff;
                font-weight: bold;
                background-color: #008eb7;
                line-height: 1.5;
                margin: 20px 0;
                box-shadow: 10px 10px 5px #888888;
                border-radius: 5px;
            }
            h3 {
                font-size: 22px;
                text-align: left;
                text-shadow: 2px 2px 1px #de4040;
                color: rgba(239, 241, 234, 0.99);
                line-height: 1.5;
            }
            h4 {
                color: #e10092;
                font-family: 楷体;
                font-size: 20px;
                text-align: center;
            }
            td img {
                /*width: 60px;*/
                max-width: 300px;
                max-height: 300px;
            }
        </STYLE>
</head>
<body>

<div id="myModal" class="modal">
    <div class="modal-content">
        <span class="close" onclick="closeModal()">&times;</span>
        <p id="modalText">Initial Text</p>
    </div>
</div>
    """

# 右下角跳转到目录按钮 +
html_goto_catalogue  = """
        <button class="scroll-top-btn" onclick="scrollToTop()">返回目录</button>

    <script>
        <!--右下角跳转到目录按钮-->
        function scrollToTop() {
            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        }
        <!--显示完整信息按钮自动关闭当前的alert框-->
        let modal = document.getElementById("myModal");
        let modalText = document.getElementById("modalText");
        let index = 0;
        let alerts = ["Alert 1", "Alert 2", "Alert 3"]; // Add your list of alerts here
    
        function openModal(text) {
            modalText.innerHTML = text;
            modal.style.display = "block";
            index = (index + 1) % alerts.length;
        }
    
        function closeModal() {
            modal.style.display = "none";
        }
    
        window.onclick = function(event) {
            if (event.target == modal) {
                modal.style.display = "none";
            }
        }
    </script>
</body>
</html>
"""


# 报告文件大标题
html_title = """
        <div align="center" class="header">
            <!--标题部分的信息-->
            <h1 align="center">{host}_{date}运行状态报告 </h1>
        </div> 
        """

# 服务小标题
html_service_title = """
        <div align="center" class="header">
            <!--标题部分的信息-->
            <h2 align="center">{host_port}运行状态报告 </h2>
            <hr>
        </div> 
        """

# 指标分类标题
html_metric_type = """
        <div align="center" class="header">
            <!--标题部分的信息-->
            <h3 align="center">{metric_type} </h3>
            <hr>
        </div> 
        """

# 导航标签
html_goto_title = """
        <a name="{metric_name_for_goto}"></a>
        """


# 构建导航页表格
navigation_head="""
        <a name="directory"><font size=+2 face="Consolas" color="#336699"><b>目录</b></font></a>
        <hr>
        <table width="100%" border="1" bordercolor="#000000" cellspacing="0px" style="border-collapse:collapse; margin-top:0.3cm;" align="center">"""

navigation_row_start="""
        <tr>
        <td style="background-color:#FFCC00" rowspan="{rowspan}"  nowrap align="center" width="10%"><a class="info" href="#{href_link}"><font size=+0.5 face="Consolas" color="#000000"><b>{row_title}</b><span> </span></font></a></td>"""
navigation_row_end="""
        </tr>"""

navigation_cell="""<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#{navigation_2_level}"><font size=2.5 face="Consolas" color="#336699">{navigation_2_name}<span>{cellspan}</span></font></a></td>"""


def text_box_html(df_html,metric_class):
    html_table_statu = \
        """
        <div align="left">
            <!--标题部分的信息-->
            <font  color="00CCFF" style="text-align: left;"><b>{metric_class}</b></font>
        </div>
        </br><textarea style="width:800px;font-family:Consolas;font-size:11px;overflow:auto;background-color:#FFFFCC" rows="20"> 
        {df_html}
        </textarea>
        """.format(metric_class=metric_class,df_html=df_html)
    return html_table_statu

def html_table_build_for_class(df_html,metric_class):

    html_table_statu = \
        """
        <div align="left">
            <!--标题部分的信息-->
            <font  color="00CCFF" style="text-align: left;"><b>{metric_class}</b></font>
        </div>
        <div class="content">
            <!--正文内容-->
            <div>
                {df_html}
            </div>
            <p style="text-align: center">
            </p>
        </div>
        """.format(metric_class=metric_class,df_html=df_html)
    return html_table_statu


# 将过长的cell截断显示,并且提供一个按钮，点击该按钮显示完整数据
def format_longdata(val):
    if val is not None and val != ""  and  len(val) > 40 :
        return (f'{val[:40]}... <button class="scroll-btn" onclick="openModal(\'完整sql语句: <br> {val}\')">显示完整语句</button>')

    else:
        return val


# 往字典中写入相同的 key 时，将原来的 value 和新的 value 合并为一个列表
def merge_values_to_list(dictionary, key, value):
    if key in dictionary:
        if not isinstance(dictionary[key], list):
            dictionary[key] = [dictionary[key]]
        dictionary[key].append(value)
    else:
        dictionary[key] = value

# 往字典中写入相同的 key 时，将原来的 value 和新的 value 拼接
def merge_values(dictionary, key, new_value):
    if key in dictionary:
        dictionary[key] = dictionary[key] + new_value
    else:
        dictionary[key] = new_value


