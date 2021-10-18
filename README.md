# Overview

SHJP is json parser writed by shell script in one file.  
This has only minumum functions, but you can just copy it and use it.

## Premise

- MIT Lisense, description is in source file.

## Functions

In addition to get json value directly,  
**compile mode that reduce overhead of performing json parsing multiple times is provided.**  
For example, compile mode is effective when following cases.
 - Parsing a json array containing json objects by loop processing.
 - Get step by step for readability or assignment to a variable.

***
### Get value directly

#### Command format
`shjp.sh [1] [2]...`
1. Json file path or json string.
2. Json key that you want to get value, If it is in a hierarchy, please connect with dots(*).
3. Other arguments after that are the same as 2.

(*)If key includes dot, please it is escaped with backslash.

***
### Compile

Compile json and output a compilation result.  
Because it is supposed to be reused, please redirect the result to a file.

#### Command format
`shjp.sh [1]`
1. Json file path or json string.

***
### Get value from the compilation result

#### Command format
`shjp.sh -g [1] [2]...`
1. File path of the compilation result.
2. Json key that you want to get value, If it is in a hierarchy, please connect with dots.
3. Other arguments after that are the same as 2.

***
## Attention

- Currently, newline expression (`\r|\n`) in json value is not supported.
