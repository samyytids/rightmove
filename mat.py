import json

with open("./ttest.txt", "r") as f:
    lines = f.readlines()

lines = [
    line.split(" ")
    for line in lines
    if "c1" not in line
    and "p-value" not in line
    and "c2" not in line
    and "c3" not in line
]
lines = [line for sub_lines in lines for line in sub_lines if line != ""]
tupled_lines = []

for idx, line in enumerate(lines):
    remainder = idx % 4
    match remainder:
        case 0:
            line = line.replace("\n", "")
            line = line.replace("\t", "")
        case 1 | 2:
            line = "0" + line
            line = line.replace("\n", "")
            line = line.replace("\t", "")
            line = float(line)
        case 3:
            line = "0" + line
            line = line.replace("\n", "")
            line = line.replace("\t", "")
            line = float(line)
            tupled_lines.append((lines[idx - 3], lines[idx - 2], lines[idx - 1], line))

    lines[idx] = line

tupled_lines = tuple(tupled_lines)
result = {"Good different": {}, "Good not different": {}}

for k, p, m1, m2 in tupled_lines:
    if p < 0.1:
        result["Good different"][k] = {"difference": m2 - m1, "p": p}
    else:
        result["Good not different"][k] = {"difference": m2 - m1, "p": p}

with open("./ttest.json", "w") as f:
    json.dump(result, f)
