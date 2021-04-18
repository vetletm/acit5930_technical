import matplotlib
import pandas as pd
import matplotlib.pyplot as plt

# Use SVG as default renderer
matplotlib.use('svg')

nm_bw1 = pd.read_json('data/baseline/no_monitoring/old_results/'
                      '20210413-1428-iperf-results-metric-collection-no-monitoring.json')
nm_bw2 = pd.read_json('data/baseline/no_monitoring/old_results/'
                      '20210413-1454-iperf-results-metric-collection-no-monitoring.json')

nm_bw3 = pd.read_json('data/baseline/no_monitoring/20210416-1308-iperf-results-metric-collection-no-monitoring.json')
nm_bw4 = pd.read_json('data/baseline/no_monitoring/20210416-1325-iperf-results-metric-collection-no-monitoring.json')

nm_bw5 = pd.read_json('data/baseline/no_monitoring/20210417-0927-iperf-results-metric-collection-no-monitoring.json')
nm_bw6 = pd.read_json('data/baseline/no_monitoring/20210417-0944-iperf-results-metric-collection-no-monitoring.json')

trshoot = pd.read_json('data/troubleshooting/20210417-1122-iperf-results-test-retransmits.json')

nm_1_frames = [nm_bw1, nm_bw2]
nm_2_frames = [nm_bw3, nm_bw4]
nm_3_frames = [nm_bw5, nm_bw6]

nm_1_result = pd.concat(nm_1_frames, ignore_index=True)
nm_2_result = pd.concat(nm_2_frames, ignore_index=True)
nm_3_result = pd.concat(nm_3_frames, ignore_index=True)

baseline_bw = [
    nm_1_result['sent_mbps'],
    nm_2_result['sent_mbps'],
    nm_3_result['sent_mbps'],
    trshoot['sent_mbps']
]

baseline_retr = [
    nm_1_result['retransmits'],
    nm_2_result['retransmits'],
    nm_3_result['retransmits'],
    trshoot['retransmits']
]

labels = ['1st baseline', '2nd baseline', '3rd baseline', 'Trshoot']
figs = [
    [baseline_bw, 'Baseline Bandwidth, multiple readings', 'Mb/s', 'figures/multiple_baselines_bw'],
    [baseline_retr, 'Baseline Retransmissions, multiple readings', 'Retransmissions', 'figures/multiple_baselines_retr'],
]

fig, axs = plt.subplots(1, 2, figsize=(10, 10))
axs[0].boxplot(baseline_bw, labels=labels)
axs[0].set_title('Baseline Bandwidth, multiple readings')
axs[0].set_ylabel('Mb/s')

axs[1].boxplot(baseline_retr, labels=labels)
axs[1].set_title('Baseline Retransmissions, multiple readings')
axs[1].set_ylabel('retransmissions')

plt.savefig('baseline_bw_retr')
plt.close(fig)
