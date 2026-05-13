import paramiko
import sys

def run():
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect('114.215.175.120', username='root', password='Sx1204180109!', timeout=15)
        
        commands = [
            'find /root/docker/nginx -name "*.conf"',
            'docker ps --format "{{.Names}} {{.ID}}"',
            'cat /root/docker/nginx/conf/conf.d/default.conf'
        ]
        
        for cmd in commands:
            print(f"--- Running: {cmd} ---")
            stdin, stdout, stderr = client.exec_command(cmd)
            print(stdout.read().decode())
            print(stderr.read().decode())
            
        client.close()
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == '__main__':
    run()
