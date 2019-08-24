#!/bin/bash

install_name=redis-4.0.10 					## 默认安装版本
install_dir=/opt/redis 						## 安装目录
sbin_dir=$install_dir/sbin					## redis-server、redis-benchmark、redis-cli等命令存放目录
conf_dir=$install_dir/conf 				 	## redis-server启动配置文件放置目录
data_dir=$install_dir/data    	 			## RDB持久化数据存放目录
backup_dir=$install_dir/backup 	 			## 数据备份目录

txt_begin="\033[32;49;1m [ "
txt_end=" ] \033[39;49;0m"

print(){
	echo -e $txt_begin$1$txt_end
}

evn_func() {
	print "***检测本机Redis环境***"
	# 判断redis是否启动，如果启动，则终止安装
	re=`ps aux | grep redis | awk '{print $11}' | grep redis`
	if [ ! -z $re ]; then
		echo $re
		echo "正在运行redis服务！！"
		return 11
	else
		return 10
	fi
}

install_func() {
	# 尝试进入redis安装目录，如果路径切换成功，直接认定redis已经安装，不再重新走下载安装流程
	cd $install_dir
	stauts=$?
	echo "是否已经安装redis：" `[ $stauts -eq 0 ] && echo "yes" || echo "no" `
	if [ $stauts -eq 0 ]; then 
		return 12
	fi

	echo "建立Redis安装目录"
	mkdir -p $install_dir

	cd $install_dir
	print "正在下载，请稍等。。。"
	wget http://download.redis.io/releases/$install_name.tar.gz
	stauts=$?
	echo "是否下载成功：" `[ $stauts -eq 0 ] && echo "yes" || echo "no" `
	if [ $stauts -eq 0 ]; then 
	 	print "正在解压，请稍等。。。"
		sleep 3 	
		tar -zxvf $install_name.tar.gz
		rm -rf $install_dir/$install_name.tar.gz
		print "正在编译及安装。。。" 
		cd $install_name
		make
		make install
		make test
	 	echo -e "安装目录：" `pwd` "\n\n"
	 	return 12
	else
	 	print "下载失败，检查安装文件名是否正确？"
	 	echo "文件名："$install_name
	 	return 13
	fi
}

excute_install(){
	# redis环境检测
	# evn_func
	# if [ $? -ne 10 ]; then
	# 	print "安装终止"
	# 	exit 1
	# fi

	# 下载并安装文件
	print "开始安装"
	install_func

	if [ $? -eq 12 ]; then
		print "请继续完成剩余的安装步骤。。。"
		print "输入redis的端口："
		read redis_port

		print "输入redis的密码："
		read redis_pass
		
		# 创建目录
		mkdir -p $sbin_dir
		mkdir -p $conf_dir
		mkdir -p $data_dir
		mkdir -p $backup_dir

		# 拷贝文件
		cp -f $install_dir/$install_name/src/redis-server $sbin_dir
		cp -f $install_dir/$install_name/src/redis-benchmark $sbin_dir
		cp -f $install_dir/$install_name/src/redis-cli $sbin_dir
		cp -f $install_dir/$install_name/redis.conf $conf_dir

		# 以"redis_端口号.conf"形式重命名配置文件
		conf_name=redis_$redis_port.conf
		mv $conf_dir/redis.conf $conf_dir/$conf_name

		# 修改配置文件
		conf_file=${conf_dir}/${conf_name}
		dbfilename=dump_${redis_port}.rdb 					
		pidfile=/var/run/redis_${redis_port}.pid 
		prefix='\n#++#\n'
		sed -i "s|daemonize no|${prefix}daemonize yes|g" $conf_file 								# 开启守护进程模式
		sed -i "s|pidfile /var/run/redis_6379.pid|${prefix}pidfile ${pidfile}|g" $conf_file	 		# 修改pid文件
		sed -i "s|bind 127.0.0.1|${prefix}#bind 127.0.0.1|g" $conf_file 							# 注释绑定默认ip
		sed -i "s|port 6379|${prefix}port ${redis_port}|g" $conf_file 								# 设置端口号
		sed -i "s|dir ./|${prefix}dir ${data_dir}|g" $conf_file 									# 修改RDB持久化数据库存放目录
		sed -i "s|dbfilename dump.rdb|${prefix}dbfilename ${dbfilename}|g" $conf_file 				# 修改RDB持久化数据库的文件名
		sed -i "s|# requirepass foobared|${prefix}requirepass ${redis_pass}|g" $conf_file 			# 设置密码
		
		# 注册命令
		start_file=/bin/start_redis_${redis_port}
		stop_file=/bin/stop_redis_${redis_port}
		savedb_file=/bin/savedb_redis_${redis_port}
		touch start_file
		touch stop_file
		touch savedb_file
		# 启动命令
		echo "$sbin_dir/redis-server ${conf_file}" > $start_file
		chmod 777 $start_file
		# 停止命令
		echo "$sbin_dir/redis-cli -h 127.0.0.1 -p ${redis_port} -a ${redis_pass} shutdown" > $stop_file
		chmod 777 $stop_file
		# 备份数据命令
		echo "$a ${sbin_dir}/redis-cli -h 127.0.0.1 -p ${redis_port} -a ${redis_pass} save" > $savedb_file
		echo "$a cp -f ${data_dir}/${dbfilename} ${backup_dir}/${dbfilename}" >> $savedb_file
		chmod 777 $savedb_file

		print "安装完成！！！"
		echo "-----------------------------"
		echo "安装目录:" $install_dir
		echo "快速启动命令：" start_redis_$redis_port
		echo "快速停止命令：" stop_redis_$redis_port
		echo "备份数据命令：" savedb_redis_$redis_port
		echo "-----------------------------"
	else
		print "安装失败"
	fi
}

main(){
	print "----------安装Redis----------"

	# 判断当前用户是否为root用户，不是则终止部署
	if [ `whoami` != "root" ]; then
		print "部署请将用户切换到root用户，安装终止\n\n"
		exit 1
	fi

	if [ $# -gt 0 ]; then
		install_name=$1
	fi

	excute_install
}

main $1
exit 0