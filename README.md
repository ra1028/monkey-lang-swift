# 🐒 The Monkey Programming Language
![The Monkey Programming Language](https://cloud.githubusercontent.com/assets/1013641/22617482/9c60c27c-eb09-11e6-9dfa-b04c7fe498ea.png)

This repository is the monkey lang interpreter written in Swift.  
Monkey is a programming language designed for [Writing An Interpreter In Go](https://interpreterbook.com)  

---

## Overview

[Official Website](https://interpreterbook.com/#the-monkey-programming-language)


```javascript
let version = 1;
let name = "Monkey programming language";
let myArray = [1, 2, 3, 4, 5];
let coolBooleanLiteral = true;

let awesomeValue = (10 / 2) * 5 + 30;
let arrayWithValues = [1 + 1, 2 * 2, 3];
```

```javascript
let fibonacci = fn(x) {
  if (x == 0) {
    0
  } else {
    if (x == 1) {
      return 1;
    } else {
      fibonacci(x - 1) + fibonacci(x - 2);
    }
  }
};
```

---

## Getting Started

Simply run the monkey to play with REPL.  
```bash
$ git clone https://github.com/prologic/monkey-lang
$ monkey-lang
$ make
$ .build/release/monkey
```

---

## Usage

- REPL

```bash
$ monkey
```
```bash
$ monkey repl
```

- Run Source Files

```bash
$ monkey path/to/file.monkey
```

---

## Requirements for build

- Xcode 10.2.1+
- Swift 5.0.1+

---

## Lisense
[MIT](./LICENSE)
