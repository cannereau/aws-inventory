#!/bin/bash

# constants
ROOT_PROFILE="master"
ORG_ROLE="ReadOnlyRole"
REPORT_PATH="../data"
DATE_BEGIN="2020-03-01T00:00:00Z"
DATE_END="2020-04-01T00:00:00Z"
SNAP_LIMIT=$(date +%Y-%m-%d --date '6 months ago')
