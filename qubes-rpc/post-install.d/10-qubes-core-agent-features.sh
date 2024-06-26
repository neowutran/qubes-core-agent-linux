#!/bin/sh

# announce features supported by this template

version=$(grep "^[0-9]" /usr/share/qubes/marker-vm | head -1)
qvm-features-request "qubes-agent-version=$version"

if [ -r /etc/os-release ]; then
    distro=$(grep ^ID= /etc/os-release)
    distro=${distro#ID=}
    if [ -f /usr/share/kicksecure/marker ]; then
        distro="kicksecure"
    fi
    if [ -f /usr/share/whonix/marker ]; then
        distro="whonix"
    fi
    qvm-features-request os-distribution="$distro"

    version=$(grep ^VERSION_ID= /etc/os-release)
    version=${version#VERSION_ID=}
    version=${version#\"}
    version=${version%\"}
    if [ "$distro" = "whonix" ]; then
        version=$(cat /etc/whonix_version)
    elif [ "$distro" = "kicksecure" ]; then
        version=$(cat /etc/kicksecure_version)
    fi
    qvm-features-request os-version="$version"

    eol=$(grep ^SUPPORT_END= /etc/os-release)
    eol=${eol#SUPPORT_END=}
    # Debian/Ubuntu have it elsewhere:
    if [ -z "$eol" ] && [ -f "/usr/share/distro-info/$distro.csv" ]; then
        # debian: version,codename,series,created,release,eol,eol-lts,eol-elts
        # ubuntu: version,codename,series,created,release,eol,eol-server,eol-esm
        eol=$(grep "^$version," "/usr/share/distro-info/$distro.csv" | cut -f 6 -d ,)
    fi
    qvm-features-request os-eol="$eol"
fi

qvm-features-request qrexec=1
qvm-features-request os=Linux
qvm-features-request vmexec=1

if [ -x /usr/bin/qubes-gui ]; then
    qvm-features-request gui=1
fi

if systemctl -q is-enabled qubes-firewall.service 2>/dev/null; then
    qvm-features-request qubes-firewall=1
else
    qvm-features-request qubes-firewall=0
fi

qvm-features-request supported-service.meminfo-writer=1

if [ -e /etc/xdg/autostart/blueman.desktop ]; then
    qvm-features-request supported-service.blueman=1
fi

# native services plugged into qubes-services with systemd drop-ins, list them
# only when actual service is installed
advertise_systemd_service() {
    qsrv=$1
    shift
    for unit in "$@"; do
        if systemctl -q is-enabled "$unit" 2>/dev/null; then
            qvm-features-request supported-service."$qsrv"=1
        fi
    done
}

advertise_systemd_service network-manager NetworkManager.service \
                              network-manager.service
advertise_systemd_service modem-manager ModemManager.service
advertise_systemd_service avahi avahi-daemon.service
advertise_systemd_service crond anacron.service cron.service crond.service
advertise_systemd_service cups cups.service cups.socket org.cups.cupsd.service
advertise_systemd_service clocksync chronyd.service qubes-sync-time.service \
                              systemd-timesyncd.service
advertise_systemd_service exim4 exim4.service
advertise_systemd_service getty@tty getty@tty.service
advertise_systemd_service netfilter-persistent netfilter-persistent.service
advertise_systemd_service qubes-update-check qubes-update-check.service
advertise_systemd_service updates-proxy-setup qubes-updates-proxy-forwarder.socket
advertise_systemd_service qubes-updates-proxy qubes-updates-proxy.service
advertise_systemd_service qubes-firewall qubes-firewall.service
advertise_systemd_service qubes-network qubes-network.service
advertise_systemd_service apparmor apparmor.service
