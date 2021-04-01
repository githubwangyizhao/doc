[root@alimysql06 ~]# ./mysql_auto_install.sh
###########  A tool to auto-compile & install MySQL on Redhat/CentOS 6 or 7  Linux ################ 
################检查本机安装mysql的基本条件########################
Checking  user :
user is root, this is ok!
checking  os version
os  is linux,this is ok!
mysql datadir  /data/mysql is exist! ,this is fail!
[root@alimysql06 ~]# cat mysql_auto_install.sh
#!/bin/bash

#Part1:整个流程分3步
#1.mysql官网下载二进制版本的mysql5.7.21安装包(mysql-5.7.21-linux-glibc2.12-x86_64.tar.gz)和mysql_auto_install.sh脚本放至/root目录
#2.执行下文所述的mysql_auto_install.sh脚本
#3.输入您设置的密码登录数据库
###### 二进制自动安装数据库脚本root默认密码:MANAGER, 将脚本和安装包放在/root目录即可.###############
######数据库目录/usr/local/mysql############
######数据目录/data/mysql############
######慢日志目录/data/slowlog############
######端口号默认3306其余参数按需自行修改############
######author：anzhen at 2018/02/27

function check_install_mysql_environment()
{
echo "################检查本机安装mysql的基本条件########################"
echo "Checking  user :"
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install"
    exit 1
else
    echo "user is root, this is ok!"
fi

echo "checking  os version"
if [ `uname -s`="linux" ]; then
    echo "os  is linux,this is ok!"
else
    echo "os  isnot linux,this is fail!"
    exit 1
fi

if [ -d /data/mysql ]; then
   echo "mysql datadir  /data/mysql is exist! ,this is fail!"
   exit 1
else
   echo "mysql datadir  /data/mysql is not exist,this is ok!"
fi

os_version=`uname -r|cut -d . -f 4`
if [ ${os_version}="el7" ] || [${os_version}="el6" ]; then
   echo "os version is el6 or el7, this is ok!"
else
   echo "os version isnot el6 or el7, this is fail!"
   exit 1
fi
port=`netstat -ntl| awk '{ print $4}' |grep '3306'|awk  -F: '{ print $4}'`
if [[ ${port} = "3306" ]]; then
   echo "mysql port 3306 is exist, please uninstall existed mysql or modify script , this is fail!"   
   exit 1
else
    echo "msyql port is not 3306! this is ok!"
fi

}

#Install MySQL
function InstallMySQL()
{
echo -e "\n"
echo "#############################  MySQL  installing..........########################"

#Set timezone
#rm -rf /etc/localtime
#ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime   
#Delete Old Mysql program
#Disable SeLinux
if [ -s /etc/selinux/config ]; then
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
fi
setenforce 0

groupadd mysql -g 512
useradd -u 512 -g mysql -s /sbin/nologin -d /home/mysql mysql

#mysql directory configuration
if [ -d /root/mysql-5.7.21-linux-glibc2.12-x86_64 ]; then
  rm -rf /root/mysql-5.7.21-linux-glibc2.12-x86_64
fi

echo -e "uncompressioning mysql-5.7.21-linux-glibc2.12-x86_64.tar.gz  file..........\nplease  wait a few minutes..........."
tar  -zxvf /root/mysql-5.7.21-linux-glibc2.12-x86_64.tar.gz > /dev/null

if [ -d /usr/local/mysql ]; then
mv /usr/local/mysql /usr/local/mysql_`date +%Y%m%d%H%M%S`
fi
mv /root/mysql-5.7.21-linux-glibc2.12-x86_64 /usr/local/mysql
chown -R mysql:mysql /usr/local/mysql

if [ -d /data/mysql ]; then
mv /data/mysql /data/mysql_`date +%Y%m%d%H%M%S`
mkdir -p /data/mysql
chown -R mysql:mysql /data/mysql
echo "directory  /data/mysql created succeed!"
else
mkdir -p /data/mysql
chown -R mysql:mysql /data/mysql
echo "directory  /data/mysql created succeed!"
fi

if [ -d /data/slowlog ]; then
mv /data/slowlog /data/slowlog_`date +%Y%m%d%H%M%S`
mkdir -p /data/slowlog
chown -R mysql:mysql /data/slowlog
echo "directory  /data/slowlog created succeed!"
else
mkdir -p /data/slowlog
chown -R mysql:mysql /data/slowlog
echo "directory  /data/slowlog created succeed!"
fi

#edit /etc/my.cnf
SERVERID=1000
os_version=`uname -r|cut -d . -f 4`

if [ ${os_version}="el6" ]; then
SERVERID=`ifconfig eth0 | grep "inet addr" | awk '{ print $2}'| awk -F. '{ print $3$4}'`
elif [ ${os_version}="el7" ]; then
SERVERID=`ifconfig ens32 | grep "inet "| awk '{ print $2}'| awk -F. '{ print $3$4}'`
else
   SERVERID=1000
fi

#Backup old my.cnf    rm -f /etc/my.cnf
ipaddr=`ifconfig eth0 | grep "inet addr" | awk '{ print $2}'| awk -F. '{ print $3$4}'`
if [ -s /etc/my$ipaddr.cnf ]; then
    mv /etc/my$ipaddr.cnf /etc/my${ipaddr}.cnf.bak
    touch /etc/my$ipaddr.cnf
else
    touch /etc/my$ipaddr.cnf
fi


cat >>/etc/my$ipaddr.cnf<<EOF
[client]
port=3308
socket=/tmp/mysql.sock
default-character-set=utf8

[mysql]
no-auto-rehash
default-character-set=utf8
 
[mysqld]
port=3306
character-set-server=utf8
socket=/tmp/mysql.sock
basedir=/usr/local/mysql
datadir=/data/mysql
pid-file =/data/mysql/mysql.pid
explicit_defaults_for_timestamp=true
lower_case_table_names=1
back_log=103
max_connections=3000
max_connect_errors=100000
table_open_cache=512
external-locking=FALSE
max_allowed_packet=32M
sort_buffer_size=2M
join_buffer_size=2M
thread_cache_size=51
query_cache_size=32M
#query_cache_limit=4M
transaction_isolation=REPEATABLE-READ
tmp_table_size=96M
max_heap_table_size=96M
 
###***slowqueryparameters
long_query_time=1
slow_query_log = 1
slow_query_log_file=/data/slowlog/slow.log

###***binlogparameters
log-bin=mysql-bin
binlog_cache_size=4M
max_binlog_cache_size=4096M
max_binlog_size=1024M
binlog_format=row
expire_logs_days=7

###***relay-logparameters
#relay-log=/data/3307/relay-bin
#relay-log-info-file=/data/3307/relay-log.info
#master-info-repository=table
#relay-log-info-repository=table
#relay-log-recovery=1

#***MyISAMparameters
key_buffer_size=16M
read_buffer_size=1M
read_rnd_buffer_size=16M
bulk_insert_buffer_size=1M
#skip-name-resolve

###***master-slavereplicationparameters
server-id=$SERVERID
#slave-skip-errors=all
 
#***Innodbstorageengineparameters
innodb_buffer_pool_size=512M
innodb_data_file_path=ibdata1:10M:autoextend
#innodb_file_io_threads=8
innodb_thread_concurrency=16
innodb_flush_log_at_trx_commit=1
innodb_log_buffer_size=16M
innodb_log_file_size=512M
innodb_log_files_in_group=2
innodb_max_dirty_pages_pct=75
innodb_buffer_pool_dump_pct=50
innodb_lock_wait_timeout=50
innodb_file_per_table=on

[mysqldump]
quick
max_allowed_packet=32M

[myisamchk]
key_buffer=16M
sort_buffer_size=16M
read_buffer=8M
write_buffer=8M
 
[mysqld_safe]
open-files-limit=8192
log-error=/data/mysql/error.log
pid-file=/data/mysql/mysqld.pid
EOF

/usr/local/mysql/bin/mysqld --defaults-file=/etc/my$ipaddr.cnf --user=mysql --datadir=/data/mysql --basedir=/usr/local/mysql --initialize-insecure
cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
chmod 700 /etc/init.d/mysqld
chkconfig --add mysqld
chkconfig --level 2345 mysqld on
cat >> /etc/ld.so.conf.d/mysql-x86_64.conf<<EOF
/usr/local/mysql/lib
EOF


/etc/init.d/mysqld start
 
cat >> /etc/profile <<EOF
export PATH=$PATH:/usr/local/mysql/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/mysql/lib
EOF

/usr/local/mysql/bin/mysqladmin -u root password $mysqlrootpwd

cat > /tmp/mysql_sec_script<<EOF
use mysql;
delete from mysql.user where user!='root' or host!='localhost';
grant all privileges on *.* to 'sys_admin'@'%' identified by 'MANAGER';
flush privileges;
EOF

/usr/local/mysql/bin/mysql -u root -p$mysqlrootpwd -h localhost < /tmp/mysql_sec_script
rm -f /tmp/mysql_sec_script
/etc/init.d/mysqld restart

echo "============================MySQL 5.7.15 install completed========================="
echo -e "\n"
}


function CheckInstall_result()
{
echo "===================================== Check install ==================================="
ismysql=""
echo "Checking..."
if [ -s /usr/local/mysql/bin/mysql ] && [ -s /usr/local/mysql/bin/mysqld_safe ] && [ -s /etc/my$ipaddr.cnf ] && [ `netstat -ntl| awk '{ print $4}' |grep '3306'|awk  -F: '{ print $4}'`="3306" ] ; then
  echo "MySQL: OK"
  ismysql="ok"
  else
  echo "Error: /usr/local/mysql not found!!! MySQL install failed."
fi

if [ "$ismysql" = "ok" ]; then
netstat -ntl
ps -ef|grep mysql
echo "=================checked successed!checking result MySQL  completed! ================"
else
echo "Sorry,Failed to install MySQL!"
echo "You can tail /root/mysql-install.log from your server."
fi
}

function if_select_install()
{
echo -e "\n"
mysqlrootpwd="MANAGER"
echo -e "Please input the root password for mysql:"
read -p "(Default password: MANAGER):" mysqlrootpwd
if [ "$mysqlrootpwd" = "" ]; then
        mysqlrootpwd="MANAGER"
fi
echo "MySQL root password:$mysqlrootpwd"
echo -e "=========do you want to install mysql? ========"
isinstallmysql="n"
echo "Install MySQL,Please input y"
read -p "(Please input y or  n):" isinstallmysql
    case "$isinstallmysql" in
    [yY][eE][sS]|y|Y)
    echo "You will install MySQL........"
    isinstallmysql="y"
    ;;
    [nN][oO]|N|n )  
    echo "you will exit install MySQL........"  
    isinstallmysql="n"
    exit 1
    ;;  
    *)
    echo "INPUT error,You will exit install MySQL......."
    isinstallmysql="n"
    exit 1
    esac
}

#The installation flow path
echo "###########  A tool to auto-compile & install MySQL on Redhat/CentOS 6 or 7  Linux ################ "
cd /root
check_install_mysql_environment
if_select_install
InstallMySQL
CheckInstall_result
