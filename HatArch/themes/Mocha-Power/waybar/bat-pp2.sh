#!/bin/bash

# This variable selects mode to run.
MODE=$1

# Power profile switcher
if [[ $MODE == "toggle" ]]; then
  PROFILE=$(powerprofilesctl get)
  if [[ $PROFILE == "power-saver" ]]; then
    powerprofilesctl set performance &
  elif [[ $PROFILE == "balanced" ]]; then
    powerprofilesctl set power-saver &
  else
    powerprofilesctl set balanced &
  fi
fi

while true; do
  # Refreshes the whole module.
  if [[ $MODE == "refresh" ]]; then

    # Delay, so that powerprofile switches first.
    # Increase if doesn't update on click.
    sleep 0.25

    # Get battery information.
    BATTERY=$(upower -e | grep 'BAT')
    PERCENT=$(upower -i "$BATTERY" | awk '/percentage/ {print $2}' | tr -d '%')
    STATE=$(upower -i "$BATTERY" | awk '/state/ {print $2}' | tr -d '%')
    RATE=$(upower -i "$BATTERY" | awk '/energy-rate/ {print $2}' | tr -d '%')
    # EOL=$(upower -i "$BATTERY" | awk '/time to empty/ {print $4}' | tr -d '%')
    EOL="Empty in: \n$(upower -i "$BATTERY" | awk '/time to empty/ {for (i=4; i<=NF; i++) printf $i (i<NF?" ":"\n")}')"

    if [[ $EOL == "Empty in: \n" ]]; then
      EOL="Full in: \n$(upower -i "$BATTERY" | awk '/time to full/ {for (i=4; i<=NF; i++) printf $i (i<NF?" ":"\n")}')"
    fi

    # Set class for styling.
    if [[ $STATE == "charging" ]]; then
      CLASS=$"charging"
    elif [[ $PERCENT -le 10 ]]; then
      CLASS=$"critical"
    elif [[ $PERCENT -le 20 ]]; then
      CLASS=$"warning"
    else
      CLASS=$"normal"
    fi

    # Set energy rate polarity.
    if [[ $STATE == "charging" ]]; then
      TOOLTIP="+$RATE"
    else
      TOOLTIP=$"-$RATE"
    fi

    # Get power profile and format icon.
    # Nerd font used in this case.
    PROFILE=$(powerprofilesctl get)
    case "$PROFILE" in
    performance)
      PROFILE=$" 󱀚"
      ;;
    balanced)
      PROFILE=$" "
      ;;
    power-saver)
      PROFILE=$" "
      ;;
    esac

    current_time=$(date +%s)

    # Export as json.
    printf '{"text": "%s", "class": "%s", "alt": "%s"}\n' "$current_time $PERCENT" "$CLASS" "$TOOLTIP W \n$EOL"
  fi
  sleep 1
done
# Indicator bar

if [[ $MODE == "bar" ]]; then
  BATTERY=$(upower -e | grep 'BAT')
  PERCENT=$(upower -i "$BATTERY" | awk '/percentage/ {print $2}' | tr -d '%')
  STATE=$(upower -i "$BATTERY" | awk '/state/ {print $2}' | tr -d '%')

  # Set class for styling.
  if [[ $STATE == "fully-charged" ]]; then
    CLASS=$"full"
  elif [[ $STATE == "charging" ]]; then
    CLASS=$"charging"
  elif [[ $PERCENT -le 10 ]]; then
    CLASS=$"critical"
  elif [[ $PERCENT -le 20 ]]; then
    CLASS=$"warning"
  else
    CLASS=$"discharging"
  fi

  # Export as json.
  printf '{"class": "%s"}\n' "$CLASS"
fi
