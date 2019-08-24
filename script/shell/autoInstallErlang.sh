#!/bin/bash

install_name=otp_src_20.3 			# 默认安装版本
install_path=/opt/erl 				# 安装目录
txt_begin="\033[32;49;1m [ "
txt_end=" ] \033[39;49;0m"

print(){
	echo -e $txt_begin$1$txt_end
}

evn_func(){
	path=`whereis erl | awk '{print $2}'`
	if [ ! -z $path ]; then
		echo "检测到环境中已经存在erlang！"
		return 1
	else
		return 0
	fi
}

install_func(){
	print "安装依赖库"
	yum -y install gcc-c++
	yum -y install ncurses-devel	
	yum -y install openssl-devel
	yum -y install unixODBC-devel
	
	rm -rf $install_path
	mkdir -p $install_path
	cd $install_path
	print "准备下载"
	wget "http://www.erlang.org/download/$install_name.tar.gz"
	stauts=$?
	echo "是否下载成功：" `[ $stauts -eq 0 ] && echo "yes" || echo "no" `
	if [ $stauts -eq 0 ]; then 
	 	print "解压文件"
	 	sleep 3s 
		tar -zxvf $install_name.tar.gz
		rm -rf $install_path/$install_name.tar.gz
		
		print "开始编译及安装" 
		cd $install_name
		./configure --prefix=/home/erlang --without-javac
		make
		make install
	 	return 2
	else
	 	echo "下载安装错误，文件名："$install_name
	 	return 3
	fi
}

main(){
	print "----------安装Erlang----------"
	
	# 判断当前用户是否为root用户，不是则终止部署
	if [ `whoami` != "root" ]; then
		print "部署请将用户切换到root用户，安装终止"
		exit 1
	fi

	if [ $# -gt 0 ]; then
		install_name=$1
	fi

	evn_func
	if [ $? -ne 0 ]; then
		echo "是否覆盖安装？[y/n]："
		read input
		case $input in
		    y|Y)
		    	install_func;;
		    [nN]*)
		        print "安装终止"
				exit 1;;
		esac
	else
		# 直接安装
		install_func
	fi

	if [ $? -eq 2 ]; then
		print "安装成功！"
		echo "可执行文件目录： $install_path/$install_name/bin" 
	else
		print "安装失败！"
	fi
}

main $1
exit 0
