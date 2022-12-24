#!/bin/bash

# Regression test for common-rpl

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; else source ../Common/common-rpl.sh; fi

#Define values or override default values
if [[ -f "validator-id.txt" ]]; then
    VALIDATOR_ID=$(cat validator-id.txt);
else
    echo "ERROR: validator-id.txt file is missing. Save the test validator id to validator-id.txt.";
    return
fi

# log
randomMessage="TEST_MESSAGE:$(echo $RANDOM | md5sum | head -c 20;)"
expectedCount=$(grep -o "$randomMessage" "$LOG_FILE" | wc -l)
(( expectedCount++ ))
log "$randomMessage"
if [[ $expectedCount -eq $(grep -o "$randomMessage" "$LOG_FILE" | wc -l) ]]; then echo "PASSED: log()"; else echo "ERROR: log() returned unexpected result: $(grep -o "$randomMessage" "$LOG_FILE" | wc -l)"; fi

# log_fail
randomMessage="TEST_MESSAGE:$(echo $RANDOM | md5sum | head -c 20;)"
expectedCount=$(grep -o "$randomMessage" "$LOG_FILE" | wc -l)
(( expectedCount++ ))
log_fail "$randomMessage"
if [[ $expectedCount -eq $(grep -o "$randomMessage" "$LOG_FILE" | wc -l) ]]; then echo "PASSED: log_fail()"; else echo "ERROR: log_fail() returned unexpected result: $(grep -o "$randomMessage" "$LOG_FILE" | wc -l)"; fi

# log_step
randomMessage="TEST_MESSAGE:$(echo $RANDOM | md5sum | head -c 20;)"
expectedCount=$(grep -o "$randomMessage" "$LOG_FILE" | wc -l)
(( expectedCount++ ))
log_step "$randomMessage"
if [[ $expectedCount -eq $(grep -o "$randomMessage" "$LOG_FILE" | wc -l) ]]; then echo "PASSED: log_step()"; else echo "ERROR: log_step() returned unexpected result: $(grep -o "$randomMessage" "$LOG_FILE" | wc -l)"; fi

# debug_enter_function
expectedCount=$(grep -o "Enter function" "$LOG_FILE" | wc -l)
(( expectedCount++ ))
debug_enter_function
if [[ $expectedCount -eq $(grep -o "Enter function" "$LOG_FILE" | wc -l) ]]; then echo "PASSED: debug_enter_function()"; else echo "ERROR: debug_enter_function() returned unexpected result: $(grep -o "Enter function" "$LOG_FILE" | wc -l)"; fi

# debug_leave_function
expectedCount=$(grep -o "Leave function" "$LOG_FILE" | wc -l)
(( expectedCount++ ))
debug_leave_function
if [[ $expectedCount -eq $(grep -o "Leave function" "$LOG_FILE" | wc -l) ]]; then echo "PASSED: debug_leave_function()"; else echo "ERROR: debug_leave_function() returned unexpected result: $(grep -o "Leave function" "$LOG_FILE" | wc -l)"; fi

# Initialize
expectedCount=$(grep -o "Script initialized and starting" "$LOG_FILE" | wc -l)
(( expectedCount++ ))
Initialize
if [[ $expectedCount -eq $(grep -o "Script initialized and starting" "$LOG_FILE" | wc -l) ]]; then echo "PASSED: Initialize()"; else echo "ERROR: Initialize() returned unexpected result: $(grep -o "Script initialized and starting" "$LOG_FILE" | wc -l)"; fi

# Cleanup
expectedCount=$(grep -o "Script Duration" "$LOG_FILE" | wc -l)
(( expectedCount++ ))
Cleanup
if [[ $expectedCount -eq $(grep -o "Script Duration" "$LOG_FILE" | wc -l) ]]; then echo "PASSED: Cleanup()"; else echo "ERROR: Cleanup() returned unexpected result: $(grep -o "Script Duration" "$LOG_FILE" | wc -l)"; fi

# getNetwork
if [[ "Prater" == $(getNetwork) ]]; then echo "PASSED: getNetwork()"; else echo "ERROR: getNetwork() returned unexpected result: $(getNetwork)"; fi

# getDomain
if [[ "prater." == $(getDomain) ]]; then echo "PASSED: getDomain()"; else echo "ERROR: getDomain() returned unexpected result: $(getDomain)"; fi

# getValidator
if [[ "$VALIDATOR_ID" == $(getValidator) ]]; then echo "PASSED: getValidator()"; else echo "ERROR: getValidator() returned unexpected result: $(getValidator)"; fi

# getLastEpoch
if [[ $(getLastEpoch) -gt 0 ]]; then echo "PASSED: getLastEpoch()"; else echo "ERROR: getLastEpoch() returned unexpected result: $(getLastEpoch)"; fi

# waitForNextEpoch
nextEpoch=$(( $(getLastEpoch) + 1 ))
echo -ne "waitForNextEpoch will take up to several minutes..."\\r
#waitForNextEpoch -s
if [[ nextEpoch == $(getLastEpoch) ]]; then echo "PASSED: waitForNextEpoch()"; else echo "ERROR: waitForNextEpoch() returned unexpected result: $(getLastEpoch)"; fi



