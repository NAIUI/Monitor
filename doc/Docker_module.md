## **Docker 模块**

使用 Dockerfile 指定相应的Cmake，gRPC，Protod等源码和依赖项，构建整个项目环境，支持在多台服务器上部署环境，并编写容器操作脚本指令，方便启动项目所依赖的环境。

### Dockerfile

```cpp
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
```

### Shell

分别进行各个运行环境库的安装，其中qt的运行包需要单独下载。

1. `ldconfig` ：动态链接库管理命令，让动态链接库为系统所共享。
2. `/usr/local`：第三方软件安装目录。
3. `abseil`：C++代码的开源集合（符合C++14），旨在增强C++标准库。

### Scripts

**xhost**

1. xhost命令是X服务器的访问控制工具，用来控制哪些X客户端能在X服务器上显示。
2. 使用：`xhost [+ | -] [name]` ，"+"表示添加，"-"表示删除。
3. 示例：`xhost +` 使所有用户都能访问XServer，`xhost + local:root` 只有本地root用户可以访问XServer。

**DISPLAY**

    在Linux/Unix类操作系统上，DISPLAY用来设置将图形显示到何处.。接登录图形界面或者登录命令行界面后使用startx启动图形，DISPLAY环境变量将自动设置为:0:0，此时可以打开终端，输出图形程序的名称(比如xclock)来启动程序，图形将显示在本地窗口上，在终端上输入printenv查看当前环境变量，输出结果中有如下内容：DISPLAY=:0.0。

    使用xdpyinfo可以查看到当前显示的更详细的信息。

    DISPLAY环境变量格式如下host:NumA.NumB, host指Xserver所在的主机主机名或者ip地址，图形将显示在这一机器上，可以是启动了图形界面的Linux/Unix机器，也可以是安装了Exceed, X-Deep/32等Windows平台运行的Xserver的Windows机器。如果Host为空，则表示Xserver运行于本机，并且图形程序(Xclient)使用unix socket方式连接到Xserver,而不是TCP方式。使用TCP方式连接时,NumA为连接的端口减去6000的值,如果NumA为0，则表示连接到6000端口；使用unix socket方式连接时则表示连接的unix socket的路径，如果为0，则表示连接到/tmp/.X11-unix/X0 。NumB则几乎总是0。
