#!/usr/bin/env bash
# measure-brick.sh — characterize the USB-C/MagSafe charger currently plugged in.
#
# Prints the charger's NEGOTIATED PD profile (the real measure of a brick's
# capability — works at any battery level) plus live watts going into the pack.
#
#   measure-brick.sh            # one-shot snapshot
#   measure-brick.sh watch      # refresh every 2s until Ctrl-C
#   measure-brick.sh "yellow lazada"   # label the reading in the output
#
# Why the profile and not the live wattage? Near a full battery the Mac only
# sips a few watts no matter how strong the brick is. The negotiated voltage
# (5V = legacy/slow, 20V = real PD) tells you the truth instantly.

set -euo pipefail

read_adapter() {
  # Pull the live adapter dict from the battery controller.
  ioreg -rn AppleSmartBattery 2>/dev/null \
    | grep -oE '"AppleRawAdapterDetails" = \(\{.*\}\)' | head -1
}

batt_field() {  # batt_field "FieldName" -> raw value (top-level scalar only)
  # Split on " = " (with spaces) so the inline "Voltage"=NNN inside the giant
  # BatteryData blob — which has no spaces around its = — can't match.
  ioreg -rn AppleSmartBattery 2>/dev/null \
    | awk -F' = ' -v k="$1" '$1 ~ ("\"" k "\"[[:space:]]*$") {v=$2; gsub(/[^0-9-]/,"",v); print v; exit}'
}

# Two's-complement: ioreg reports current as unsigned 64-bit; bash arithmetic is
# signed 64-bit, so $(( )) already wraps a "charging" value to a negative number.
to_signed() { echo $(( $1 )); }

snapshot() {
  local label="${1:-}"
  local det volts watts curr desc tier
  det="$(read_adapter)"

  if [[ -z "$det" ]]; then
    printf '%s  ⚪️  no charger connected\n' "${label:+[$label] }"
    return
  fi

  volts=$(sed -E 's/.*"AdapterVoltage"=([0-9]+).*/\1/' <<<"$det")
  watts=$(sed -E 's/.*"Watts"=([0-9]+).*/\1/'         <<<"$det")
  curr=$(sed  -E 's/.*"Current"=([0-9]+).*/\1/'       <<<"$det")
  tier=$(sed  -E 's/.*"AdapterPowerTier"=([0-9]+).*/\1/' <<<"$det")
  desc=$(sed  -E 's/.*"Description"="([^"]*)".*/\1/'  <<<"$det")
  [[ "$desc" == "$det" ]] && desc="legacy usb"

  # Live charge rate into the battery.
  local amp_raw amp pack_mv w_in
  amp_raw=$(batt_field InstantAmperage); amp=$(to_signed "$amp_raw")
  pack_mv=$(batt_field Voltage)
  # watts = |amp(mA)| * packV(mV) / 1e6
  w_in=$(awk -v a="${amp#-}" -v v="$pack_mv" 'BEGIN{printf "%.1f", a*v/1000000}')

  local verdict
  if   (( volts >= 20000 )); then verdict="✅ full PD"
  elif (( volts >=  9000 )); then verdict="🟡 partial PD"
  else                            verdict="❌ legacy 5V — slow"
  fi

  printf '%s%s / %sW  (tier %s, %s)  %s   → %sW into battery now\n' \
    "${label:+[$label]  }" \
    "$(awk -v v="$volts" 'BEGIN{printf "%g", v/1000}')V" \
    "$watts" "$tier" "$desc" "$verdict" "$w_in"

  # Full negotiated ladder, one rung per line. (|| true: a 1-rung legacy brick
  # yields no matches and grep would otherwise trip `set -e`.)
  grep -oE '"MaxCurrent"=[0-9]+,"MaxVoltage"=[0-9]+' <<<"$det" \
    | sed -E 's/"MaxCurrent"=([0-9]+),"MaxVoltage"=([0-9]+)/    \2 mV @ \1 mA/' \
    | awk '{printf "%6.1f V @ %5.2f A  (%4.0f W)\n", $1/1000, $4/1000, ($1/1000)*($4/1000)}' \
    || true
}

case "${1:-}" in
  watch)
    while true; do clear; date '+%H:%M:%S'; snapshot "${2:-}"; sleep 2; done ;;
  *)
    snapshot "${1:-}" ;;
esac
