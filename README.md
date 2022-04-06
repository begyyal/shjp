[![CI](https://github.com/begyyal/shjp/actions/workflows/push-develop.yml/badge.svg)](https://github.com/begyyal/shjp/actions/workflows/push-develop.yml)

# Overview

SHJP is json parser writed by shell script in one file.  
This has only minumum functions, but you can just copy [./shjp](./shjp) and use it.

## Premise

- MIT Lisense, description is in source file.
- Compliant to Bash.

## Functions

In addition to get json value directly,  
**compile mode that reduce overhead of performing json parsing multiple times is provided.**  
For example, compile mode is effective when following cases.
 - Parsing a json array containing json objects by loop processing.
 - Get step by step for readability or assignment to a variable.

***
### Get value directly

#### Command format
`shjp [1] -t [2]`  
1. Json file path or json value.   
    - If argument `1` is empty and stdin is pipe, it is used instead of `1`.
2. Json key that you want to get value.   
    - If it is in a hierarchy, please connect with dots(*1).
    - If you specify multiple keys, separate them with commas(*1).

***
### Compile

Compile json and output a compilation result.  
Because it is supposed to be reused, please redirect the result to a file.

#### Command format
`shjp [1]`
1. Json file path or json value.
    - If argument `1` is empty and stdin is pipe, it is used instead of `1`.

***
### Get value from the compilation result

#### Command format
`shjp [1] -g [2]`
1. File path of the compilation result.

2. Json key that you want to get value. 
    - If it is in a hierarchy, please connect with dots(*1).
    - If you specify multiple keys, separate them with commas(*1).

***
### Accept pipe input
If the argument as above `[1]` is empty and stdin is pipe, it is used instead of `[1]`.

- `cat [1] | shjp -t [2]`
- `cat [1] | shjp`
- `cat [1] | shjp -g [2]`

***
### Spread processing to array.
It can get value in every element of array as below.

1. json  
```
{
  "array": [ 
    {"key":1}, 
    {"key":2}, 
    {"key":3} 
  ]
}
```

2. command  
`shjp [1] -t array | shjp -t key`

3. output
```
1
2
3
```

## Option

|key|detail|
|:---|:---|
|t|Please refer [here](#Get&#32;value&#32;directly).|
|g|Please refer [here](#Get&#32;value&#32;from&#32;the&#32;compilation&#32;result).|
|e|Handle as an error if specified targets is empty.|
|v|Output version.|

## Attention

- Currently, newline expression (`\r|\n`) in a value of string is not supported.
- (*1) If key includes dot(`.`) or comma(`,`), please it is escaped with backslash.  
    In this case, note that backslash is escape character when it isn't enclosed in quotation marks..
  - ng -> `aaa\.bbb` 
  - ok -> `'aaa\.bbb'`
  - ok -> `aaa\\.bbb`
