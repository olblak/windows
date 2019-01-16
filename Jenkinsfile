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
      //agent { label 'windows && packaging' }
      agent { label 'windows' }

      steps {
        script {
          def msbuild = tool 'MSBuild'
          dir('msi') {
            bat """
powershell -f mkrelease.ps1 ${env.JENKINS_VERSION} \"${msbuild}\"
copy bin\\Release\\jenkins-${env.JENKINS_VERSION}.msi ..\\"""
          }
        }
        stash name: 'Installer', includes: "jenkins-${env.JENKINS_VERSION}.msi"
      }
    }
    
    stage('Chocolatey') {
      agent { label 'windows'}
      steps {
        script {
          dir('chocolatey') {
            bat """
powershell -f mkrelease.ps1 ${env.JENKINS_VERSION}
copy bin\\jenkins-*.${env.JENKINS_VERSION}.nupkg ..\\"""
          }
        }
        stash name: 'Chocolatey', includes: "jenkins-*.${env.JENKINS_VERSION}.nupkg"
      }
    }

//     stage('Sign') {
//       agent { label 'windows && packaging' }
//       when {
//         expression isTrusted()
//       }

//       steps {
//         unstash name: 'Installer'
//         bat """openssl pkcs12 -export -out ${SIGN_KEYSTORE} -in ${SIGN_CERTIFICATE} -password pass:${SIGN_STOREPASS} -name ${SIGN_ALIAS}
// signtool sign /v /f ${SIGN_KEYSTORE} /p ${SIGN_STOREPASS} /t http://timestamp.verisign.com/scripts/timestamp.dll /d "Jenkins-${env.JENKINS_VERSION}" Jenkins-${env.JENKINS_VERSION}.msi"""
//         stash name: 'Installer'
//         // do we want to publish here as well?
//       }
//     }
    
    // stage('Archive Artifacts') {
    //   agent { any }
    //   steps {
    //     unstash name: 'Installer'
        
    //   }
    //}
  }
}
