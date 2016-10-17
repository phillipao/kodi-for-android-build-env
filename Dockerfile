FROM ubuntu:16.04
MAINTAINER Phillip Oertel <phillipao@gmail.com>
# Environment for building Kodi for Android.
#
# Installs required packages and Android SDK/NDK. Currently intended more for
# documentation, and as a detailed spec of a kodi build environment. But it's
# also easy to use directly for doing Kodi development.

RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    build-essential \
    cmake \
    curl \
    default-jdk \
    # Used by configure to check arch. Will incorrectly identify arch without it.
    file \
    gawk \
    git \
    gperf \
    lib32stdc++6 \
    lib32z1 \
    lib32z1-dev \
    libcurl4-openssl-dev \
    nasm \
    unzip \
    zip \
    zlib1g-dev

WORKDIR /opt
RUN curl -O http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz 
RUN tar xzf android-sdk_r24.4.1-linux.tgz 
RUN rm -f android-sdk_r24.4.1-linux.tgz

ENV ANDROID_HOME /opt/android-sdk-linux
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools

RUN echo y | android update sdk --filter android-21 --no-ui --force -a

ENV ANDROID_NDK_DIR android-ndk-r12b
ENV ANDROID_NDK_ZIP "${ANDROID_NDK_DIR}-linux-x86_64.zip"
ENV ANDROID_NDK_URL "https://dl.google.com/android/repository/${ANDROID_NDK_ZIP}"
RUN curl -O "${ANDROID_NDK_URL}"
RUN unzip "${ANDROID_NDK_ZIP}" -x "${ANDROID_NDK_DIR}/platforms/*"
RUN unzip "${ANDROID_NDK_ZIP}" "${ANDROID_NDK_DIR}/platforms/android-21/*"
RUN rm "${ANDROID_NDK_ZIP}"

RUN keytool -genkey -keystore ~/.android/debug.keystore -v -alias \
      androiddebugkey -dname "CN=Android Debug,O=Android,C=US" -keypass \
      android -storepass android -keyalg RSA -keysize 2048 -validity 10000

RUN echo y | android update sdk --all -u -t build-tools-20.0.0

WORKDIR /opt/${ANDROID_NDK_DIR}/build/tools
RUN ./make-standalone-toolchain.sh --ndk-dir=../.. \
      --install-dir=/opt/android-toolchain-x86/android-21 --platform=android-21 \
      --toolchain=x86-4.9 --arch=x86

# The following steps don't really belong in a Dockerfile, because ideally you don't
# want data (i.e. the source code) inside a docker container. But I included them here
# to show how I used it. A more idiomatic docker setup would be to create containers
# around the configure and make commands, with the source mounted as a volume.
# WORKDIR /root
# RUN git clone git://github.com/xbmc/xbmc.git kodi-android
# WORKDIR /root/kodi-android/tools/depends

# RUN ./bootstrap
# RUN ./configure --with-tarballs=/opt/xbmc-depends/tarballs --host=i686-linux-android \
#     --with-sdk-path=/opt/android-sdk-linux --with-ndk=/opt/${ANDROID_NDK_DIR} \
#     --with-toolchain=/opt/android-toolchain-x86/android-21 --prefix=/opt/android-dev/android/xbmc-depends

# These commands tend to fail, but they generate state as they do so. I
# think this project has some nondeterministic build failures, and that's why
# it's necessary to build several times. As such, I don't guarantee that the
# following commands will successfully build the project. But they worked for
# me at least once.
# RUN make -j20 || echo failed
# RUN make || echo failed
# RUN make -C target/libcdio-gplv3 distclean
# RUN make
# RUN make -j20 -C target/binary-addons

# WORKDIR /root/kodi-android
# RUN make -j20 -C tools/depends/target/xbmc

CMD ["/bin/bash"]
