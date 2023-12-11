FROM  ubuntu:18.04

# 用于设置 Debian 环境变量的系统环境变量。noninteractive 是一个模式，
# 它告诉 Debian 系统以非交互方式运行。
# 在非交互模式下，Debian 工具（例如 apt-get）不会等待用户输入，而是使用默认值或事先定义好的值。
ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Asia/Shanghai

# /bin/bash 是 Bash Shell 的路径，-c 表示将后续的命令作为字符串参数传递给 Bash Shell 来执行。
SHELL ["/bin/bash", "-c"]

RUN apt-get clean && \
    apt-get autoclean
COPY apt/sources.list /etc/apt/

RUN apt-get update  && apt-get upgrade -y  && \
    apt-get install -y \
    htop \
    apt-utils \
    curl \
    cmake \
    git \
    openssh-server \
    build-essential \
    qtbase5-dev \
    qtchooser \
    qt5-qmake \
    qtbase5-dev-tools \
    libboost-all-dev \
    net-tools \
    vim \
    stress 

RUN apt-get install -y libc-ares-dev  libssl-dev gcc g++ make 
RUN apt-get install -y  \
    libx11-xcb1 \
    libfreetype6 \
    libdbus-1-3 \
    libfontconfig1 \
    libxkbcommon0   \
    libxkbcommon-x11-0

RUN apt-get install -y python-dev \
    python3-dev \
    python-pip \
    python-all-dev 


COPY install/protobuf /tmp/install/protobuf
RUN /tmp/install/protobuf/install_protobuf.sh

COPY install/abseil /tmp/install/abseil
RUN /tmp/install/abseil/install_abseil.sh

COPY install/grpc /tmp/install/grpc
RUN /tmp/install/grpc/install_grpc.sh

COPY install/cmake /tmp/install/cmake
RUN /tmp/install/cmake/install_cmake.sh

RUN apt-get install -y python3-pip
RUN pip3 install cuteci -i https://mirrors.aliyun.com/pypi/simple

COPY install/qt /tmp/install/qt
RUN /tmp/install/qt/install_qt.sh