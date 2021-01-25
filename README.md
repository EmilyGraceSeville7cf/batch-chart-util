# chart

simple chart drawer.

# Syntax
```bat
chart [options] [value { [options] } [value { [options] }]...]
```

# Options
- `-h`|`--help` - writes help and exits
- `-v`|`--version` - writes version and exits
- `-i`|`--interactive` - fall in interactive mode
- `-w`|`--width` - chart item width

Style options:
- `if`|`--item-foreground` - specifies chart item foreground color
- `ib`|`--item-background` - specifies chart item background color
- `ic`|`--item-char` - specifies chart item char used to display it
- `ipc`|`--item-placeholder`-char - specifies chart item placeholder char used to display it

Interactive mode commands:
- `q`|`quit` - exits
- `c`|`clear` - clears screen
- `h`|`help` - writes help

# Error codes
- `0` - Success
- `10` - bc utility not found to perform calculations with float numbers.
- `20` - Unexpected value instead of nonnegative number.
- `30` - Missing opening curly brace ({).
- `31` - Missing closing curly brace (}).
- `40` - Unexpected foreground color name. Valid color name set is: black, red, green, yellow, blue, purple, cyan, white.
- `50` - Unexpected background color name. Valid color name set is: black, red, green, yellow, blue, purple, cyan, white.

# Examples
```bat
chart --help
```
```bat
chart 1 5 3
```
```bat
chart 1 { --item-foreground red } 5 { --item-foreground green } 3 { --item-foreground blue }
```
