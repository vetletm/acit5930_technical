from datetime import datetime

import pandas as pd
import numpy as np

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

# Transform integer notated IP address to dotted decimal form
for item in items:
    for key in ['sAddr', 'dAddr']:
        item[0][key] = item[0][key].apply(lambda x: dec_to_ip(x))

# Create new aggregated dataframes with the most important information about the results
results = []
for item in items:
    result = item[0].groupby('hash').agg(
        total_pcount=('ploss_count', sum),
        total_loss=('pcount_diff', sum),
        sAddr=('sAddr', set),
        dAddr=('dAddr', set),
        sPort=('sPort', set),
        dPort=('dPort', set),
        prot=('prot', set)
    )
    result['loss_percent'] = (result['total_loss'] / result['total_pcount']) * 100
    result['switch'] = item[1]
    result['case'] = item[2]
    result = result[result['total_pcount'] > 1000]
    results.append(result)

pd.set_option('display.max_columns', None)
pd.set_option('display.max_colwidth', None)
pd.set_option('display.width', 2000)
for item in results:
    # Extract all possible hash collisions, i.e. 2 or more elements in sPort or dPort
    dport_collisions = item.loc[item['dPort'].apply(lambda x: len(list(x)) > 1)]
    sport_collisions = item.loc[item['sPort'].apply(lambda x: len(list(x)) > 1)]
    hash_collisions = pd.concat([dport_collisions, sport_collisions], ignore_index=True)
    # Clean up the final tables to be printed, i.e. all sets are converted to comma-separated values in a string
    to_clean = ['sAddr', 'dAddr', 'sPort', 'dPort', 'prot']
    for column in to_clean:
        item[column] = item[column].apply(lambda x: ','.join(str(i) for i in x))

    print(item.sample(5))
    print('mean loss:', round(item['loss_percent'].mean(), 3))
    if not hash_collisions.empty:
        print('hash collisions:')
        print(hash_collisions)
    print()
