# 晶晨s9xxx设备使用的ArchLinux ARM
**本项目不是ArchLinuxARM的官方发行，而是预构建的可刷写并启动的用于晶晨平台的普通s9xxx盒子的镜像，项目存在的原因是有很多需要对内核作出的没有合并到官方仓库用的主线内核的修改**

## 信息

**请仅使用本项目提供的镜像作为用pacstrap安装另一个ArchLinuxARM的live环境，而不是日常系统。预定义的ArchLinux带来的不是真正的ArchLinux的体验。为了让镜像能启动，我替你做了不少配置和包上的决定，而这些决定恐怕不是你真的想在你的系统上所要的。参考[我博客上的安装指南][alarm guide on blog]来了解怎么在晶晨平台上以Arch的方式安装**

[alarm guide on blog]: https://7ji.github.io/embedded/2022/11/08/alarm-install.html

## 安装

### 驱动器
建议安装在USB驱动器上，然后可以参考[alarm-install][alarm guide on blog]使用**ArchLinux的方式**来安装到eMMC或者另一个USB驱动器/SD卡上

### 发行与镜像
所有的Amlogic s9xxx设备**共用同一个通用镜像**，也就是说镜像里**没有设置默认的u-boot.ext和dtb**，你必须根据你的设备设置。并请注意dtb需要在``uEnv.txt``和``extlinux/extlinux.conf``里一并设置

有三种类型的发布可用
 - `ArchLinuxARM-aarch64-Amlogic-*.img.xz`就和你能在Armbian和Openwrt项目里找到的普通镜像一样，只要解压后写到SD卡或者是USB驱动器上就能用。布局是写死的，不过也因此很简单，因为你不需要担心分区的问题。
 - ``ArchLinuxARM-aarch64-Amlogic-*-root.tar.xz`` 是压缩过的根文件系统的归档，可以把它解压到已经分区过的盘里，这样你就可以自由地决定分区布局和大小了，不过你需要根据你的实际分区来更新``/etc/fstab``, ``/boot/uEnv.txt``, ``/boot/extlinux/extlinux.conf``。用下面这条命令来提取归档：
    ```
    bsdtar -C /your/root --acls --xattrs -xvpf /the/archive.tar.xz
    ```
 - `ArchLinuxARM-aarch64-Amlogic-*-pkgs.tar.xz`是压缩过的构建并安装到上面镜像里的AUR包。如果你升级的时候不想自己构建，你可以下载、解压，再用`pacman -U`安装里面现成的包。你也可以用这些包来`pacstrap`一个安装

### 启动配置
当你写入镜像以后，你应该打开FAT32的卷标是`ALARMBOOT`的第一个/启动分区分区，然后做以下调整
 - 在`uboot`文件夹中找到对应的u-boot，把它改名为``u-boot.ext``复制或移动到这个分区的根目录。然后如果你想节约空间的话，你可以放心地把`uboot`文件夹删掉
 - 编辑``uEnv.txt``，把这行
    ```
    FDT=/dtbs/linux-aarch64-flippy/amlogic/PLEASE_SET_YOUR_DTB.dtb
    ```
    根据你实际的设备和``/dtbs/linux-aarch64-flippy/amlogic``下对应的文件修改。比如，HK1Box应该改成：
    ```
    FDT=/dtbs/linux-aarch64-flippy/amlogic/meson-sm1-hk1box-vontar-x3.dtb
    ```
 - 相似地，编辑``extlinux/extlinux.conf``，把这行
    ```
    FDT     /dtbs/linux-aarch64-flippy/amlogic/PLEASE_SET_YOUR_DTB.dtb
    ```
    以相同的思路改成像这样
    ```
    FDT     /dtbs/linux-aarch64-flippy/amlogic/meson-sm1-hk1box-vontar-x3.dtb
    ```
### 启动
按住重置键，保持SD卡/USB驱动器插入，给盒子上电，就和你在Armbian和Openwrt上那样做的一样

### 连接

#### 网络
默认情况下`systemd-networkd.service`和`systemd-resolved.service`都已启用，DHCP在`en*` 和 `eth*`上启动，你可以到你的路由器上去查询盒子的IP

#### SSH
默认情况下`sshd.service`已启用，且允许root登录，root的密码是`alarm_please_change_me`

#### 用户
默认情况下，有一个组为`wheel`的用户`alarm`，可以在输入密码后使用`sudo`。这个用户的密码是`alarm_please_change_me`

### 升级
#### 包
建议你开机后立即进行一次全局升级：
```
sudo pacman -Syu
```
或者（不带任何参数的``yay``隐式调用``sudo pacman -Syu``）
```
yay
```
#### 初始化内存盘
并立即生成初始化内存盘，因为为了节约空间，只有u-boot传统内存盘的回落镜像被保留，其他三个初始化内存盘都在打包前删掉了（标准默认配置，标准回落配置和传统默认配置）
```
mkinitcpio -P
```
根据你的启动配置，你可以选择是否保留u-boot传统初始化内存盘：https://7ji.github.io/embedded/2022/11/11/amlogic-booting.html. 
 - 如果你使用标准的初始化内存盘，你能省出两个初始化内存盘的空间，你需要用``/boot/extlinux/extlinux.conf``作为配置文件
    - 删除`/boot/boot.scr`和`/boot/uEnv.txt`
    - ``/boot/extlinux/extlinux.conf``里面的这一行需要更新
      ```
      INITRD  /initramfs-linux-aarch64-flippy-fallback.uimg
      ```
      成这样
      ```
      INITRD  /initramfs-linux-aarch64-flippy.img
      ```
      生成传统内存镜像的钩子可以被移除
      ```
      pacman -R uboot-legacy-initrd-hooks
      ```
 - 如果你想要继续用uboot传统内存盘的话，你需要注意传统内存盘额外占用的空间  
   - 我的AUR包[uboot-legacy-initrd-hooks](https://aur.archlinux.org/packages/uboot-legacy-initrd-hooks)提供的钩子会自动把初始化内存盘转换为u-boot传统内存盘，默认已经预装  
   - 在你自己不经过钩子手动更新初始化内存盘的情况下（比如，手动运行``mkinitcpio -P``），记得调用脚本也把传统内存盘更新
      ```
      img2uimg
      ```

## 构建
构建脚本**必须在装有ArchLinux ARM自己或者是Manjaro ARM等衍生发行版的AArch64设备上原生运行**，因为有的AUR包需要被原生构建，并且包管理器Pacman也应且仅应当该被原生运行来安装它们还有其他的必要包。除非你想整一堆包管理器追踪不到的文件（**非常危险，而且根本不是Arch的风格**），不然这就是正确的唯一路子。

你可以用这里的镜像或者照着[我博客上的文章](https://7ji.github.io/embedded/2022/11/08/alarm-install.html) 来从头自举一个可以工作的ArchLinux ARM安装来当作构建环境

记得提前根据[ArchWiki上的文档][Arch Wiki distcc]设置好distcc，用其他更强大的机子（比如说你的x86-64的服务器）作为构建志愿者。AArch64设备本身太弱了，单纯用它们构建很慢。

首次构建前，确保这些构建依赖已经安装
```
sudo pacman -Syu arch-install-scripts \
                 base-devel \
                 dosfstools \
                 git \
                 go \
                 parted \
                 uboot-tools \
                 xz \
                 wget 
```

克隆仓库的时候，记得先注册所有的子模块并更新。不然的话AUR包会因为找不到``PKGBUILD``而构建失败。选项`--recursive`可以自动在克隆期间处理这些琐事
```
git clone --recursive https://github.com/7Ji/amlogic-s9xxx-archlinuxarm.git
```

_拉取更新时，也需要用`git submodule update`来更新子模块_
```
git pull
git submodule init
git submodule update
```

当你本地的仓库就绪后，只需要一条简单的``./build.sh``就能构建镜像了
```
./build.sh
```
或者你更喜欢在前面加上对应的shell的话（必须设置 **`-e`** 标志）
```
bash -e build.sh
```
_这个脚本应当以一个能用`sudo`的用户的身份运行，因为它会通过`sudo`运行一些高风险的命令，而不是一直作为`root`运行，如果以`root`身份或者是通过`sudo`，脚本会拒绝工作。如果你要让脚本在后台运行的话，你可能需要在`sudoers`里添加以下选项来取消超时：_
```
Defaults passwd_timeout=0
```

你可以设置一些环境变量来决定行为
 - ``compressor``
   - 压缩程序的执行文件名以及可选的参数（比如，`gzip`就是用gzip以默认选项压缩，`xz -9e`就是用xz以最大压缩率压缩）
   - 如果设置为no，归档和镜像不会被压缩。那样的话你就能在比如说你强大的x86-64主机上来压缩

## 来源

释放到``/boot/uboot``的u-boot是在构建过程中自[ophub的 Armbian仓库][Armbian u-boot overload]下载的

``/boot``下的脚本和配置也是从[ophub的Armbian仓库][Armbian boot common]修改适配而来，不过直接在这里维护


包[ampart-git][AUR ampart-git], [linux-aarch64-flippy-bin][AUR linux-aarch64-flippy-bin], [linux-firmware-amlogic-ophub][AUR linux-firmware-amlogic-ophub] and [uboot-legacy-initrd-hooks][AUR uboot-legacy-initrd-hooks]均为我维护的AUR包

包[yay][AUR yay]为其作者维护的AUR包

[Arch Wiki distcc]: https://wiki.archlinux.org/title/Distcc#Arch_Linux_ARM_as_clients_(x86_64_as_volunteers)

[Armbian u-boot overload]: https://github.com/ophub/amlogic-s9xxx-armbian/tree/main/build-armbian/amlogic-u-boot/overload
[Armbian boot common]: https://github.com/ophub/amlogic-s9xxx-armbian/blob/main/build-armbian/amlogic-armbian/boot-common.tar.xz


[AUR ampart-git]: https://aur.archlinux.org/packages/ampart-git
[AUR linux-aarch64-flippy-bin]: https://aur.archlinux.org/packages/linux-aarch64-flippy-bin
[AUR linux-firmware-amlogic-ophub]: https://aur.archlinux.org/packages/linux-firmware-amlogic-ophub
[AUR uboot-legacy-initrd-hooks]: https://aur.archlinux.org/packages/uboot-legacy-initrd-hooks
[AUR yay]: https://aur.archlinux.org/packages/yay