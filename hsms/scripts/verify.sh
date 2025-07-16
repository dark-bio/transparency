#!/bin/sh

# YubiHSM Audit Log Verifier
#
# This script verifies the integrity of a (human readable) YubiHSM audit log by
# iterating over each entry and verifying the hash progression.

set -e # Exit on any error

# Figure out the input, either stdin or a file
if [ -p /dev/stdin ]; then
  input="/dev/stdin"
elif [ $# -ge 1 ]; then
  input="$1"
else
  echo "Usage: $0 [yubihsm-audit-logs.md]" >&2
  exit 1
fi

# Iterate over each log line
while IFS= read -r line; do
    # Extract the individual fields from the log entry. Ugh...
    #   item: N -- cmd: 0xXX -- length: N -- session key: 0xXX -- target key: 0xXX -- second key: 0xXX -- result: 0xXX -- tick: N -- hash: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    eval $(printf "%s\n" "$line" | sed -E '
        s/.*item: +([0-9]+) -- cmd: +0x([0-9A-Fa-f]+) -- length: +([0-9]+) -- session key: +0x([0-9A-Fa-f]+) -- target key: +0x([0-9A-Fa-f]+) -- second key: +0x([0-9A-Fa-f]+) -- result: +0x([0-9A-Fa-f]+) -- tick: +([0-9]+) -- hash: +([0-9A-Fa-f]+).*/\
        item=\1; cmd_hex=\2; len=\3; ses_hex=\4; fst_hex=\5; snd_hex=\6; res_hex=\7; tick=\8; seen_hash=\9/
    ')
    # Convert hex values to decimal for binary packing
    cmd=$((0x$cmd_hex))
    ses=$((0x$ses_hex))
    fst=$((0x$fst_hex))
    snd=$((0x$snd_hex))
    res=$((0x$res_hex))

    # Skip the first item (should be all ones) and just save it's hash
    if [ $item -gt 1 ]; then
        # Pack entry data into hex format
        # Format: item(16-bit) || cmd(8-bit) || length(16-bit) || session_key(16-bit) ||
        #         target_key(16-bit) || second_key(16-bit) || result(16-bit) || tick(32-bit)
        item_data=$(printf "%04x%02x%04x%04x%04x%04x%02x%08x" "$item" "$cmd" "$len" "$ses" "$fst" "$snd" "$res" "$tick")

        # Compute SHA256(entry_data || previous_digest) and take first 16 bytes
        calc_hash=$(printf "%s%s" "$item_data" "$prev_hash" | xxd -r -p | openssl dgst -sha256 -binary | head -c 16 | xxd -p -c 256)
        if [ "$calc_hash" != "$seen_hash" ]; then
            echo "❌ Audit trail verification FAILED at line #$((prev_item + 1))"
            echo "   Expected: $seen_hash"
            echo "   Computed: $calc_hash"
            exit 1
        fi
    fi
    # Update previous digest for next iteration
    prev_hash="$seen_hash"
    prev_item="$item"
done < "$input"

# Verification complete
printf "✅ Verified %d entries.\n" "$item"
