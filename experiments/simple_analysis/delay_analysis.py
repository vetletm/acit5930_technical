import pandas as pd

from utils import save_fig


nm_d_bw1 = pd.read_json('data/with_delay/no_monitoring/'
                        '20210414-1237-iperf-results-metric-collection-no-monitoring-with-delay.json')
nm_d_bw2 = pd.read_json('data/with_delay/no_monitoring/'
                        '20210414-1256-iperf-results-metric-collection-no-monitoring-with-delay.json')
hfp_d_bw1 = pd.read_json('data/with_delay/hfp/20210414-1409-iperf-results-metric-collection-hfp-delay.json')
hfp_d_bw2 = pd.read_json('data/with_delay/hfp/20210414-1432-iperf-results-metric-collection-hfp-delay.json')
pcap_d_bw1 = pd.read_json('data/with_delay/pcaps/20210414-1505-iperf-results-metric-collection-pcaps-delay.json')
pcap_d_bw2 = pd.read_json('data/with_delay/pcaps/20210414-1525-iperf-results-metric-collection-pcaps-delay.json')
int_d_bw1 = pd.read_json('data/with_delay/int/20210415-0927-iperf-results-metric-collection-int-delay.json')
int_d_bw2 = pd.read_json('data/with_delay/int/20210415-0952-iperf-results-metric-collection-int-delay.json')

nm_d_metrics1 = pd.read_csv('data/with_delay/no_monitoring/20210414-1237-metrics.csv')
nm_d_metrics2 = pd.read_csv('data/with_delay/no_monitoring/20210414-1256-metrics.csv')
hfp_d_metrics1 = pd.read_csv('data/with_delay/hfp/20210414-1409-metrics.csv')
hfp_d_metrics2 = pd.read_csv('data/with_delay/hfp/20210414-1432-metrics.csv')
pcap_d_metrics1 = pd.read_csv('data/with_delay/pcaps/20210414-1505-metrics.csv')
pcap_d_metrics2 = pd.read_csv('data/with_delay/pcaps/20210414-1525-metrics.csv')
int_d_metrics1 = pd.read_csv('data/with_delay/int/20210415-0927-metrics.csv')
int_d_metrics2 = pd.read_csv('data/with_delay/int/20210415-0952-metrics.csv')

nm_frames = [nm_d_bw1, nm_d_bw2]
hfp_frames = [hfp_d_bw1, hfp_d_bw2]
pcap_frames = [pcap_d_bw1, pcap_d_bw2]
int_frames = [int_d_bw1, int_d_bw2]

nm_metric_frames = [nm_d_metrics1, nm_d_metrics2]
hfp_metric_frames = [hfp_d_metrics1, hfp_d_metrics2]
pcap_metric_frames = [pcap_d_metrics1, pcap_d_metrics2]
int_metric_frames = [int_d_metrics1, int_d_metrics2]

nm_result = pd.concat(nm_frames, ignore_index=True)
hfp_result = pd.concat(hfp_frames, ignore_index=True)
pcap_result = pd.concat(pcap_frames, ignore_index=True)
int_result = pd.concat(int_frames, ignore_index=True)

nm_metric_result = pd.concat(nm_metric_frames, ignore_index=True)
hfp_metric_result = pd.concat(hfp_metric_frames, ignore_index=True)
pcap_metric_result = pd.concat(pcap_metric_frames, ignore_index=True)
int_metric_result = pd.concat(int_metric_frames, ignore_index=True)

# Filter out results with unexplainably low bandwidth (edge cases)
nm_result = nm_result[nm_result['sent_mbps'] > 2]
hfp_result = hfp_result[hfp_result['sent_mbps'] > 2]
pcap_result = pcap_result[pcap_result['sent_mbps'] > 2]
int_result = int_result[int_result['sent_mbps'] > 2]

# Filter out results with less than 40% CPU utilization, only keep periods where Iperf3 is running
nm_metric_result = nm_metric_result[nm_metric_result['cpu1'] > 40]
hfp_metric_result = hfp_metric_result[hfp_metric_result['cpu1'] > 40]
pcap_metric_result = pcap_metric_result[pcap_metric_result['cpu1'] > 40]
int_metric_result = int_metric_result[int_metric_result['cpu1'] > 40]

delay_bw = [
    nm_result['sent_mbps'], hfp_result['sent_mbps'],
    pcap_result['sent_mbps'], int_result['sent_mbps']
]
delay_retr = [
    nm_result['retransmits'], hfp_result['retransmits'],
    pcap_result['retransmits'], int_result['retransmits']
]
delay_cpu = [
    nm_metric_result['cpu1'], hfp_metric_result['cpu1'],
    pcap_metric_result['cpu1'], int_metric_result['cpu1']
]
delay_mem = [
    nm_metric_result['mem1'], hfp_metric_result['mem1'],
    pcap_metric_result['mem1'], int_metric_result['mem1']
]
delay_disk = [
    nm_metric_result['kb_wrtn'], hfp_metric_result['kb_wrtn'],
    pcap_metric_result['kb_wrtn'], int_metric_result['kb_wrtn']
]
delay_time = [
    nm_result['total_time'], hfp_result['total_time'],
    pcap_result['total_time'], int_result['total_time']
]

# Define content of figures
labels = ['no_monitoring', 'HFP', 'PCAPs', 'INT']
to_save = [
    [delay_bw, 'Delay Bandwidth', 'Mb/s', 'figures/with_delay/delay_bw'],
    [delay_retr, 'Delay Retransmissions', 'Retransmissions', 'figures/with_delay/delay_retr'],
    [delay_cpu, 'Delay CPU Usage of BMV2 Switches', 'CPU %', 'figures/with_delay/delay_cpu'],
    [delay_mem, 'Delay Memory Usage of BMV2 Switches', 'Mem %', 'figures/with_delay/delay_mem'],
    [delay_disk, 'Delay Disk I/O', 'KBytes/5s', 'figures/with_delay/delay_disk'],
    [delay_time, 'Delay Time Usage, Iperf3 Client', 'Seconds', 'figures/with_delay/delay_time']
]

# Draw and save figures
for item in to_save:
    save_fig(data=item[0], fig_labels=labels, title=item[1], ylabel=item[2], fig_name=item[3])
