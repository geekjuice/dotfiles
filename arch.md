# arch linux

## installation

1. follow https://wiki.archlinux.org/index.php/installation_guide

2. use `parted` instead of `fdisk` and create swap space later if needed

  ```
  parted /dev/sda

  mklabel  msdos
  mkpart  primary  ext4  0%  100%
  set 1 boot on
  print
  quit
  ```

  __note__: format using `mkfs.ext4` on `/dev/sda1`

3. use us mirror list

  `https://www.archlinux.org/mirrorlist/?country=US&protocol=https&ip_version=4`

4. use `systemctl enable dhcpcd.service` for network configuration

5. install bootloader e.g. grub

  ```
  pacman -S intel-ucode
  pacman -S grub
  grub-install --target=i386-pc /dev/sda
  grub-mkconfig -o /boot/grub/grub.cfg
  ```

## post-installation

1. setup non-root user with sudo

  ```
  useradd -m -g users -s /bin/bash nick
  passwd nick

  # in /etc/sudoers
  nick ALL=(ALL) NOPASSWD: ALL
  ```

2. install packages

  ```
  pacman -S net-tools pkgfile base-devel cava openssh vim zsh...
  ```

3. install gui

  ```
  pacman -S xorg xorg-server xorg-apps i3 ttf-hack feh rofi...
  ```

4. update `~/.xinitrc`

  ```
  # update keyboard rate
  xset r rate 200 30

  # run i3
  exec i3
  ```

5. setup directory for packages

  ```
  mkdir ~/packages # or similar...
  ```

6. install `st`

  ```
  cd ~/packages
  git clone https://git.suckless.org/st
  make clean install
  ```

  __note__: copy `config.h` from dotfiles

7. install aur packages

  ```
  cd ~/package
  git clone https://aur.archlinux.org/yay.git
  git clone https://aur.archlinux.org/spotify.git

  # etc...
  cd spotify
  makepkg -is
  ```

## notes

- update `install.sh` for arch and automate
- add linux vs mac switched e.g. `/usr/opt/...` vs `/usr/share`

