FROM ubuntu:18.04

RUN apt-get update && apt-get install -y \
    git \
    python-pip \
    python \
    python3.5 \
    wget \
    curl \
    unzip \
    htop \
    vim

LABEL maintainer="wshands@gmail.com"

WORKDIR root

RUN wget http://eddylab.org/software/hmmer/hmmer.tar.gz
RUN tar zxf hmmer.tar.gz
WORKDIR hmmer-3.2.1
RUN ./configure --prefix /usr/local
RUN make
# optional: run automated tests
RUN make check
# optional: install HMMER programs, man pages
RUN make install
# optional: install Easel tools
RUN (cd easel; make install)
