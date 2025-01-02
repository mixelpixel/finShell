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

  # Skip if no data or .results is null
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
      | sort_by(.[0].declaration_date)
      | last as $latestDeclGroup

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

  if [[ -z "$most_recent_dividend" || "$most_recent_dividend" == "null" ]]; then
    return
  fi

  # Print the row in the main table
  print_most_recent_dividend "$most_recent_dividend"

  #####################################
  # 2) The next future ex-dividend date
  #
  #    This is the earliest ex_dividend_date > today
  #    (for the second report).
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

  if [[ -n "$next_dividend_json" ]]; then
    local fut_symbol fut_exdate
    fut_symbol="$(echo "$next_dividend_json" | jq -r '.Symbol')"
    fut_exdate="$(echo "$next_dividend_json" | jq -r '.ExDate')"
    future_ex_dates+=("${fut_symbol},${fut_exdate}")
  fi
}

###############################################################################
# TABLE 1 PRINT LOGIC
#
# 1) Declaration Date:
#    - If decl == current_date => leading "*" (YYYY-MM-DD)
#    - If 70 <= age_in_days <= 119 => trailing "*"
#    - If next annual is within 10 weeks => trailing "*"
#
# 2) Ex-Dividend Date:
#    - within 3 days => leading "*"
#    - within 7 days => single trailing "*"
#    - within 30 days => double trailing "**"
#
# 3) Pay Date:
#    - if pay_date is in the next 5 days => trailing "*"
#
# All displayed as YYYY-MM-DD with asterisks, never converting to MM/DD/YYYY.
###############################################################################
print_most_recent_dividend() {
  local json="$1"

  # Extract fields from JSON
  local sym cash decl ex pay freq
  sym="$(echo "$json" | jq -r '.Symbol')"
  cash="$(echo "$json" | jq -r '."Cash Amount"')"
  decl="$(echo "$json" | jq -r '."Declaration Date"')"
  ex="$(echo "$json" | jq -r '."Ex-Dividend Date"')"
  pay="$(echo "$json" | jq -r '."Pay Date"')"
  freq="$(echo "$json" | jq -r '.Frequency')"

  local current_secs
  current_secs="$(date_to_seconds "$current_date")"

  ########################################
  # Declaration Date (YYYY-MM-DD + asterisks)
  ########################################
  local decl_str="$decl"
  local decl_secs
  decl_secs="$(date_to_seconds "$decl")"
  if (( decl_secs > 0 )); then
    local age_in_days=$(( (current_secs - decl_secs) / 86400 ))
    local one_year_secs=$((365*86400))
    local decl_plus_year_secs=$(( decl_secs + one_year_secs ))
    local days_until_annual=$(( (decl_plus_year_secs - current_secs) / 86400 ))

    # 1) If decl == current_date => leading "*"
    if [[ "$decl" == "$current_date" ]]; then
      decl_str="*${decl}"
    else
      # 2) 10-17 weeks old => trailing "*"
      if (( age_in_days >= 70 && age_in_days <= 119 )); then
        decl_str="${decl}*"
      # 3) Next annual is within 10 weeks => trailing "*"
      elif (( days_until_annual <= 70 )); then
        decl_str="${decl}*"
      fi
    fi
  fi

  ########################################
  # Ex-Dividend Date (YYYY-MM-DD + asterisks)
  ########################################
  local ex_str="$ex"
  local ex_secs
  ex_secs="$(date_to_seconds "$ex")"
  if (( ex_secs > current_secs )); then
    local days_until_ex=$(( (ex_secs - current_secs) / 86400 ))

    if (( days_until_ex <= 3 )); then
      # within 3 days => leading "*"
      ex_str="*${ex}"
    elif (( days_until_ex <= 7 )); then
      # within 7 days => trailing "*"
      ex_str="${ex}*"
    elif (( days_until_ex <= 30 )); then
      # within 30 days => double trailing "**"
      ex_str="${ex}**"
    fi
  fi

  ########################################
  # Pay Date (YYYY-MM-DD + trailing "*" if within 5 days)
  ########################################
  local pay_str="$pay"
  local pay_secs
  pay_secs="$(date_to_seconds "$pay")"
  if (( pay_secs > current_secs )); then
    local days_until_pay=$(( (pay_secs - current_secs) / 86400 ))
    if (( days_until_pay <= 5 )); then
      pay_str="${pay}*"
    fi
  fi

  # Print the row
  printf "| %-10s | %-14s | %-18s | %-18s | %-12s | %-10s |\n" \
    "$sym" "$cash" "$decl_str" "$ex_str" "$pay_str" "$freq"
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

# We'll check if any are within the next 10 days.
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
