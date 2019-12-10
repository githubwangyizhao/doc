#!/bin/bash

base_dir=/opt
install_dir=$base_dir/ssdb 					## 安装目录
sbin_dir=$install_dir/sbin		
data_dir=/data/ssdb 						## 数据及pid文件存放目录
backup_dir=$install_dir/backup 	 			## 数据备份目录

print() {
	echo -e "\033[32;49;1m [ $1 ] \033[39;49;0m"
}

installIfNotExist() {
	mkdir -p $base_dir						## 确保基础目录存在
	cd $base_dir

	# 尝试进入ssdb目录，如果路径切换成功，直接认定ssdb已经安装，不再走安装流程
	cd ssdb
	if [ $? -eq 0 ]; then 
		echo "$base_dir/ssdb目录已存在！"
		return 12
	fi

	yum -y install autoconf					## 依赖工具安装
	yum -y install gcc+ gcc-c++

	### 不走网络下载，网络包可能会有问题
	# print "准备下载。"	
	# wget --no-check-certificate https://github.com/ideawu/ssdb/archive/master.zip

	## 手动通过工具传包到服务器$base_dir/bak/目录下
	if [ -f "$base_dir/bak/ssdb-master.zip" ];then
		yum -y install unzip zip 						## 确保已经安装zip解压工具
		unzip -n -d ./ $base_dir/bak/ssdb-master.zip	## 解压不覆盖
		mv ssdb-master ssdb 							## 重命名
		print "安装编译：" 
		cd ssdb
		make && make install
		if [ $? -eq 0 ]; then 
			return 12
		else 
			echo "安装编译失败！"
			return 13
		fi
	else
		echo "$base_dir/bak/ssdb-master.zip文件不存在！"
		return 13
	fi
}

InstallAndRegConfig() {
	# 下载并安装文件
	installIfNotExist

	if [ $? -eq 12 ]; then
		print "设置SSDB端口："
		read ssdb_port

		print "设置SSDB密码："
		read ssdb_passwd
		
		# 创建目录
		mkdir -p $sbin_dir
		mkdir -p $backup_dir
		mkdir -p ${data_dir}/${ssdb_port}

		## 设置软连接
		cd $sbin_dir
		ln -sf /usr/local/ssdb/ssdb-server ssdb-server
		ln -sf /usr/local/ssdb/ssdb-cli ssdb-cli
		ln -sf /usr/local/ssdb/ssdb-dump ssdb-dump
		ln -sf /usr/local/ssdb/ssdb-repair ssdb-repair

		## 拷贝文件
		cp -f $install_dir/ssdb.conf $sbin_dir

		# 以"ssdb_端口号.conf"形式重命名配置文件
		conf_name=ssdb_$ssdb_port.conf
		mv $sbin_dir/ssdb.conf $sbin_dir/$conf_name

		# 修改配置文件
		conf_file=${sbin_dir}/${conf_name}
		sed -i "s|work_dir = ./var|work_dir = ${data_dir}/${ssdb_port}|g" $conf_file 							
		sed -i "s|pidfile = ./var/ssdb.pid|pidfile = ${data_dir}/${ssdb_port}/ssdb.pid|g" $conf_file	 		
		sed -i "s|ip: 127.0.0.1|ip: 0.0.0.0|g" $conf_file 							
		sed -i "s|port: 8888|port: ${ssdb_port}|g" $conf_file 						
		sed -i "s|#auth: very-strong-password|auth: ${ssdb_passwd}|g" $conf_file 	
		sed -i "s|output: log.txt|output: log_${ssdb_port}.txt|g" $conf_file 			
		sed -i "s|cache_size: 500|cache_size: 2000|g" $conf_file
		sed -i "s|level: debug|level: error|g" $conf_file
		
		# 注册命令
		start_server=/bin/start_ssdb_${ssdb_port}
		stop_server=/bin/stop_ssdb_${ssdb_port}
		restart_server=/bin/restart_ssdb_${ssdb_port}
		savedb=/bin/savedb_ssdb_${ssdb_port}
		# 启动命令
		echo "cd $sbin_dir" > $start_server
		echo "./ssdb-server -d ${conf_name}" >> $start_server
		chmod 777 $start_server
		# 停止命令
		echo "cd $sbin_dir" > $stop_server
		echo "./ssdb-server ${conf_name} -s stop" >> $stop_server
		chmod 777 $stop_server
		# 重启命令
		echo "cd $sbin_dir" > $restart_server
		echo "./ssdb-server -d ${conf_name} -s restart" >> $restart_server
		chmod 777 $restart_server
		# 备份数据命令
		echo "cd $sbin_dir" > $savedb
		echo "rm -rf ${backup_dir}/${ssdb_port}" >> $savedb
		echo "mkdir -p ${backup_dir}" >> $savedb
		echo "./ssdb-dump -h 127.0.0.1 -p ${ssdb_port} -a ${ssdb_passwd} -o ${backup_dir}/${ssdb_port}" >> $savedb
		chmod 777 $savedb

		echo "安装完成！！！"
		echo "-----------------------------"
		echo "安装目录:" $install_dir
		echo "启动服务命令：" start_ssdb_$ssdb_port
		echo "停止服务命令：" stop_ssdb_$ssdb_port
		echo "重启服务命令：" restart_ssdb_$ssdb_port
		echo "备份数据命令：" savedb_ssdb_$ssdb_port
		echo "-----------------------------"
	else
		echo "安装失败"
	fi
}

main(){
	print "----------安装SSDB----------"

	# 判断当前用户是否为root用户，不是则终止部署
	if [ `whoami` != "root" ]; then
		print "部署请将用户切换到root用户，安装终止\n\n"
		exit 1
	fi

	InstallAndRegConfig
}

main $1
exit 0
