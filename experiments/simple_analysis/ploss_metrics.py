import pandas as pd

from utils import save_boxplot

int_ploss_base1 = pd.read_json('data/ploss/baseline/20210429-1047-iperf-results-metric-collection-ploss-baseline.json')
int_ploss_base2 = pd.read_json('data/ploss/baseline/20210429-1104-iperf-results-metric-collection-ploss-baseline.json')
int_ploss_delay1 = pd.read_json(
    'data/ploss/with_loss/20210429-1139-iperf-results-metric-collection-ploss-baseline.json')
int_ploss_delay2 = pd.read_json(
    'data/ploss/with_loss/20210429-1202-iperf-results-metric-collection-ploss-baseline.json')
int_bw1 = pd.read_json('data/baseline/int/20210413-1829-iperf-results-metric-collection-int.json')
int_bw2 = pd.read_json('data/baseline/int/20210413-1851-iperf-results-metric-collection-int.json')
int_d_bw1 = pd.read_json('data/with_delay/int/20210415-0927-iperf-results-metric-collection-int-delay.json')
int_d_bw2 = pd.read_json('data/with_delay/int/20210415-0952-iperf-results-metric-collection-int-delay.json')

int_ploss_metrics_base1 = pd.read_csv('data/ploss/baseline/20210429-1047-metrics.csv')
int_ploss_metrics_base2 = pd.read_csv('data/ploss/baseline/20210429-1104-metrics.csv')
int_ploss_metrics_delay1 = pd.read_csv('data/ploss/with_loss/20210429-1139-metrics.csv')
int_ploss_metrics_delay2 = pd.read_csv('data/ploss/with_loss/20210429-1202-metrics.csv')
int_metrics1 = pd.read_csv('data/baseline/int/20210413-1831-metrics.csv')
int_metrics2 = pd.read_csv('data/baseline/int/20210413-1853-metrics.csv')
int_d_metrics1 = pd.read_csv('data/with_delay/int/20210415-0927-metrics.csv')
int_d_metrics2 = pd.read_csv('data/with_delay/int/20210415-0952-metrics.csv')

# Create lists of dataframes that hold similar data
int_frames = [int_bw1, int_bw2]
int_d_frames = [int_d_bw1, int_d_bw2]
int_ploss_bw_base_frames = [int_ploss_base1, int_ploss_base2]
int_ploss_bw_delay_frames = [int_ploss_delay1, int_ploss_delay2]
int_metric_frames = [int_metrics1, int_metrics2]
int_metric_d_frames = [int_d_metrics1, int_d_metrics2]
int_ploss_metrics_base_frames = [int_ploss_metrics_base1, int_ploss_metrics_base2]
int_ploss_metrics_delay_frames = [int_ploss_metrics_delay1, int_ploss_metrics_delay2]

# Concatenate dataframes to a single frame
int_result = pd.concat(int_frames, ignore_index=True)
int_d_result = pd.concat(int_d_frames, ignore_index=True)
int_ploss_bw_base_results = pd.concat(int_ploss_bw_base_frames, ignore_index=True)
int_ploss_bw_delay_results = pd.concat(int_ploss_bw_delay_frames, ignore_index=True)
int_metric_result = pd.concat(int_metric_frames, ignore_index=True)
int_metric_d_result = pd.concat(int_metric_d_frames, ignore_index=True)
int_ploss_metrics_base_results = pd.concat(int_ploss_metrics_base_frames, ignore_index=True)
int_ploss_metrics_delay_results = pd.concat(int_ploss_metrics_delay_frames, ignore_index=True)

# Filter out results below given threshold
int_result = int_result[int_result['sent_mbps'] > 2]
int_d_result = int_d_result[int_d_result['sent_mbps'] > 2]
int_ploss_bw_base_results = int_ploss_bw_base_results[int_ploss_bw_base_results['sent_mbps'] > 2]
int_ploss_bw_delay_results = int_ploss_bw_delay_results[int_ploss_bw_delay_results['sent_mbps'] > 2]
int_metric_result = int_metric_result[int_metric_result['cpu1'] > 40]
int_metric_d_result = int_metric_d_result[int_metric_d_result['cpu1'] > 40]
int_ploss_metrics_base_results = int_ploss_metrics_base_results[int_ploss_metrics_base_results['cpu1'] > 40]
int_ploss_metrics_delay_results = int_ploss_metrics_delay_results[int_ploss_metrics_delay_results['cpu1'] > 40]

baseline_bw = [
    int_result['sent_mbps'],
    int_d_result['sent_mbps'],
    int_ploss_bw_base_results['sent_mbps'],
    int_ploss_bw_delay_results['sent_mbps']
]
baseline_retr = [
    int_result['retransmits'],
    int_d_result['retransmits'],
    int_ploss_bw_base_results['retransmits'],
    int_ploss_bw_delay_results['retransmits']
]
baseline_cpu = [
    int_metric_result['cpu1'],
    int_metric_d_result['cpu1'],
    int_ploss_metrics_base_results['cpu1'],
    int_ploss_metrics_delay_results['cpu1']
]
baseline_mem = [
    int_metric_result['mem1'],
    int_metric_d_result['mem1'],
    int_ploss_metrics_base_results['mem1'],
    int_ploss_metrics_delay_results['mem1']
]
baseline_disk = [
    int_metric_result['kb_wrtn'],
    int_metric_d_result['kb_wrtn'],
    int_ploss_metrics_base_results['kb_wrtn'],
    int_ploss_metrics_delay_results['kb_wrtn']
]

labels = ['tstamp baseline', 'tstamp with delay', 'ploss baseline', 'ploss with loss']
baseline_figs = [
    [baseline_bw, 'Bandwidth', 'Mb/s', 'figures/ploss/bw'],
    [baseline_retr, 'Retransmissions', 'Retransmissions', 'figures/ploss/retr'],
    [baseline_cpu, 'CPU Usage of BMV2 Switches', 'CPU %', 'figures/ploss/cpu'],
    [baseline_mem, 'Memory Usage of BMV2 Switches', 'Mem %', 'figures/ploss/mem'],
    [baseline_disk, 'Disk I/O', 'KBytes/5s', 'figures/ploss/disk'],
]
for item in baseline_figs:
    save_boxplot(data=item[0], fig_labels=labels, title=item[1], ylabel=item[2], fig_name=item[3])
