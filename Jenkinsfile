pipeline {
  agent any

  parameters {
    string(name: 'JENKINS_VERSION', defaultValue: '2.150.1', description: 'The version of Jenkins to package')
  }

  environment {
    JENKINS_VERSION = "${params.JENKINS_VERSION}"
  }
    
  stages {
    stage('MSI') {
      agent { label 'windows && packaging' }
      
      tools { msbuild 'default' }

      steps {
        bat """
cd msi
powershell -f build.ps1
copy bin/Release/jenkins-${env.JENKINS_VERSION}.msi ../
            """
        stash name: 'Installer', includes: "jenkins-${env.JENKINS_VERSION}.msi"
      }
    }

    stage('Sign') {
      agent { label 'windows && packaging' }
      when {
        expression isTrusted()
      }

      steps {
        unstash name: 'Installer'
        bat """openssl pkcs12 -export -out ${SIGN_KEYSTORE} -in ${SIGN_CERTIFICATE} -password pass:${SIGN_STOREPASS} -name ${SIGN_ALIAS}
signtool sign /v /f ${SIGN_KEYSTORE} /p ${SIGN_STOREPASS} /t http://timestamp.verisign.com/scripts/timestamp.dll /d "Jenkins-${env.JENKINS_VERSION}" Jenkins-${env.JENKINS_VERSION}.msi"""
        stash name: 'Installer'
        // do we want to publish here as well?
      }
    }
    
    stage('Archive Artifacts') {
      agent { any }
      steps {
        unstash name: 'Installer'
        
      }
    }
  }
}
