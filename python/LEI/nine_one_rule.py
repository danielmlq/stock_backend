import os
import sys
import shutil
import pandas_datareader as web
import numpy as np

from configobj import ConfigObj


class nine_one_rule:
    def add_date_column(input_df):
        input_df['date'] = input_df.index

    # Calculate customized exponential moving average
    def calculate_input_days_exponential_moving_average(input_df, days, col_name):
        input_df[col_name] = np.round(input_df.iloc[:, 3].ewm(span=days, adjust=False).mean(), 2)

    # Calculate specified days return 1d, 5d (weekly), 20d (monthly)
    def calculate_specified_day_return(input_df, days_back, col_name):
        input_df[col_name] = np.round(((input_df['Close'] / input_df['Close'].shift(days_back)) - 1) * 100, 2)

    # Compare among close, 20d_ema, 60d_ema and 120d_ema
    def calculate_to_compare_values(input_df, input_col1, input_col2, col_name):
        input_df[col_name] = np.round(((input_df[input_col1] - input_df[input_col2]) / input_df[input_col2]) * 100, 2)

    # Clear all the rows contain NAN values
    def clear_nan_rows(input_df, col_name):
        return input_df.loc[(input_df[col_name].notnull())]

    def standardize_accuracy(input_df, col_names):
        col_names_array = col_names.split(',')
        for col_name in col_names_array:
            input_df[col_name] = np.round(input_df[col_name], 2)

    def generate_historical_output(input_df, output_csv_file):
        # Delete legacy data if exists and create new empty output file for storing results.
        if os.path.exists(output_csv_file):
            os.remove(output_csv_file)

        open(output_csv_file, 'a')
        input_df.to_csv(output_csv_file, index=False, header=False)

    def generate_daily_output(input_df, output_csv_file):
        # Delete legacy data if exists and create new empty output file for storing results.
        if os.path.exists(output_csv_file):
            os.remove(output_csv_file)

        open(output_csv_file, 'a')
        input_df.tail(1).to_csv(output_csv_file, index=False, header=False)

    if __name__ == '__main__':
        config_file = sys.argv[1]
        start_date = sys.argv[2]
        end_date = sys.argv[3]
        output_dir = sys.argv[4]

        cfg = ConfigObj(config_file)
        stocks_to_run = cfg.get('STOCKS_TO_RUN')
        ema_days_look_back = cfg.get('EMA_DAYS_TO_LOOK_BACK')
        return_days_look_back = cfg.get('CHANGE_DAYS_TO_LOOK_BACK')
        is_daily_run = cfg.get('IS_DAILY_RUN')

        # Remove pre-exist data and recreate directory
        if os.path.exists(output_dir):
            shutil.rmtree(output_dir)
        os.mkdir(output_dir)

        for stock in stocks_to_run:
            # Delete pre-exist sub_directory and recreate it
            sub_output_dir = "{}/{}/".format(output_dir, stock)
            if os.path.exists(sub_output_dir):
                shutil.rmtree(sub_output_dir)
            os.mkdir(sub_output_dir)

            # Load raw data from Yahoo finance and add date indexes
            input_df = web.DataReader(stock, data_source='yahoo', start=start_date, end=end_date)
            add_date_column(input_df)

            # Calculate exponential moving average values for different days (20, 60, 120)
            for day_to_look_back in ema_days_look_back:
                col_name = "{}d_ema".format(day_to_look_back)
                calculate_input_days_exponential_moving_average(input_df, int(day_to_look_back), col_name)

            # Calculate change values or percentages for certain days of gap.
            for change_day_to_look_back in return_days_look_back:
                col_name = "{}d_change".format(change_day_to_look_back)
                calculate_specified_day_return(input_df, int(change_day_to_look_back), col_name)

            # Compare among close, 20d_ema, 60d_ema and 120d_ema
            calculate_to_compare_values(input_df, 'Close', '20d_ema', 'close_over_short')
            calculate_to_compare_values(input_df, '20d_ema', '60d_ema', 'short_over_medium')
            calculate_to_compare_values(input_df, '60d_ema', '120d_ema', 'medium_over_long')

            input_df = clear_nan_rows(input_df, '20d_change')
            standardize_accuracy(input_df, 'High,Low,Open,Close,Adj Close')

            if is_daily_run == "TRUE":
                generate_daily_output(input_df, "{}/raw.csv".format(sub_output_dir))
            else:
                generate_historical_output(input_df, "{}/raw.csv".format(sub_output_dir))
