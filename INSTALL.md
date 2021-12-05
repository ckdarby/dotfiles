# Installation

## Packages

### Common packages

```shell
sudo apt-get install git curl automake make apt-transport-https wget texinfo linux-headers-$(uname -r)
```

### Terminal

```shell
sudo apt-get install zsh fonts-font-awesome fonts-powerline
```

### Oh my zsh

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

#### p10k

```shell
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
```

#### Fuzzy finder

```shell
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```


### i3wm

#### Installation

**Older version**

```shell
sudo apt-get install i3
```

**Latest stable**

[Instructions here](https://i3wm.org/docs/repositories.html)

#### i3 "addons"

```shell
sudo apt-get install i3lock i3blocks
```


#### Rofi Dmenu Replacement

**Required packages**
```shell
sudo apt-get install debhelper dh-autoreconf bison flex libpango1.0-dev libstartup-notification0-dev libxkbcommon-dev libxkbcommon-x11-dev libxcb1-dev libxcb-xkb-dev libxcb-xinerama0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-randr0-dev libxcb-util0-dev librsvg2-dev libxcb-xrm-dev
```

**Installation**

Installing from source can be found, [here](https://github.com/davatorium/rofi/blob/next/INSTALL.md)

*If newer version of libcheck required installing from source can be found, [here](https://github.com/libcheck/check).*


####  Fix Nautilus

```shell
gsettings set org.gnome.desktop.background show-desktop-icons false
```

### Bluetooth
```shell
sudo apt-get install blueman
```

## Linking dotfiles to config

```shell
ln -s ~/dotfiles/i3 ~/.config/
ln -s ~/dotfiles/i3blocks ~/.config/
ln -s ~/dotfiles/i3lock ~/.config/
ln -s ~/dotfiles/p10k ~/.config/
ln -s ~/dotfiles/rofi ~/.config/
ln -s ~/dotfiles/dunst ~/.config/
```
