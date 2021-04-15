def parse_timediffs(filename):
    to_return = []
    with open(filename, 'r') as f:
        lines = f.readlines()
        for line in lines:
            first_half = line.split('TIMEDIFFS:')[0]
            second_half = line.split('TIMEDIFFS:')[1]
            to_add = {
                'timestamp': first_half.split(' ')[0].strip('[').strip(']'),
                'flow_hash': second_half.split(',')[0].split('=')[1],
                'ip_src': second_half.split(',')[1].split('=')[1],
                'time_diff': second_half.split(',')[2].split('=')[1],
                'inc_time_diff': second_half.split(',')[3].split('=')[1].strip()
            }
            to_return.append(to_add)
    return to_return


def dec_to_ip(decimal_representation):
    hex_repr = hex(int(decimal_representation))
    hex_repr = hex_repr[2:]
    # pad with extra 0 if hex-representation is less than 8 (will only happen in cases where first octet is <15)
    if len(hex_repr) < 8:
        hex_repr = ''.join(('0', hex_repr))
    ip_addr = '.'.join([str(int(hex_repr[i:i+2], 16)) for i in range(0, len(hex_repr), 2)])
    return ip_addr


s2_timediffs = parse_timediffs('data/baseline/int/s2_timediffs.txt')
s3_timediffs = parse_timediffs('data/baseline/int/s3_timediffs.txt')

# for item in s2_timediffs:
#     item['ip_src'] = dec_to_ip(item['ip_src'])
#
# for item in s3_timediffs:
#     item['ip_src'] = dec_to_ip(item['ip_src'])
#
for item in s2_timediffs[:10]:
    print(item['ip_src'], dec_to_ip(item['ip_src']))
for item in s3_timediffs[:10]:
    print(item['ip_src'], dec_to_ip(item['ip_src']))
