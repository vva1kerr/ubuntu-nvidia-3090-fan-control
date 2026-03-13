#!/bin/bash
LOG_FILE="/var/log/gpu_fan_curve.log"

export DISPLAY=:1
export XAUTHORITY=/run/user/1000/gdm/Xauthority

# Enable persistence mode
nvidia-smi -pm ENABLED

echo "Starting GPU fan curve daemon" | tee -a $LOG_FILE

# Enable manual fan control
nvidia-settings -c $DISPLAY -a "[gpu:0]/GPUFanControlState=1" | tee -a $LOG_FILE

# Determine fan speed based on temperature
get_fan_speed() {
  local TEMP=$1
  local FAN_SPEED=30
  if [ "$TEMP" -ge 75 ]; then
    FAN_SPEED=100
  elif [ "$TEMP" -ge 70 ]; then
    FAN_SPEED=90
  elif [ "$TEMP" -ge 60 ]; then
    FAN_SPEED=70
  elif [ "$TEMP" -ge 50 ]; then
    FAN_SPEED=50
  fi
  echo $FAN_SPEED
}

# Dynamic adjustment loop
while true; do
  TEMP=$(nvidia-smi -i 0 --query-gpu=temperature.gpu --format=csv,noheader,nounits)
  FAN_SPEED=$(get_fan_speed $TEMP)

  echo "$(date) | Temp: ${TEMP}C | Fan: ${FAN_SPEED}%" | tee -a $LOG_FILE

  nvidia-settings -c $DISPLAY -a "[fan:0]/GPUTargetFanSpeed=$FAN_SPEED" | tee -a $LOG_FILE
  nvidia-settings -c $DISPLAY -a "[fan:1]/GPUTargetFanSpeed=$FAN_SPEED" | tee -a $LOG_FILE

  sleep 5
done
