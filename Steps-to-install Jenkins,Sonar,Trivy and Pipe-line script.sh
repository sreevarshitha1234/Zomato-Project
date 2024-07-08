Build Server 
-------------------------------------------------------
yum update -y
hostnamectl set-hostname jenkinsserver
exec bash
yum install git vim wget tar make unzip fontconfig java-11-openjdk-devel -y






#Trivy Install 
vim /etc/yum.repos.d/trivy.repo
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$releasever/$basearch/
gpgcheck=0
enabled=1
# Save and exit by :wq
#Install Trivy by applying below command. 
yum -y install trivy



#Download Tomcat now 
cd /opt 
https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.87/bin/apache-tomcat-9.0.87.tar.gz
tar -xvf apache-tomcat-9.0.87.tar.gz
mv apache-tomcat-9.0.87 tomcat 

#Download Jenkins now 
https://get.jenkins.io/war-stable/2.440.1/jenkins.war



## Docker Install 
yum install yum-utils device-mapper-persistent-data lvm2 -y
yum-config-manager --add-repo  https://download.docker.com/linux/centos/docker-ce.repo
systemctl start docker && systemctl enable docker




#plugins:
Eclipse Temurin Installer
SonarQube Scanner
NodeJS
OWASP Dependency-Check
Docker
Docker Commons
Docker Pipeline
Docker API 
Docker Build Step 


#Tools in Jenkins

#Java 
 
name:  jdk17 
version: jdk-17.0.81

# Git
Git 2.39.3
path: /usr/bin/git 


#SonarQube Scanner 
name: sonar-scanner
version: SonarQube Scanner Latest Version: 5.0.1.3006

#NodeJS

name: node16 
Version: 16.2.0


#OWASP Dependency-Check Installations:
name: Dependency-Check
install form: install from github.com 
version: dependency-check 6.5.1

#Docker
name: docker 
install form: install from github.com 
version: latest









--------------------------------------------------------
SonarQube Configure
---------------------------------------------------------
sudo yum update -y
hostnamectl set-hostname sonarqube
sudo yum install vim wget curl unzip -y
sudo setenforce 0
sudo sed -i 's/^SELINUX-enforcing$/SELINUX=permissive/' /etc/selinux/config
sudo tee -a /etc/sysctl.conf<<EOF
vm.max_map_count=262144
fs.file-max=65536
EOF
sudo sysctl --system

# Create a user for sonar

sudo useradd sonar 
sudo passwd sonar       CloudGen@123

# Install Java 11 on Rocky Linux 9.3
sudo yum install java-17-openjdk-devel -y

java --version

#Install and configure PostgreSQL

##Step 2 – Install and Configure PostgreSQL

##SonarQube uses PostgreSQL as a database backend, so you will need to install a PostgreSQL database on your server.

##First, install the PostgreSQL repo using the following command:

dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm

##Next, disable the default PostgreSQL module and install the latest version of PostgreSQL with the following command:

dnf install postgresql16 postgresql16-server -y 
##Once the installation is completed, initialize the PostgreSQL database using the following command:

/usr/pgsql-16/bin/postgresql-16-setup initdb

##Next, start and enable the PostgreSQL service with the following command:

systemctl enable --now postgresql-16

##Next, log in to PostgreSQL with the following command:

sudo vim /var/lib/pgsql/16/data/pg_hba.conf    // need not change anything in this file

vim /var/lib/pgsql/16/data/postgresql.conf    // uncoment line number 60 and replace as  listen_addresses = '*'
systemctl restart postgresql-16
su - postgres
psql

alter user postgres with password 'CloudGen@123';
\q
createdb sonarqube
psql
CREATE USER sonarqube WITH PASSWORD 'CloudGen@123';
GRANT ALL PRIVILEGES ON DATABASE sonarqube to sonarqube;
\q
exit
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.4.87374.zip
unzip sonarqube-9.9.4.87374.zip

mv sonarqube-*/ /opt/sonarqube
sudo vim /opt/sonarqube/conf/sonar.properties      //copy the below lines from 66 to 83 and paste at 407th line

## Database details
sonar.jdbc.username=sonarqube
sonar.jdbc.password=CloudGen@123
sonar.jdbc.url-jdbc:postgresql://localhost/sonarqube


##How you will access SonarQube web UI
sonar.web.host=0.0.0.0
sonar.web.post=9000

##Java options

sonar.web.javaOpts=-server -Xms512m -Xmx512m -XX:+HeapDumpOnOutOfMemoryError
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:MaxDirectMemorySize=256m -XX:+HeapDumpOnOutOfMemoryError

##Also add the following Elasticsearch storage paths 
sonar.path.data=/var/sonarqube/data 
sonar.path.temp=/var/sonarqube/temp


chown -R sonar:sonar /opt/sonarqube
mkdir -p /var/sonarqube
chown -R sonar:sonar /var/sonarqube


vim /etc/systemd/system/sonarqube.service


[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
LimitNOFILE=65536
LimitNPROC=4096
User=sonar
Group=sonar
Restart=on-failue

[Install]

WantedBy=multi-user.target



sudo systemctl daemon-reload
sudo systemctl start sonarqube.service
sudo systemctl enable sonarqube.service
systemctl status sonarqube.service

#Firewall rules to allow SonarQube Access

sudo systemctl status firewalld 
sudo systemctl start firewalld
sudo systemctl status firewalld
sudo firewall-cmd --permanent --add-port=9000/tcp && sudo firewall-cmd --reload



Access the Web User Interface

http://server-ip:9000


username : admin
New Password : CloudGen@123








pipeline{
    agent any
    tools{
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
    }
    stages {
  
        stage('clean workspace'){
            steps{
                cleanWs()
            }
        }
        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/Devops9AM/Zomato-Clone.git'
            }
        }
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=zomato \
                    -Dsonar.projectKey=zomato '''
                }
            }
        }
        stage("quality gate"){
           steps {
                script {
                     timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token' 
                }
            } 
        }
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        stage('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        
        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        stage("Docker Build & Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){   
                       sh "docker build -t zomato ."
                       sh "docker tag zomato thanish/zomato:latest "
                       sh "docker push thanish/zomato:latest "
                    }
                }
            }
        }
        stage("TRIVY"){
            steps{
                sh "trivy image thanish/zomato:latest > trivy.txt" 
            }
        }
        stage('Deploy to container'){
            steps{
                sh 'docker run -d --name zomato -p 3000:3000 thanish/zomato:latest'
            }
        }
    }
}
