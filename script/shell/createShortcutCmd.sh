#!/bin/bash
# 创建快捷命令

base_path=/usr/local/sbin/

generate() {
	cd $base_path
	echo "快捷命令生成目录："$base_path

	cmdFile="killnode"
	rm -rf $cmdFile
	touch $cmdFile
	chmod 777 $cmdFile
	echo "" >$cmdFile
	sed -i '$a #!/bin/bash' $cmdFile
	sed -i '$a node=$1' $cmdFile
	sed -i '$a ps -ef | grep $USER | grep sname | grep $node | grep $ERLANG_COOKIE | grep -v grep | awk '\''{print $2}'\'' | xargs kill -9' $cmdFile
	sed -i '$a shownode' $cmdFile

	cmdFile="shownode"
	rm -rf $cmdFile
	touch $cmdFile
	chmod 777 $cmdFile
	echo "" >$cmdFile
	sed -i '$a #!/bin/bash' $cmdFile
	sed -i '$a echo "---------------------------" ' $cmdFile
	sed -i '$a ps -ef | grep $USER | grep $ERLANG_COOKIE | grep sname  | grep -v grep | awk '\''{print $21 " " $2}'\'' ' $cmdFile
	sed -i '$a echo	"---------------------------" ' $cmdFile

	cmdFile="attachnode"
	rm -rf $cmdFile
	touch $cmdFile
	chmod 777 $cmdFile
	echo "" >$cmdFile
	sed -i '$a #!/bin/bash' $cmdFile
	sed -i '$a node=$1' $cmdFile
	sed -i '$a erl -sname test_$USER -setcookie $ERLANG_COOKIE -remsh $node@$HOSTNAME' $cmdFile
}

main(){
	print "----------生成快捷命令-----------"

	if [ `whoami` != "root" ]; then
		echo "权限不够，请登录root账号执行脚本！"
		exit 1
	fi

	generate
	echo "----------------------------"
	echo "显示节点列表：shownode"
	echo "杀掉节点：	killnode [节点名称]"
	echo "登录节点：	attachnode [节点名称]"
	echo "----------------------------"
}

main
exit 0