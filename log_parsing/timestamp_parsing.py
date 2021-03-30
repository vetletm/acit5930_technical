import csv

timestamping = []
with open('s3-timestamping.log') as f:
    csv_reader = csv.reader(f, delimiter=',')
    line_count = 0
    for row in csv_reader:
        to_add = {
            'flow_hash': int(row[0].split('TIMESTAMPING:')[1].split('=')[1]),
            'millisecs': int(row[1].split('=')[1]),
            'microsecs': int(row[2].split('=')[1]),
            'time_diff': int(row[3].split('=')[1]),
            'curr_tstamp': int(row[4].split('=')[1]),
            'prev_tstamp': int(row[5].split('=')[1]),
            'diff_repr': int(row[6].split('=')[1]),
            'milli_hex': int(row[7].split('=')[1]),
            'micro_hex': int(row[8].split('=')[1]),
        }
        timestamping.append(to_add)

time_diffs = []
for item in timestamping:
    time_diff = item['diff_repr']
    as_binary = bin(time_diff)[2:].rjust(8, '0')
    milli, micro = as_binary[0:4], as_binary[4:8]
    # print(item['diff_repr'], '->', as_binary, '->', milli, micro, '->', int(milli, 2), int(micro, 2), '=>', end=' ')

    milli, micro = int(milli, 2), int(micro, 2) * 64
    found_time_diff = (milli * 1000) + micro
    time_diffs.append(found_time_diff)

    # print('stored time_diff:', item['time_diff'], 'found_time_diff:', found_time_diff)

sorted_time_diffs = sorted(set(time_diffs))
count_time_diffs = sorted(time_diffs)

dict_time_diffs = {}
for item in sorted_time_diffs:
    dict_time_diffs[item] = count_time_diffs.count(item)

print(dict_time_diffs)

#time_diff_vars = set(count_time_diffs)
#print(sorted(time_diff_vars))



#for

# print(counted)

# dict_format = dict(zip(time_diff_vars, counted))
# print(dict_format)
