#!/bin/bash
#
# Andrei Nagy 2018-05-27
#
# Project source code summary
#
# Style guide:
# https://google.github.io/styleguide/shell.xml
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

FORMAT_JSON="JSON"
FORMAT_TSV="TSV"
ANONYMOUS_OPTION="anon"

if [[ $# -eq 0 ]] ; then
    echo "Project source code summary

    Note: To ignore Pods, pass the main project source code folder.
    Note: Basic grep is used for keywords, false possitives can/will occur.

    JSON output usage:
    	sourceCodeSummary.sh /Path/To/Main/SwiftFiles/Folder

    anonymous JSON output:
    	sourceCodeSummary.sh /Path/To/Main/SwiftFiles/Folder $ANONYMOUS_OPTION

    TSV output:
    	sourceCodeSummary.sh /Path/To/Main/SwiftFiles/Folder $FORMAT_TSV

    anonymous TSV:
    	sourceCodeSummary.sh /Path/To/Main/SwiftFiles/Folder $FORMAT_TSV $ANONYMOUS_OPTION
    "
    exit 0
fi

INDENT='\t'

# TSV Constants
HACK_TSV_KEYWORDS_LENGHT=20

# JSON Constants get toggled for TSV
JSON_BRACE_OPEN="{"
JSON_BRACE_CLOSE="}"
JSON_BRACKET_OPEN="["
JSON_BRACKET_CLOSE="]"
JSON_QUOTES="\""
JSON_COLON=": "
JSON_COMMA=","

# Arguments
PROJECT_PATH=$1
FILE_EXTENSION="swift"
FORMAT=$FORMAT_JSON

SHOULD_ANONYMIZE=false
if [[ $2 == $ANONYMOUS_OPTION ]] || [[ $3 == $ANONYMOUS_OPTION ]]; then
	SHOULD_ANONYMIZE=true
fi


if [[ $2 == $FORMAT_TSV ]] || [[ $3 == $FORMAT_TSV ]]; then
	FORMAT=$FORMAT_TSV

	JSON_BRACE_OPEN=""
	JSON_BRACE_CLOSE=""
	JSON_BRACKET_OPEN=""
	JSON_BRACKET_CLOSE=""
	JSON_QUOTES=""
	JSON_COLON=$INDENT
	JSON_COMMA=""
fi

# Domain Constants
TYPES=(
	"class "
	"struct "
	"enum "
	"protocol "
	"typealias "
)

FUNCTIONS=(
	"func "
	"{ (" #closure
)

COMPLEXITY=(
	"if "
	"guard "
	"switch" # maybe not?
	" ? " # ternary operator
)

POSITIVE=( #keywords that denote good practices
	"init?("
	"init() throws"
	"extension"
	"forEach"
	"map"
	" in " #fast enumerations and closures
	"self]" #weak and unowned
	" ?? "
	"assert("
	"fatalError("
)

NEGATIVE=( #keywords that denote bad practices
	"! " #force unwrap, downcasting
	" shared" #singletons
	"DispatchQueue.main" #uses delays to layout views?
	"TODO"
	"FIXME"
	"TBD"
	"HACK"
)

# Utilities

strip_spaces() {
	local result
	result=$(echo "${1}" | tr -d '[:space:]')
	echo $result
}

# truncate date to YYYY-MM-DD
truncate_to_10_chars() {
	local result
	result=$(echo $1 |head -c 10)
	echo $result
}

anonymize_string_if_needed() {
	if [ "$SHOULD_ANONYMIZE" = true ]; then
		echo $(anonymize.sh $1)
	else
		echo $1
	fi
}

print_if_json() {
	if [[ $FORMAT == $FORMAT_JSON ]]; then
		echo -e $1
	fi
}

print_json_key_value() { # With optional leading space and trailingcomma
	echo -e "$1$JSON_QUOTES$2$JSON_QUOTES$JSON_COLON$3$4"
}

# Shell commands

files_number() { # file type in $1
	# Number of files		find . -name "*.swift" |wc -l
	local command_string
	command_string="find . -name \"*.$1\" |wc -l"
	local command_result
	command_result=$(eval $command_string)
	local result
	result=$(strip_spaces ${command_result})
	echo ${result}
}

lines_number() {
	local command_string
	command_string="find . -name \"*.$1\" -print0 |xargs -0 cat | sed '/^\s*$/d' | wc -l"
	local command_result
	command_result=$(eval $command_string)
	local result
	result=$(strip_spaces ${command_result})
	echo ${result}
}

occurrences_number() {
	local command_string
	command_string="find . -name \"*.$1\" -print0 |xargs -0 cat | sed '/^\s*$/d' | grep -e \"$2\" | wc -l"
	local command_result
	command_result=$(eval $command_string)
	local result
	result=$(strip_spaces ${command_result})
	echo ${result}
}

# Git

date_from_git_command() {
	local command_result
	command_result=$(eval $1)
	local git_date_prefix
	git_date_prefix="Date:   "
	local result
	result=${command_result#$git_date_prefix}
	result=$(truncate_to_10_chars $result)
	echo $result
}

date_start() {
	# Project start date		git log --date=iso --reverse |head -3 |grep "Date"
	local result
	result=$(date_from_git_command "git log --date=iso --reverse |head -3 |grep \"Date\"")
	echo $result
}

date_end () {
	local result
	result=$(date_from_git_command "git log --date=iso |head -4 |grep \"Date\"")
	echo $result
}

contributors_number () {
	# Number of contributors		git shortlog -s -n |wc -l
	local command_string
	command_string="git shortlog -s -n |wc -l"
	local command_result
	command_result=$(eval $command_string)
	local result
	result=$(strip_spaces ${command_result})
	echo ${result}
}

print_contributors () {
	# Number of contributors		git shortlog -s -n |wc -l
	local command_string
	command_string="git shortlog -s -n"
	local command_result
	command_result="$(eval $command_string)"

	while read -r line; do
	    IFS='	' read -r commits author <<< "$line"
	    print_if_json $1$JSON_BRACE_OPEN

	    local auth
	    auth=$(anonymize_string_if_needed $author)
	    echo -e $1$INDENT$JSON_QUOTES$auth$JSON_QUOTES$JSON_COLON$commits

	    print_if_json $1$JSON_BRACE_CLOSE$JSON_COMMA
	done <<< "$command_result"

	print_if_json $1$JSON_BRACE_OPEN
# 	print_if_json $1$INDENT$JSON_QUOTES"no_comma"$JSON_QUOTES$JSON_COLON"0" not working for some reason
	print_if_json $1$INDENT"\"no_comma\":0"
	print_if_json $1$JSON_BRACE_CLOSE
}

print_empty_lines_if_tsv() {
	if [[ $FORMAT == $FORMAT_TSV ]]; then
		for i in `seq 1 $1`;
		do
			echo
		done
	fi
}

print_array_occurences() { # array argument
	arr=("$@")
	for i in "${arr[@]}"
	do
		print_json_key_value $INDENT "$i"	$(occurrences_number $FILE_EXTENSION $i)	$JSON_COMMA
	done

	array_lenght="${#arr[@]}"
	needed_empty_lines=$((HACK_TSV_KEYWORDS_LENGHT-array_lenght))
	print_empty_lines_if_tsv $needed_empty_lines
}

# Main

cd $PROJECT_PATH

print_if_json $JSON_BRACE_OPEN
echo -e $JSON_QUOTES"project"$JSON_QUOTES$JSON_COLON$JSON_BRACE_OPEN

print_json_key_value $INDENT "script_title"	$JSON_QUOTES$0$JSON_QUOTES $JSON_COMMA
print_json_key_value $INDENT "script_author"	$JSON_QUOTES"Andrei Nagy"$JSON_QUOTES $JSON_COMMA
project=$(anonymize_string_if_needed $PROJECT_PATH)
print_json_key_value $INDENT "project_path"	$JSON_QUOTES$project$JSON_QUOTES $JSON_COMMA
print_json_key_value $INDENT "project_scan_date"	$JSON_QUOTES"$(date '+%Y-%m-%d')"$JSON_QUOTES
print_if_json $JSON_BRACE_CLOSE$JSON_COMMA

echo -e $JSON_QUOTES"files"$JSON_QUOTES$JSON_COLON$JSON_BRACE_OPEN
print_json_key_value $INDENT "extension"	$JSON_QUOTES$FILE_EXTENSION$JSON_QUOTES	$JSON_COMMA
print_json_key_value $INDENT "files_number"	$(files_number $FILE_EXTENSION)	$JSON_COMMA
print_json_key_value $INDENT "non_empty_lines_number"	$(lines_number $FILE_EXTENSION)
print_if_json $JSON_BRACE_CLOSE$JSON_COMMA

echo -e $JSON_QUOTES"keywords_types"$JSON_QUOTES$JSON_COLON$JSON_BRACE_OPEN
print_array_occurences "${TYPES[@]}"
print_json_key_value $INDENT "no_comma"	$JSON_QUOTES"Strings occurrences only. May result in false positives."$JSON_QUOTES
print_if_json $JSON_BRACE_CLOSE$JSON_COMMA

echo -e $JSON_QUOTES"keywords_functions"$JSON_QUOTES$JSON_COLON$JSON_BRACE_OPEN
print_array_occurences "${FUNCTIONS[@]}"
print_json_key_value $INDENT "no_comma"	$JSON_QUOTES"Strings occurrences only. May result in false positives."$JSON_QUOTES
print_if_json $JSON_BRACE_CLOSE$JSON_COMMA

echo -e $JSON_QUOTES"keywords_complexity"$JSON_QUOTES$JSON_COLON$JSON_BRACE_OPEN
print_array_occurences "${COMPLEXITY[@]}"
print_json_key_value $INDENT "no_comma"	$JSON_QUOTES"Strings occurrences only. May result in false positives."$JSON_QUOTES
print_if_json $JSON_BRACE_CLOSE$JSON_COMMA

echo -e $JSON_QUOTES"keywords_positive"$JSON_QUOTES$JSON_COLON$JSON_BRACE_OPEN
print_array_occurences "${POSITIVE[@]}"
print_json_key_value $INDENT "no_comma"	$JSON_QUOTES"Strings occurrences only. May result in false positives."$JSON_QUOTES
print_if_json $JSON_BRACE_CLOSE$JSON_COMMA

echo -e $JSON_QUOTES"keywords_negative"$JSON_QUOTES$JSON_COLON$JSON_BRACE_OPEN
print_array_occurences "${NEGATIVE[@]}"
print_json_key_value $INDENT "no_comma"	$JSON_QUOTES"Strings occurrences only. May result in false positives."$JSON_QUOTES
print_if_json $JSON_BRACE_CLOSE$JSON_COMMA

echo -e $JSON_QUOTES"git"$JSON_QUOTES$JSON_COLON$JSON_BRACE_OPEN
print_json_key_value $INDENT "commit_first"	"$JSON_QUOTES$(date_start)$JSON_QUOTES"	$JSON_COMMA
print_json_key_value $INDENT "commit_last"	"$JSON_QUOTES$(date_end)$JSON_QUOTES"	$JSON_COMMA
print_json_key_value $INDENT "contributors_number"	$(contributors_number)	$JSON_COMMA

echo -e $INDENT$JSON_QUOTES"contributors"$JSON_QUOTES$JSON_COLON$JSON_BRACKET_OPEN
print_contributors $INDENT
print_if_json $INDENT$JSON_BRACKET_CLOSE

print_if_json $JSON_BRACE_CLOSE #git
print_if_json $JSON_BRACE_CLOSE #main
