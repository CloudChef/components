#!/bin/bash

install_path=$(ctx node properties install_path)
service iptables stop
nohup bash ${install_path}/Oracle/Middleware/Oracle_Home/user_projects/domais/base_domomain/bin/startWebLogic.sh  > /dev/null 2>&1 &