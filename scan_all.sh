#!/bin/bash
#
# Andrei Nagy 2018-05-27
# 
# Example to scan all folders
#
#
# The MIT License (MIT)
# 
# Copyright (c) 2015 XMARTLABS
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Fill in paths for all your projects.
arr=(
	"Path/to/some/project/swift/files"
	"Path/to/another/project/swift/files"
	"Path/to/yetanother/project/swift/files"
)

# Output path is the current directory.
output_file_name_for_path () {
	local OUTPUT
	OUTPUT=$(awk -F/ '{print $1}'<<<$1)
	echo "${OUTPUT}.txt"
}

for i in "${arr[@]}"
do
	echo
	echo "$i"
	file_name=$(output_file_name_for_path $i)
	eval "sourceCodeSummary.sh $i tsv anon > $file_name"
done
