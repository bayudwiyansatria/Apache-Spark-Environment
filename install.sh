#!/bin/bash
echo "";

echo "################################################";
echo "##  Welcom To Bayu Dwiyan Satria Installation ##";
echo "################################################";

echo "";

echo "Use of code or any part of it is strictly prohibited.";
echo "File protected by copyright law and provided under license.";
echo "To Use any part of this code you need to get a writen approval from the code owner: bayudwiyansatria@gmail.com.";

echo "";

# User Access
if [ $(id -u) -eq 0 ]; then

    echo "################################################";
    echo "##        Checking System Compability         ##";
    echo "################################################";

    echo "";
    echo "Please wait! Checking System Compability";
    echo "";

    # Operation System Information
    if type lsb_release >/dev/null 2>&1 ; then
        os=$(lsb_release -i -s);
    elif [ -e /etc/os-release ] ; then
        os=$(awk -F= '$1 == "ID" {print $2}' /etc/os-release);
    elif [ -e /etc/os-release ] ; then
        os=$(awk -F= '$1 == "ID" {print $3}' /etc/os-release);
    else
        exit 1;
    fi

    os=$(printf '%s\n' "$os" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');

    # Update OS Current Distribution
    read -p "Update Distro (y/n) [ENTER] (y)(Recommended): " update;
    update=$(printf '%s\n' "$update" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');

    if [ "$update" == "y" ] ; then 
        if [ "$os" == "ubuntu" ] || [ "$os" == "debian" ] ; then
            apt-get -y update && apt-get -y upgrade;
        elif [ "$os" == "centos" ] || [ "$os" == "rhel" ] || [ "$os" == "fedora" ] ; then
            yum -y update && yum -y upgrade;
        else
            exit 1;
        fi
    fi

    # Required Packages
    if [ "$os" == "ubuntu" ] || [ "$os" == "debian" ] ; then
        apt-get -y install git && apt-get -y install wget;
    elif [ "$os" == "centos" ] || [ "$os" == "rhel" ] || [ "$os" == "fedora" ]; then
        yum -y install git && yum -y install wget;
    else
        exit 1;
    fi

    echo "################################################";
    echo "##          Check Spark Environment           ##";
    echo "################################################";
    echo "";

    echo "We checking spark is running on your system";

    SPARK_HOME="/usr/local/spark";
    
    if [ -e "$SPARK_HOME/etc/conf" ]; then
        echo "";
        echo "Spark is already installed on your machines.";
        echo "";
        exit 1;
    else
        echo "Preparing install spark";
        echo "";
    fi

    if [ "$1" ] ; then
        version=$1;
        distribution="stable";
        packages="spark-$version";
    else
        read -p "Enter spark distribution version, (NULL FOR STABLE) [ENTER] : "  version;
        version=$(printf '%s\n' "$version" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');

        if [ -z "$version" ] ; then 
            echo "spark version is not specified! Installing spark with lastest stable version";
            distribution="stable";
            version="2.4.0";
            packages="spark-$version";
            read -p "Using hadoop binary? (y/N) [ENTER] (y) : "  hadoop;
            hadoop=$(printf '%s\n' "$hadoop" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');
            if [ "$hadoop" == "y" ]; then
                packages="$packages-bin-hadoop2.7"
            fi
        else
            distribution="spark-$version";
            packages=$distribution;
            read -p "Using hadoop binary? (y/N) [ENTER] (y) : "  hadoop;
            hadoop=$(printf '%s\n' "$hadoop" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');
            if [ "$hadoop" == "y" ]; then
                packages="$packages-bin-hadoop2.7"
            fi
        fi
    fi

    echo "################################################";
    echo "##         Collect Spark Distribution         ##";
    echo "################################################";
    echo "";

    # Packages Available
    if [ "$2" ] ; then
        mirror="$2";
    else
        mirror=https://www-eu.apache.org/dist/spark;
    fi

    url=$mirror/$distribution/$packages.tgz;
    echo "Checking availablility spark $version";
    if curl --output /dev/null --silent --head --fail "$url"; then
        echo "spark version is available: $url";
    else
        echo "spark version isn't available: $url";
        exit 1;
    fi

    echo "";
    echo "spark version $version install is in progress, Please keep your computer power on";

    wget $mirror/$distribution/$packages.tgz -O /tmp/$packages.tgz;

    echo "";
    echo "################################################";
    echo "##             Spark Installation            ##";
    echo "################################################";
    echo "";

    echo "Installing Spark Version  $distribution";
    echo "";

    # Extraction Packages
    tar -xvf /tmp/$packages.tgz;
    mv $packages $SPARK_HOME;

    # User Generator
    read -p "Do you want to create user for spark administrator? (y/N) [ENTER] (y) " createuser;
    createuser=$(printf '%s\n' "$createuser" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');

    if [ -n createuser ] ; then
        if [ "$createuser" == "y" ] ; then
            read -p "Enter username : " username;
            read -s -p "Enter password : " password;
            egrep "^$username" /etc/passwd >/dev/null;
            if [ $? -eq 0 ]; then
                echo "$username exists!"
            else
                pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
                useradd -m -p $pass $username
                [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
            fi
            usermod -aG $username $password;
        else
            read -p "Do you want to use exisiting user for spark administrator? (y/N) [ENTER] (y) " existinguser;
            if [ "$existinguser" == "y" ] ; then
                read -p "Enter username : " username;
                egrep "^$username" /etc/passwd >/dev/null;
                if [ $? -eq 0 ]; then
                    echo "$username | OK" ;
                else
                    echo "Username isn't exist we use root instead";
                    username=$(whoami);
                fi 
            else 
                username=$(whoami);
            fi
        fi
    else
        read -p "Enter username : " username;
        read -s -p "Enter password : " password;
        egrep "^$username" /etc/passwd >/dev/null;
        if [ $? -eq 0 ]; then
            echo "$username exists!"
        else
            pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
            useradd -m -p $pass $username
            [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
            usermod -aG $username $password;
            echo "User $username created successfully";
            echo "";
        fi
    fi

    echo "";
    echo "################################################";
    echo "##             Spark Configuration            ##";
    echo "################################################";
    echo "";

    echo "Generate configuration file";

    mkdir -p $SPARK_HOME/logs;
    mkdir -p $SPARK_HOME/works;
    files=(slaves spark-defaults.conf spark-env.sh);
    for configuration in "${files[@]}" ; do  
        wget https://raw.githubusercontent.com/bayudwiyansatria/Apache-Spark-Environment/master/$packages/conf/$configuration -O /tmp/$configuration;
        rm $SPARK_HOME/conf/$configuration;
        chmod 674 /tmp/$configuration;
        mv /tmp/$configuration $SPARK_HOME/conf;
    done

    # Network Configuration

    interface=$(ip route | awk '/^default/ { print $5 }');
    ipaddr=$(ip -o -4 addr list "$interface" | awk '{print $4}' | cut -d/ -f1);
    gateway=$(ip route | awk '/^default/ { print $3 }');
    subnet=$(ip addr show "$interface" | grep "inet" | awk -F'[: ]+' '{ print $3 }' | head -1);
    network=$(ipcalc -n "$subnet" | cut -f2 -d= );
    prefix=$(ipcalc -p "$subnet" | cut -f2 -d= );
    hostname=$(echo "$HOSTNAME");
    
    if [ -n "$master" ] ; then
        if [ "$master" == "y" ] ; then
            read -p "Do you want set this host as a worker to?? (y/N) [ENTER] (y): "  work;
            work=$(printf '%s\n' "$work" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');
            if [ -n "$work" ] ; then
                if [ "$work" == "y" ] ; then
                    echo "Master & Worker only serve";
                    echo -e ''$ipaddr' # '$hostname'' >> $SPARK_HOME/conf/slaves;
                else
                    echo "Master only serve";
                fi
            else
                echo "Master & Worker only serve";
                echo -e ''$ipaddr' # '$hostname'' >> $SPARK_HOME/conf/slaves;
            fi
        else
            echo "Worker only serve";
            echo -e ''$ipaddr' # '$hostname'' >> $SPARK_HOME/conf/slaves;
        fi
    else
        echo "Worker only serve";
        echo -e ''$ipaddr' # '$hostname'' >> $SPARK_HOME/conf/slaves;
    fi

    if [ "$master" == "n" ] ; then
        read -p "Do you want set this host as a worker to?? (y/N) [ENTER] (y): "  masterhost;
        masterhost=$(printf '%s\n' "$masterhost" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');
        files=(slaves spark-defaults.conf spark-env.sh);
        for configuration in "${files[@]}" ; do
            sed -i "s/localhost/$masterhost/g" $SPARK_HOME/conf/$configuration;
        done
    else
        files=(slaves spark-defaults.conf spark-env.sh);
        for configuration in "${files[@]}" ; do
            sed -i "s/localhost/$ipaddr/g" $SPARK_HOME/conf/$configuration;
        done
    fi

    chown $username:$username -R $SPARK_HOME;
    chmod g+rwx -R $SPARK_HOME;

    echo "";
    echo "################################################";
    echo "##             Java Virtual Machine           ##";
    echo "################################################";
    echo "";
    
    echo "Checking Java virtual machine is running on your machine";
    profile="/etc/profile.d/bayudwiyansatria.sh";
    env=$(echo "$PATH");
    if [ -e "$profile" ] ; then
        echo "Environment already setup";
    else
        touch $profile;
        echo -e 'export LOCAL_PATH="'$env'"' >> $profile;
    fi

    java=$(echo "$JAVA_HOME");

    if [ -z "$java" ] ; then
        if [ "$os" == "ubuntu" ] || [ "$os" == "debian" ] ; then
            apt-get -y install openjdk-8-jdk;
        elif [ "$os" == "centos" ] || [ "$os" == "rhel" ] || [ "$os" == "fedora" ]; then
            yum -y install java-1.8.0-openjdk;  
        else 
            exit 1;  
        fi
    fi

    java=$(dirname $(readlink -f $(which java))|sed 's^/bin^^');
    python=$(dirname $(readlink -f $(which java)));
    echo -e 'export JAVA_HOME="'$java'"' >> $profile;
    echo -e '# Apache Spark Environment' >> $profile;
    echo -e 'export SPARK_HOME="'$SPARK_HOME'"' >> $profile;
    echo -e 'export SPARK_CONF_DIR=${SPARK_HOME}/conf' >> $profile;
    echo -e 'export SPARK_HISTORY_OPTS=""' >> $profile;
    echo -e 'export PYSPARK_PYTHON="'$python'"' >> $profile;
    echo -e 'export SPARK=${SPARK_HOME}/bin:${SPARK_HOME}/sbin' >> $profile;

    hadoop=$(echo "$HADOOP");
    if [ -z "$HADOOP" ] ; then
        echo -e 'export PATH=${LOCAL_PATH}:${SPARK}' >> $profile;
    else
        echo -e 'export PATH=${LOCAL_PATH}:${HADOOP}:${SPARK}' >> $profile;
    fi

    echo "Successfully Checking";

    echo "";
    echo "################################################";
    echo "##             Authorization                  ##";
    echo "################################################";
    echo "";

    echo "Setting up cluster authorization";
    echo "";

    if [[ -f "/home/$username/.ssh/id_rsa" && -f "/home/$username/.ssh/id_rsa.pub" ]]; then
        echo "SSH already setup";
        echo "";
    else
        echo "SSH setup";
        echo "";
        sudo -H -u $username bash -c 'ssh-keygen';
        echo "Generate SSH Success";
    fi

    if [ -e "/home/$username/.ssh/authorized_keys" ] ; then
        echo "Authorization already setup";
        echo "";
    else
        echo "Configuration authentication";
        echo "";
        sudo -H -u $username bash -c 'touch /home/'$username'/.ssh/authorized_keys';
        echo "Authentication Compelete";
        echo "";
    fi
    
    sudo -H -u $username bash -c 'cat /home/'$username'/.ssh/id_rsa.pub >> /home/'$username'/.ssh/authorized_keys';
    chown -R $username:$username "/home/$username/.ssh/";
    sudo -H -u $username bash -c 'chmod 600 /home/'$username'/.ssh/authorized_keys';

    # Firewall
    echo "################################################";
    echo "##            Firewall Configuration          ##";
    echo "################################################";
    echo "";

    echo "Documentation firewall rule for Spark https://spark.apache.org/";

    if [ "$os" == "ubuntu" ] || [ "$os" == "debian" ] ; then
        echo "Enable Firewall Services";
        echo "";

    elif [ "$os" == "centos" ] || [ "$os" == "rhel" ] || [ "$os" == "fedora" ] ; then 
        echo "Enable Firewall Services";
        echo "";
        systemctl start firewalld;
        systemctl enable firewalld;

        echo "Adding common firewall rule for spark security";
        firewall=$(firewall-cmd --get-default-zone);
        firewall-cmd --zone="$firewall" --permanent --add-port=7077/tcp;
        firewall-cmd --zone="$firewall" --permanent --add-port=8080-8089/tcp;
        
        echo "Allowing DNS Services";
        firewall-cmd --zone="$firewall" --permanent --add-service=dns;
        echo "";

        echo "Reload Firewall Services";
        firewall-cmd --reload;
        echo "";

        echo "";
        echo "Success Adding Firewall Rule";
        echo "";
    else
        exit 1;
    fi
    
    if [ "$master" == "n" ] ; then 
        echo "Your worker already setup";
    else
        echo "";
        echo "############################################";
        echo "##        Adding Worker Nodes             ##";
        echo "############################################";
        echo "";

        read -p "Do you want to setup worker? (y/N) [ENTER] (n) " workeraccept;
        workeraccept=$(printf '%s\n' "$workeraccept" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');

        if [ -n "$workeraccept" ] ; then 
            if [ "$workeraccept" == "y" ] ; then 
                while [ "$workeraccept" == "y" ] ; do 
                    read -p "Please enter worker IP Address [ENTER] " worker;
                    echo -e  ''$worker' # Worker' >> $SPARK_HOME/conf/slaves;
                    if [[ -f "~/.ssh/id_rsa" && -f "~/.ssh/id_rsa.pub" ]]; then 
                        echo "SSH already setup";
                        echo "";
                    else
                        echo "SSH setup";
                        echo "";
                        ssh-keygen;
                        echo "Generate SSH Success";
                    fi

                    if [ -e "~/.ssh/authorized_keys" ] ; then 
                        echo "Authorization already setup";
                        echo "";
                    else
                        echo "Configuration authentication";
                        echo "";
                        touch ~/.ssh/authorized_keys;
                        echo "Authentication Compelete";
                        echo "";
                    fi
                    ssh-copy-id -i ~/.ssh/id_rsa.pub "$username@$ipaddr"
                    ssh-copy-id -i ~/.ssh/id_rsa.pub "$worker"

                    scp /tmp/$packages.tgz $worker:/tmp/
                    ssh $worker "wget https://raw.githubusercontent.com/bayudwiyansatria/Apache-Spark-Environment/master/express-install.sh";
                    ssh $worker "chmod 777 express-install.sh";
                    ssh $worker "./express-install.sh" "$version" "$mirror" "$username" "$password" "$ipaddr";
                    scp /home/$username/.ssh/authorized_keys /home/$username/.ssh/id_rsa /home/$username/.ssh/id_rsa.pub $username@$worker:/home/$username/.ssh/
                    ssh $worker "chown -R $username:$username /home/$username/.ssh/";
                    ssh $worker "echo -e  ''$ipaddr' # Master' >> $SPARK_HOME/conf/slaves";
                    read -p "Do you want to add more worker? (y/N) [ENTER] (n) " workeraccept;
                    workeraccept=$(printf '%s\n' "$workeraccept" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g'); 
                done
            fi
        fi

        echo "Worker added";
    fi

    echo "";
    echo "############################################";
    echo "##                Cleaning                ##";
    echo "############################################";
    echo "";

    echo "Cleaning Installation Packages";

    rm -rf /tmp/$packages.tgz;
    rm -rf install.sh;

    echo "Success Installation Packages";

    echo "";
    echo "############################################";
    echo "## Thank You For Using Bayu Dwiyan Satria ##";
    echo "############################################";
    echo "";
    
    echo "Installing Spark $version Successfully";
    echo "Installed Directory $SPARK_HOME";
    echo "";

    echo "User $username";
    echo "Pass $password";
    echo "";

    echo "Author    : Bayu Dwiyan Satria";
    echo "Email     : bayudwiyansatria@gmail.com";
    echo "Feel free to contact us";
    echo "";

    read -p "Do you want to reboot? (y/N) [ENTER] [n] : "  reboot;
    if [ -n "$reboot" ] ; then
        if [ "$reboot" == "y" ]; then
            reboot;
        else
            echo "We highly recomended to reboot your system";
        fi
    else
        echo "We highly recomended to reboot your system";
    fi

else
    echo "Only root may can install to the system";
    exit 1;
fi