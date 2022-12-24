#!/bin/bash

# Regression test for common-rpl

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; else source ../Common/common-rpl.sh; fi
if [[ -f "common-rpl-maintenance.sh" ]]; then source common-rpl-maintenance.sh; else source ../Common/common-rpl-maintenance.sh; fi

# getLatestRPVersion
installVersion=$(getLatestRPVersion)
if [[ $(getLatestRPVersion) == *"1."* ]]; then echo "PASSED: getLatestRPVersion()"; else echo "ERROR: getLatestRPVersion() returned unexpected result: $(getLatestRPVersion)"; fi

# getNodeVersion
nodeVersion=$(getNodeVersion)
if [[ $(getNodeVersion) == *"1."* ]]; then echo "PASSED: getNodeVersion()"; else echo "ERROR: getNodeVersion() returned unexpected result: $(getNodeVersion)"; fi

# verifyMatchingNodeVersion
if [[ $(verifyMatchingNodeVersion) ]]; then echo "PASSED: verifyMatchingNodeVersion()"; else echo "ERROR: verifyMatchingNodeVersion() returned unexpected result: $(verifyMatchingNodeVersion)"; fi

# verifyNodeIsActive
if [[ $(verifyNodeIsActive) ]]; then echo "PASSED: verifyNodeIsActive()"; else echo "ERROR: verifyNodeIsActive() returned unexpected result: $(verifyNodeIsActive)"; fi




