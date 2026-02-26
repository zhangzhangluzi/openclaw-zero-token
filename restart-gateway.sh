#!/bin/bash
echo "重启 Gateway..."
pkill -f "openclaw.*gateway" 2>/dev/null
sleep 2
echo "启动 Gateway..."
./server.sh
