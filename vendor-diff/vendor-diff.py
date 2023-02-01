# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument("-p", "--path", type=str, help="project directory path", default=".")

GO_MOD_FILE = "go.mod"
VENDOR_MODULES_FILE = "vendor/modules.txt"

def main():
	args = parser.parse_args()
	path = args.path

	go_mod_file = os.path.join(path, GO_MOD_FILE)
	if not os.path.exists(go_mod_file):
		print("ERROR: %s not found. Is the project using go mod?" % go_mod_file)
		exit(1)

	vendor_modules_file = os.path.join(path, VENDOR_MODULES_FILE)
	if not os.path.exists(vendor_modules_file):
		print("ERROR: %s not found. Is the project vendored?" % vendor_modules_file)
		exit(1)

	# Parse go.mod for required modules
	required = {}
	with open(go_mod_file) as f:
		parse = False
		for line in f:
			if "require (" in line:
				parse = True
			elif ")" in line:
				parse = False
			elif parse:
				s = line.split()
				module, version = s[0], s[1]
				required[module] = version

	# Parse vendor/modules.txt for vendored modules
	vendored = {}
	with open(vendor_modules_file) as f:
		for line in f:
			if line.startswith("# "):
				s = line.lstrip("#").split()
				module, version = s[0], s[1]
				vendored[module] = version

	# Compare vendor with go mod
	missing = {}
	version_mismatch = {}
	for module, version in required.items():
		vendored_version = vendored.get(module)

		if vendored_version is None:
			# find missing modules
			missing[module] = version
			continue

		elif version != vendored_version:
			# find unexpected module versions
			version_mismatch[module] = {"go.mod": version, "vendor": vendored_version}

		# find non required modules that are vendored
		vendored.pop(module)

	error = False

	if len(version_mismatch):
		print("\nERROR: Unexpected module versions vendored")
		for module, versions in version_mismatch.items():
			print("%s %s (%s)" % (module, versions["go.mod"], versions["vendor"]))
		error = True

	if len(missing):
		print("\nWARN: Missing required modules from vendor")
		for module, version in missing.items():
			print(module, version)

	if len(module):
		print("\nINFO: Vendored modules not required")
		for module, version in vendored.items():
			print(module, version)

	if error:
		exit(1)

if __name__ == "__main__":
	main()
