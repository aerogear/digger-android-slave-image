FROM openshift/jenkins-slave-base-centos7

MAINTAINER AeroGear Team <https://aerogear.org/>

#build args
ARG KEYSTORE_ALIAS=AndroidDebugKey
ARG FULL_NAME=AG
ARG ORG_UNIT=AeroGear
ARG ORG_NAME=RedHat
ARG LOCALITY=WaterFord
ARG PROVINCE=WD
ARG COUNTRY_CODE=IRL
ARG STORE_PASS=android
ARG KEY_PASS=android

#env vars
ENV ANDROID_SLAVE_SDK_BUILDER=1.0.0 \
    NODEJS_DEFAULT_VERSION=6.9.1 \
    CORDOVA_DEFAULT_VERSION=7.0.1 \
    GRUNT_DEFAULT_VERSION=1.0.1 \
    FASTLANE_DEFAULT_VERSION=2.60.1 \
    GRADLE_VERSION=3.5 \
    ANDROID_HOME=/opt/android-sdk-linux \
    NVM_DIR=/opt/nvm \
    PROFILE=/etc/profile \
    CI=Y \
    BASH_ENV=/etc/profile \
    JAVA_HOME=/etc/alternatives/java_sdk_1.8.0

#update PATH env var
ENV PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$NVM_DIR:/opt/gradle/gradle-$GRADLE_VERSION/bin

LABEL io.k8s.description="Platform for building slave android sdk image" \
      io.k8s.display-name="jenkins android sdk slave builder" \
      io.openshift.tags="jenkins-android-slave builder"

#system pakcages
RUN yum install -y \
  zlib.i686 \
  ncurses-libs.i686 \
  bzip2-libs.i686 \
  java-1.8.0-openjdk-devel \
  java-1.8.0-openjdk \
  ruby \
  rubygems \
  ruby-devel \
  nodejs \
  gcc-c++ \
  make \
  ant \
  which\
  wget \
  expect && \
  yum groupinstall -y "Development Tools" && \
  yum clean all

#install nvm and nodejs
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash && \
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && \
    echo 'export NVM_DIR=${NVM_DIR}' >> ${HOME}/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> ${HOME}/.bashrc && \
    echo 'CI=Y' >> ${HOME}/.bashrc && \
    nvm install ${NODEJS_DEFAULT_VERSION} && \
    chmod -R 777 ${NVM_DIR} && \
    npm install -g cordova@${CORDOVA_DEFAULT_VERSION} && \
    gem install fastlane -v ${FASTLANE_DEFAULT_VERSION} && \
    npm install -g grunt@${GRUNT_DEFAULT_VERSION}

#install gradle
RUN mkdir -p /opt/gradle && \
    wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    unzip -d /opt/gradle gradle-${GRADLE_VERSION}-bin.zip && \
    rm gradle-${GRADLE_VERSION}-bin.zip

#install jq
RUN wget -O jq  https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && \
    chmod +x ./jq &&\
    cp jq /usr/bin

#fix permissions
RUN mkdir -p $HOME/.android && \
    touch $HOME/.android/analytics.settings && \
    touch $HOME/.android/reposiories.cfg

RUN keytool -genkey -noprompt -alias $KEYSTORE_ALIAS \
    -dname "CN=$FULL_NAME, OU=$ORG_UNIT, O=$ORG_NAME, L=$LOCALITY, S=$PROVINCE, C=$COUNTRY_CODE" \
    -keystore $HOME/.android/debug.keystore \
    -storepass $STORE_PASS \
    -keypass $KEY_PASS \
    -keysize 2048 \
    -keyalg RSA

RUN chown -R 1001:0 $HOME && \
    chmod -R g+rw $HOME

COPY scripts/run-jnlp.sh /usr/local/bin/run-jnlp.sh

USER 1001
WORKDIR /tmp

ENTRYPOINT ["/usr/local/bin/run-jnlp.sh"]
