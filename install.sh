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

install() {
  local shortuname=$(uname -s)
  if [ "${shortuname}" != "Darwin" ]; then
    echo "Sorry, requires Mac OS X to run." >&2
    exit 1
  fi

  install_osx

  echo ""
  echo ""
  echo "Installation is complete."
}

uninstall() {
  uninstall_osx

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

