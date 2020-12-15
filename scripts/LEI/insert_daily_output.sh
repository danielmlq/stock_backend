#!/bin/bash

config_file=$1
if [ -z $config_file ]; then
    echo "Need provide config file."
    exit 99
fi

source $config_file

end_date=`date +"%Y-%0m-%d"`

echo "Step 1 -> Trigger calculating nine_one_rule daily result for all the input stocks"
python3 $NINE_ONE_RULE_MODEL_PYTHON_DIR $config_file '2020-07-31' $end_date $NINE_ONE_RULE_STOCK_OUTPUT_DIR
echo "Finished running nine_one_rule daily result for all the input stocks"

echo "Step 2 -> Storing nine_one_rule daily result to database"
IFS=',' read -r -a stocks_array <<< "$STOCKS_TO_RUN"
for stock in "${stocks_array[@]}"
do
    echo "$stock"
    psql "host=$DB_HOST dbname=$DB_NAME user=$DB_USER password=$DB_PWD" -t -c "\copy ${stock}_information(high, low, open, close, volume, adj_close, date, short_term_ema, medium_term_ema, long_term_ema, daily_change, weekly_change, monthly_change, close_over_short, short_over_medium, medium_over_long) from '$NINE_ONE_RULE_STOCK_OUTPUT_DIR/$stock/raw.csv' WITH DELIMITER ','"
done
echo "Finished storing nine_one_rule daily result to database"