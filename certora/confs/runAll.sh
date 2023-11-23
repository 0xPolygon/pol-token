#!/bin/bash

# Get a list of all .conf files
CONF_FILES=$(ls certora/confs/*.conf)

# Iterate over each .conf file
for CONF_FILE in $CONF_FILES; do
    echo "Executing $CONF_FILE..."
    
    # Execute certoraRun with the current .conf file
    certoraRun "$CONF_FILE" --msg "$CONF_FILE"
    
    echo "Done executing $CONF_FILE."
    echo
done