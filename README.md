# Overview

SHJP is json parser writed by shell script in one file.  
This has only minumum functions, but you can just copy it and use it.

## Premise

- MIT Lisense, description is in source file.

## Functions

In addition to get json value directly,  
compile mode that reduce overhead of performing json parsing multiple times is provided.  
For example, compile mode is effective when following cases.
 - Parsing a json array containing json objects by loop processing.
 - Get step by step for readability or assignment to a variable.

### Get value directly

#### Command format
`shjp.sh [1] [2]...`
1. Json file path or json string.
2. Json key that you want to get value, If it is in a hierarchy, please connect with dots.
3. Other arguments after that are the same as 2.

#### Example1 - get a value
in -> `shjp.sh ./test.json test1`  
out -> `hoge`

#### Example1 - get a value in a hierarchy
in -> `shjp.sh ./test.json test2.test3`  
out -> `fuga`

#### Example3 - get values
in -> `shjp.sh ./test.json test1 test2.test3`  
out ->  
```
hoge
fuga
```

#### Example4 - get a array value
in -> `shjp.sh ./test.json test4`  
out ->  
```
hoge1  
hoge2
```

### Compile

Compile json and output a compilation result.  
Because it is supposed to be reused, please redirect the result to a file.

#### Command format
`shjp.sh [1]`
1. Json file path or json string.

#### Example
`shjp.sh ./test.json > ./comp`

### Get value from compiled file.

Get value from the compilation result.

#### Command format
`shjp.sh -g [1] [2]...`
1. The compilation result.
2. Json key that you want to get value, If it is in a hierarchy, please connect with dots.
3. Other arguments after that are the same as 2.

#### Example

The acquisition format is the same as [Get value directly](./shjp#Get-value-directly) except -g option.
