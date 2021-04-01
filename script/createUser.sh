#/bin/bash
# 创建新用户

addUser() {
	read -p "请输入用户名：" user

	if [ -z $user ]; then
		echo "没有用户名，创建失败！"
		exit 1
	fi

	read -p "请输入密码：" passwd

	# 默认密码 用户名123
	default_passwd=$user"123" 
	passwd=${passwd:-$default_passwd}
	if useradd $user; then 
		echo $passwd | passwd --stdin $user
		echo "创建成功！"
		echo "用户名：	"$user
		echo "用户密码："$passwd
	else
		echo "创建失败！"
	fi
}

main(){
	echo "---------创建用户----------"
	
	if [ $USER != "root" ];then
	 	echo "您不是管理员，没有权限创建用户！"
	 	exit 1
	else
		addUser
	fi
}

main
exit 0