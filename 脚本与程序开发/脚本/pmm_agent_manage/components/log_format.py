import functools
import subprocess

from components.ordinary import exe_shell_cmd_stdout, exe_shell_cmd
from config import logger


def log_decorator(func):
    """提示输出，错误处理统一入口，用于所有函数调用"""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        logger.info(f'--------------- 开始执行函数 {func.__name__}')
        try:
            result = func(*args, **kwargs)
            if result:
                logger.info(f'--------------- {func.__name__} 执行成功')
            else:
                raise Exception(f'--------------- {func.__name__} 执行失败')
            return result
        except Exception as e:
            import traceback
            traceback.print_exc()
            logger.error(e)
            unregister_node()
            exit(0)
        except subprocess.CalledProcessError as e:
            import traceback
            traceback.print_exc()
            logger.error(e.stdout.decode('utf-8'))
            unregister_node()
            exit(0)
    return wrapper

def unregister_node():
    command = "pmm-admin list | grep -v 'type' | awk -F ' ' '{print $2}' | awk -F '-' '{if($1 != \"\") print $1}'"
    print(command)
    if exe_shell_cmd_stdout(command).strip() != "" and exe_shell_cmd_stdout(command).find('Failed'):
        command_unregister = f'pmm-admin unregister --force'
        command_restart_pmm_client = f'systemctl restart pmm-agent'
        return exe_shell_cmd(command_unregister) and exe_shell_cmd(command_restart_pmm_client)