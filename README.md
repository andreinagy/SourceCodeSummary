# SourceCodeSummary
Bash tool to obtain stats of a source code directory with git source control

It collects project stats from a directory containing swift files. For example:
- number of files
- number of non empty lines in each file
- number of occurences of certain keywords in lines
- and last commit date
- summary of authors

The output is intended for quick quality metrics.

# Table of Contents
1. [Installation](#Installation)
2. [Demo](#Demo)
3. [Usage](#Usage)

## Installation
Clone or download .zip and unpack.

To run on any any project, adding the directory to $PATH may be useful.

## Demo
Check out the files in ReferenceOutput.

## Usage
Run in the terminal:
sourceCodeSummary.sh /Path/To/Main/SwiftFiles/Folder

It will output in json format for your project.
The path to the main code directory is needed to avoid obfuscating results with 3rd party dependencies (eg. cocoapods)

