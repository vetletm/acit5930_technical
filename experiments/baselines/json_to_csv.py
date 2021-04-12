#!/usr/bin/env python3

import json
import csv
import argparse

parser = argparse.ArgumentParser(description='Convert json file to csv and keep name')
parser.add_argument('-i', '--input', help='input file', default='', type=str)
args = parser.parse_args()

input = args.input

output_name = input.split('.')[0] + '.csv'

with open(input, 'r') as f:
    data = json.loads(f.read())

keys = data[0].keys()

with open(output_name, 'w') as f:
    dict_writer = csv.DictWriter(f, keys)
    dict_writer.writeheader()
    dict_writer.writerows(data)
