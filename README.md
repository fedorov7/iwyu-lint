# iwyu-lint

Include-what-you-use compilation database linter

## Getting started

Bash script iwyu-lint.sh is wrapper around two include-what-you-use tools.
It make simple linting with one call with all tools options supported.

### Prerequisites

Script uses IWYU tools from <https://include-what-you-use.org/>.
Please install IWYU tools first.

### Installing

Copy iwyu-lint.sh in your PATH directory as name would you like.

### Running

Run script with flags required for IWYU tools.

Examples:

``` shell
./iwyu-lint.sh -p build -b --comments --nosafe_headers file1.cpp file2.cpp
```

## Authors

* **Alexander Fedorov** - *iwyu-lint.sh* - [fedorov7](https://github.com/fedorov7)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
