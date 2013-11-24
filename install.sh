#!/bin/bash


DAEMON_PLIST="com.github.pekepeke.mocksmtpd.firewall.plist"
AGENT_PLIST="com.github.pekepeke.mocksmtpd.plist"

opt_uninstall=0
usage() {
  prg_name=`basename $0`
  cat <<EOM
  Usage: $prg_name [-h]
  -h : Show this message
  -u : Uninstall
EOM
  exit 1
}


# install_command() {
#   # gem install specific_install
#   # gem specific_install -l git://github.com/boomerang/mocksmtpd.git
#   # gem specific_install -l http://github.com/koseki/mocksmtpd/
#   # gem install koseki-mocksmtpd -s http://gems.github.com
#   # gem install boomerang-mocksmtpd
# }

mocksmtpd_plist() {
  LABEL=$1
  BIN=$2
  cat <<EOM
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>$BIN</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>OnDemand</key>
  <false/>
</dict>
</plist>
EOM
  return 0
}

mocksmtpd_upstart() {
  LABEL=$1
  BIN=$2
  cat <<EOM
description "$LABEL"
author  "pekepeke <pekepekesamurai+github@gmail.com>"

start on runlevel [2345]
stop on runlevel [016]

chdir /tmp
exec $BIN
respawn
EOM
  return 0
}

install_repository() {
  if [ ! -e ~/.mocksmtpd-web ]; then
    git clone https://github.com/pekepeke/mocksmtpd-web.git ~/.mocksmtpd-web
    cd ~/.mocksmtpd-web
    git submodule update --init
  fi
}

install_osx() {
  if [ ! -e ~/.pow ]; then
    echo "Sorry, required pow to run." >&2
    exit 1
  fi
  install_repository

  # install with root privilege
  echo "*** Register ipfw rule... (required root privilege)"
  cat "conf/$DAEMON_PLIST" | sudo tee "/Library/LaunchDaemons/$DAEMON_PLIST" >/dev/null
  sudo launchctl load -Fw "/Library/LaunchDaemons/$DAEMON_PLIST"

  echo "*** Register daemons..."
  LABEL=$(basename $AGENT_PLIST .plist)
  mocksmtpd_plist "$LABEL" "$PWD/bin/mocksmtpd.sh" > "$HOME/Library/LaunchAgents/$AGENT_PLIST"
  launchctl load -Fw  "$HOME/Library/LaunchAgents/$AGENT_PLIST"

  echo "*** Register application to pow..."
  [ ! -e ~/.pow/mocksmtpd ] && ln -s $PWD/web ~/.pow/mocksmtpd
}

uninstall_osx() {
  echo "*** Unregister ipfw rule(required root privilege)"
  DAEMON_FILE="/Library/LaunchDaemons/$DAEMON_PLIST"
  sudo launchctl unload "$DAEMON_FILE"
  sudo rm "$DAEMON_FILE"

  echo "*** Unregister daemons..."
  launchctl unload "$HOME/Library/LaunchAgents/$AGENT_PLIST"
  rm               "$HOME/Library/LaunchAgents/$AGENT_PLIST"


  echo "*** Unregister application..."
  [ -e ~/.pow/mocksmtpd ] && rm ~/.pow/mocksmtpd
}

install_linux() {
  if [ ! -e ~/.prax ]; then
    echo "Sorry, required prax to run." >&2
    exit 1
  fi
  install_repository

  echo "*** Register daemons..."
  LABEL=$(basename $AGENT_PLIST .plist)
  mocksmtpd_upstart "$LABEL" "$PWD/bin/mocksmtpd.sh" | sudo tee /etc/init/${LABEL}.conf
  sudo initctl reload-configuration
  # launchctl load -Fw  "$HOME/Library/LaunchAgents/$AGENT_PLIST"

  echo "*** Register application to prax..."
  [ ! -e ~/.prax/mocksmtpd ] && ln -s $PWD/web ~/.prax/mocksmtpd

  echo "*** Please add ufw rule - /etc/ufw/before.rules"
  cat <<EOM
  iptables -t nat -A OUTPUT -p tcp -d 127.0.0.1 --dport 25  -j REDIRECT --to-ports 60025

  sudo iptables-save | sudo tee /etc/ufw/before.rules
EOM
  # echo "echo -A PREROUTING -p tcp -i eth0 --dport 25 -j REDIRECT --to-port 60025 | sudo tee /etc/ufw/before.rules"
  # iptables -t nat -A POSTROUTING -m tcp -p tcp --dst 127.0.0.1 --dport 25 -j SNAT --to-source 127.0.0.1 --to-destination 127.0.0.1:60025
}

uninstall_linux() {
  echo "*** Unregister daemons..."
  # launchctl unload "$HOME/Library/LaunchAgents/$AGENT_PLIST"
  # rm               "$HOME/Library/LaunchAgents/$AGENT_PLIST"
  LABEL=$(basename $AGENT_PLIST .plist)
  sudo rm /etc/init/${LABEL}.conf
  sudo initctl reload-configuration


  echo "*** Unregister application..."
  [ -e ~/.prax/mocksmtpd ] && rm ~/.prax/mocksmtpd

  echo "*** Please remove line from ufw rule - /etc/ufw/before.rules"
  echo "-A PREROUTING -p tcp --dport 25 -j REDIRECT --to-port 60025"
}

is_osx() {
  local shortuname=$(uname -s)
  [ "${shortuname}" != "Darwin" ] && return 1
  return 0
}

is_linux() {
  local shortuname=$(uname -s)
  [ "${shortuname}" != "Linux" ] && return 1
  return 0
}

install() {
  if is_osx; then
    install_osx
  elif is_linux; then
    install_linux
  else
    echo "Sorry, requires Mac OS X or Linux to run." >&2
    exit 1
  fi

  echo ""
  echo ""
  echo "Installation is complete."
}

uninstall() {
  if is_osx; then
    uninstall_osx
  elif is_linux; then
    uninstall_linux
  else
    echo "Sorry, requires Mac OS X or Linux to run." >&2
    exit 1
  fi

  echo ""
  echo ""
  echo "Uninstallation is complete."
}

main() {
  if [ $opt_uninstall -eq 1 ]; then
    uninstall
  else
    install
  fi
}

OPTIND_OLD=$OPTIND
OPTIND=1
while getopts "hvu" opt; do
  case $opt in
    h)
      usage ;;
    v)
      ;;
    u)
      opt_uninstall=1 ;;
  esac
done
shift `expr $OPTIND - 1`
OPTIND=$OPTIND_OLD
if [ $OPT_ERROR ]; then
  usage
fi

main "$@"

