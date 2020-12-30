from fuzzywuzzy import process
import requests

def getCompany(text):
    r = requests.get('https://api.iextrading.com/1.0/ref-data/symbols')
    stockList = r.json()
    return process.extractOne(text, stockList)[0]


# print(getCompany('GOOG'))
# print(getCompany('Alphabet'))
result_dict = getCompany('mastercard')
print(result_dict)
print(result_dict['symbol'])
