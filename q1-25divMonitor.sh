#!/bin/bash

# Set your Finnhub API key (Free Tier LIMIT: 60 requests per min)
API_KEY="get_yr_own_API_KEY_https://finnhub.io/"

# Define your portfolio as an array of strings in the format "symbol:buy_in_price" (in USD)
# Context: Q1'25 these are some dividend and reward yielding stocks (and 1 crypto) in a portfolio I am monitoring regularly
# I have yet to explore RapidAPI's Seeking Alpha https://rapidapi.com/apidojo/api/seeking-alpha/pricing
# So far I have tried polygon.io (5 API requests per minute)
# and https://www.alphavantage.co/ but I am ignorant of other simple and FREE means to get current price and dividend data
# Please feel free to replace my list of stocks and buy in prices with yur own portfolio!
# REQUIRES jq & curl in yr env

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

# Global variable to track the last request time (per the free tier API call limits)
last_request_time=0

# Function to fetch the current stock price from Finnhub API
get_stock_price() {
  local symbol=$1
  
  # Get the current time in seconds since epoch
  local current_time=$(date +%s)

  # If less than 1 second has passed since the last request, sleep
  if (( current_time - last_request_time < 1 )); then
    sleep_time=$(( 1 - (current_time - last_request_time) ))
    echo "Sleeping for $sleep_time seconds to respect rate limit."
    sleep $sleep_time
  fi

  # Send the request to Finnhub API
  response=$(curl -s "https://finnhub.io/api/v1/quote?symbol=$symbol&token=$API_KEY")
  
  # Update the last request time
  last_request_time=$(date +%s)

  # Extract the current price from the response (field 'c' i.e. cost)
  current_price=$(echo "$response" | jq -r '.c')
  
  echo "$current_price"
}

# Function to fetch SOL cryptocurrency price from the Coinbase API
get_crypto_price() {
  response=$(curl -s "https://api.coinbase.com/v2/prices/SOL-USD/spot")
  price=$(echo "$response" | jq -r '.data.amount' 2>/dev/null)
  echo "$price"
}

# Function to calculate and format percentage difference
calculate_percentage() {
  local buy_in_price=$1
  local current_price=$2

  # Calculate the percentage difference
  percent_change=$(echo "scale=5; (($current_price - $buy_in_price) / $buy_in_price) * 100" | bc)

  # Round the result to 2 decimal places (for readability)
  percent_change_rounded=$(echo "$percent_change" | awk '{printf "%.2f", $1}')

  # Add a space if positive, keep negative values as is
  if (( $(echo "$percent_change > 0" | bc -l) )); then
    percent_change_rounded=" $percent_change_rounded"  # Add leading space for positive percentages
  fi

  # Return the formatted percentage
  echo "$percent_change_rounded"
}

# Report header
echo "Symbol | Buy-In Price | Current Price | Delta      | % Change"
echo "-------------------------------------------------------------"

# Iterate through each stock in the portfolio
for stock in "${portfolio[@]}"; do
  symbol="${stock%%:*}"     # Extract symbol
  buy_in="${stock##*:}"     # Extract buy-in price

  # Check if the symbol is SOL (cryptocurrency)
  if [[ "$symbol" == "SOL" ]]; then
    current_price=$(get_crypto_price)
  else
    current_price=$(get_stock_price "$symbol")
  fi

  # Check if the API returned a valid price
  if [[ -z "$current_price" || "$current_price" == "null" ]]; then
    echo "$symbol | $buy_in | Error fetching price"
  else
    # Calculate the delta
    delta=$(echo "scale=2; $current_price - $buy_in" | bc)
    
    # Calculate the percentage change with the new function
    percent_change=$(calculate_percentage "$buy_in" "$current_price")

    # Print the data
    printf "%-6s | %-12s | %-13s | %-10s | %-8s%%\n" "$symbol" "$buy_in" "$current_price" "$delta" "$percent_change"
  fi
done
