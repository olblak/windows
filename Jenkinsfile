pipeline {
  agent any

  parameters {
    string(name: 'JENKINS_VERSION', defaultValue: '2.150.1', description: 'The version of Jenkins to package')
  }

  environment {
    JENKINS_VERSION = "${params.JENKINS_VERSION}"
    MSI_SHA256 = ""
  }
    
  stages {
    stage('MSI') {
      //agent { label 'windows && packaging' }
      agent { label 'windows' }

      steps {
        script {
          def msbuild = tool 'MSBuild'
          dir('msi') {
            bat "powershell -f mkrelease.ps1 ${env.JENKINS_VERSION} \"${msbuild}\""
          }
        }
        stash name: 'MSI', includes: "bin/Release/**/jenkins-${env.JENKINS_VERSION}.msi"
      }
    }
    
    
//      stage('Sign') {
//        agent { label 'windows && packaging' }
//        when {
//          expression isTrusted()
//        }

//        steps {
  // TODO: sign each localized version of the installer
//          unstash name: 'Installer'
//          bat """openssl pkcs12 -export -out ${SIGN_KEYSTORE} -in ${SIGN_CERTIFICATE} -password pass:${SIGN_STOREPASS} -name ${SIGN_ALIAS}
//  signtool sign /v /f ${SIGN_KEYSTORE} /p ${SIGN_STOREPASS} /t http://timestamp.verisign.com/scripts/timestamp.dll /d "Jenkins-${env.JENKINS_VERSION}" Jenkins-${env.JENKINS_VERSION}.msi"""
//         stash name: 'Installer'
//         // do we want to publish here as well?
//       }
//     }

    stage('Hash MSI') {
      agent { label 'windows' }
      steps {
        unstash 'MSI'
        script {
          
          MSI_SHA256 = powershell(returnStdout: true, script: "(Get-FileHash -Algorithm SHA256 -Path bin/Release/en-US/jenkins*${env.JENKINS_VERSION}.msi).Hash.ToLower()").trim()
        }
      }
    }

    stage('Chocolatey') {
      agent { label 'windows'}
      steps {
        script {
          dir('chocolatey') {
            bat "powershell -f mkrelease.ps1 ${env.JENKINS_VERSION} ${MSI_SHA256}"
          }
        }
        stash name: 'Chocolatey', includes: "jenkins*.${env.JENKINS_VERSION}.nupkg"
      }
    }
    
    stage('Archive Artifacts') {
      agent any
      steps {
        unstash name: 'MSI'
        unstash name: 'Chocolatey'
        
        archiveArtifacts artifacts: "**/jenkins-${env.JENKINS_VERSION}.msi, **/jenkins*.${env.JENKINS_VERSION}.nupkg"
      }
    }
  }
}
