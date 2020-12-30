import sys
from fuzzywuzzy import process
import requests

class stock_symbol_fetcher:
    def get_company_symbol(input_str):
        r = requests.get('https://api.iextrading.com/1.0/ref-data/symbols')
        stockList = r.json()
        return process.extractOne(input_str, stockList)[0]

    if __name__ == '__main__':
        stock_input = sys.argv[1]
        result_dict = get_company_symbol(stock_input)

        print(result_dict['symbol'])