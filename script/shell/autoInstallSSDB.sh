#!/bin/bash

base_dir=/opt
install_dir=$base_dir/ssdb 					## 安装目录
sbin_dir=$install_dir/sbin		
data_dir=/data/ssdb 						## 数据及pid文件存放目录
backup_dir=$install_dir/backup 	 			## 数据备份目录

txt_begin="\033[32;49;1m [ "
txt_end=" ] \033[39;49;0m"
print(){
	echo -e $txt_begin$1$txt_end
}

evn_func() {
	re=`ps aux | grep ssdb | awk '{print $11}' | grep ssdb`
	if [ ! -z $re ]; then
		echo $re
		echo "正在运行SSDB服务！"
		return 11
	else
		return 10
	fi
}

install_func() {
	# rm -rf $install_dir					## 切记：不删除旧安装目录
	mkdir -p $base_dir						## 确保基础目录存在		
	cd $base_dir

	# 尝试进入ssdb目录，如果路径切换成功，直接认定ssdb已经安装，不再重新走下载安装流程
	cd ssdb
	stauts=$?
	echo "是否已经安装ssdb：" `[ $stauts -eq 0 ] && echo "是" || echo "否" `
	if [ $stauts -eq 0 ]; then 
		return 12
	fi

	yum -y install autoconf					## 依赖工具安装
	yum -y install gcc+ gcc-c++

	print "准备下载。"
	wget --no-check-certificate https://github.com/ideawu/ssdb/archive/master.zip
	stauts=$?
	echo "是否下载成功：" `[ $stauts -eq 0 ] && echo "是" || echo "否" `
	if [ $stauts -eq 0 ]; then 
	 	print "下载成功，准备安装。"
		sleep 3 	
		yum install -y unzip zip 			## 确保已经安装zip解压工具
		unzip master.zip  					## 解压
		mv ssdb-master ssdb 				## 重命名
		rm -rf master.zip			   		## 删除文件
		print "开始编译及安装。" 
		cd ssdb
		make && make install
	 	return 12
	else
	 	print "下载失败。"
	 	return 13
	fi
}

excute_func(){
	# SSDB环境检测
	# evn_func
	# if [ $? -ne 10 ]; then
	# 	print "安装终止"
	# 	exit 1
	# fi

	# 下载并安装文件
	install_func

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

		print "安装完成！！！"
		echo "-----------------------------"
		echo "安装目录:" $install_dir
		echo "启动服务命令：" start_ssdb_$ssdb_port
		echo "停止服务命令：" stop_ssdb_$ssdb_port
		echo "重启服务命令：" restart_ssdb_$ssdb_port
		echo "备份数据命令：" savedb_ssdb_$ssdb_port
		echo "-----------------------------"
	else
		print "安装失败"
	fi
}

main(){
	print "----------安装SSDB----------"

	# 判断当前用户是否为root用户，不是则终止部署
	if [ `whoami` != "root" ]; then
		print "部署请将用户切换到root用户，安装终止\n\n"
		exit 1
	fi

	excute_func
}

main $1
exit 0