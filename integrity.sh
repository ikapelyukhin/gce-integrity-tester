#!/bin/bash

INSTANCE_ID=$(curl -s -H Metadata-Flavor:Google http://metadata.google.internal/computeMetadata/v1/instance/id)
PROJECT_ID=$(curl -s -H Metadata-Flavor:Google http://metadata/computeMetadata/v1/project/project-id)

python3 3< <(gcloud logging read --format=json "logName=\"projects/${PROJECT_ID}/logs/compute.googleapis.com%2Fshielded_vm_integrity\" AND resource.labels.instance_id=\"${INSTANCE_ID}\" AND jsonPayload.@type=\"type.googleapis.com/cloud_integrity.IntegrityEvent\"") <<EOF
import os
import json

fh = os.fdopen(3)
data = json.loads(fh.read())

RED = '\033[0;31m'
GREEN = '\033[0;32m'
RESET = '\033[0m'

boots = {}
for item in data:
    if not item.get('jsonPayload'):
        continue

    boot_counter = item.get("jsonPayload").get('bootCounter')
    event_types = ['earlyBootReportEvent', 'lateBootReportEvent']
    for event_type in event_types:
        event = item.get('jsonPayload').get(event_type)
        if not event:
            continue

        policy_measurements = {}
        actual_measurements = {}
        for m in event['policyMeasurements']:
            policy_measurements[m["pcrNum"]] = m["value"]

        for m in event['actualMeasurements']:
            actual_measurements[m["pcrNum"]] = m["value"]

        if not boots.get(boot_counter):
            boots[boot_counter] = {}

        boots[boot_counter][event_type] = (event['policyEvaluationPassed'], policy_measurements, actual_measurements)

for boot_counter in sorted(boots.keys()):
    print(f"Boot #{boot_counter}:")
    print()

    for event_type in sorted(boots[boot_counter].keys()):
        has_passed, policy_measurements, actual_measurements = boots[boot_counter][event_type]

        color = GREEN if has_passed else RED
        print(f"Event: {event_type}, passed: {color}{has_passed}{RESET}")
        print(f"PCR #\t{'POLICY'.rjust(28)}\t{'ACTUAL'.rjust(28)}")
        for pcr in sorted(policy_measurements.keys()):
            policy = policy_measurements.get(pcr)
            actual = actual_measurements.get(pcr)
            color = GREEN if policy == actual else RED
            print(f"{pcr}: {color}{policy_measurements[pcr]}\t{actual}{RESET}")
        print()
    print()
EOF
