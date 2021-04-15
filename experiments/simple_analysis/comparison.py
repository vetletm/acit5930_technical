import pandas as pd

from utils import save_fig

nm_bw1 = pd.read_json('data/baseline/no_monitoring/20210413-1428-iperf-results-metric-collection-no-monitoring.json')
nm_bw2 = pd.read_json('data/baseline/no_monitoring/20210413-1454-iperf-results-metric-collection-no-monitoring.json')
nm_d_bw1 = pd.read_json('data/with_delay/no_monitoring/'
                        '20210414-1237-iperf-results-metric-collection-no-monitoring-with-delay.json')
nm_d_bw2 = pd.read_json('data/with_delay/no_monitoring/'
                        '20210414-1256-iperf-results-metric-collection-no-monitoring-with-delay.json')

hfp_bw1 = pd.read_json('data/baseline/high_freq_ping/20210413-1650-iperf-results-metric-collection-hfp.json')
hfp_bw2 = pd.read_json('data/baseline/high_freq_ping/20210413-1707-iperf-results-metric-collection-hfp.json')
hfp_d_bw1 = pd.read_json('data/with_delay/hfp/20210414-1409-iperf-results-metric-collection-hfp-delay.json')
hfp_d_bw2 = pd.read_json('data/with_delay/hfp/20210414-1432-iperf-results-metric-collection-hfp-delay.json')

pcap_bw1 = pd.read_json('data/baseline/pcaps/20210414-1325-iperf-results-metric-collection-pcap.json')
pcap_bw2 = pd.read_json('data/baseline/pcaps/20210414-1344-iperf-results-metric-collection-pcap.json')
pcap_d_bw1 = pd.read_json('data/with_delay/pcaps/20210414-1505-iperf-results-metric-collection-pcaps-delay.json')
pcap_d_bw2 = pd.read_json('data/with_delay/pcaps/20210414-1525-iperf-results-metric-collection-pcaps-delay.json')

int_bw1 = pd.read_json('data/baseline/int/20210413-1829-iperf-results-metric-collection-int.json')
int_bw2 = pd.read_json('data/baseline/int/20210413-1851-iperf-results-metric-collection-int.json')
int_d_bw1 = pd.read_json('data/with_delay/int/20210415-0927-iperf-results-metric-collection-int-delay.json')
int_d_bw2 = pd.read_json('data/with_delay/int/20210415-0952-iperf-results-metric-collection-int-delay.json')

nm_metrics1 = pd.read_csv('data/baseline/no_monitoring/20210413-1428-metrics.csv')
nm_metrics2 = pd.read_csv('data/baseline/no_monitoring/20210413-1456-metrics.csv')
nm_d_metrics1 = pd.read_csv('data/with_delay/no_monitoring/20210414-1237-metrics.csv')
nm_d_metrics2 = pd.read_csv('data/with_delay/no_monitoring/20210414-1256-metrics.csv')

hfp_metrics1 = pd.read_csv('data/baseline/high_freq_ping/20210413-1652-metrics.csv')
hfp_metrics2 = pd.read_csv('data/baseline/high_freq_ping/20210413-1709-metrics.csv')
hfp_d_metrics1 = pd.read_csv('data/with_delay/hfp/20210414-1409-metrics.csv')
hfp_d_metrics2 = pd.read_csv('data/with_delay/hfp/20210414-1432-metrics.csv')

pcap_metrics1 = pd.read_csv('data/baseline/pcaps/20210414-1325-metrics.csv')
pcap_metrics2 = pd.read_csv('data/baseline/pcaps/20210414-1344-metrics.csv')
pcap_d_metrics1 = pd.read_csv('data/with_delay/pcaps/20210414-1505-metrics.csv')
pcap_d_metrics2 = pd.read_csv('data/with_delay/pcaps/20210414-1525-metrics.csv')

int_metrics1 = pd.read_csv('data/baseline/int/20210413-1831-metrics.csv')
int_metrics2 = pd.read_csv('data/baseline/int/20210413-1853-metrics.csv')
int_d_metrics1 = pd.read_csv('data/with_delay/int/20210415-0927-metrics.csv')
int_d_metrics2 = pd.read_csv('data/with_delay/int/20210415-0952-metrics.csv')

# Combine to a single frame
nm_frames = [nm_bw1, nm_bw2]
hfp_frames = [hfp_bw1, hfp_bw2]
pcap_frames = [pcap_bw1, pcap_bw2]
int_frames = [int_bw1, int_bw2]
nm_d_frames = [nm_d_bw1, nm_d_bw2]
hfp_d_frames = [hfp_d_bw1, hfp_d_bw2]
pcap_d_frames = [pcap_d_bw1, pcap_d_bw2]
int_d_frames = [int_d_bw1, int_d_bw2]

nm_metric_frames = [nm_metrics1, nm_metrics2]
hfp_metric_frames = [hfp_metrics1, hfp_metrics2]
pcap_metric_frames = [pcap_metrics1, pcap_metrics2]
int_metric_frames = [int_metrics1, int_metrics2]
nm_metric_d_frames = [nm_d_metrics1, nm_d_metrics2]
hfp_metric_d_frames = [hfp_d_metrics1, hfp_d_metrics2]
pcap_metric_d_frames = [pcap_d_metrics1, pcap_d_metrics2]
int_metric_d_frames = [int_d_metrics1, int_d_metrics2]

nm_result = pd.concat(nm_frames, ignore_index=True)
hfp_result = pd.concat(hfp_frames, ignore_index=True)
pcap_result = pd.concat(pcap_frames, ignore_index=True)
int_result = pd.concat(int_frames, ignore_index=True)
nm_d_result = pd.concat(nm_d_frames, ignore_index=True)
hfp_d_result = pd.concat(hfp_d_frames, ignore_index=True)
pcap_d_result = pd.concat(pcap_d_frames, ignore_index=True)
int_d_result = pd.concat(int_d_frames, ignore_index=True)

nm_metric_result = pd.concat(nm_metric_frames, ignore_index=True)
hfp_metric_result = pd.concat(hfp_metric_frames, ignore_index=True)
pcap_metric_result = pd.concat(pcap_metric_frames, ignore_index=True)
int_metric_result = pd.concat(int_metric_frames, ignore_index=True)
nm_metric_d_result = pd.concat(nm_metric_d_frames, ignore_index=True)
hfp_metric_d_result = pd.concat(hfp_metric_d_frames, ignore_index=True)
pcap_metric_d_result = pd.concat(pcap_metric_d_frames, ignore_index=True)
int_metric_d_result = pd.concat(int_metric_d_frames, ignore_index=True)

# Filter out results with unexplainably low bandwidth (edge cases)
nm_result = nm_result[nm_result['sent_mbps'] > 2]
hfp_result = hfp_result[hfp_result['sent_mbps'] > 2]
pcap_result = pcap_result[pcap_result['sent_mbps'] > 2]
int_result = int_result[int_result['sent_mbps'] > 2]
nm_d_result = nm_d_result[nm_d_result['sent_mbps'] > 2]
hfp_d_result = hfp_d_result[hfp_d_result['sent_mbps'] > 2]
pcap_d_result = pcap_d_result[pcap_d_result['sent_mbps'] > 2]
int_d_result = int_d_result[int_d_result['sent_mbps'] > 2]

# Filter out results with less than 40% CPU utilization, only keep periods where Iperf3 is running
nm_metric_result = nm_metric_result[nm_metric_result['cpu1'] > 40]
hfp_metric_result = hfp_metric_result[hfp_metric_result['cpu1'] > 40]
pcap_metric_result = pcap_metric_result[pcap_metric_result['cpu1'] > 40]
int_metric_result = int_metric_result[int_metric_result['cpu1'] > 40]
nm_metric_d_result = nm_metric_d_result[nm_metric_d_result['cpu1'] > 40]
hfp_metric_d_result = hfp_metric_d_result[hfp_metric_d_result['cpu1'] > 40]
pcap_metric_d_result = pcap_metric_d_result[pcap_metric_d_result['cpu1'] > 40]
int_metric_d_result = int_metric_d_result[int_metric_d_result['cpu1'] > 40]

# Merge related frames together
baseline_bw = [
    nm_result['sent_mbps'], hfp_result['sent_mbps'],
    pcap_result['sent_mbps'], int_result['sent_mbps']
]
baseline_retr = [
    nm_result['retransmits'], hfp_result['retransmits'],
    pcap_result['retransmits'], int_result['retransmits']
]
baseline_cpu = [
    nm_metric_result['cpu1'], hfp_metric_result['cpu1'],
    pcap_metric_result['cpu1'], int_metric_result['cpu1']
]
baseline_mem = [
    nm_metric_result['mem1'], hfp_metric_result['mem1'],
    pcap_metric_result['mem1'], int_metric_result['mem1']
]
baseline_disk = [
    nm_metric_result['kb_wrtn'], hfp_metric_result['kb_wrtn'],
    pcap_metric_result['kb_wrtn'], int_metric_result['kb_wrtn']
]
baseline_time = [
    nm_result['total_time'], hfp_result['total_time'],
    pcap_result['total_time'], int_result['total_time']
]
delay_bw = [
    nm_d_result['sent_mbps'], hfp_d_result['sent_mbps'],
    pcap_d_result['sent_mbps'], int_d_result['sent_mbps']
]
delay_retr = [
    nm_d_result['retransmits'], hfp_d_result['retransmits'],
    pcap_d_result['retransmits'], int_d_result['retransmits']
]
delay_cpu = [
    nm_metric_d_result['cpu1'], hfp_metric_d_result['cpu1'],
    pcap_metric_d_result['cpu1'], int_metric_d_result['cpu1']
]
delay_mem = [
    nm_metric_d_result['mem1'], hfp_metric_d_result['mem1'],
    pcap_metric_d_result['mem1'], int_metric_d_result['mem1']
]
delay_disk = [
    nm_metric_d_result['kb_wrtn'], hfp_metric_d_result['kb_wrtn'],
    pcap_metric_d_result['kb_wrtn'], int_metric_d_result['kb_wrtn']
]
delay_time = [
    nm_d_result['total_time'], hfp_d_result['total_time'],
    pcap_d_result['total_time'], int_d_result['total_time']
]

comparison_nm_bw = [
    nm_result['sent_mbps'], nm_d_result['sent_mbps']
]
comparison_hfp_bw = [
    hfp_result['sent_mbps'], hfp_d_result['sent_mbps']
]

comparison_pcap_bw = [
    pcap_result['sent_mbps'], pcap_d_result['sent_mbps']
]

comparison_int_bw = [
    int_result['sent_mbps'], int_d_result['sent_mbps']
]

comparison_all_bw = [
    nm_result['sent_mbps'], nm_d_result['sent_mbps'],
    hfp_result['sent_mbps'], hfp_d_result['sent_mbps'],
    pcap_result['sent_mbps'], pcap_d_result['sent_mbps'],
    int_result['sent_mbps'], int_d_result['sent_mbps']
]

# Define content of figures
labels = ['no_monitoring', 'HFP', 'PCAPs', 'INT']
baseline_figs = [
    [baseline_bw, 'Baseline Bandwidth', 'Mb/s', 'figures/no_delay/baseline_bw'],
    [baseline_retr, 'Baseline Retransmissions', 'Retransmissions', 'figures/no_delay/baseline_retr'],
    [baseline_cpu, 'Baseline CPU Usage of BMV2 Switches', 'CPU %', 'figures/no_delay/baseline_cpu'],
    [baseline_mem, 'Baseline Memory Usage of BMV2 Switches', 'Mem %', 'figures/no_delay/baseline_mem'],
    [baseline_disk, 'Baseline Disk I/O', 'KBytes/5s', 'figures/no_delay/baseline_disk'],
    [baseline_time, 'Baseline Time Usage, Iperf3 Client', 'Seconds', 'figures/no_delay/baseline_time']
]

# Draw and save figures
for item in baseline_figs:
    save_fig(data=item[0], fig_labels=labels, title=item[1], ylabel=item[2], fig_name=item[3])

delay_figs = [
    [delay_bw, 'Delay Bandwidth', 'Mb/s', 'figures/with_delay/delay_bw'],
    [delay_retr, 'Delay Retransmissions', 'Retransmissions', 'figures/with_delay/delay_retr'],
    [delay_cpu, 'Delay CPU Usage of BMV2 Switches', 'CPU %', 'figures/with_delay/delay_cpu'],
    [delay_mem, 'Delay Memory Usage of BMV2 Switches', 'Mem %', 'figures/with_delay/delay_mem'],
    [delay_disk, 'Delay Disk I/O', 'KBytes/5s', 'figures/with_delay/delay_disk'],
    [delay_time, 'Delay Time Usage, Iperf3 Client', 'Seconds', 'figures/with_delay/delay_time']
]

# Draw and save figures
for item in delay_figs:
    save_fig(data=item[0], fig_labels=labels, title=item[1], ylabel=item[2], fig_name=item[3])

# Prepare figure data for comparisons
labels = ['Without Delay', 'With Delay']
to_compare = [
    [
        comparison_nm_bw,
        'Bandwidth, with and without Delay, No Monitoring',
        'Mb/s',
        'figures/comparisons/comp_bw_nm'
    ],
    [
        comparison_hfp_bw,
        'Bandwidth, with and without Delay, High Frequency Ping',
        'Mb/s',
        'figures/comparisons/comp_bw_hfp'
    ],
    [
        comparison_pcap_bw,
        'Bandwidth, with and without Delay, Packet Capturing',
        'Mb/s',
        'figures/comparisons/comp_bw_pcap'
    ],
    [
        comparison_int_bw,
        'Bandwidth, with and without Delay, In-band Network Telemetry',
        'Mb/s',
        'figures/comparisons/comp_bw_int'
    ],
]
for item in to_compare:
    save_fig(data=item[0], fig_labels=labels, title=item[1], ylabel=item[2], fig_name=item[3])

save_fig(comparison_all_bw,
         title='Bandwidth, With and Without Delay, all methods',
         ylabel='Mb/s',
         fig_name='figures/comparisons/comp_bw_all',
         fig_labels=['nm', 'nm_d', 'hfp', 'hfp_d', 'pcap', 'pcap_d', 'int', 'int_d'])
