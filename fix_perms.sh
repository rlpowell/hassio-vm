#!/bin/bash

sudo chown -R qemu:qemu data*/
sudo chcon -R -t svirt_image_t data*/

sudo chown -R rlpowell:rlpowell README* USAGE-NOTES *.sh
sudo chcon -R -t user_home_t README* USAGE-NOTES *.sh
