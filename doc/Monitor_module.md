## Monitor 模块

使用工厂方法创建抽象类定义接口，实现 CPU 状态、系统负载、软中断、内存、网络等监控功能。使用 stress 工具模拟真实的性能问题，分析服务器在不同时刻的 CPU 使用率和中断情况。

### chrono库

#### 时间间隔duration

duration表示一段时间间隔，用来记录时间长度，可以表示几秒、几分钟、几个小时的时间间隔

#### 时间点time point

chrono库中提供了一个表示时间点的类time_point

#### 时钟clock

chrono库中提供了获取当前的系统时间的时钟类，包含的时钟一共有三种:

* system_clock: 系统的时钟，系统的时钟可以修改，甚至可以网络对时，因此使用系统时间计算时间差可能不准。
* steady_clock:是固定的时钟，相当于秒表。开始计时后，时间只会增长并且不能修改，适合用于记录程序耗时。
* high_resolution_clock:和时钟类steady_clock 是等价的(是它的别名)。

如果我们通过时钟不是为了获取当前的系统时间，而是进行程序耗时的时长，此时使用syetem_clock就不合适了，因为这个时间可以跟随系统的设置发生变化。在C++11中提供的时钟类steady_clock相当于秒表，只要启动就会进行时间的累加，并且不能被修改，非常适合于进行耗时的统计。

### 数据采集

在GUN/Linux操作系统中，/proc是一个位于内存中的伪文件系统(in-memory pseudo-file system)。该目录下保存的不是真正的文件和目录，而是一些"运行时"信息，如系统内存、磁盘io、设备挂载信息和硬件配置信息等。proc目录是一个控制中心，用户可以通过更改其中某些文件来改变内核的运行状态。proc目录也是内核提供给我们的查询中心，我们可以通过这些文件查看有关系统硬件及当前正在运行进程的信息。在Linux系统中，许多工具的数据来源正是proc目录中的内容。例如，top命令是通过/proc/stat中数据，进行换算得出。

#### cpu load

/proc/loadavg保存了系统负载的平均值，其前三列分别表示最近1分钟、5分钟及15分的平均负载。反映了当前系统的繁忙情况。

```
/proc/loadavg
1 lavg_1   1-分钟平均负载
2 lavg_5   5-分钟平均负载
3 lavg_15 15-分钟平均负载
4 nr_running 在采样时刻，运行队列的任务的数目，与/proc/stat的procs_running表示相同意思
5 nr_threads 在采样时刻，系统中活跃的任务的个数(不包括运行已经结束的任务)
6 last_pid   最大的pid值，包括轻量级进程，即线程。
```

1. 平均负载：单位时间内，系统处于可运行状态和不可中断状态的平均进程数，也就是平均活跃进程数，包括了正在使用CPU的进程，等待CPU和等待I/O的进程。它和CPU使用率并没有直接关系。
2. 平均负载最理想的情况是等于CPU个数。通过top命令或者从文件/proc/cpuinfo中读取CPU个数。
3. 平均负载与CPU使用率：CPU密集型进程，使用大量CPU会导致平均负载升高，此时这两者是一致的;I/0密集型进程，等待I/0也会导致平均负载升高，但CPU使用率不一定很高;大量等待CPU的进程调度也会导致平均负载升高，此时的CPU使用率也会比较高。

#### cpu stat

Linux通过/proc虚拟文件系统，向用户空间提供了系统内部状态的信息，而/proc/stat 提供的就是系统的CPU和任务统计信息。

```
/proc/stat
1 user(通常缩写为us)，代表用户态CPU时间。注意，它不包括下面的 nice时间，但包括了guest时间。
2 nice (通常缩写为 ni)，代表低优先级用户态CPU时间，也就是进程的nice值被调整为1-19之间时的CPU时间。这里注意，nice 可取值范围是-20 到19，数值越大，优先级反而越低。
3system(通常缩写为sys) ，代表内核态 CPU时间。
4 idle (通常缩写为id)，代表空闲时间。注意，它不包括等待I/o 的时间(iowait)。5 iowait(通常缩写为wa) ，代表等待I/0的CPU时间。
6 irq(通常缩写为hi) ，代表处理硬中断的CPU时间。
7 softirq(通常缩写为si)，代表处理软中断的CPU 时间。
8 steal (通常缩写为st)，代表当系统运行在虚拟机中的时候，被其他虚拟机占用的 CPU时间。
9 guest(通常缩写为 guest)，代表通过虚拟化运行其他操作系统的时间，也就是运行虚拟机的CPU时间。10 guest_nice (通常缩写为gnice)，代表以低优先级运行虚拟机的时间。
```

    ![img](../img/CPU.png)

为了计算CPU使用率，取间隔一段时间(比如3秒)的两次值，作差后，再计算出这段时间内的平均CPU使用率

    ![img](../img/CPU_AVG.png)

#### cpu softirqs

/proc/softirqs记录自开机以来软中断累积次数；/proc/interrupts记录自开机以来的累积中断次数

```
/proc/softirqs
1 TIMER(定时中断)
2 NET_TX(网络发送)
3 NET_RX (网络接收)
4 SCHED(内核调度)
5 RCU (RCU锁)中，网络接收变化最快
```

Linux中的中断处理程序分为上半部和下半部:

* 上半部对应硬件中断，用来快速处理中断。
* 下半部对应软中断，用来异步处理上半部未完成的工作。
* Linux中的软中断包括网络收发、定时、调度、RCU锁等各种类型，可以通过查看/proc/softirqs 来观察软中断的运行情况。

#### mem info

/proc/meminfo当前内存使用的统计信息，常由free命令使用;可以使用文件查看命令直接读取此文件，其内容显示为两列，前者为统计属性，后者为对应的值。

```shell
/proc/meminfo
1 MemTotal: 所有内存(RAM)大小,减去—些预留空间和内核的大小。
2 MemFree: 完全没有用到的物理内存，lowFree+highFree。
3 MemAvailable: 在不使用交换空间的情况下，启动一个新的应用最大可用内存的大小，计算方式: MemFree+Active(file)+Inactive(file)-(watermark+min(watermark,Active(file)+Inactive(file)/2))。
4 Buffers: 块设备所占用的缓存页，包括: 直接读写块设备以及文件系统元数据(metadata)，比如superblock使用的缓存页。
5 cached: 表示普通文件数据所占用的缓存页。
6 SwapCached: swap cache中包含的是被确定要swapping换页，但是尚未写入物理交换区的匿名内存页。那些匿名页，比如用户进程malloc申请的内存页是没有关联任何文件的，如果发生swapping换页，这类内存会被写入到交换区。
7 Active: active包含active anon和active file。
8 Inactive: inactive包含inactive anon和inactive file。
9 Active( anon): anonymous pages(匿名页)，用户进程的内存页分为两种:与文件关联的内存页(比如程序文件，数据文件对应的内存页）和与内存无关的内存页(比如进程的堆栈，用malloc申请的内存)，前者称为file pages或mapped pages ,后者称为匿名页。
10 Inactive( anon): 见上
11 Active(file): 见上
12 Inactive(file): 见上
13 SwapTotal: 可用的swap空间的总的大小(swap分区在物理内存不够的情况下，把硬盘空间的一部分释放出来，以供当前程序使用).
14 SwapFree: 当前剩余的swap的大小。
15 Dirty: 需要写入磁盘的内存去的大小。
16writeback: 正在被写回的内存区的大小。
17 AnonPages: 未映射页的内存的大小。
18 Mapped: 设备和文件等映射的大小。
19 slab: 内核数据结构slab的大小。
20SReclaimable: 可回收的slab的大小。
21 SUnreclaim: 不可回收的slab的大小.
22 PageTables: 管理内存页页面的大小.
23 NFS_Unstable: 不稳定页表的大小
24VmallocTotal: vmalloc内存区的大小
25 VmallocUsed: 已用vmalloc内存区的大小
26vmallocchunk : vmalloc区可用的连续最大快的大小

```

内存使用率

```
free
1 total是总内存大小;
2 used是已使用内存的大小，包含了共享内存;
3 free是未使用内存的大小;
4 shared是共享内存的大小;
5 buff/cache是缓存和缓冲区的大小;
6 available是新进程可用内存的大小，available 不仅包含未使用内存，还包括了可回收的缓存，所以一般会比未使用内存更大。不过，并不是所有缓存都可以回收，因为有些缓存可能正在使用中。
```

Buffer和Cache

1. Buffer是对原始磁盘块的临时存储，也就是用来缓存磁盘的数据，通常不会特别大(20MB左右)。这样，内核就可以把分散的写集中起来，统一优化磁盘的写入，比如可以把多次小的写合并成单次大的写等等。
2. Cache是从磁盘读取文件的页缓存，也就是用来缓存从文件读取的数据。这样，下次访问这些文件数据时，就可以直接从内存中快速获取，而不需要再次访问缓慢的磁盘。
3. Buffer是对磁盘数据的缓存，而Cache是文件数据的缓存，它们既会用在读请求中，也会用在写请求中。

#### net

/proc/net(dev网络流入流出的统计信息，包括接收包的数量、发送包的数量，发送数据包时的错误和冲突情况等。

```
/proc/net
1 bytes:(接口发送或接收的数据的总字节数)
2 packets:(接发送或接收的数据包总数)
3 errs:(由设备驱动程序检测到的发送或接收错误的总数)
4 drop:(设备驱动程序丢弃的数据包总数)
5 fifo:(FIFO缓冲区错误的数量)
6 frame: T(分组帧错误的数量)
7 colls:(接口上检测到的冲突数)
8 compressed: (设备驱动程序发送或接收的压缩数据包数)
9 carrier:(由设备驱动程序检测到的载波损耗的数量)
10 multicast:(设备驱动程序发送或接收的多播帧数)

```

### stress 压测

主要用来模拟系统负载较高时的场景，本文介绍其基本用法。文中 demo 的演示环境为 ubuntu 18.04。

```
语法格式：
stress <options>

常用选项：
-c, --cpu N              产生 N 个进程，每个进程都反复不停的计算随机数的平方根
-i, --io N                  产生 N 个进程，每个进程反复调用 sync() 将内存上的内容写到硬盘上
-m, --vm N             产生 N 个进程，每个进程不断分配和释放内存
    --vm-bytes B      指定分配内存的大小
    --vm-stride B     不断的给部分内存赋值，让 COW(Copy On Write)发生
    --vm-hang N      指示每个消耗内存的进程在分配到内存后转入睡眠状态 N 秒，然后释放内存，一直重复执行这个过程
    --vm-keep          一直占用内存，区别于不断的释放和重新分配(默认是不断释放并重新分配内存)
-d, --hadd N           产生 N 个不断执行 write 和 unlink 函数的进程(创建文件，写入内容，删除文件)
    --hadd-bytes B  指定文件大小
-t, --timeout N       在 N 秒后结束程序      
--backoff N            等待N微妙后开始运行
-q, --quiet              程序在运行的过程中不输出信息
-n, --dry-run          输出程序会做什么而并不实际执行相关的操作
--version                显示版本号
-v, --verbose          显示详细的信息
```

### 参考

[Linux stress 命令 - sparkdev - 博客园 (cnblogs.com)](https://www.cnblogs.com/sparkdev/p/10354947.html)

[处理日期和时间的chrono库 | 爱编程的大丙 (subingwen.cn)](https://subingwen.cn/cpp/chrono/)

[44 | 套路篇：网络性能优化的几个思路（下） (geekbang.org)](https://time.geekbang.org/column/article/84003)
