# gentoo_systemd_box

gentoo install systemd is very difficult for gentoo biginner user.

this box is building systemd only execute vagrant up command.

## time

build time 2016 mac book pro
4 hour.

## Vagrantfile

check cpu core num and memory.

this vagrant box processing heaby.

assign specific value!

```ruby
    vb.cpus = 4
    # Customize the amount of memory on the VM:
    vb.memory = "8192"
```

## build

```bash
vagrant up

# sysstemdの環境を読み込み。
vagrant reload

# 停止
vagrant halt

# 再利用のためパッケージ化
vagrant package --output out/gentoo_systemd.box

# check sum upload時に必要。
sha256sum out/gentoo_systemd.box | cut -d ' ' -f 1

OtogawaKatsutoshi/Gentoo_systemd 

```

## version

build date v{yyyy.mm.dd}.

[openrcとsystemdのサービス対応](https://wiki.gentoo.org/wiki/Systemd/ja)
