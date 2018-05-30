#!/bin/bash
#
# Andrei Nagy 2018-05-27
# 
# Project source code summary
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

if [[ $# -eq 0 ]] ; then
    echo "Project source code summary
    
    Note: To ignore Pods, pass the main project source code folder.
    Note: Basic grep is used for keywords, false possitives can/will occur.
    
    JSON output usage: 
    	sourceCodeSummary.sh /Path/To/Main/SwiftFiles/Folder json
    
    TSV output usage: 
    	sourceCodeSummary.sh /Path/To/Main/SwiftFiles/Folder tsv
    
    anonimous tsv: 
    	sourceCodeSummary.sh /Path/To/Main/SwiftFiles/Folder tsv anon
    "
    exit 0
fi

PROJECT_PATH=$1
FILE_EXTENSION="swift"
FORMAT=$2 #default is json
ANONYMOUS="false"
ANONYMOUS=$3

HACK_TSV_KEYWORDS_LENGHT=20

JSON_BRACE_OPEN="{"
JSON_BRACE_CLOSE="}"
JSON_BRACKET_OPEN="["
JSON_BRACKET_CLOSE="]"
JSON_QUOTES="\""
JSON_COLON=": "
JSON_COMMA=","

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

POSITIVE=(
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

NEGATIVE=(
	"! " #force unwrap, downcasting
	" shared" #singletons
	"DispatchQueue.main" #uses delays to layout views?
	"TODO"
	"FIXME"
	"TBD"
	"HACK"
)

KEYWORD_CLASS="class"
KEYWORD_STRUCT="struct"
KEYWORD_ENUM="enum"
KEYWORD_PROTOCOL="protocol"
KEYWORD_TYPEALIAS="typealias"
KEYWORD_EXCLAMATION="!"

# Utilities

strip_spaces() {
	local OUTPUT
	OUTPUT=$(echo "${1}" | tr -d '[:space:]')
	echo $OUTPUT
}

# truncate date to YYYY-MM-DD
truncate_to_10_chars() {
	local OUTPUT
	OUTPUT=$(echo $1 |head -c 10)
	echo $OUTPUT
}

anonymize_string_if_needed() {
	if [[ $ANONYMOUS == "anon" ]]; then 
		echo $(anonymize.sh $1)
	else
		echo $1
	fi
}

# Values

print_json_key_value() { # With optional leading space and trailingcomma
	echo -e "$1$JSON_QUOTES$2$JSON_QUOTES$JSON_COLON$3$4"
}

date_start() {
	# Project start date		git log --date=iso --reverse |head -3 |grep "Date"	
	local CMD
	CMD="git log --date=iso --reverse |head -3 |grep \"Date\""
	local GITOUTPUT
	GITOUTPUT=$(eval $CMD)
	local GITPREFIX
	GITPREFIX="Date:   "
	local OUTPUT
	OUTPUT=${GITOUTPUT#$GITPREFIX}
	OUTPUT=$(truncate_to_10_chars $OUTPUT)
	echo $OUTPUT
}

date_end() {
	# Project start date		git log --date=iso --reverse |head -3 |grep "Date"	
	local CMD
	CMD="git log --date=iso |head -4 |grep \"Date\""
	local GITOUTPUT
	GITOUTPUT=$(eval $CMD)
	local GITPREFIX
	GITPREFIX="Date:   "
	local OUTPUT
	OUTPUT=${GITOUTPUT#$GITPREFIX}
	OUTPUT=$(truncate_to_10_chars $OUTPUT)
	echo $OUTPUT
}

files_number() { # file type in $1
	# Number of files		find . -name "*.swift" |wc -l	
	local CMD
	CMD="find . -name \"*.$1\" |wc -l"
	local GITOUTPUT
	GITOUTPUT=$(eval $CMD)
	local OUTPUT
	OUTPUT=$(strip_spaces ${GITOUTPUT})
	echo ${OUTPUT}
}

lines_number() {
	local CMD
	CMD="find . -name \"*.$1\" -print0 |xargs -0 cat | sed '/^\s*$/d' | wc -l"
	local GITOUTPUT
	GITOUTPUT=$(eval $CMD)
	local OUTPUT
	OUTPUT=$(strip_spaces ${GITOUTPUT})
	echo ${OUTPUT}
}

occurrences_number() {
	local CMD
	CMD="find . -name \"*.$1\" -print0 |xargs -0 cat | sed '/^\s*$/d' | grep -e \"$2\" | wc -l"
	local GITOUTPUT
	GITOUTPUT=$(eval $CMD)
	local OUTPUT
	OUTPUT=$(strip_spaces ${GITOUTPUT})
	echo ${OUTPUT}
}

contributors_number () {
	# Number of contributors		git shortlog -s -n |wc -l	
	local CMD
	CMD="git shortlog -s -n |wc -l"
	local GITOUTPUT
	GITOUTPUT=$(eval $CMD)
	local OUTPUT
	OUTPUT=$(strip_spaces ${GITOUTPUT})
	echo ${OUTPUT}
}

print_if_json () {
	if [[ $FORMAT == "JSON" ]];	then 
		echo -e $1
	fi
}

print_contributors () {
	# Number of contributors		git shortlog -s -n |wc -l	
	local CMD
	CMD="git shortlog -s -n"
	local GITOUTPUT
	GITOUTPUT="$(eval $CMD)"
	
	while read -r line; do
	    IFS='	' read -r commits author <<< "$line"
	    print_if_json $1$JSON_BRACE_OPEN
	    local auth
	    auth=$(anonymize_string_if_needed $author)
	    echo -e $1$INDENT$JSON_QUOTES$auth$JSON_QUOTES$JSON_COLON$commits
	    print_if_json $1$JSON_BRACE_CLOSE$JSON_COMMA
	done <<< "$GITOUTPUT"
	
	print_if_json $1$JSON_BRACE_OPEN
# 	print_if_json $1$INDENT$JSON_QUOTES"no_comma"$JSON_QUOTES$JSON_COLON"0" wtf is wrong with this?
	print_if_json $1$INDENT"\"no_comma\":0"
	print_if_json $1$JSON_BRACE_CLOSE
}

print_empty_lines_if_tsv() {
	if [[ $FORMAT == "tsv" ]]; then 
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

if [[ $FORMAT == "tsv" ]]; then 
	JSON_BRACE_OPEN=""
	JSON_BRACE_CLOSE=""
	JSON_BRACKET_OPEN=""
	JSON_BRACKET_CLOSE=""
	JSON_QUOTES=""
	JSON_COLON='\t'
	JSON_COMMA=""
else
	FORMAT="JSON"	
fi

cd $PROJECT_PATH

INDENT='\t'

print_if_json $JSON_BRACE_OPEN
echo -e $JSON_QUOTES"project"$JSON_QUOTES$JSON_COLON$JSON_BRACE_OPEN

print_json_key_value $INDENT "script_title"	$JSON_QUOTES$0$JSON_QUOTES $JSON_COMMA
print_json_key_value $INDENT "script_author"	$JSON_QUOTES"Andrei Nagy"$JSON_QUOTES $JSON_COMMA
project=$(anonymize_string_if_needed $PROJECT_PATH)
print_json_key_value $INDENT "project_path"	$JSON_QUOTES$project$JSON_QUOTES $JSON_COMMA
print_json_key_value $INDENT "project_scan_date"	$JSON_QUOTES"$(date '+%Y-%m-%d')"$JSON_QUOTES
print_if_json $JSON_BRACE_CLOSE$JSON_COMMA #project

echo -e $JSON_QUOTES"files"$JSON_QUOTES$JSON_COLON$JSON_BRACE_OPEN
print_json_key_value $INDENT "extension"	$JSON_QUOTES$FILE_EXTENSION$JSON_QUOTES	$JSON_COMMA
print_json_key_value $INDENT "files_number"	$(files_number $FILE_EXTENSION)	$JSON_COMMA
print_json_key_value $INDENT "non_empty_lines_number"	$(lines_number $FILE_EXTENSION)
print_if_json $JSON_BRACE_CLOSE$JSON_COMMA #project

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
