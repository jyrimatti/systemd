#! /bin/bash

if [ "$1" == "stop" ]; then
  podman stop systemd-ubuntu && podman rm systemd-ubuntu
else
  podman run -d --name systemd-ubuntu --privileged -v=$PWD:/home/ubuntu/systemd jrei/systemd-ubuntu
  podman exec -it systemd-ubuntu apt -y update
  podman exec -it systemd-ubuntu apt -y install curl xz-utils sudo podman
  podman exec -it systemd-ubuntu curl -L https://nixos.org/nix/install -o install-nix
  podman exec -it systemd-ubuntu sh ./install-nix --daemon --yes
  podman exec -it systemd-ubuntu sh -c "echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
  podman exec -it systemd-ubuntu su - ubuntu -c "nix-shell -p which graph-easy nginx podman 'haskellPackages.ghcWithPackages (pkgs: [pkgs.time pkgs.fastcgi])' --run 'echo'"
  podman exec -it systemd-ubuntu su - ubuntu
fi