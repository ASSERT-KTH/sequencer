# docker build -t ubuntu1604py36
FROM ubuntu:16.04

RUN apt-get update

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y install locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:jonathonf/python-3.6
RUN apt-get update
RUN apt-get install -y python3.6
RUN apt-get install -y python3-pip


RUN echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
RUN echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections

RUN apt-get install -y python-software-properties
# RUN apt-get install -y default-jre
# RUN apt-get install -y default-jdk
RUN add-apt-repository ppa:openjdk-r/ppa
RUN apt-get update
RUN apt-get install -y openjdk-8-jdk
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
ENV PATH="${PATH}:$JAVA_HOME/bin"

RUN apt-get install -y git

RUN apt-get install -y maven

RUN apt-get install -y nano

RUN apt-get install -y unzip

RUN apt-get install -y wget

RUN apt-get install -y subversion

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 2

WORKDIR /SequenceR

COPY . /SequenceR

RUN ./src/setup_env.sh

RUN apt-get install -y libcam-pdf-perl
ENV PERL_MM_USE_DEFAULT 1

RUN git clone https://github.com/rjust/defects4j /SequenceR/src/lib/defects4j
RUN cpan App::cpanminus
RUN cpanm --installdeps /SequenceR/src/lib/defects4j/
RUN /SequenceR/src/lib/defects4j/init.sh
ENV PATH="${PATH}:/SequenceR/src/lib/defects4j/framework/bin"
