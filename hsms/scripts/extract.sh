#!/bin/sh
set -e

# YubiHSM Audit Log Extractor
#
# This script iterates over the annotated YubiHSM .md logs included in this repo
# and extract the raw (but human-readable) logs for cryptographic verification.

# Figure out the input, either stdin or a file
if [ -p /dev/stdin ]; then
  input="/dev/stdin"
elif [ $# -ge 1 ]; then
  input="$1"
else
  echo "Usage: $0 [yubihsm-annotated-logs.md]" >&2
  exit 1
fi

# Iterate over each line and output anything that looks like a YubiHSM log
sed -En 's/.*(item: +[[:digit:]]+ -- cmd: +0x[[:xdigit:]]+ -- length: +[[:digit:]]+ -- session key: +0x[[:xdigit:]]+ -- target key: +0x[[:xdigit:]]+ -- second key: +0x[[:xdigit:]]+ -- result: +0x[[:xdigit:]]+ -- tick: +[[:digit:]]+ -- hash: +[[:xdigit:]]+).*/\1/p' $1
