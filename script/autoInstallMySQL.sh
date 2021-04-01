#!/bin/bash
######################################
###	说明: 
###	1).本脚本仅支持在CentOS6/CentOS7环境下安装。
### 2).默认MySQL安装版本：MySQL5.7 (mysql-5.7.27-linux-glibc2.12-x86_64.tar.gz)。
###	3).必须在root用户目录下执行改脚本。
### 4).安装过程需设置mysql密码(默认密码：【Test,123】)。
###	5).安装目录： /opt/mysql
###	6).数据仓库目录： /data/mysql
### 7).端口号默认3306，其余参数按需自行修改(/etc/my.cnf)。
### 8).InnoDB引擎需要更大物理内存支持，当前系统物理内存不足时将导致程序不能成功执行。
######################################

mysql_version=mysql-5.7.27-linux-glibc2.12-x86_64

print() {
	echo -e "\033[32;49;1m [ "$1" ] \033[39;49;0m"
}

checkEnv() {
	if [ `whoami` != "root" ]; then
		print "部署请将用户切换到root用户。安装终止！"
		exit 1
	fi
	
	if [ `uname -s` != "Linux" ]; then
   		print "操作系统错误。请在linux系统上执行本脚本。安装终止！"
   		exit 1
   	fi

   	if [ -d /data/mysql ]; then
   		print "/data/mysql目录已经存在。"
   		read -p "是否继续安装y/n？" input
		case $input in
		    y|Y|yes|YES)
		    	rm -rf /data/mysql
				rm -rf /opt/mysql
		    	;;
		    n|N|no|NO)
		    	;;
			*) 
				print "安装终止！"
				exit 1
				;;
		esac
	fi

	os_version=`cat /etc/system-release | sed -r 's/.* ([0-9]+)\..*/\1/'`
	if [ ${os_version} != "7" ] && [ ${os_version} != "6" ]; then
		print "CentOS版本错误。请在CentOS6或CentOS7版本环境下执行本脚本。安装终止！"
		exit 1
	fi

	pid=`netstat -lnp | grep 3306 | awk '{print $7}' | awk -F '/' '{print $1}'`
	if [  -n "$pid" ]; then
		print "数据库端口3306已被占用。安装终止！"   
		echo "占用进程:" $pid
		exit 1
	fi 
}

downloadFun() {
	if [ -s $mysql_version.tar.gz ]; then
		read -p "已经下载过文件，是否直接安装y/n？" input
		case $input in
		    y|Y|yes|YES)
		    	print "使用已经下载好的文件继续安装。"
				sleep 3
		    	return 0
		    	;;
		    n|N|no|NO)
		    	;;
			*) 
				ptint "安装包将被重新下载。"
				sleep 3
				rm -rf $mysql_version.tar.gz
				exit 1
				;;
		esac
	fi
	print "开始下载.."
	wget --no-check-certificate https://cdn.mysql.com//Downloads/MySQL-5.7/$mysql_version.tar.gz
	stauts=$?
	echo "是否下载成功："`[ $stauts -eq 0 ] && echo "是" || echo "否" `
	if [ $stauts -eq 0 ]; then 
	 	print "下载成功，准备安装。"
	 	return 0
	else
	 	print "下载失败，结束安装！"
	 	exit 1
	fi
}

installFun() {
	## 关闭selinux服务
	if [ -s /etc/selinux/config ]; then
		sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	fi	
	setenforce 0

	## 建立mysql用户及用户组
	egrep "^mysql" /etc/group >& /dev/null
	if [ $? -ne 0 ]; then 
		groupadd mysql
	fi
	egrep "^mysql" /etc/passwd >& /dev/null
	if [ $? -ne 0 ]; then
		useradd -r -g mysql -s /sbin/nologin -d /home/mysql mysql
	fi

	## 备份旧的安装目录
	if [ -d /opt/mysql ]; then
		mv /opt/mysql /opt/mysql_`date +%Y%m%d%H%M%S`
	fi
	if [ -d /data/mysql ]; then 
		mv /data/mysql /data/mysql_`date +%Y%m%d%H%M%S`
	fi
	if [ -s /etc/my.cnf ]; then
		mv /etc/my.cnf /etc/my`date +%Y%m%d%H%M%S`.cnf
	fi
	mkdir -p /data/mysql

	## 下载
	mkdir -p /opt
	cd /opt
	downloadFun

	##  解压、重命名文件
	tar -zxvf $mysql_version.tar.gz		
	mv $mysql_version mysql

	## 授权	
	chown -R mysql:mysql /opt/mysql	
	chown -R mysql:mysql /data/mysql
							
	#编辑my.cnf (生产工具：http://imysql.com/my-cnf-wizard.html)
cat > /etc/my.cnf <<EOF	
[client]
port	= 3306
socket	= /data/mysql/mysql.sock

[mysql]
prompt="\u@mysqldb \R:\m:\s [\d]> "
no-auto-rehash

[mysqld]
user	= mysql
port	= 3306
basedir	= /opt/mysql
datadir	= /data/mysql
socket	= /data/mysql/mysql.sock
pid-file = mysqldb.pid
character-set-server = utf8mb4
skip_name_resolve = 1

#若你的MySQL数据库主要运行在境外，请务必根据实际情况调整本参数
default_time_zone = "+8:00"

open_files_limit    = 65535
back_log = 1024
max_connections = 512
max_connect_errors = 1000000
table_open_cache = 1024
table_definition_cache = 1024
table_open_cache_instances = 64
thread_stack = 512K
external-locking = FALSE
max_allowed_packet = 32M
sort_buffer_size = 4M
join_buffer_size = 4M
thread_cache_size = 768
interactive_timeout = 600
wait_timeout = 600
tmp_table_size = 32M
max_heap_table_size = 32M
slow_query_log = 1
log_timestamps = SYSTEM
slow_query_log_file = /data/mysql/slow.log
log-error = /data/mysql/error.log
long_query_time = 0.1
log_queries_not_using_indexes =1
log_throttle_queries_not_using_indexes = 60
min_examined_row_limit = 100
log_slow_admin_statements = 1
log_slow_slave_statements = 1
server-id = 3306
log-bin = /data/mysql/mybinlog
sync_binlog = 1
binlog_cache_size = 4M
max_binlog_cache_size = 2G
max_binlog_size = 1G

#注意：MySQL 8.0开始，binlog_expire_logs_seconds选项也存在的话，会忽略expire_logs_days选项
expire_logs_days = 7

master_info_repository = TABLE
relay_log_info_repository = TABLE
gtid_mode = on
enforce_gtid_consistency = 1
log_slave_updates
slave-rows-search-algorithms = 'INDEX_SCAN,HASH_SCAN'
binlog_format = row
binlog_checksum = 1
relay_log_recovery = 1
relay-log-purge = 1
key_buffer_size = 32M
read_buffer_size = 8M
read_rnd_buffer_size = 4M
bulk_insert_buffer_size = 64M
myisam_sort_buffer_size = 128M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1
lock_wait_timeout = 3600
explicit_defaults_for_timestamp = 1
innodb_thread_concurrency = 0
innodb_sync_spin_loops = 100
innodb_spin_wait_delay = 30

transaction_isolation = REPEATABLE-READ
#innodb_additional_mem_pool_size = 16M
innodb_buffer_pool_size = 8M 	## 45875M
innodb_buffer_pool_instances = 4
innodb_buffer_pool_load_at_startup = 1
innodb_buffer_pool_dump_at_shutdown = 1
innodb_data_file_path = ibdata1:1G:autoextend
innodb_flush_log_at_trx_commit = 1
innodb_log_buffer_size = 32M
innodb_log_file_size = 2G
innodb_log_files_in_group = 2
innodb_max_undo_log_size = 4G
innodb_undo_directory = /data/mysql/undolog
innodb_undo_tablespaces = 95

# 根据您的服务器IOPS能力适当调整
# 一般配普通SSD盘的话，可以调整到 10000 - 20000
# 配置高端PCIe SSD卡的话，则可以调整的更高，比如 50000 - 80000
innodb_io_capacity = 4000
innodb_io_capacity_max = 8000
innodb_flush_sync = 0
innodb_flush_neighbors = 0
innodb_write_io_threads = 8
innodb_read_io_threads = 8
innodb_purge_threads = 4
innodb_page_cleaners = 4
innodb_open_files = 65535
innodb_max_dirty_pages_pct = 50
innodb_flush_method = O_DIRECT
innodb_lru_scan_depth = 4000
innodb_checksum_algorithm = crc32
innodb_lock_wait_timeout = 10
innodb_rollback_on_timeout = 1
innodb_print_all_deadlocks = 1
innodb_file_per_table = 1
innodb_online_alter_log_max_size = 4G
innodb_stats_on_metadata = 0

#注意：MySQL 8.0.16开始删除该选项
internal_tmp_disk_storage_engine = InnoDB

# some var for MySQL 5.7
innodb_checksums = 1
#innodb_file_format = Barracuda
#innodb_file_format_max = Barracuda
query_cache_size = 0
query_cache_type = 0
innodb_undo_logs = 128

innodb_status_file = 1
#注意: 开启 innodb_status_output & innodb_status_output_locks 后, 可能会导致log-error文件增长较快
innodb_status_output = 0
innodb_status_output_locks = 0

#performance_schema
performance_schema = 1
performance_schema_instrument = '%memory%=on'
performance_schema_instrument = '%lock%=on'

#innodb monitor
innodb_monitor_enable="module_innodb"
innodb_monitor_enable="module_server"
innodb_monitor_enable="module_dml"
innodb_monitor_enable="module_ddl"
innodb_monitor_enable="module_trx"
innodb_monitor_enable="module_os"
innodb_monitor_enable="module_purge"
innodb_monitor_enable="module_log"
innodb_monitor_enable="module_lock"
innodb_monitor_enable="module_buffer"
innodb_monitor_enable="module_index"
innodb_monitor_enable="module_ibuf_system"
innodb_monitor_enable="module_buffer_page"
innodb_monitor_enable="module_adaptive_hash"

[mysqldump]
quick
max_allowed_packet = 32M
EOF
 
cat >> /etc/ld.so.conf.d/mysql-x86_64.conf <<EOF
/opt/mysql/lib
EOF
	 
cat >> /etc/profile <<EOF
export PATH=$PATH:/opt/mysql/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/mysql/lib
EOF

cat > /tmp/mysql_sec_script <<EOF
use mysql;
delete from mysql.user where user!='root' or host!='localhost';
grant all privileges on *.* to 'root'@'%' identified by '$newmysqlpwd';
flush privileges;
EOF

	# 初始化
	/opt/mysql/bin/mysqld --defaults-file=/etc/my.cnf --user=mysql --basedir=/opt/mysql --datadir=/data/mysql --pid-file=/data/mysql/mysql.pid --initialize-insecure --explicit_defaults_for_timestamp
	# source /etc/profile

	## 加入开机自启动项
	cp /opt/mysql/support-files/mysql.server /etc/init.d/mysqld
	chmod +x /etc/init.d/mysqld
	touch /data/mysql/mysqldb.pid
	chmod -R 755 /data/mysql/mysqldb.pid
	chkconfig --add mysqld
	chkconfig --level 2345 mysqld on

	## 设置软链接
	ln -sf /opt/mysql/bin/mysql /usr/local/bin/mysql
	ln -sf /opt/mysql/bin/mysqladmin /usr/local/bin/mysqladmin

	## 启动mysql服务
	print "尝试启动服务"
	service mysqld start 
	if [[ `ps aux | grep mysqld | grep -v grep` ]]; then  
		echo "恭喜，MySQL服务启动成功！"
		## 修改密码
		mysql -u root -p$newmysqlpwd -h localhost < /tmp/mysql_sec_script
		rm -f /tmp/mysql_sec_script
	else
		echo "抱歉，MySQL服务启动失败！"
	fi

	print "MySQL【$mysql_version】安装完成！"
}

askInstall() {
	newmysqlpwd=""
	read -p "输入密码(默认密码：Test,123):" newmysqlpwd
	if [ "$newmysqlpwd" = "" ]; then
		newmysqlpwd="Test,123"
	fi

	read -p "将MySQL密码设置为:【$newmysqlpwd】，确定安装y/n？" input
	case $input in
	    y|Y|yes|YES)
	    	print "即将开始安装。";;
	    n|N|no|NO)
	    	;;
		*) 
			print "安装终止！"
			exit 1;;
	esac
}

main(){
	print "----------安装MySQL----------"
	
	askInstall
	checkEnv
	installFun
}

main $1
exit 0