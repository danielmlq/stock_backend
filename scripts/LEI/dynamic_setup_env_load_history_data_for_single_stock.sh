#!/bin/bash

config_file=$1
if [ -z $config_file ]; then
    echo "Need provide config file."
    exit 99
fi

source $config_file
stock_input=$2

# Start of definition of functions
function fetch_symbol_from_stock() {
    stock_input=$1
    stock_symbol=$(PYTHON3 $STOCK_SYMBOL_FETCHER_PYTHON_DIR $stock_input)
}

function setup_new_stock_environment(){
    stock_name=$1

    prediction_env_sequence_creation_query="create sequence ${stock_name}_sequence_id_seq"

    prediction_env_creation_query="create table if not exists ${stock_name}_information (
                                        stock_global_id Bigint DEFAULT nextval('${stock_name}_sequence_id_seq'),
                                        date Date NOT NULL UNIQUE,
                                        high Float NOT NULL,
                                        low Float NOT NULL,
                                        open Float NOT NULL,
                                        close Float NOT NULL,
                                        volume Double Precision NOT NULL,
                                        adj_close Float NOT NULL,
                                        short_term_ema Float NOT NULL,
                                        medium_term_ema Float NOT NULL,
                                        long_term_ema Float NOT NULL,
                                        daily_change Float NOT NULL,
                                        weekly_change Float NOT NULL,
                                        monthly_change Float NOT NULL,
                                        close_over_short Float NOT NULL,
                                        short_over_medium Float NOT NULL,
                                        medium_over_long Float NOT NULL,
                                        PRIMARY KEY (stock_global_id)
                                    )"

    psql "host=$DB_HOST dbname=$DB_NAME user=$DB_USER password=$DB_PWD" -c "$prediction_env_sequence_creation_query"
    psql "host=$DB_HOST dbname=$DB_NAME user=$DB_USER password=$DB_PWD" -c "$prediction_env_creation_query"
}
# End of definition of functions

echo "Step 1 -> Fetch symbol from the stock input"
fetch_symbol_from_stock $stock_input
echo "Finished fetching symbol from the stock input. symbol is $stock_symbol"

echo "Step 2 -> Setting up database environment for all the input stocks if not exist"
setup_new_stock_environment $stock_symbol
echo "Finished setting up database environment for all the input stocks if not exist"

echo "Step 3 -> Trigger calculating nine_one_rule for stock_symbol: $stock_symbol"
python3 $DYNAMIC_NINE_ONE_RULE_MODEL_PYTHON_DIR $config_file $stock_symbol '1990-01-01' '2021-12-11' $NINE_ONE_RULE_STOCK_OUTPUT_DIR
echo "Finished running nine_one_rule for all the input stocks"

echo "Step 4 -> Storing nine_one_rule result to database"
    psql "host=$DB_HOST dbname=$DB_NAME user=$DB_USER password=$DB_PWD" -t -c "\copy ${stock_symbol}_information(high, low, open, close, volume, adj_close, date, short_term_ema, medium_term_ema, long_term_ema, daily_change, weekly_change, monthly_change, close_over_short, short_over_medium, medium_over_long) from '$NINE_ONE_RULE_STOCK_OUTPUT_DIR/$stock_symbol/raw.csv' WITH DELIMITER ','"
echo "Finished storing nine_one_rule to database"
