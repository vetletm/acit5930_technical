import json


def parse_ploss(filename):
    to_return = []

    with open(filename, 'r') as f:
        lines = f.readlines()
        for line in lines:
            # Split line on PLOSS, select last item and split again on ','
            row = line.split('PLOSS:')[1].split(',')
            to_add = {}
            # Go through each item in each row
            for item in row:
                # Split each item on = to get a list of two elements
                item = item.split('=')
                # Set first element as key, second element as value
                key, val = item[0].strip(), item[1].strip()
                # Add to dictionary
                to_add[key] = val
            # Append the row as a dictionary to the final list of dictionaries
            to_return.append(to_add)

    return to_return


def as_json_file(filename, obj):
    with open(filename, 'w') as file:
        file.write(json.dumps(obj))


filenames = [
    'data/ploss/baseline/s2_loss',
    'data/ploss/baseline/s3_loss',
    'data/ploss/with_loss/s2_loss',
    'data/ploss/with_loss/s3_loss',
]

for name in filenames:
    item = parse_ploss(name + '.txt')
    as_json_file(name + '.json', item)

# s2_ploss = parse_ploss('data/ploss/s2_ploss.txt')
# s3_ploss = parse_ploss('data/ploss/s3_ploss.txt')
#
# as_json_file('data/ploss/s2_ploss.json', s2_ploss)
# as_json_file('data/ploss/s3_ploss.json', s3_ploss)
