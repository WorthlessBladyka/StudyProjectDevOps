#!/bin/bash

# Проверка запущен ли Docker
if systemctl is-active --quiet containerd.service; then
    echo "✓ Docker работает"
    echo "Статус: $(systemctl is-active containerd.service)"
    exit 0
else
    echo "✗ Docker не работает"
    sudo systemctl daemon-reload
    sudo systemctl start containerd.service
    if systemctl is-active --quiet containerd.service; then
        echo "✓ Docker работает"
        echo "Статус: $(systemctl is-active containerd.service)"
        exit 0
    else
        echo "✗ Docker не работает"
        echo "Статус: $(systemctl is-active containerd.service)"
        exit 1
    fi
fi


