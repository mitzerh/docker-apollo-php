FROM centos:7

# Image labels
LABEL org.label-schema.schema-version = "1.0" \
    org.label-schema.name="CentOS Base Image" \
    org.label-schema.vendor="CentOS" \
    org.label-schema.license="GPLv2" \
    org.label-schema.build-date="20180531"

# Package maintainance
MAINTAINER mitzerh<mitzerh+docker@gmail.com>

############################################################
# Install a build environment

RUN \
  echo Update package manager && \
  yum makecache fast && \
  yum update -y && \
  curl -O https://bootstrap.pypa.io/get-pip.py && \
  python get-pip.py && \
  pip install \
    awscli \
    boto \
    boto3 \
    && \
  echo "http-prser requirement https://bugs.centos.org/view.php?id=13669&nbn=1" && \
  rpm -ivh https://kojipkgs.fedoraproject.org//packages/http-parser/2.7.1/3.el7/x86_64/http-parser-2.7.1-3.el7.x86_64.rpm && \
  yum -y install \
    which \
    ruby \
    ruby-devel \
    gcc \
    gcc-c++ \
    make \
    rubygems \
    git \
    dos2unix \
    bzip2

RUN \
  yum -y install \
  httpd \
  httpd-tools \
  cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.orig && \
  sed -i 's/#ServerName www\.example\.com:80/ServerName localhost:80/' /etc/httpd/conf/httpd.conf

RUN \
  echo "installing node" && \
  curl -sL https://rpm.nodesource.com/setup_10.x | bash - && \
  yum install -y nodejs && \
  npm install -g grunt grunt-cli pm2

RUN echo Done!

############################################################
# Install en_US.UTF-8 locale

ENV LANG en_US.UTF-8

############################################################
# Install bootstrap script(s)

# Copy the bootstrap script(s)
ADD src /bin/

# Clean up the bootstrap script(s)
RUN \
  echo Deal with Windows miscreance CRs with LF && \
  sed -i 's/\r$//' /bin/bootstrap.sh && \
  echo Deal with Mac miscreance CRs with no LF && \
  tr '\r' '\n' < /bin/bootstrap.sh > /bin/bootstrap.sh.tmp && \
  mv /bin/bootstrap.sh.tmp /bin/bootstrap.sh

# Define working directory.
#WORKDIR /

############################################################
# Mounts in the container host

# This volume is shared between the HFS+/NTFS container host
# and locally by the container
VOLUME ["/usr/local/root"]

############################################################
# Default container entry point

ENTRYPOINT [ "/bin/sh", "/bin/bootstrap.sh" ]
