import matplotlib
import matplotlib.pyplot as plt
import pandas as pd


# Use SVG as default renderer
matplotlib.use('svg')


def save_fig(data, fig_labels, title, ylabel, fig_name):
    fig = plt.figure(figsize=(10, 10))
    plt.boxplot(data, labels=fig_labels)
    plt.title(title)
    plt.grid()
    plt.ylabel(ylabel)
    plt.savefig(fig_name)


nm_d_bw1 = pd.read_json('data/with_delay/no_monitoring/100-50ms/'
                        '20210414-1043-iperf-results-metric-collection-no-monitoring-with-delay.json')
nm_d_bw2 = pd.read_json('data/with_delay/no_monitoring/100-50ms/'
                        '20210414-1109-iperf-results-metric-collection-no-monitoring-with-delay.json')

nm_d_bw3 = pd.read_json('data/with_delay/no_monitoring/250-150ms/'
                        '20210414-1147-iperf-results-metric-collection-no-monitoring-with-delay.json')
nm_d_bw4 = pd.read_json('data/with_delay/no_monitoring/250-150ms/'
                        '20210414-1205-iperf-results-metric-collection-no-monitoring-with-delay.json')

nm_d_bw5 = pd.read_json('data/with_delay/no_monitoring/'
                        '20210414-1237-iperf-results-metric-collection-no-monitoring-with-delay.json')
nm_d_bw6 = pd.read_json('data/with_delay/no_monitoring/'
                        '20210414-1256-iperf-results-metric-collection-no-monitoring-with-delay.json')

nm_d_frames = [nm_d_bw1, nm_d_bw2]
nm_d_results = pd.concat(nm_d_frames, ignore_index=True)
nm_d_results = nm_d_results[nm_d_results['sent_mbps'] > 2]

nm_d_frames2 = [nm_d_bw3, nm_d_bw4]
nm_d_results2 = pd.concat(nm_d_frames2, ignore_index=True)
nm_d_results2 = nm_d_results2[nm_d_results2['sent_mbps'] > 2]

nm_d_frames3 = [nm_d_bw5, nm_d_bw6]
nm_d_results3 = pd.concat(nm_d_frames3, ignore_index=True)
nm_d_results3 = nm_d_results3[nm_d_results3['sent_mbps'] > 2]

delay_bw1 = nm_d_results['sent_mbps']
delay_bw2 = nm_d_results2['sent_mbps']
delay_bw3 = nm_d_results3['sent_mbps']

delay_comp = [delay_bw1, delay_bw2, delay_bw3]

save_fig(delay_comp, ['nm_d_100-50ms', 'nm_d_250-150ms', 'nm_d_500-300ms'], 'Baseline bandwidth with delay',
         'Mb/s', 'delay_bw_comparison')
