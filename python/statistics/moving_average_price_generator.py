import sys
import pandas_datareader as web
import numpy as np
import matplotlib.pyplot as plt

plt.style.use('fivethirtyeight')

class moving_average_price_generator:

    def add_date_column(input_df):
        input_df['Date'] = input_df.index

    # Calculate customized simple moving average
    def calculate_input_days_simple_moving_average(input_df, days, col_name):
        input_df[col_name] = np.round(input_df.iloc[:, 3].rolling(window=days).mean(), 2)

    # Calculate customized exponential moving average
    def calculate_input_days_exponential_moving_average(input_df, days, col_name):
        input_df[col_name] = np.round(input_df.iloc[:, 3].ewm(span=days, adjust=False).mean(), 2)

    # Filter out rows has Nan value
    def clear_nan_rows(input_df):
        return input_df.loc[(input_df['SMA'].notnull())]

    def plot_trend(input_df, stock):
        plt.figure(figsize=(16,8))
        plt.title(stock)
        plt.xlabel('Date', fontsize=18)
        plt.ylabel('USD ($)', fontsize=18)
        plt.plot(input_df[['Close', 'SMA', 'EMA']])
        plt.legend(['Close', 'SMA', 'EMA'], loc='lower right')
        plt.show()

    if __name__ == '__main__':
        stock_to_run = sys.argv[1]
        start_date = sys.argv[2]
        end_date = sys.argv[3]
        days_look_back = int(sys.argv[4])
        output_csv_file = sys.argv[5]

        stock_array = stock_to_run.split(',')

        for stock in stock_array:
            input_df = web.DataReader(stock, data_source='yahoo', start=start_date, end=end_date)
            add_date_column(input_df)

            calculate_input_days_simple_moving_average(input_df, days_look_back, 'SMA')
            calculate_input_days_exponential_moving_average(input_df, days_look_back, 'EMA')
            input_df = clear_nan_rows(input_df)

            plot_trend(input_df, stock)
            input_df.to_csv(output_csv_file, index=False, header=True)