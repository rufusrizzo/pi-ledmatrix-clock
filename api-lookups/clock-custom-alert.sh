#!/bin/bash
MQTT_BROKER="192.168.1.202"
MQTT_PORT="1883"
SOURCE_TOPIC="weather/forecast/COND"        # Topic to subscribe to
TARGET_TOPIC="weather/forecast/COND_OLD"    # Topic to publish to
ALERT_TOPIC="weather/ALERT"                 # Topic to publish alerts to

# Optional: Add credentials if needed
# MQTT_USER="username"
# MQTT_PASS="password"

MQTT_SUB() {
    SUB_CMD="/usr/bin/mosquitto_sub -C 1 -h $MQTT_BROKER -p $MQTT_PORT -t $SOURCE_TOPIC"
    [ -n "$MQTT_USER" ] && SUB_CMD="$SUB_CMD -u $MQTT_USER -P $MQTT_PASS"
    $SUB_CMD
}

MQTT_PUB() {
    local message="$1"  # Pass the message as an argument
    PUB_CMD="/usr/bin/mosquitto_pub -h $MQTT_BROKER -p $MQTT_PORT -t $TARGET_TOPIC -m \"$message\""
    [ -n "$MQTT_USER" ] && PUB_CMD="$PUB_CMD -u $MQTT_USER -P $MQTT_PASS"
    eval "$PUB_CMD"     # Use eval to handle the command string properly
}

MQTT_ALERT() {
    local alert_message="$1"
    /usr/bin/mosquitto_pub -h "$MQTT_BROKER" -p "$MQTT_PORT" -t "$ALERT_TOPIC" -m "ALERT"
    /usr/bin/mosquitto_pub -h "$MQTT_BROKER" -p "$MQTT_PORT" -t "$SOURCE_TOPIC" -m "$alert_message"
}

MQTT_ALERT_CLEAR() {
    local old_cond="$1"
    /usr/bin/mosquitto_pub -h "$MQTT_BROKER" -p "$MQTT_PORT" -t "$ALERT_TOPIC" -m "Clear"
    /usr/bin/mosquitto_pub -h "$MQTT_BROKER" -p "$MQTT_PORT" -t "$SOURCE_TOPIC" -m "$old_cond"
}

# Grabbing the current condition
OLD_COND=$(MQTT_SUB)

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Error: No argument provided"
    echo "Usage: $0 <value>"
    echo "If you want to clear the alert run: $0 clear"
    exit 1
fi

# Check first argument and handle -h or --help
case "$1" in
    -h|--help)
        echo "Usage: $0 <value>"
        echo "Description: This script will send an alert to MQTT, but you have to type a message"
        echo "If you want to clear the alert run: $0 clear"
        echo "Options:"
        echo "  -h, --help    Display this help message"
        exit 0
        ;;
    clear)
        # Run the Clear function
        MQTT_ALERT_CLEAR "$OLD_COND"
        exit 0
        ;;
    *)
        # Assign the first argument to a variable
        alert_message="$1"
        ;;
esac

# Moving the Current Condition to the backup topic
MQTT_PUB "$OLD_COND"
MQTT_ALERT "$alert_message"

