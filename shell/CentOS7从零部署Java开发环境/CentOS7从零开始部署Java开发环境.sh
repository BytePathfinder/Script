#!/bin/bash
# linux从零开始部署开发环境
echo "-------------------------------自动部署--------------------------------"
echo "|                                                                     |"
echo "|                                                                     |"
echo "|                     CentOS7从零开始部署开发环境                      |"
echo "|                                                                     |"
echo "|                                                                     |"
echo "----------------------------------------------------------------------"

echo "-------------------------------更新网卡--------------------------------"
#更新UUID
uuid=`uuidgen ens33`

#更新文件/etc/sysconfig/network-scripts/ifcfg-ens33
echo "TYPE=Ethernet">/etc/sysconfig/network-scripts/ifcfg-ens33
echo "PROXY_METHOD=none">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "BROWSER_ONLY=no">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "BOOTPROTO=static">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "DEFROUTE=yes">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "IPV4_FAILURE_FATAL=no">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "IPV6INIT=yes">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "IPV6_AUTOCONF=yes">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "IPV6_DEFROUTE=yes">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "IPV6_FAILURE_FATAL=no">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "IPV6_ADDR_GEN_MODE=stable-privacy">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "NAME=ens33">>/etc/sysconfig/network-scripts/ifcfg-ens33
#写入uuid
echo "UUID=$uuid">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "DEVICE=ens33">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "ONBOOT=yes">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "IPADDR=192.168.100.101">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "GATEWAY=192.168.100.2">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "NETMASK=255.255.255.0">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "DNS1=8.8.8.8">>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "DNS2=114.114.114.114">>/etc/sysconfig/network-scripts/ifcfg-ens33

echo "-------------------------------更新软件--------------------------------"
yum -y update

echo "-------------------------------获取软件--------------------------------"
# scp -r root@192.168.100.100:/root/package/ /root/package/
scp root@192.168.100.100:/root/mjtx.tar.gz /root/
cd /root
tar -zxvf mjtx.tar.gz
cd /root/package

echo "-------------------------------校准时间--------------------------------"
#安装ntpdate
yum -y install ntpdate
#使用ntpdate校准时间
ntpdate cn.pool.ntp.org

#Xshell快速打开接受/发送文件界面
echo "-------------------------------安装lrzsz--------------------------------"
yum -y install lrzsz

#安装vim
echo "-------------------------------安装vim--------------------------------"
yum -y install vim

#安装net-tools
echo "-------------------------------安装net-tools--------------------------------"
yum -y install net-tools

#安装lsof
echo "-------------------------------安装lsof--------------------------------"
yum -y install lsof

function install_java(){
    echo "-------------------------------安装Java--------------------------------"
    cd /root/package
    # 判断java有没有安装
    java -version
    #数字比较用 -eq,字符串用==
    if [ "$?" -eq "0" ];then
        echo "java已经安装，正在退出..."
        return 1
        echo "还没退出吗？"
    else
        echo "准备安装java..."    
    fi
    #jdk包名
    soft_name=jdk-8u301-linux-x64.tar.gz
    #目标文件夹
    target_dir=/usr/local/java
    mkdir ${target_dir}
    #解压到预定目录
    tar -zxvf ${soft_name} -C ${target_dir}/
    #解压后jdk所在目录名
    sub_dir=`ls ${target_dir}`
    #配置Java的环境变量
    echo "#jdk8">>/etc/profile
    echo "export JAVA_HOME=${target_dir}/${sub_dir}" >> /etc/profile
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile
    echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >>/etc/profile
    source /etc/profile
    echo "java配置完成"
}
#调用，执行java安装函数
install_java

install_tomcat(){
    echo "-------------------------------安装Tomcat--------------------------------"
    cd /root/package
    if [ -e /usr/local/tomcat ];then
        read -p "tomcat已存在是否替换yes/no: " answer
        #数字比较用 -ne,字符串用!=
        if [ "$answer" != "yes" ];then
            echo "您已选择不替换，安装程序退出中..."
            return 1
        fi
        rm -rf /usr/local/tomcat
    fi
    soft_name=apache-tomcat-9.0.52.tar.gz
    target_dir=/usr/local/tomcat
    mkdir $target_dir
    tar -zxvf /root/$soft_name -C /usr/local/tomcat/
    sub_dir=`ls $target_dir`
    cd $target_dir/$sub_dir/bin
    ./startup.sh
    firewall-cmd --zone=public --add-port=8080/tcp --permanent
    systemctl restart firewalld
    cd /root/package
}
#调用，执行tomcat安装函数
install_tomcat

install_nginx(){
    echo "-------------------------------安装Nginx--------------------------------"
    cd /root/package
    if [ -e /usr/local/nginx ];then
        read -p "nginx已存在是否替换yes/no: " answer
        #数字比较用 -ne,字符串用!=
        if [ "$answer" != "yes" ];then
            echo "您已选择不替换，安装程序退出中..."
            return 1
        fi
        rm -rf /usr/local/nginx
    fi
    #安装nginx的依赖:
    yum -y install gcc
    yum -y install pcre pcre-devel
    yum -y install zlib zlib-devel
    yum -y install openssl openssl-devel
    #获取安装包
    soft_name=nginx-1.21.3.tar.gz
    target_dir=/usr/local/nginx
    mkdir $target_dir
    tar -zxvf /root/$soft_name -C $target_dir/
    sub_dir=$target_dir/`ls $target_dir`
    cd $sub_dir/
    #构建nginx
    ./configure
    make
    make install
    rm -rf $sub_dir/
    cd $target_dir/sbin/
    ./nginx
    firewall-cmd --zone=public --add-port=80/tcp --permanent
    systemctl restart firewalld
    cd /root/package
}
#调用函数
install_nginx

#安装MySQL
install_mysql(){
    echo "-------------------------------安装MySQL--------------------------------"
    cd /root/package
    #移除mariadb
    mariadb_version=`rpm -qa|grep mariadb`
    if [ "$?" -eq "0" ];then
        rpm -e $mariadb_version --nodeps
    fi
    mysql_version=8.0.26-1.el7.x86_64
    #解压安装包
    tar -xvf /root/mysql-$mysql_version.rpm-bundle.tar
    #rpm方式安装
    # mysql客户端工具目录：/usr/bin(mysqladmin mysqldump等命令)
    # 配置文件：/etc/my.cnf
    # 日志目录：/var/log/mysqld.log
    # 数据库目录：/var/lib/mysql/
    # 配置文件模板：/usr/share/mysql8.0(mysql.server命令及配置文件)
    # 启动脚本：/etc/rc.d/init.d/(启动脚本文件mysql的目录)
    # sock文件目录：/var/lib/mysql/mysql.sock
    rpm -ivh mysql-community-common-$mysql_version.rpm --nodeps --force
    rpm -ivh mysql-community-libs-$mysql_version.rpm --nodeps --force
    rpm -ivh mysql-community-client-$mysql_version.rpm --nodeps --force
    rpm -ivh mysql-community-server-$mysql_version.rpm --nodeps --force
    #初始化
    mysqld --initialize;
    chown mysql:mysql /var/lib/mysql -R
    systemctl restart mysqld.service
    systemctl enable mysqld
    #对外开放端口
    firewall-cmd --zone=public --add-port=3306/tcp --permanent
    systemctl restart firewalld
    #设置密码
    temppasswd=`grep "temporary password" /var/log/mysqld.log|awk -F' ' "{print $NF}"|awk '{print $NF}'`
    /usr/bin/mysqladmin -uroot -p${temppasswd} password "mysql123456"
    # 开启远程访问
    # use mysql
    # select host,user from user;
    # update user set host='%' where user='root';
    # flush privileges;
}
#调用函数
install_mysql

#安装redis
install_redis(){
    echo "-------------------------------安装redis--------------------------------"
    cd /root/package
    #gcc版本过低编译redis6.0时会报如下错误
    # 升级到gcc 9.3：
    yum -y install centos-release-scl
    yum -y install devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils
    scl enable devtoolset-9 bash
    yum -y install tcl

    # 需要注意的是scl命令启用只是临时的，退出shell或重启就会恢复原系统gcc版本。
    # 如果要长期使用gcc 9.3的话：
    # echo -e "\nsource /opt/rh/devtoolset-9/enable" >>/etc/profile
    soft_name=redis-6.2.5.tar.gz
    target_dir=/usr/local/redis
    mkdir $target_dir
    tar -zxvf $soft_name -C $target_dir/
    cd $target_dir/`ls $target_dir`
    make MALLOC=libc
    make PREFIX=$target_dir install
    #复制配置文件
    cp redis.conf /etc/redis.conf
    #对外开放端口
    firewall-cmd --zone=public --add-port=6379/tcp --permanent
    systemctl restart firewalld  
    # 启动
    # /usr/local/redis/bin/redis-server /etc/redis.conf
    cd /root/package
    
}
#调用函数
install_redis

#合并为1个集群
#/usr/local/redis/redis-6.2.5/src/redis-cli --cluster create --cluster-replicas 1  192.168.100.101:6379 192.168.100.101:6380 192.168.100.101:6381 192.168.100.101:6389 192.168.100.101:6390 192.168.100.101:6391 

#安装模拟并发访问的工具
yum -y install httpd-tools

#安装ActiveMQ
install_activemq(){
    echo "-------------------------------安装ActiveMQ--------------------------------"
    cd /root/package
    if [ -e /usr/local/tomcat ];then
        read -p "activemq已存在是否替换yes/no: " answer
        #数字比较用 -ne,字符串用!=
        if [ "$answer" != "yes" ];then
            echo "您已选择不替换，安装程序退出中..."
            return 1
        fi
        rm -rf /usr/local/tomcat
    fi
    soft_name=apache-activemq-5.16.3-bin.tar.gz
    target_dir=/usr/local/activemq
    mkdir $target_dir
    tar -zxvf $soft_name -C $target_dir/
    cd $target_dir/`ls $target_dir`/bin/linux-x86-64/activemq start
    firewall-cmd --zone=public --add-port=61616/tcp --permanent
    firewall-cmd --zone=public --add-port=8161/tcp --permanent
    systemctl restart firewalld
    # 检查61616端口是否被占用，间接判断activemq是否启动成功
    # netstat -anp |grep 61616
    # ps -ef |grep activemq
    cd /root/package
}
#调用，执行安装函数
install_activemq