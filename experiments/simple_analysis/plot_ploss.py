from datetime import datetime

import pandas as pd
import matplotlib.pyplot as plt

from matplotlib.ticker import PercentFormatter

from utils import dec_to_ip

names = [
    'data/ploss/baseline/s2_loss.json',
    'data/ploss/baseline/s3_loss.json',
    'data/ploss/with_loss/s2_loss.json',
    'data/ploss/with_loss/s3_loss.json',
]
print(datetime.now(), 'Starting parsing')
items = []
for name in names:
    item = pd.read_json(name)
    switch_name = name.split('/')[-1].split('_')[0]
    case = name.split('/')[2]
    items.append((item, switch_name, case))

print(datetime.now(), 'Finished parsing')

# s2_ploss = pd.read_json('data/ploss/s2_ploss.json')
# s3_ploss = pd.read_json('data/ploss/s3_ploss.json')

# Transform integer notated IP address to dotted decimal form
for item in items:
    for key in ['sAddr', 'dAddr']:
        item[0][key] = item[0][key].apply(lambda x: dec_to_ip(x))

results = []
for item in items:
    result = item[0].groupby('hash').agg(
        total_pcount=('ploss_count', sum),
        total_inc_pcount=('inc_pcount', sum),
        total_loss=('pcount_diff', sum)
    )
    # add new column that displays the loss percent of each flow
    result['loss_percent'] = (result['total_loss'] / result['total_pcount']) * 100
    result = result[result['total_pcount'] > 1000]
    results.append(result)

final = []
for result, item in zip(results, items):
    final.append({
        'name': item[1],
        'case': item[2],
        'loss_percent': round(result['loss_percent'].mean(), 3)
    })

print(final)
