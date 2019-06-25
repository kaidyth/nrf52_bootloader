import sys

try:
    version = sys.argv[1]
except IndexError:
    print("Specify a semantic version to convert.")
    exit(0)

split = version.split(".")
fullversion = ""
for i, v in enumerate(split, start=0):
    fullversion += v.rjust(3, "0")

print(hex(int(fullversion)))
