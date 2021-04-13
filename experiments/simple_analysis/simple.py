import matplotlib.pyplot as plt
import pandas as pd

df1 = pd.read_csv('data/baseline/no_monitoring/20210413-1428-metrics.csv')
df2 = pd.read_csv('data/baseline/no_monitoring/20210413-1456-metrics.csv')

df3 = pd.read_json('data/baseline/no_monitoring/20210413-1428-iperf-results-metric-collection-no-monitoring.json')
df4 = pd.read_json('data/baseline/no_monitoring/20210413-1454-iperf-results-metric-collection-no-monitoring.json')

# Read baseline iperf3 results
nm_bw1 = pd.read_json('data/baseline/no_monitoring/20210413-1428-iperf-results-metric-collection-no-monitoring.json')
nm_bw2 = pd.read_json('data/baseline/no_monitoring/20210413-1454-iperf-results-metric-collection-no-monitoring.json')
hfp_bw1 = pd.read_json('data/baseline/high_freq_ping/20210413-1650-iperf-results-metric-collection-hfp.json')
hfp_bw2 = pd.read_json('data/baseline/high_freq_ping/20210413-1707-iperf-results-metric-collection-hfp.json')
pcap_bw1 = pd.read_json('data/baseline/pcaps/20210413-1739-iperf-results-metric-collection-pcaps.json')
pcap_bw2 = pd.read_json('data/baseline/pcaps/20210413-1804-iperf-results-metric-collection-pcaps.json')
int_bw1 = pd.read_json('data/baseline/int/20210413-1829-iperf-results-metric-collection-int.json')
int_bw2 = pd.read_json('data/baseline/int/20210413-1851-iperf-results-metric-collection-int.json')

# Read baseline metric results
nm_metrics1 = pd.read_csv('data/baseline/no_monitoring/20210413-1428-metrics.csv')
nm_metrics2 = pd.read_csv('data/baseline/no_monitoring/20210413-1456-metrics.csv')
hfp_metrics1 = pd.read_csv('data/baseline/high_freq_ping/20210413-1652-metrics.csv')
hfp_metrics2 = pd.read_csv('data/baseline/high_freq_ping/20210413-1709-metrics.csv')
pcap_metrics1 = pd.read_csv('data/baseline/pcaps/20210413-1741-metrics.csv')
pcap_metrics2 = pd.read_csv('data/baseline/pcaps/20210413-1807-metrics.csv')
int_metrics1 = pd.read_csv('data/baseline/int/20210413-1831-metrics.csv')
int_metrics2 = pd.read_csv('data/baseline/int/20210413-1853-metrics.csv')

# Combine to a single frame
nm_frames = [nm_bw1, nm_bw2]
hfp_frames = [hfp_bw1, hfp_bw2]
pcap_frames = [pcap_bw1, pcap_bw2]
int_frames = [int_bw1, int_bw2]

nm_metric_frames = [nm_metrics1, nm_metrics2]
hfp_metric_frames = [hfp_metrics1, hfp_metrics2]
pcap_metric_frames = [pcap_metrics1, pcap_metrics2]
int_metric_frames = [int_metrics1, int_metrics2]

nm_result = pd.concat(nm_frames, ignore_index=True)
hfp_result = pd.concat(hfp_frames, ignore_index=True)
pcap_result = pd.concat(pcap_frames, ignore_index=True)
int_result = pd.concat(int_frames, ignore_index=True)

nm_metric_result = pd.concat(nm_metric_frames, ignore_index=True)
hfp_metric_result = pd.concat(hfp_metric_frames, ignore_index=True)
pcap_metric_result = pd.concat(pcap_metric_frames, ignore_index=True)
int_metric_result = pd.concat(int_metric_frames, ignore_index=True)

nm_result = nm_result[nm_result['sent_mbps'] > 2]
hfp_result = hfp_result[hfp_result['sent_mbps'] > 2]
pcap_result = pcap_result[pcap_result['sent_mbps'] > 2]
int_result = int_result[int_result['sent_mbps'] > 2]

nm_metric_result = nm_metric_result[nm_metric_result['cpu1'] > 40]
hfp_metric_result = hfp_metric_result[hfp_metric_result['cpu1'] > 40]
pcap_metric_result = pcap_metric_result[pcap_metric_result['cpu1'] > 40]
int_metric_result = int_metric_result[int_metric_result['cpu1'] > 40]

baseline_bw = [nm_result['sent_mbps'], hfp_result['sent_mbps'], pcap_result['sent_mbps'], int_result['sent_mbps']]
baseline_retr = [nm_result['retransmits'], hfp_result['retransmits'],
                 pcap_result['retransmits'], int_result['retransmits']]
baseline_cpu = [nm_metric_result['cpu1'], hfp_metric_result['cpu1'],
                pcap_metric_result['cpu1'], int_metric_result['cpu1']]
baseline_mem = [nm_metric_result['mem1'], hfp_metric_result['mem1'],
                pcap_metric_result['mem1'], int_metric_result['mem1']]
baseline_disk = [nm_metric_result['kb_wrtn'], hfp_metric_result['kb_wrtn'],
                 pcap_metric_result['kb_wrtn'], int_metric_result['kb_wrtn']]

# frames1 = [df1, df2]
# frames2 = [df3, df4]
#
# result1 = pd.concat(frames1, ignore_index=True)
# result2 = pd.concat(frames2, ignore_index=True)
#
# result1_filtered = result1[result1['cpu1'] > 40]
# result1_filtered = result1_filtered.reset_index().drop(['pid1', 'pid2'], axis=1)

fig_baseline_bw = plt.figure(figsize=(10, 10))
plt.boxplot(baseline_bw, labels=['no_monitoring', 'HFP', 'PCAPs', 'INT'])
plt.title('Baseline Bandwidth')
plt.show()

fig_baseline_retr = plt.figure(figsize=(10, 10))
plt.boxplot(baseline_retr, labels=['no_monitoring', 'HFP', 'PCAPs', 'INT'])
plt.title('Baseline Retransmissions')
plt.show()

fig_baseline_cpu = plt.figure(figsize=(10, 10))
plt.boxplot(baseline_cpu, labels=['no_monitoring', 'HFP', 'PCAPs', 'INT'])
plt.title('Baseline CPU usage of BMV2 switches')
plt.show()

fig_baseline_mem = plt.figure(figsize=(10, 10))
plt.boxplot(baseline_mem, labels=['no_monitoring', 'HFP', 'PCAPs', 'INT'])
plt.title('Baseline Memory usage of BMV2 switches')
plt.show()

fig_baseline_disk = plt.figure(figsize=(10, 10))
plt.boxplot(baseline_disk, labels=['no_monitoring', 'HFP', 'PCAPs', 'INT'])
plt.title('Baseline Disk I/O EPC VM, kBytes written')
plt.show()
