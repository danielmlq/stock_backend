#!/bin/bash

config_file=$1
if [ -z $config_file ]; then
    echo "Need provide config file."
    exit 99
fi

source $config_file

# Start of definition of functions
function setup_sp500_environment(){
    stock_list_file_dir=$1

    sp500_list_sequence_creation_query="create sequence sp500_list_sequence_id_seq"

    sp500_list_env_creation_query="create table if not exists spy_stock_list (
                                        spy_stock_id Bigint DEFAULT nextval('sp500_list_sequence_id_seq'),
                                        symbol VARCHAR(40) NOT NULL,
                                        name VARCHAR(1000) NOT NULL,
                                        sector VARCHAR(1000) NOT NULL,
                                        PRIMARY KEY (spy_stock_id)
                                 )"

    psql "host=$DB_HOST dbname=$DB_NAME user=$DB_USER password=$DB_PWD" -c "$sp500_list_sequence_creation_query"
    psql "host=$DB_HOST dbname=$DB_NAME user=$DB_USER password=$DB_PWD" -c "$sp500_list_env_creation_query"
    psql "host=$DB_HOST dbname=$DB_NAME user=$DB_USER password=$DB_PWD" -t -c "\copy spy_stock_list(symbol, name, sector) from '$stock_list_file_dir' WITH DELIMITER ',' CSV HEADER"
}

function setup_nasdaq100_environment(){
    stock_list_file_dir=$1

    nasdaq_list_sequence_creation_query="create sequence nasdaq_list_sequence_id_seq"

    nasdaq_list_env_creation_query="create table if not exists nasdaq_stock_list (
                                        nasdaq_stock_id Bigint DEFAULT nextval('nasdaq_list_sequence_id_seq'),
                                        symbol VARCHAR(40) NOT NULL,
                                        name VARCHAR(1000) NOT NULL,
                                        sector VARCHAR(1000) NOT NULL,
                                        PRIMARY KEY (nasdaq_stock_id)
                                  )"

    psql "host=$DB_HOST dbname=$DB_NAME user=$DB_USER password=$DB_PWD" -c "$nasdaq_list_sequence_creation_query"
    psql "host=$DB_HOST dbname=$DB_NAME user=$DB_USER password=$DB_PWD" -c "$nasdaq_list_env_creation_query"
    psql "host=$DB_HOST dbname=$DB_NAME user=$DB_USER password=$DB_PWD" -t -c "\copy nasdaq_stock_list(symbol, name, sector) from '$stock_list_file_dir' WITH DELIMITER ',' CSV HEADER"
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
echo "Step 1.1 -> Setting up database environment for list of SP500 stocks"
setup_sp500_environment $SPY_STOCK_LIST_DIR
echo "Finished setting up database environment for list of SP500 stocks"


echo "Step 1.2 -> Setting up database environment for list of NASDAQ stocks"
setup_nasdaq100_environment $NASDAQ_STOCK_LIST_DIR
echo "Finished setting up database environment for list of NASDAQ stocks"


echo "Step 2 -> Setting up database environment for all the input stocks if not exist"
IFS=',' read -r -a stocks_array <<< "$STOCKS_TO_RUN"
for stock in "${stocks_array[@]}"
do
    setup_new_stock_environment $stock
done
echo "Finished setting up database environment for all the input stocks if not exist"


echo "Step 3 -> Trigger calculating nine_one_rule for all the input stocks"
python3 $NINE_ONE_RULE_MODEL_PYTHON_DIR $config_file '1990-01-01' '2021-12-11' $NINE_ONE_RULE_STOCK_OUTPUT_DIR
echo "Finished running nine_one_rule for all the input stocks"


echo "Step 4 -> Storing nine_one_rule result to database"
for stock in "${stocks_array[@]}"
do
    psql "host=$DB_HOST dbname=$DB_NAME user=$DB_USER password=$DB_PWD" -t -c "\copy ${stock}_information(high, low, open, close, volume, adj_close, date, short_term_ema, medium_term_ema, long_term_ema, daily_change, weekly_change, monthly_change, close_over_short, short_over_medium, medium_over_long) from '$NINE_ONE_RULE_STOCK_OUTPUT_DIR/$stock/raw.csv' WITH DELIMITER ','"
done
echo "Finished storing nine_one_rule to database"