#!/usr/bin/env python3
import os
import re

# Load license

header = "// " 
with open("LICENSE", "r") as license_file:
    license_content = license_file.read()
    for i in range(0, len(license_content)):
        c = license_content[i]
        header += c
        if c == "\n":
            header += "//"
            if i + 1 < len(license_content) and not license_content[i + 1] == "\n":
                header += " "

# Update license header

def update_header(file_path):
    with open(file_path, "r+") as file:
        content = file.read()
        header_match = re.match("^(((\\/\\/.*\n)+|(\\/\\*[\\S\\s]+\\*\\/)))\\s*", content)
        if header_match == None:
            return
        content = "\n".join([header, content[header_match.span()[1] - 1:]])
        file.seek(0)
        file.write(content)
        file.truncate()

# Update header for every swift file

def update_headers_in_folder(path):
    for root, _, files in os.walk(path):
        for file in files:
            if file.endswith(".swift"):
                update_header(os.path.join(root, file))

update_headers_in_folder("./RxBluetoothKit")
update_headers_in_folder("./RxBluetoothKitTests")
