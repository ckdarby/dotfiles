# Installation

## Packages

```shell
sudo apt-get install \
  acpi alsa-utils blueman curl dunst fonts-font-awesome fonts-powerline git \
  imagemagick i3 i3blocks i3lock jq libnotify-bin network-manager-gnome \
  pulseaudio-utils sysstat terminator texinfo wget wireplumber xsettingsd zsh
```

## Shell extras

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
git clone --depth=1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```

## Link configs

```shell
mkdir -p ~/.config ~/.ssh ~/.config/systemd/user

for name in i3 i3blocks i3lock p10k rofi dunst ssh; do
  ln -sfn "$HOME/dotfiles/$name" "$HOME/.config/$name"
done

grep -qxF "Include ~/dotfiles/ssh/*_conf" ~/.ssh/config 2>/dev/null \
  || echo "Include ~/dotfiles/ssh/*_conf" >> ~/.ssh/config
```

## Enable user services

```shell
for service in obs-audio-router streamcontroller xsettingsd huiontablet; do
  ln -sf "$HOME/dotfiles/systemd/user/$service.service" "$HOME/.config/systemd/user/$service.service"
done

systemctl --user daemon-reload
systemctl --user enable --now \
  obs-audio-router.service \
  streamcontroller.service \
  xsettingsd.service \
  huiontablet.service
```
