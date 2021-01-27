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
- `-f`|`--foreground` - specifies --item-foreground for all chart items (user defined values take precedence)
- `-b`|`--background` - specifies --item-background for all chart items (user defined values take precedence)
- `-c`|`--char` - specifies --item-char for all chart items (user defined values take precedence)
- `-pc`|`--placeholder`-char - specifies --item-placeholder-char for all chart items (user defined values take precedence)

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
- `30` - No data provided to draw chart.
- `40` - Unexpected value instead of nonnegative number.
- `50` - Missing opening curly brace ({).
- `51` - Missing closing curly brace (}).
- `60` - Unexpected foreground color name. Valid color name set is: black, red, green, yellow, blue, purple, cyan, white.
- `70` - Unexpected background color name. Valid color name set is: black, red, green, yellow, blue, purple, cyan, white.

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
```bat
chart --foreground red 1 2 3
```
