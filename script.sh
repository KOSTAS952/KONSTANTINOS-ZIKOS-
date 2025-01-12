#!/bin/bash

# Number of products, customers, and orders per customer
NUM_PRODUCTS=20
NUM_CUSTOMERS=10  # Updated to 10 customers
ORDERS_PER_CUSTOMER=10

# Declare catalog (simulated with an associative array)
declare -A catalog
declare -A order_stats
declare -A order_results
declare -A customer_totals

# Initialize catalog with product description, price, and stock count
for i in {0..19}; do
  price=$((RANDOM % 50 + 5))  # Random price between 5 and 55
  catalog[$i]="Product_$i $price 2"  # Format: description, price, stock_count
  order_stats[$i]="0 0"  # Format: request_count, sold_count
  order_results[$i]=""
  customer_totals[$i]=0  # Initialize total revenue per product
done

# Function to handle customer orders
process_order() {
  local product_id=$1
  local customer_pid=$2
  local order_result="Order for Product_$product_id failed"
  local total_price=0

  # Extract product information from catalog
  IFS=' ' read -r description price stock <<< "${catalog[$product_id]}"

  # Check product availability and process the order
  if [[ $stock -gt 0 ]]; then
    # Decrease stock by 1
    catalog[$product_id]="${description} $price $(($stock - 1))"

    # Update order stats
    order_stats[$product_id]=$(($(echo ${order_stats[$product_id]} | cut -d' ' -f1) + 1))  # Increment request count
    order_stats[$product_id]=$(($(echo ${order_stats[$product_id]} | cut -d' ' -f2) + 1))  # Increment sold count
    total_price=$price
    order_result="CLIENT $customer_pid PURCHASE COMPLETE, YOUR TOTAL: $total_price$"
  else
    order_stats[$product_id]=$(($(echo ${order_stats[$product_id]} | cut -d' ' -f1) + 1))  # Increment request count
    order_result="CLIENT $customer_pid PURCHASE WAS UNSUCCESSFUL"
    order_results[$product_id]="${order_results[$product_id]} Customer_$customer_pid failed for Product_$product_id. "
  fi

  # Send result back to customer
  echo "$order_result" > "pipe_from_server_to_$customer_pid"
  customer_totals[$customer_pid]=$((${customer_totals[$customer_pid]} + total_price))
}

# Create pipes and fork customer processes
for customer_pid in {1..10}; do  # Change to 10 customers
  mkfifo "pipe_to_server_from_$customer_pid"
  mkfifo "pipe_from_server_to_$customer_pid"

  # Fork a customer process
  (
    for i in {1..10}; do
      # Randomly choose a product from 0 to NUM_PRODUCTS-1
      product_id=$(($RANDOM % NUM_PRODUCTS))
      echo $product_id > "pipe_to_server_from_$customer_pid"

      # Wait for order result from server
      order_result=$(cat "pipe_from_server_to_$customer_pid")
      echo "$order_result"
      sleep 1  # Wait 1 second between orders
    done
  ) &
done

# Main server process
for customer_pid in {1..10}; do  # Change to 10 customers
  for i in {1..10}; do
    product_id=$(cat "pipe_to_server_from_$customer_pid")  # Read order from customer
    process_order $product_id $customer_pid  # Process the order
  done
done

# Wait for all customer processes to finish
wait

# Report generation
echo "------------------------------------"
echo "Summary Report"
echo "------------------------------------"
total_orders=0
successful_orders=0
failed_orders=0
total_revenue=0

# Loop through the catalog for generating the report
for i in {0..19}; do
  IFS=' ' read -r description price stock <<< "${catalog[$i]}"
  requests=$(echo ${order_stats[$i]} | cut -d' ' -f1)
  sold=$(echo ${order_stats[$i]} | cut -d' ' -f2)

  total_orders=$((total_orders + requests))
  successful_orders=$((successful_orders + sold))
  failed_orders=$((failed_orders + (requests - sold)))
  total_revenue=$((total_revenue + (sold * price)))

  echo "Product: $description"
  echo "  Requests: $requests"
  echo "  Sold: $sold"
  echo "  Unfulfilled Requests: $(($requests - $sold))"
  echo "  Customers who failed: ${order_results[$i]}"
  echo "------------------------------------"
done

# Print final summary
echo "Total Orders: $total_orders"
echo "Successful Orders: $successful_orders"
echo "Failed Orders: $failed_orders"
echo "Total Revenue: $total_revenue"
echo "------------------------------------"

# Print customer totals
echo "------------------------------------"
echo "Customer Purchase Totals"
echo "------------------------------------"
for customer_pid in {1..10}; do  # Change to 10 customers
  echo "CLIENT $customer_pid TOTAL REVENUE: ${customer_totals[$customer_pid]}$"
done
echo "------------------------------------"
