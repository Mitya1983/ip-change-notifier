#!/bin/bash

SCRIPT_DIR=$HOME/.ip-change-notifier

mkdir -p "$SCRIPT_DIR" || { echo "failed to create working directory"; exit 1; }

[[ -f ip-checker.sh ]] || { echo "ip-checker.sh not found"; exit 1; }

cp ip-checker.sh "$SCRIPT_DIR"

{
  echo "[Unit]"
  echo "Description=Ip change notification service"
  echo "After=network.target"
  echo "[Service]"
  echo "Type=simple"
  echo "ExecStart=/bin/bash $SCRIPT_DIR/ip-checker.sh"
  echo "Restart=always"
  echo "RestartSec=5"
  echo "User=\"$USER\""
  echo "WorkingDirectory=$SCRIPT_DIR"
  echo "StandardOutput=append:/var/log/ip-checker.log"
  echo "StandardError=append:/var/log/ip-checker.log"

  echo "[Install]"
  echo "WantedBy=multi-user.target"
} > ip-tracker.service

sudo mv ip-tracker.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable ip-tracker.service
sudo systemctl start ip-tracker.service

{
  echo "sudo systemctl stop ip-tracker.service"
  echo "sudo systemctl disable ip-tracker.service"
  echo "sudo rm /etc/systemd/system/ip-tracker.service"
  echo "sudo systemctl daemon-reload"
  echo "rm -rf $SCRIPT_DIR"
} > uninstall.sh
chmod +x uninstall.sh
mv uninstall.sh "$SCRIPT_DIR"/
