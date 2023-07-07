#!/bin/bash
function backup_database(){
    QUEUE=`echo "show tables from $db" | mysql -u root -pxx  | sed '1d'`  
    table_num=`echo $QUEUE  | sed 's/ /\n/g' | wc -l `

    # echo "QUEUE: $QUEUE "
    THREAD=10                       
    TMPFIFO=/tmp/$$.fifo
    mkfifo $TMPFIFO                
    exec 5<>${TMPFIFO}              
    rm -rf ${TMPFIFO}               
    for((i=1;i<=$THREAD;i++))
    do
        echo ;                       
    done >&5                        

    for table_name in $QUEUE           
    do
            read -u5        
            {          
            mysqldump  -u root -pxx $db --tables $table_name > ${backup_dir}/${table_name}.sql

            if [[ $? -eq 0 ]]; then
                echo "`date +'%F %T'` ${db}|${table_num}|SUCCEED|$db.$table_name" >> $infofile
            else
                echo "`date +'%F %T'` ${db}|${table_num}|FAILED|$db.$table_name" >> $infofile
            fi
            echo "" >&5      
            } &
    done
    wait
    exec 5>&-
    # exit 0
}

delete_old_backup(){
    echo "delete backup file:" >> ${logfile}
    find /mysql_backup/data/ -type f -mtime +${retain_day} | tee ${logfile} | xargs rm -rf
    echo "Deleted files before 7 days" >>  ${logfile}
}


function send_dump_message(){
    echo "Send wechat message"
    python3 /mysql_backup/check_backup.py $*
}

function main(){
    backup_time=`date +%F`
    db_list="patal apps lisa"
    backup_dir=/mysql_backup/data
    mkdir ${backup_dir}/${backup_time}/
    logfile=${backup_dir}/${backup_time}/backup.log
    infofile=${backup_dir}/${backup_time}/backup.info

    touch $logfile $infofile
    echo > $infofile
    retain_day=7
    
    for db in $db_list
    do
        backup_dir=/mysql_backup/data/${backup_time}/${db}
        mkdir -p $backup_dir
        backup_database 
        sleep 1
    done

    send_dump_message $db_list
    delete_old_backup

}

main
exit 0
