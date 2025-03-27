#! /bin/bash

clear

reset() {
  echo -e "\e[0m"
}

scroll() {
   perl -pe "system 'sleep .05'"
}

cmd() {
  echo -e "\e[1;32m"
  read -p "\$ $1"$'\n'
  echo -e "\e[1;33m"
  bash -c "$1" | scroll
  reset
}

wait() {
  read -p ''
}

slide() {
  echo
  read -p ''
  clear
  tput cup 5
  echo
}

echo -e "\e[1;36m"
echo -----------------------------------------------------------------------------------------------------------------------------
echo ------------------------------------------- Systemd: Running stuff on the ground --------------------------------------------
echo -----------------------------------------------------------------------------------------------------------------------------
reset

wait

echo '"Lennart Poettering and Kay Sievers, the software engineers then working for Red Hat who initially developed systemd,[2] started a project to replace Linux'\''s conventional System V init in 2010.[17] An April 2010 blog post from Poettering, titled "Rethinking PID 1", introduced an experimental version of what would later become systemd."'
echo '-- https://en.wikipedia.org/wiki/Systemd'

wait

echo 'Systemd is said to be a "cancer" which little by little eats all Linux subsystems inside itself.'
sleep 1
echo ' - true. Far from the famous "do only one thing (and do it well)".'
sleep 1
echo ' - on the other hand, it'\''s quite good and versatile.'

slide

echo 'Systemd handles the boot process.'
echo 'It can provide some statistics about how the boot went:'

cmd 'systemd-analyze time'

wait

echo 'or the most time consuming parts:'
cmd 'systemd-analyze blame'

wait

echo 'or print dependency graphs:'
cmd "nix-shell -p graph-easy --run 'systemd-analyze dot dbus.service | graph-easy'"

slide

echo 'Systemd has its own top utility to see how much different units consume resources:'
cmd 'systemd-cgtop --cpu=time --depth=6 --batch --iterations=1'

slide

echo 'A basic building block in systemd is a "unit". They can be of different types:'
echo
echo '| *Unit Type* | *Description*'
echo '|             |'
echo '| Target      | It is a group of units that defines a synchronization point.'
echo '|             |   Linux uses the synchronization point to start the system in a particular state at the boot time.'
echo '| Service     | A service unit starts, stops, restarts or reloads a service daemon such as Apache webserver.'
echo '| Socket      | A socket unit activates a service when the service receives incoming traffic on a listening socket.'
echo '| Device      | A device unit implements device-based activation, such as a device driver.'
echo '| Mount       | A mount unit controls the mount point of the file system.'
echo '| Automount   | An automount unit provides and controls on-demand mounting of file systems.'
echo '| Swap        | A swap unit activates and deactivates the swap partition.'
echo '| Path        | A path unit monitors files and directories.'
echo '|             |   It activates and deactivates a service if the specified file or directory is accessed.'
echo '| Timer       | A timer unit activates and deactivates a service based on a timer or when a time has elapsed.'
echo '| Snapshot    | A snapshot unit creates and saves the current state of all running units'
echo '|             |   that we can use to restore the system later.'
echo '| Slice       | It is a group of units. It manages system resources such as CPU and memory.'
echo '| Scope       | A scope unit organizes and manages foreign processes.'
echo '| Busname     | A bus unit controls the DBus system.'
echo
echo '-- https://www.computernetworkingnotes.com/linux-tutorials/systemd-units-explained-with-types-and-states.html'

slide

echo "Let's see some of what we have here:"
cmd 'systemctl list-units --all | shuf -n10'

wait

echo 'Default systemd configuration can be seen in the disk:'
cmd 'ls /lib/systemd/system | head -n10'

wait

echo 'System default configuration is usually under /etc:'
cmd 'ls /etc/systemd/system'

slide

read -r -d '' service <<EOF
#!/bin/sh
for i in \$(seq 1 10)
do
  echo "ticking..."
  echo "." >> /tmp/ticks
  sleep 1
done
EOF

read -r -d '' minimal <<EOF
[Unit]
Description=My minimal service

[Service]
ExecStart=$HOME/minimal-service.sh
StandardOutput=journal

[Install]
WantedBy=default.target
EOF

echo "Systemd user units are stored under $HOME/.config/systemd/user/"
cmd "mkdir -p $HOME/.config/systemd/user"

echo "Let's create a minimal service:"
cmd "echo '$service' > $HOME/minimal-service.sh"
cmd "chmod u+x $HOME/minimal-service.sh"

echo '...and a unit config:'
cmd "echo '$minimal' > $HOME/.config/systemd/user/minimal.service"

echo 'Let systemd know that there are changes:'
cmd 'systemctl --user daemon-reload'

echo 'We can enable the unit to be started on boot:'
cmd 'systemctl --user enable minimal'

echo "...but let's just start it now:"
cmd 'systemctl --user start minimal'

echo "We can see it's ticking:"
cmd 'for i in $(seq 1 5); do { wc -l /tmp/ticks; sleep 1; }; done'

slide

echo "You don't need root to run systemd units. Just do as we just did:"
sleep 1
echo ' - add "--user" switch to commands'
sleep 1
echo " - put config under '$HOME/.config/systemd/user/'"

wait 

echo 'But now if we leave the shell and come back, it will stop!'
sleep 1
echo ' - when we exit the shell, all our processes die'
sleep 1
echo ' - enable linger for yourself to make systemd keep them running in the background:'
sleep 1
cmd "sudo loginctl enable-linger $USER"

slide

echo 'Systemd contains a logging facility, "journald"'
sleep 1
echo ' - binary format'
sleep 1
echo ' - indexed'

wait

echo 'See "/etc/systemd/journald.conf" for settings, like storage capacity:'
cmd 'cat /etc/systemd/journald.conf | head -n30'

wait

echo 'Messages can be logged in many ways, including programming language libraries, but we can just use system logger:'
cmd 'logger -t sometag "Hello devs!"'

echo '...and read with many tools, including monitoring software like Netdata, but we can just use journalctl command:'
cmd 'journalctl -t sometag'

wait

echo "Let's check what our minimal unit has logged:"
cmd 'journalctl --user-unit minimal --no-pager'

echo '...or check kernel messages, in json format:'
cmd 'sudo journalctl -k -o json'

echo '..well, nothing there on my test setup.'
echo 'Or show logs since yesterday. Journalctl is quite a versatile tool to search the logs.'
cmd 'journalctl --since yesterday --no-pager'

slide

echo 'Containers are pop when you need to run stuff from third parties, or just stuff with complex dependencies.'
echo 'Systemd can of course run also containers. Benefits include:'
sleep 1
echo ' - automatic startup on boot'
sleep 1
echo ' - manage inter-service dependencies'
sleep 1
echo ' - control logging'

wait

read -r -d '' container <<EOF
[Unit]
Description=Hello container
After=podman.service
Requires=podman.service

[Service]
Type=oneshot
ExecStart=podman run --rm --name %n quay.io/podman/hello
EOF

echo 'Create config:'
cmd "echo '$container' > $HOME/.config/systemd/user/container.service"

echo 'Load it and start the service:'
cmd "systemctl --user daemon-reload"
cmd "systemctl --user start container"

echo 'Yep, it has executed:'
cmd 'journalctl --user-unit container --no-pager'

wait

echo 'You can even use Podman to generate the systemd unit configuration for an existing container:'
cmd 'podman run --name hello quay.io/podman/hello >/dev/null && podman generate systemd --new --name hello'

slide

echo 'Systemd supports socket activation, which is a way to start services on demand.'
echo 'We can for example configure Nginx to pass CGI/FCGI requests to a specified socket, which activates a service through systemd.'

wait

echo 'But why?'
sleep 1
echo ' - we can restart the web server or the FastCGI application without restarting the other.'
sleep 1
echo ' - we can run them in different chroots or use any other limits provided by systemd.'
sleep 1
echo ' - systemd can stop the service after a while of inactivity, saving resources.'
echo

wait

prefix="$(nix-shell -p nginx which --run 'dirname $(dirname "$(which nginx)")')"
read -r -d '' nginx <<EOF
pid /tmp/nginx.pid;
error_log /tmp/nginx-error.log;
http {
    error_log /tmp/nginx-error.log;
    access_log /tmp/nginx-access.log;
    include $prefix/conf/mime.types;
    server {
        listen 8080;
        location /my-app { 
          fastcgi_pass unix:/tmp/my-app.sock;
          include      $prefix/conf/fastcgi_params;
        }
    }
}
events {}
EOF

read -r -d '' nginx_service <<EOF
[Service]
Type=forking
PIDFile=/tmp/nginx.pid
PrivateDevices=yes
SyslogLevel=err

ExecStart=/bin/sh -c ". /etc/profile.d/nix.sh; nix-shell -p nginx --run \"nginx -c $HOME/nginx.conf\""
ExecReload=/bin/sh -c ". /etc/profile.d/nix.sh; nix-shell -p nginx --run \"nginx -s reload\""
KillMode=mixed
EOF

echo "Let's create a basic nginx config:"
cmd "echo '$nginx' > $HOME/nginx.conf"

echo "...create nginx service:"
cmd "echo '$nginx_service' > $HOME/.config/systemd/user/nginx.service"

echo "...and run nginx web server:"
cmd "systemctl --user daemon-reload && systemctl --user start nginx"

read -r -d '' my_app_socket <<EOF
[Unit]
Description=My app socket

[Socket]
ListenStream=/tmp/my-app.sock
Accept=false
EOF

echo 'and then create a socket for your FastCGI application.'
echo 'Accept=false makes this FastCGI: the app is started only on first requests, and the subsequent requests go to the same instant.'
cmd "echo '$my_app_socket' > $HOME/.config/systemd/user/my-app.socket"

read -r -d '' my_app <<EOF
#! /usr/bin/env nix-shell
#! nix-shell -i runhaskell -p "haskellPackages.ghcWithPackages (pkgs: [pkgs.time pkgs.fastcgi])"
module MyApp where
import Data.Time
import Network.FastCGI
main = do
  started <- getCurrentTime
  runFastCGIorCGI $ do
    setHeader "Content-type" "text/plain"
    output $ "Hello devs! I was started at " ++ show started
EOF

echo "Now create the actual app. Let's write this in Haskell, because why not:"
cmd "echo '$my_app' > $HOME/my-app.sh"
cmd "chmod u+x $HOME/my-app.sh"

read -r -d '' my_app_service <<EOF
[Unit]
Description=My app

[Service]
Type=oneshot
ExecStart=/bin/sh -c ". /etc/profile.d/nix.sh; $HOME/my-app.sh"
StandardInput=socket
TimeoutStartSec=5
EOF

echo 'and the systemd unit for the service whose input is the socket:'
cmd "echo '$my_app_service' > $HOME/.config/systemd/user/my-app.service"

echo "reload and start the socket to wait for connections:"
cmd "systemctl --user daemon-reload && systemctl --user start my-app.socket"

echo 'Now test it actually works:'
cmd 'curl --silent http://localhost:8080/my-app'

echo
echo '...and again...'
echo 
cmd 'curl --silent http://localhost:8080/my-app'

echo
echo '...and now wait >5 seconds and then again...'
cmd 'sleep 7 && curl --silent http://localhost:8080/my-app'

slide

read -r -d '' hello <<EOF
#! /bin/sh
echo "Hi there, devs!"
EOF

read -r -d '' hello_service <<EOF
[Service]
ExecStart=$HOME/hello.sh
StandardOutput=journal
EOF

read -r -d '' timer <<EOF
[Unit]
Description=Periodic hello

[Timer]
Unit=hello.service
OnActiveSec=1
OnUnitInactiveSec=1
RandomizedDelaySec=3
AccuracySec=1

[Install]
WantedBy=timers.target
EOF

echo 'Cron is great and all, but systemd can act as even better cron.'
echo "Create a simple hello app:"
cmd "echo '$hello' > $HOME/hello.sh && chmod u+x $HOME/hello.sh"

echo "and a unit:"
cmd "echo '$hello_service' > $HOME/.config/systemd/user/hello.service"

echo "and then a timer for it:"
cmd "echo '${timer}' > $HOME/.config/systemd/user/hello.timer"

echo 'Start the timer:'
cmd 'systemctl --user daemon-reload && systemctl --user start hello.timer'

echo 'See the currently existing timers:'
cmd 'systemctl --user --all list-timers'

echo 'Check if our timer is actually executing:'
cmd 'journalctl --user-unit hello.service --no-pager'

wait

echo 'If you should need to, you can also run a timed command without any kind of unit file:'
cmd 'systemd-run --user sh -c "echo moi > /tmp/foo"'

echo '...and see that it appears:'
cmd 'sleep 2 && cat /tmp/foo'

slide

read -r -d '' slice <<EOF
[Unit]
Description=Limited cpu and mem
Before=slices.target

[Slice]
CPUQuota=20%
MemoryLimit=1.2G
EOF

echo 'Systemd can impose various limits on units.'
echo
echo 'We can also create resource groups called "slices" to create a shared resource pool for a bunch of services:'
cmd "echo '${slice}' > $HOME/.config/systemd/user/my-limited.slice"

echo 'and then use it for a service in the unit config like this:'
echo '[Service]'
echo 'Slice=my-limited.slice'
echo

echo "but let's not try it this time. Homework for you!"

wait

echo 'We can also ask it how the security of a service looks:'
cmd 'systemd-analyze --user security hello.service --no-pager'

echo 'UNSAFE!?! Oh my, such secure by default...'

slide

echo "We've only scratched the surface of what systemd can do."
echo 'Here are some more resources:'
sleep 1
echo ' - https://systemd.io'
sleep 1
echo ' - https://www.freedesktop.org/software/systemd/man/latest/systemd.html'
sleep 1
echo ' - https://www.goodreads.com/book/show/60733716-linux-service-management-made-easy-with-systemd'
sleep 1
echo ' - these slides: https://github.com/jyrimatti/systemd'

wait

echo
echo 'Thank you for interest!'
echo
echo 'Remember to keep your feet on the ground ;)'
wait