#!/bin/bash

# Generates files to be used as a known good reference.

arr=(
	"sourceCodeSummary.sh Eureka/Example/ > ReferenceOutput/eureka_ref.json"
	"sourceCodeSummary.sh Eureka/Example/ JSON anon > ReferenceOutput/eureka_ref_anon.json"
	"sourceCodeSummary.sh Eureka/Example/ TSV > ReferenceOutput/eureka_ref.txt"
	"sourceCodeSummary.sh Eureka/Example/ TSV anon > ReferenceOutput/eureka_ref_anon.txt"
)

git clone https://github.com/xmartlabs/Eureka.git
mkdir "ReferenceOutput"

for i in "${arr[@]}"
do
	echo "-------- Generating comparison reference $i"
	eval $i
done