#!/bin/bash
service ssh start
wetty -p 3001 --ssh-host localhost --ssh-user kali
