#!/bin/zsh

# Define your Finnhub API key
FINNHUB_API_KEY="get_yr_own_API_KEY_https://finnhub.io/"

# Define your Polygon.io API key for dividend data
POLYGON_API_KEY="get_yr_own_API_KEY_https://polygon.io/"

# Define your portfolio as an array of strings in the format "symbol:buy_in_price"
# Feel free to replace with your own list of dividend yielding stocks.
# This particular list is ranked.
# From top to bottom, the highest yield rewards (~19% w/$OXLC and ~5% w/$T)
# Conceptually this associated yield rate is simply what Robinhoood reported on the day ~12/24/2024
# The value can be thought of as the rate that caught my interest.
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
  "SOL:123.14"
  "ATNI:22.46"
  "T:19.5"
)

# Function to fetch real-time stock data from Finnhub
fetch_stock_price() {
  symbol="$1"
  curl -s "https://finnhub.io/api/v1/quote?symbol=${symbol}&token=${FINNHUB_API_KEY}" | jq -r '.c'
}

# Function to fetch dividend data from Polygon.io for the last year
fetch_dividend_data() {
  symbol="$1"
  curl -s "https://api.polygon.io/v3/reference/dividends?ticker=${symbol}&apiKey=${POLYGON_API_KEY}&limit=50" | jq .
}

# Function to fetch SOL cryptocurrency price from Coinbase API
get_crypto_price() {
  response=$(curl -s "https://api.coinbase.com/v2/prices/SOL-USD/spot")
  price=$(echo "$response" | jq -r '.data.amount' 2>/dev/null)
  echo "$price"
}

# Function to calculate trailing and forward dividend yields
calculate_yields() {
  local symbol="$1"
  local buy_in_price="$2"

  # If the symbol is SOL, handle cryptocurrency logic
  if [[ "$symbol" == "SOL" ]]; then
    # Fetch SOL price
    crypto_price=$(get_crypto_price)

    # Check if the response is valid
    if [[ -z "$crypto_price" || "$crypto_price" == "null" ]]; then
      echo "Error fetching cryptocurrency price for $symbol"
      return
    fi

    # Calculate Proj. Div. (Next Yr) as 6% of buy-in price
    projected_dividend=$(echo "$crypto_price * 0.06" | bc)
    
    # Assume a frequency of 73.4 times per year (for a 5-day frequency)
    forward_yield=$(echo "($projected_dividend / $crypto_price) * 100" | bc -l)

    # Format forward yield to two decimal places
    forward_yield=$(printf "%.2f" "$forward_yield")

    # Output the results in tabular format for cryptocurrency
    printf "| %-6s | %-12s | %-12s | %-21s | %-12s | %-23s | %-9s |\n" "$symbol" "$buy_in_price" "$crypto_price" "n/a" "n/a" "$projected_dividend" "$forward_yield%"
    return
  fi

  # Fetch dividend data for the symbol (stocks only)
  dividend_data=$(fetch_dividend_data "$symbol")
  if [[ $? -ne 0 || -z "$dividend_data" || $(echo "$dividend_data" | jq -r '.results') == "null" ]]; then
    echo "Error fetching dividend data for $symbol"
    return
  fi

  # Extract cash amounts and pay dates
  cash_amounts=($(echo "$dividend_data" | jq -r '.results[].cash_amount'))
  pay_dates=($(echo "$dividend_data" | jq -r '.results[].pay_date'))

  # Check if cash_amounts and pay_dates are valid
  if [[ ${#cash_amounts[@]} -eq 0 || ${#pay_dates[@]} -eq 0 ]]; then
    echo "No valid dividend data available for $symbol"
    return
  fi

  # Calculate total dividends over the past year (sum of dividends from the last 12 months)
  total_dividends=0
  current_date=$(date +%s)
  one_year_ago=$(($current_date - 31536000))  # Subtract 1 year in seconds

  # Filter and sum dividends within the last year
  for i in "${!pay_dates[@]}"; do
    dividend_date="${pay_dates[$i]}"
    dividend_timestamp=$(date -j -f "%Y-%m-%d" "$dividend_date" +%s 2>/dev/null)

    # Skip invalid dates
    if [[ $? -ne 0 || $dividend_timestamp -le 0 ]]; then
      continue
    fi

    if [[ $dividend_timestamp -gt $one_year_ago ]]; then
      dividend_index="${cash_amounts[$i]}"
      total_dividends=$(echo "$total_dividends + $dividend_index" | bc)
    fi
  done

  # Fetch real-time stock price from Finnhub
  stock_price=$(fetch_stock_price "$symbol")
  
  # Check for errors
  if [[ -z "$stock_price" || "$stock_price" == "null" ]]; then
    echo "Error fetching stock price for $symbol"
    echo ""
    return
  fi

  # Calculate trailing yield based on total dividends from the last year and current stock price
  trailing_yield=$(printf "%.2f" "$(echo "($total_dividends / $stock_price) * 100" | bc -l)")

  # Now, calculate forward yield based on the sum of dividends for the most recent pay date
  recent_pay_date=$(echo "$pay_dates" | sort -r | head -n 1)  # Most recent pay date
  sum_recent_dividends=0

  # Sum all dividends with the same most recent pay date
  for i in "${!pay_dates[@]}"; do
    if [[ "${pay_dates[$i]}" == "$recent_pay_date" ]]; then
      sum_recent_dividends=$(echo "$sum_recent_dividends + ${cash_amounts[$i]}" | bc)
    fi
  done

  # Calculate forward yield based on this summed dividend for the most recent pay date and frequency
  frequency=$(echo "$dividend_data" | jq -r '.results[0].frequency')
  projected_annual_dividend=$(echo "$sum_recent_dividends * $frequency" | bc -l)
  forward_yield=$(printf "%.2f" "$(echo "($projected_annual_dividend / $stock_price) * 100" | bc -l)")

  # Output the results in tabular format for stocks
  printf "| %-6s | %-12s | %-12s | %-21s | %-12s | %-23s | %-9s |\n" "$symbol" "$buy_in_price" "$stock_price" "$total_dividends" "$trailing_yield%" "$projected_annual_dividend" "$forward_yield%"

  # Add delay to respect the free-tier rate limit of 5 requests per minute (12 seconds delay)
  sleep 12
}

# Output the table header once
echo "+--------+--------------+--------------+-----------------------+--------------+-------------------------+-----------+"
echo "| Symbol | Buy-in Price | Curr. Price  | Tot. Div. (Last Yr)   | TRAIL YLD    | Proj. Div. (Next Yr)    | FWD YLD   |"
echo "+--------+--------------+--------------+-----------------------+--------------+-------------------------+-----------+"

# Main loop to iterate over portfolio
for entry in "${portfolio[@]}"; do
  IFS=":" read -r symbol buy_in_price <<< "$entry"
  calculate_yields "$symbol" "$buy_in_price"
done

# Output the bottom delimiter of the table
echo "+--------+--------------+--------------+-----------------------+--------------+-------------------------+-----------+"
echo ""
