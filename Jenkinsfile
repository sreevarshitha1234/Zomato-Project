pipeline{
	agent any 
	tools{
		jdk 'jdk17'
		nodejs 'node16'
	}
	environment{
		SCANNER_HOME=tool 'sonar-server'
	}
	stages{
		stage('clean workspace'){
			steps{
				cleanWs()
			}
		}
		stage('Code Checkout From Git'){
			steps{
				git branch: 'main', url: 'https://github.com/sreevarshitha1234/Zomato-Project.git'
			}
		}
		stage("SonarQube Code Analysis"){
			steps{
				withSonarQubeEnv('sonar-server'){
					sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=zomato \
                    -Dsonar.projectKey=zomato '''
				}
			}
		}
		stage("Code Quality Gates"){
			steps{
				script{
					 timeout(time: 2, unit: 'MINUTES'){
					waitForQualityGate abortPipeline: false, credentialsId: 'sonar-server'
				}
			}
		}
	}
		stage("Install Dependencies"){
			steps{
				sh "npm install"
			}
		}
		stage("OWASP FS SCAN"){
			steps{
				dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
				dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
			}
		}
		stage("TRIVY FS SCAN"){
			steps{
				sh "trivy fs . > trivy.txt"
			}
		}
		stage("DOcker Image Build and Push"){
			steps{
				script{
				withDockerRegistry(credentialsId: 'docker-hub', toolName: 'docker'){
					sh "docker build -t cloudzomato . "
					sh "docker tag cloudzomato 192.168.121.129:8085/cloudzomato:latest"
					sh "docker push 192.168.121.129:8085/cloudzomato:latest"
						}
					}
				}
			}
		stage("TRIVY is Image Scanning"){
			steps{
				sh "trivy image 192.168.121.129:8085/cloudzomato:latest >trivy.txt"
			}
		}
		stage("Creating Docker Container "){
			steps{
				sh 'docker run -d --name zomato-app -h zomato -p 3000:3000 192.168.121.129:8085/cloudzomato:latest'
			}
		}
	}
}
