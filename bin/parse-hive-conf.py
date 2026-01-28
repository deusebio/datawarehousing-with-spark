import argparse
import xml.etree.ElementTree as ET


parser = argparse.ArgumentParser()

parser.add_argument("--input", "-i", type=str, default="hive-site.xml")
parser.add_argument("--output", "-o", type=str, default="spark.conf")

args = parser.parse_args()

tree = ET.parse(args.input)

root = tree.getroot()

with open(args.output, "w") as fid:
    for key, value in root:
        fid.write(f"spark.hadoop.{key.text}={value.text}\n")

print(f"File {args.output} written successfully")

