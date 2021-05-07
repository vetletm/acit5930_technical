import pandas as pd
import numpy as np

from datetime import datetime
from scipy import stats

from utils import save_scatter_with_line_regr


print(datetime.now(), 'Starting parsing')
# These are more than 580,000 lines each, be patient
s2_timediffs = pd.read_json('data/baseline/int/s2_timediffs.json').sample(50000)
s3_timediffs = pd.read_json('data/baseline/int/s3_timediffs.json').sample(50000)
print(datetime.now(), 'Parsed INT baseline, 100000 samples')

s2_timediffs_d = pd.read_json('data/with_delay/int/s2_timediffs.json').sample(50000)
s3_timediffs_d = pd.read_json('data/with_delay/int/s3_timediffs.json').sample(50000)
print(datetime.now(), 'Parsed INT with delay, 100000 samples')

s2_timediffs_ed = pd.read_json('data/with_delay/int_epc_delay/s2_timediffs.json').sample(50000)
s3_timediffs_ed = pd.read_json('data/with_delay/int_epc_delay/s3_timediffs.json').sample(50000)
print(datetime.now(), 'Parsed INT with delay at EPC, 100000 samples')

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

    slope, intercept, r_value, p_value, std_err = stats.linregress(x, y)
    eq_label = f'{round(slope, 3)}x + {round(intercept, 3)}'
    title = f'Time Diff vs Inc Time Diff, {name}, ' \
            + '$r^{2}=' + str(round(r_value, 3)) + '$'
    # Draw and save figures
    # save_histogram(x, y, 30, title, 'Millisecs', f'figures/int/hists/{name}_td_v_itd_hist')
    save_scatter_with_line_regr(x, y, slope, intercept, title, 'inc_time_diff', 'time_diff', eq_label,
                                f'figures/testing/{name}_td_v_itd_scatter_lineregr_rsqrd')
    print(datetime.now(), f'--- Drawn scatterplott of {name}')

print(datetime.now(), 'Finished parsing and drawing')
