# stock_backend
stock back end service for generating data for front end to display.

LEI Section:
Description: Implementing the stock modules mentioned by LEI in his video

Modules:
1. Nine-One-Rule
    1.1 Purposes:
        For comparing stock performance between specified stocks and indexes (S&P500 - SPY or NASDAQ - QQQ) to tell the performance of which stocks are better than indexes. Job is triggered as a cron job on the server on daily basis.
    
    1.2 Related files:
        ../configs/stock_tracer.cfg
        ../python/LEI/nine_one_rule.py
        ../scripts/LEI/insert_daily_output.sh
        ../scripts/LEI/setup_env_and_load_history_data.sh
    
    1.3 Commands to run:
        e.g. sh /Users/danielmeng/Downloads/stock_backend/scripts/LEI/insert_daily_output.sh /Users/danielmeng/Downloads/stock_backend/configs/stock_tracer.cfg
        e.g. sh /Users/danielmeng/Downloads/stock_backend/scripts/LEI/setup_env_and_load_history_data.sh /Users/danielmeng/Downloads/stock_backend/configs/stock_tracer.cfg
    
    1.4 Steps to run:
        Update the properties in the stock_tracer.cfg (STOCKS_TO_RUN, IS_DAILY_RUN, NINE_ONE_RULE_STOCK_OUTPUT_DIR, NINE_ONE_RULE_MODEL_PYTHON_DIR)
        Run the command in 1.3
    
    1.5 Postgre table description
        1.5.1 Table name: 
            ${stock}_information   ${stock} is the variable of stock symbol e.g. Symbol of Apple is AAPL.
        1.5.2 Columns with definitions: (16 columns)
            stock_global_id (primary_key): bigint, used to identify the record within the table. (GUID)
            date: Date, used to tell the date of the records
            high: double precision, tell the high price of the stock for specified date.
            low: double precision, tell the low price of the stock for specified date.
            open: double precision, tell the open price of the stock for specified date.
            close: double precision, tell the close price of the stock for specified date.
            volume: double precision, quantity of stocks get traded within a specified date.
            adj_close: double precision, adjusted close price.
            short_term_ema: double precision, 20 days exponential moving average.
            medium_term_ema: double precision, 60 days exponential moving average.
            long_term_ema: double precision, 120 days exponential moving average.
            daily_change: double precision, price difference in percentage between today and yesterday. e.g. (today_close_price / yesterday_close_price) - 1
            weekly_change: double precision, price difference in percentage between today and 5 days ago. e.g. (today_close_price / 5days_ago_close_price) - 1
            monthly_change: double precision, price difference in percentage between today and 20 days ago. e.g. (today_close_price / 20days_ago_close_price) - 1
            close_over_short: double precision, percentage difference between close and short_term_ema. e.g. ((close - short_term_ema) / short_term_ema) * 100
            short_over_medium: double precision, percentage difference between short_term_ema and medium_term_ema. e.g. ((short_term_ema - medium_term_ema) / medium_term_ema) * 100
            medium_over_long: double precision, percentage difference between medium_term_ema and long_term_ema. e.g. ((medium_term_ema - long_term_ema) / long_term_ema) * 100
    
    1.6 UI display
        Back-end calculate the values of the columns above for SPY(S&P 500) and QQQ(NASDAQ) as well. Each stock need to be compared to the indexes with following rules:
        pre-condition: value of columns of a specified stock is positive (value > 0)
        1.6.1 value of column for a specified stock is more than SPY/QQQ value of the same column -> display light green color
        1.6.2 value of column for a specified stock is less than SPY/QQQ value of the same column -> display dark green color
        pre-condition: value of columns for a specified stock is negative (value < 0)
        1.6.3 value of column for a specified stock is less than SPY/QQQ value of the same colmnn -> display dark red color
        1.6.4 value of column for a specified stock is more than SPY/QQQ value of the same column -> display light red color
        1.6.5 columns that need to use the algorithm above: short_term_ema, medium_term_ema, long_term_ema, daily_change, weekly_change, monthly_change, close_over_short, short_over_medium, medium_over_long
        
        Business logics details: (compare apple with S&P 500)
        1. we get the specified columns values of S&P 500 from spy_infomration,
        2. we get the same clumns values of Apple from aapl_information.
        3.1 compare the vlaues of column with 0, if > 0 green, if less than 0 red.
        3.2 compare the values of the columns with same columns values of spy, if > spy values -> light if < spy values -> dark color
        Result:
        light green -> value is more than spy and positive.
        dark green -> value is less than spy but positive
        light red -> value is more than spy but negative
        dark red -> value is less than spy and negative
