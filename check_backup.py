import subprocess
import requests
import sys
import json
from prometheus_client import push_to_gateway, CollectorRegistry, Gauge
from datetime import datetime

def run_shell_command(command):
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = process.communicate()
    print(output)
    return output.decode('utf-8').strip()

def send_alerts(m):
    message = m
    url = "企业微信告警机器人url"
    headers = {'Content-Type': 'application/json;charset=utf-8'}
    data_text = {
        "msgtype": "text",
        "text": {
            "content": message,
        }
    }
    r = requests.post(url,data=json.dumps(data_text),headers=headers)

if __name__ == "__main__":
    db_list = sys.argv[1:]
    print(db_list)
    dt = datetime.today().strftime('%Y-%m-%d')
    log_dir=f"/mysql_backup/data/{dt}/backup.info"

    for db in db_list:
        check_table_number_command = f"backNum=`cat {log_dir}  | grep -E '{db}' | wc -l`;tableNum=`cat {log_dir}  | grep  '{db}' | head -n1 | awk -F'|' '{{print $2}}'`;if [ $backNum -eq $tableNum ];then echo '所有的表均备份';else echo '有些表没有正常备份';fi"
        check_is_succeed = f"is_succeed=`cat {log_dir} | grep FAIL `;if [ -n \"$is_succeed\" ];then echo $is_succeed;else echo '并成功备份' ;fi"
        table_number_output = run_shell_command(check_table_number_command)
        check_succeed_output = run_shell_command(check_is_succeed)
        
        message_str = db + table_number_output + ', ' + check_succeed_output
        
        print(message_str)
        send_alerts(message_str)
