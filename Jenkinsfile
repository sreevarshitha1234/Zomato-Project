pipeline{
	agent any 
	tools{
		jdk 'jdk17'
		nodejs 'node16'
	}
	environment{
		SCANNER_HOME=tool 'sonar-scanner'
	}
	stages{
		stage('clean workspace'){
			steps{
				cleanWs()
			}
		}
		stage('Code Checkout From Git'){
			steps{
				git branch: 'main', url: 'https://github.com/Devops9AM/Zomato-Project.git'
			}
		}
		stage("SonarQube Code Analysis"){
			steps{
				withSonarQubeEnv('sonar-scanner'){
					sh '''$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Zomato-Test-Project \ -Dsonar.projectkey=Zomato-Test-Project'''
					
				}
			}
		}





	}
}