import pandas as pd
import numpy as np

from datetime import datetime

from utils import save_scatterplot, save_histogram, save_boxplot

print(datetime.now(), 'Starting parsing')
# These are more than 580,000 lines each, be patient
s2_timediffs = pd.read_json('data/baseline/int/s2_timediffs.json').sample(5000)
s3_timediffs = pd.read_json('data/baseline/int/s3_timediffs.json').sample(5000)
print(datetime.now(), 'Parsed INT baseline, 10000 samples')

s2_timediffs_d = pd.read_json('data/with_delay/int/s2_timediffs.json').sample(5000)
s3_timediffs_d = pd.read_json('data/with_delay/int/s3_timediffs.json').sample(5000)
print(datetime.now(), 'Parsed INT with delay, 10000 samples')

s2_timediffs_ed = pd.read_json('data/with_delay/int/s2_timediffs.json').sample(5000)
s3_timediffs_ed = pd.read_json('data/with_delay/int/s3_timediffs.json').sample(5000)
print(datetime.now(), 'Parsed INT with delay at EPC, 10000 samples')

items = [
    ('s2', s2_timediffs), ('s3', s3_timediffs),
    ('s2_d', s2_timediffs_d), ('s3_d', s3_timediffs_d),
    ('s2_ed', s2_timediffs_ed), ('s3_ed', s3_timediffs_ed)
]

print(datetime.now(), 'Starting to draw and save figures')
for item in items:
    name = item[0]
    df = item[1]

    # Replace all values in X that are larger than 15960 to ensure similar scaling
    a = np.array(df['time_diff'].values.tolist())
    df['time_diff'] = np.where(a > 15960, 15960, a).tolist()
    x = df['time_diff']
    y = df['inc_time_diff']

    title = f'Time Diff vs Inc Time Diff, {name}'
    # Draw and save figures
    save_histogram(x, y, 30, title, 'Millisecs', f'figures/int/{name}_td_v_itd_hist_delay')
    # save_scatterplot(x, y, title, 'inc_time_diff', 'time_diff', f'figures/int/{name}_td_v_itd_scatter_delay')

    print('\t', datetime.now(), f'Draw histogram and scatterplott of {name}')
#    save_boxplot([x, y], ['time_diff', 'inc_time_diff'],
#                 f'Time Diff vs Inc Time Diff, {name}',
#                 'milliseconds',
#                 f'figures/int/{name}_td_v_itd_box_delay'
#                 )
print(datetime.now(), 'Finished parsing and drawing')
