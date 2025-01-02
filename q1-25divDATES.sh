#!/bin/zsh

########################################
# Configuration
########################################
POLYGON_API_KEY="get_yr_own_API_KEY_https://polygon.io/"
portfolio=(
  "OXLC:5.09"
  "BCE:22.63"
  "ABR:13.68"
  "GNK:14.05"
  "CSWC:21.47"
  "DKL:40.62"
  "HTGC:18.39"
  "AB:37.45"
  "WES:38.75"
  "BTI:36.31"
  "F:9.91"
  "EPR:44.1"
  "MO:52.38"
  "ET:11.98"
  "ATNI:22.46"
  "T:19.5"
)

batch_size=5

########################################
# Variables
########################################
current_date=$(date '+%Y-%m-%d')
next_week=$(date -j -v+7d '+%Y-%m-%d')

# We'll gather the next future ex-date for each symbol (if any) here
future_ex_dates=()

########################################
# Helper Functions
########################################

fetch_dividend_data() {
  local symbol="$1"
  curl -s "https://api.polygon.io/v3/reference/dividends?ticker=${symbol}&apiKey=${POLYGON_API_KEY}&limit=50"
}

# Convert "YYYY-MM-DD" to epoch seconds (macOS/BSD variant).
date_to_seconds() {
  local date_str="$1"
  date -j -f "%Y-%m-%d" "$date_str" "+%s" 2>/dev/null || echo 0
}

########################################
# Processing Logic (Single Fetch)
########################################

process_symbol() {
  local stock="$1"
  local symbol="${stock%%:*}"

  # Fetch data once
  local data
  data="$(fetch_dividend_data "$symbol")"

  # Skip if no data
  if [[ -z "$data" || $(echo "$data" | jq -r '.results') == "null" ]]; then
    return
  fi

  #####################################
  # 1) Most recent dividend (Table 1)
  #
  #   Among the group with the most
  #   recent (max) declaration_date:
  #     - Pick earliest future ex-date if any
  #     - Otherwise pick the latest past ex-date
  #####################################
  local most_recent_dividend
  most_recent_dividend="$(
    echo "$data" | jq -r --arg today "$current_date" '
      .results
      # Group all records by declaration_date
      | group_by(.declaration_date)
      # Sort these groups by their date, ascending
      | sort_by(.[0].declaration_date)
      # Take the group with the MAX (latest) declaration_date
      | last as $latestDeclGroup

      # Among that group, pick earliest ex-div if it’s in the future
      # else pick the largest ex-div date in the past.
      | ( $latestDeclGroup
          | map(select(.ex_dividend_date > $today))
          | sort_by(.ex_dividend_date)
          | first
        ) as $futurePick

      | if $futurePick != null then
          $futurePick
        else
          ( $latestDeclGroup
            | map(select(.ex_dividend_date <= $today))
            | sort_by(.ex_dividend_date)
            | last
          )
        end

      # Project final pick into a smaller JSON
      | if . == null then "" else {
          "Symbol": .ticker,
          "Cash Amount": .cash_amount,
          "Declaration Date": .declaration_date,
          "Ex-Dividend Date": .ex_dividend_date,
          "Pay Date": .pay_date,
          "Frequency": .frequency
        } end
    '
  )"

  # If we got nothing, skip
  if [[ -z "$most_recent_dividend" || "$most_recent_dividend" == "null" ]]; then
    return
  fi

  # Print the row in the main table
  print_most_recent_dividend "$most_recent_dividend"

  #####################################
  # 2) The next future ex-dividend date
  #
  #    This is the earliest ex_dividend_date > today.
  #####################################
  local next_dividend_json
  next_dividend_json="$(
    echo "$data" | jq -r --arg today "$current_date" '
      .results
      | map(select(.ex_dividend_date > $today))
      | sort_by(.ex_dividend_date)
      | first
      | if . == null then "" else {
          "Symbol": .ticker,
          "ExDate": .ex_dividend_date
        } end
    '
  )"

  # If we found a next future ex-date, store it for our later reporting
  if [[ -n "$next_dividend_json" ]]; then
    local fut_symbol fut_exdate
    fut_symbol="$(echo "$next_dividend_json" | jq -r '.Symbol')"
    fut_exdate="$(echo "$next_dividend_json" | jq -r '.ExDate')"
    future_ex_dates+=("${fut_symbol},${fut_exdate}")
  fi
}

###############################################################################
# This function prints the row for Table 1 with the new highlighting rules:
#
# 1) If decl == current_date => single leading asterisk in MM/DD/YYYY
#      e.g.  *05/01/2025
# 2) Else, compute how many days old the declaration is:
#      age_in_days = (today_secs - decl_secs) / 86400
#    a) If 70 <= age_in_days <= 119 => trailing asterisk (05/01/2025*)
#    b) Else if (decl_date + 1 year) is within 10 weeks => trailing asterisk
#         i.e., if ( (decl_secs + 365 days) - today_secs ) <= 70 days
#    Otherwise, no highlight.
###############################################################################
print_most_recent_dividend() {
  local json="$1"

  local sym cash decl ex pay freq
  sym="$(echo "$json" | jq -r '.Symbol')"
  cash="$(echo "$json" | jq -r '."Cash Amount"')"
  decl="$(echo "$json" | jq -r '."Declaration Date"')"
  ex="$(echo "$json" | jq -r '."Ex-Dividend Date"')"
  pay="$(echo "$json" | jq -r '."Pay Date"')"
  freq="$(echo "$json" | jq -r '.Frequency')"

  local decl_str="$decl"

  # Convert to seconds
  local decl_secs
  decl_secs="$(date_to_seconds "$decl")"
  local current_secs
  current_secs="$(date_to_seconds "$current_date")"

  local age_in_days
  age_in_days=$(( (current_secs - decl_secs) / 86400 ))

  # For "add 1 year", we'll define 365 days. (Not perfect for leap years, but typical usage.)
  local one_year_secs=$((365*86400))
  local decl_plus_year_secs=$(( decl_secs + one_year_secs ))
  local days_until_annual=$(( (decl_plus_year_secs - current_secs) / 86400 ))

  # We'll attempt to convert to MM/DD/YYYY if we plan to highlight
  local decl_formatted
  decl_formatted=$(date -j -f "%Y-%m-%d" "$decl" '+%m/%d/%Y' 2>/dev/null)
  # If date command fails, we keep the original YYYY-MM-DD format

  # Condition 1: decl == current_date => single leading asterisk
  if [[ "$decl" == "$current_date" ]]; then
    if [[ -n "$decl_formatted" ]]; then
      decl_str="*$decl_formatted"
    else
      decl_str="*$decl"
    fi

  else
    # Condition 2: if 70 <= age_in_days <= 119 => trailing asterisk
    # (10 to 17 weeks old)
    if (( age_in_days >= 70 && age_in_days <= 119 )); then
      if [[ -n "$decl_formatted" ]]; then
        decl_str="${decl_formatted}*"
      else
        decl_str="${decl}*"
      fi
    # Condition 3: if next annual is within 10 weeks => trailing asterisk
    elif (( days_until_annual <= 70 )); then
      # That means the next annual declaration is soon
      if [[ -n "$decl_formatted" ]]; then
        decl_str="${decl_formatted}*"
      else
        decl_str="${decl}*"
      fi
    fi
  fi

  printf "| %-10s | %-14s | %-18s | %-18s | %-12s | %-10s |\n" \
    "$sym" "$cash" "$decl_str" "$ex" "$pay" "$freq"
}

########################################
# Print Table Header
########################################

printf "| %-10s | %-14s | %-18s | %-18s | %-12s | %-10s |\n" \
  "Symbol" "Cash Amount" "Declaration Date" "Ex-Dividend Date" "Pay Date" "Frequency"
printf "|------------|----------------|--------------------|--------------------|--------------|------------|\n"

########################################
# Main Loop: Process in Batches of 5
########################################
for ((i = 0; i < ${#portfolio[@]}; i+=batch_size)); do
  # Slice out up to 5 stocks
  batch=("${portfolio[@]:i:batch_size}")

  # Process each symbol in this batch
  for stock in "${batch[@]}"; do
    process_symbol "$stock"
  done

  # If there's more to process, wait 60s to respect free-tier rate limit
  if ((i + batch_size < ${#portfolio[@]})); then
    printf "YO, hold up A MINUTE, we got speed LIMITS here... 60"
    for ((t=59; t>=0; t--)); do
      sleep 1
      printf "\rYO, hold up A MINUTE, we got speed LIMITS here... %02d" "$t"
    done
    printf "\r                                                  \r"
  fi
done

########################################
# SECOND REPORT: Future Ex-Dividends
########################################
printf "\n=== FUTURE Ex-Dividend Report ===\n"

# If no future ex-dates found at all
if [[ ${#future_ex_dates[@]} -eq 0 ]]; then
  printf "No future ex-dividend dates found across the entire portfolio.\n"
  printf "\n"
  exit 0
fi

# Sort them by date (the portion after the comma).
sorted_future_ex_dates=($(printf "%s\n" "${future_ex_dates[@]}" | sort -t',' -k2))

# We’ll check if any are within the next 10 days.
ten_days_from_now=$(date -j -v+10d '+%Y-%m-%d')
current_secs=$(date_to_seconds "$current_date")
ten_days_secs=$(date_to_seconds "$ten_days_from_now")

within_10_days=()

for entry in "${sorted_future_ex_dates[@]}"; do
  sym="${entry%%,*}"
  xdate="${entry#*,}"

  xdate_secs="$(date_to_seconds "$xdate")"
  if [[ "$xdate_secs" -le "$ten_days_secs" && "$xdate_secs" -gt "$current_secs" ]]; then
    within_10_days+=("$sym,$xdate")
  fi
done

if [[ ${#within_10_days[@]} -eq 0 ]]; then
  # Then no ex-dates in the next 10 days, so just show earliest overall
  earliest="${sorted_future_ex_dates[0]}"
  earliest_sym="${earliest%%,*}"
  earliest_date="${earliest#*,}"

  printf "No ex-dividend dates fall within the next 10 days.\n"
  printf "Earliest future ex-dividend date in the portfolio:\n"
  printf "  Symbol: %s\n" "$earliest_sym"
  printf "  Ex-Dividend Date: %s\n" "$earliest_date"
else
  # Print a simple 2-col table
  printf "Ex-Dividend dates occurring in the next 10 days:\n"
  printf "| %-10s | %-18s |\n" "Symbol" "Ex-Dividend Date"
  printf "|------------|--------------------|\n"

  for entry in "${within_10_days[@]}"; do
    s="${entry%%,*}"
    d="${entry#*,}"
    printf "| %-10s | %-18s |\n" "$s" "$d"
  done
fi

# Trailing newline for visual clarity
printf "\n"
