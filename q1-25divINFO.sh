#!/bin/zsh

# Define your Finnhub API key
FINNHUB_API_KEY="ctm4tdhr01qvk0t3ap0gctm4tdhr01qvk0t3ap10"

# Define your Polygon.io API key for dividend data
POLYGON_API_KEY="9_vLLYqfkow4neALRDCLwuriDxAIpfxu"

# Define your portfolio as an array of strings in the format "symbol:buy_in_price"
portfolio=(
  "OXLC:5.09"
  "CSWC:21.47"
  "DKL:40.62"
  "HTGC:18.39"
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

# Function to calculate trailing and forward dividend yields
calculate_yields() {
  local symbol="$1"
  local buy_in_price="$2"

  # Fetch dividend data for the symbol
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
    # Check if the date is valid (not null or empty)
    if [[ -z "$dividend_date" || "$dividend_date" == "null" ]]; then
      continue
    fi

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

  # Output results
  echo "$symbol:"
  echo "  Buy-in Price: $buy_in_price"
  echo "  Current Price: $stock_price"
  echo "  Total Dividends (Last Year): $total_dividends"
  echo "  Trailing Yield: $trailing_yield%"
  echo "  Projected Total Dividends (Next Year): $projected_annual_dividend"
  echo "  Forward Yield: $forward_yield%"
  echo ""
}

# Main loop to iterate over portfolio
for entry in "${portfolio[@]}"; do
  IFS=":" read -r symbol buy_in_price <<< "$entry"
  calculate_yields "$symbol" "$buy_in_price"
done
