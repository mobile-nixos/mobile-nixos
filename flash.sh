#!/usr/bin/env bash
fastboot flash boot ./result/boot.img
fastboot flash userdata ./result/system.img
fastboot set_active a
fastboot reboot
