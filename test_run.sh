#!/bin/bash

arr=(
	"./sourceCodeSummary.sh Eureka/Example/ | diff ReferenceOutput/eureka_ref.json -"
	"./sourceCodeSummary.sh Eureka/Example/ JSON anon | diff ReferenceOutput/eureka_ref_anon.json -"
	"./sourceCodeSummary.sh Eureka/Example/ TSV | diff ReferenceOutput/eureka_ref.txt -"
	"./sourceCodeSummary.sh Eureka/Example/ TSV anon | diff ReferenceOutput/eureka_ref_anon.txt -"
)

for i in "${arr[@]}"
do
	echo "-------- Testing $i"
	eval $i
done