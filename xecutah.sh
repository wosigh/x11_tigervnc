#!/bin/sh

APP_DIR=`dirname $0`

export DISPLAY=${1:-:0.0}

export LD_LIBRARY_PATH=/usr/bin:/media/cryptofs/apps/usr/palm/applications/org.webosinternals.xserver/xlib

export PATH=${APP_DIR}/bin:${PATH}
# Give the X card a chance to start.
sleep 2

${APP_DIR}/bin/dwm  &> /tmp/dwm.log &
${APP_DIR}/bin/vncviewer  &> /tmp/vncviewer.log &

