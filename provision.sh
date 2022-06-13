#! /bin/bash

# 最新のパッケージ情報を撮っておく。
emerge-webrsync

# openrcの形で一度emerge worldしておく。profileをいじる前にはしたほうが混乱が少ない。 
emerge -DNu @world
emerge --depclean

# debugするならここで vagrant snapshot saveとしておく。

# # systemdのオプションを有効にしてカーネルの再構築

# # カーネルオプション設定
# # ここは今の所手動でないと無理。
# # 実際にカーネルオプションを変更してから.configの差分を見て、
# # sedでビルド自動化用のスクリプトを書く。
# cd /usr/src/linux && make menuconfig

# systemdインストール時に/usr/src/linuxのカーネルコンフィグを見るので
# 必ず先にkernelの方をビルドする必要がある。
# カーネルオプションでsystemdを有効にする。
sed -i 's/# CONFIG_GENTOO_LINUX_INIT_SYSTEMD is not set/CONFIG_GENTOO_LINUX_INIT_SYSTEMD=y/' /usr/src/linux/.config
# openrcの無効化。特にしなくても良い。気になるなら。なくせばカーネルのビルド自体は早くなるかもだが、本番サーバーでやるのは
# 考えたほうがいい。openrcに戻すときにまたカーネルビルドが必要になるため。
# カーネルオプションでopenrcを無効にする。
# sed -i 's/CONFIG_GENTOO_LINUX_INIT_SCRIPT=y/# CONFIG_GENTOO_LINUX_INIT_SCRIPT is not set/' /usr/src/linux/.config
cd /usr/src/linux
# 前のゴミが残っている可能性があるので、削除してからカーネルビルド
make clean
make 
make modules_install
make install

# 共有ライブラリの更新
ldconfig

# vagrant snapshot save

# systemdの起動があるところに飛ぶ。
targetrow_num=$(grep GRUB_CMDLINE_LINUX= -n /etc/default/grub | grep systemd | sed 's/:.*$//')
sed -i "${targetrow_num} s/# //" /etc/default/grub

# ビルドしたkernelをインストールしておく。
grub-mkconfig -o /boot/grub/grub.cfg

# 競合するので、openrcを最初にdeselectでdepclean候補にしておく。
emerge --deselect sys-apps/openrc

# アーキテクトを変えずにinitシステムだけsystemdにする。
profile_num=$(eselect profile list | grep "/17.1/no-multilib/systemd (dev)" | sed 's/\].*$//' | rev | sed 's/\[.*$//' | rev)

eselect profile set $profile_num

# systemdにして組み直し。
emerge -DNu @world

# systemdのネットワークの設定
cat << END >> /etc/systemd/network/eth0.network
[Match]
Name=eth0

[Network]
DHCP=both
END

cat << END >> /etc/systemd/network/enp0s3.network
[Match]
Name=enp0s3

[Network]
DHCP=both
END

# systemdは再起動するまで有効じゃないので、
# シンボリックリンクを作るとenableになる。

# 最低限必須なサービスのネットワークとsshdをインストール

# systemdのデフォルトのネットワーク管理の systemd networkdを使う。
# profileをsystemdにしてると勝手に入ってくる。
# 両方立ち上げる必要がある。
mkdir /etc/systemd/system/network-online.target.wants
ln -s /lib/systemd/system/systemd-networkd-wait-online.service /etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service
ln -s /lib/systemd/system/systemd-networkd.service /etc/systemd/system/multi-user.target.wants/systemd-networkd.service

# sshd serviceを有効化
ln -s /lib/systemd/system/sshd.service /etc/systemd/system/multi-user.target.wants/sshd.service

## 最低限ではないが、openrc時にインストールされていたから移行にいる。

# rsyslog
ln -s /lib/systemd/system/rsyslog.service /etc/systemd/system/multi-user.target.wants/rsyslog.service

# sysstat
ln -s /lib/systemd/system/sysstat.service /etc/systemd/system/multi-user.target.wants/sysstat.service

# virtualbox-guest-additions.service
ln -s /lib/systemd/system/virtualbox-guest-additions.service /etc/systemd/system/multi-user.target.wants/virtualbox-guest-additions.service
# カーネルを再ビルドしたので、新しいカーネルが動作したときに適切な
# カーネルモジュールが読み込まれている必要あり。
# カーネルモジュールは再起動後に読み込んでもいいが、systemdに管理させておくと勝手に読み込んでくれる。
# gentoo は開発時にカーネルビルドをよく行うのでsystemd管理の方が楽。
echo '# install virtualbox kernel module' >> /etc/modules-load.d/vboxguest.conf
echo vboxguest >> /etc/modules-load.d/vboxguest.conf

# その他カールを再ビルドしたので、必要なカーネルモジュールの読み込みあれば書く。

emerge --depclean
# defrag
dd if=/dev/zero of=/EMPTY bs=1M; rm -f /EMPTY
