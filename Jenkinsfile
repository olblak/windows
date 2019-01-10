pipeline {
  agent any

  parameters {
    string(name: 'JENKINS_VERSION', defaultValue: '2.138.3', description: 'The version of Jenkins to package')
  }

  environment {
    PRODUCTNAME='Jenkins'
    ARTIFACTNAME='jenkins'
    CAMELARTIFACTNAME='Jenkins'
    VENDOR='Jenkins Project'
    SUMMARY='Jenkins Automation Server'
    PORT='8080'

    AUTHOR='Kohsuke Kawaguchi <kk@kohsuke.org>'
    LICENSE='MIT/X License, GPL/CDDL, ASL2'
    HOMEPAGE='http://jenkins.io/'
    CHANGELOG_PAGE='http://jenkins.io/changelog'
    JENKINS_VERSION = "${params.JENKINS_VERSION}"
  }
    
  stages {
    stage('Prepare') {
      agent { any }
      
      environment {
        JENKINS_WAR = env.LTS.equalsIgnoreCase('true') ? "http://mirrors.jenkins.io/war-stable/${env.JENKINS_VERSION}/jenkins.war" : "http://mirrors.jenkins.io/war/${env.JENKINS_VERSION}/jenkins.war"
        JENKINS_WAR_SHA = env.LTS.equalsIgnoreCase('true') ? "http://mirrors.jenkins.io/war-stable/${env.JENKINS_VERSION}/jenkins.war.sha256" : "http://mirrors.jenkins.io/war/${env.JENKINS_VERSION}/jenkins.war.sha256"
      }

      // This is where we get the correct version from the environment
      // Download the jenkins.war and stash it for use below
      sh """curl ${JENKINS_WAR_SHA} > jenkins.war.sha256
curl ${JENKINS_WAR} > jenkins.war
sha256sum -c jenkins.war.sha256
mkdir -p tmp
unzip -p jenkins.war 'WEB-INF/lib/jenkins-core-*.jar' > tmp/core.jar
unzip -p tmp/core.jar windows-service/jenkins.exe > tmp/jenkins.exe
unzip -p tmp/core.jar windows-service/jenkins.xml > tmp/jenkins.xml
"""
      stash name: 'WAR' includes: "jenkins.war, tmp/*"
    }

    stage('Build Installer') {
      agent { label 'windows && packaging' }
      tools { msbuild 'default' }

      steps {
        unstash name: 'WAR'
        bat """
nuget restore -PackagesDirectory packages
${msbuild} jenkins.wixproj /p:DisplayVersion=${env.JENKINS_VERSION} /p:Configuration=Release /verbosity:minimal
copy bin/Release/jenkins-${env.JENKINS_VERSION}.msi .
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
