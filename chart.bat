@echo off
setlocal enableextensions

call :init
set /a "init_error_level=%errorlevel%"
if %init_error_level% gtr 0 exit /b %init_error_level%

call :clear_arguments args

set /a "i=0"
:copy_options
    set "option=%~1"
    if defined option (
        set "args[%i%]=%option%"
        shift
        set /a "i+=1"
        goto copy_options
    )

call :expand_sugar_options args
set /a "temp_error_level=%errorlevel%"
if %temp_error_level% gtr 0 exit /b %temp_error_level%

set /a "i=0"
:main_loop
    set /a "j=%i% + 1"
    call set "option=%%args[%i%]%%"
    call set "value=%%args[%j%]%%"

    set /a "is_help=%false%"
    if "%option%" == "-h" set /a "is_help=%true%"
    if "%option%" == "--help" set /a "is_help=%true%"

    if "%is_help%" == "%true%" (
        call :help
        exit /b %ec_success%
    )

    set /a "is_version=%false%"
    if "%option%" == "-v" set /a "is_version=%true%"
    if "%option%" == "--version" set /a "is_version=%true%"

    if "%is_version%" == "%true%" (
        call :version
        exit /b %ec_success%
    )

    set /a "is_interactive=%false%"
    if "%option%" == "-i" set /a "is_interactive=%true%"
    if "%option%" == "--interactive" set /a "is_interactive=%true%"

    if "%is_interactive%" == "%true%" (
        call :interactive
        exit /b %ec_success%
    )

    set /a "is_width=%false%"
    if "%option%" == "-w" set /a "is_width=%true%"
    if "%option%" == "--width" set /a "is_width=%true%"

    if "%is_width%" == "%true%" (
        set /a "width=%value%"
        set /a "i+=2"
        goto main_loop
    )

    set /a "is_debug_mode=%false%"
    if "%option%" == "-dm" set /a "is_debug_mode=%true%"
    if "%option%" == "--debug-mode" set /a "is_debug_mode=%true%"

    if "%is_debug_mode%" == "%true%" (
        set /a "debug_mode=%true%"
        set /a "i+=1"
        goto main_loop
    )

    if "%debug_mode%" == "%true%" call :print_array args "Expansion result: "

	if "%debug_mode%" == "%true%" echo Parsing input data... [stderr stream] >&2
    call :parse_chart_data i args data_value data_color data_char data_placeholder_char
    set /a "temp_errorlevel=%errorlevel%"
    if %temp_errorlevel% gtr 0 exit /b %temp_errorlevel%

    if "%debug_mode%" == "%true%" (
        call :print_array data_value "Data/Values: "
        call :print_array data_char "Data/Chars: "
        call :print_array data_placeholder_char "Data/Placeholder chars: "
    )

	if "%debug_mode%" == "%true%" echo Rendering chart... [stderr stream] >&2
    call :try_draw_chart data_value data_color data_char data_placeholder_char
    set /a "temp_error_level=%errorlevel%"
    if %temp_error_level% gtr 0 exit /b %temp_error_level%
    exit /b %ec_success%

:init
    set /a "ec_success=0"
    set /a "ec_gawk_not_found=10"
	set /a "ec_grep_not_found=11"

    set "em_gawk_not_found=gawk utility not found to perform calculations with float numbers."
	set "em_grep_not_found=grep utility not found to perform string search."

    set /a "true=0"
    set /a "false=1"

    set "prompt=>>> "
    set "number_regex=^[0-9][0-9]*$"

    set /a "default_width=10"
    set /a "width=%default_width%"

    set "default_char=-"
    set "default_placeholder_char= "

    set /a "debug_mode=%false%"

    call :set_esc

    set "default_color_code=%esc%[0m"
	
	set /a "is_wine=%false%"
	if defined WINEDEBUG set /a "is_wine=%true%"
	
	if "%is_wine%" == "%false%" exit /b %ec_success%
	
	set "gnu_path=C:\Program Files (x86)\GnuWin32\bin"
	set "PATH=%gnu_path%;%PATH%"
	
    gawk --version 2> nul > nul
	if %errorlevel% gtr 0 (
        echo %em_gawk_not_found%
        exit /b %ec_gawk_not_found%
    )
	
    grep --version 2> nul > nul
	if %errorlevel% gtr 0 (
        echo %em_grep_not_found%
        exit /b %ec_grep_not_found%
    )
exit /b %ec_success%

:help
    echo Creates simple chart.
    echo.
    echo Syntax:
    echo    chart [options] [value { [options] } [value { [options] }]...]
    echo.
    echo Options:
    echo    -h^|--help - writes help and exits
    echo    -v^|--version - writes version and exits
    echo    -i^|--interactive - fall in interactive mode
    echo    -w^|--width - chart item width
    echo    -f^|--foreground - specifies --item-foreground for all chart items (user defined values take precedence)
    echo        Available value set is: black, red, green, yellow, blue, purple, cyan, white, random, random-all.
    echo    -b^|--background - specifies --item-background for all chart items (user defined values take precedence)
    echo        Available value set is: black, red, green, yellow, blue, purple, cyan, white, random, random-all.
    echo    -c^|--char - specifies --item-char for all chart items (user defined values take precedence)
    echo    -pc^|--placeholder-char - specifies --item-placeholder-char for all chart items (user defined values take precedence)
    echo    -dm^|--debug-mode - enables debug mode
    echo.
    echo Style options:
    echo    -if^|--item-foreground - specifies chart item foreground color
    echo    -ib^|--item-background - specifies chart item background color
    echo    -ic^|--item-char - specifies chart item char used to display it
    echo    -ipc^|--item-placeholder-char - specifies chart item placeholder char used to display it
    echo.
    echo Interactive mode commands:
    echo    q^|quit - exits
    echo    c^|clear - clears screen
    echo    h^|help - writes help
    echo.
    echo Error codes:
    echo    - 0 - Success
    echo    - 10 - gawk utility not found to perform calculations with float numbers. [gawk is only required in Wine]
	echo    - 11 - grep utility not found to perform string search. [grep is only required in Wine]
    echo    - 20 - Unexpected value instead of nonnegative number while expanding --foreground^|--background^|--char^|--placeholder-char."
    echo    - 30 - Unexpected value instead of nonnegative number while expanding random colors.
    echo    - 40 - No data provided to draw chart.
    echo    - 50 - Unexpected value instead of nonnegative number.
    echo    - 60 - Missing opening curly brace ^({^).
    echo    - 61 - Missing closing curly brace ^(}^).
    echo    - 70 - Unexpected foreground color name. Valid color name set is: black (default), red, green, yellow, blue, purple, cyan, white, random.
    echo    - 80 - Unexpected background color name. Valid color name set is: black (default), red, green, yellow, blue, purple, cyan, white, random.
    echo.
    echo Examples:
    echo    - chart --help
    echo    - chart 1 5 3
    echo    - chart 1 { --item-foreground red } 5 { --item-foreground green } 3 { --item-foreground blue }
    echo    - chart --foreground red 1 2 3 =^> is converted to =^> chart 1 { --item-foreground red } 2 { --item-foreground red } 3 { --item-foreground red }
    echo    - chart --foreground random 1 2 3 =^> is converted to =^> chart --foreground ^<random-color^> 1 2 3 =^> is converted to =^> chart 1 { --item-foreground ^<random-color^> } 2 { --item-foreground ^<random-color^> } 3 { --item-foreground ^<random-color^> }
    echo    - chart --foreground random-all 1 2 3 =^> is converted to =^> chart 1 { --item-foreground ^<random-color-for-1^> } 2 { --item-foreground ^<random-color-for-2^> } 3 { --item-foreground ^<random-color-for-3^> }
exit /b %ec_success%

:version
    echo 1.1 ^(c^) 2021 year
exit /b %ec_success%

:interactive
    set "i_em_help_option_is_not_available=--help option is not available in ineractive mode. You have to use help command."
    set "i_em_version_option_is_not_available=--version option is not available in ineractive mode."
    set "i_em_interactive_option_is_not_available=--interactive option is not available in ineractive mode."

    set /a "i_last_errorlevel=0"

    :interactive_loop
        set /a "i_color_code=32"
        if not %i_last_errorlevel% == 0 set /a "i_color_code=31"
        set /a "debug_mode=%false%"
        set /a "width=%default_width%"
        set "i_command="
        call :clear_arguments i_args
        call :clear_arguments i_data_value
        call :clear_arguments i_data_color
        call :clear_arguments i_data_char
        call :clear_arguments i_data_placeholder_char
		
		if "%is_wine%" == "%false%" (
			set /p "i_command=%esc%[%i_color_code%m%i_last_errorlevel% %prompt%%esc%[0m"
		) else (
			set /p "i_command=%i_last_errorlevel% %prompt%"
		)
        call :perform_substitutions i_command "%i_command%"
        
        if not defined i_command goto interactive_loop
        if "%i_command: =%" == "" goto interactive_loop
        
        call :to_array i_args %i_command%
        set "i_first=%i_args[0]%"
        
        set "i_comment_regex=^#.*$"
		call :match_string "%i_first%" "%i_comment_regex%"
		if %errorlevel% equ 0 goto interactive_loop

        call set "i_command=%%i_command:!!=%i_previous_command%%%"
        call :to_array i_args %i_command%

        set "i_first=%i_args[0]%"

        set /a "i_is_quit=%false%"
        if "%i_first%" == "q" set /a "i_is_quit=%true%"
        if "%i_first%" == "quit" set /a "i_is_quit=%true%"

        if "%i_is_quit%" == "%true%" exit /b %ec_success%
    
        set /a "i_is_clear=%false%"
        if "%i_first%" == "c" set /a "i_is_clear=%true%"
        if "%i_first%" == "clear" set /a "i_is_clear=%true%"

        if "%i_is_clear%" == "%true%" (
            cls
            goto interactive_loop
        )

        set /a "i_is_help=%false%"
        if "%i_first%" == "h" set /a "i_is_help=%true%"
        if "%i_first%" == "help" set /a "i_is_help=%true%"

        if "%i_is_help%" == "%true%" (
            call :help
            goto interactive_loop
        )

        call :expand_sugar_options i_args
        set /a "i_temp_error_level=%errorlevel%"
        if %i_temp_error_level% gtr 0 (
            set /a "i_last_errorlevel=0"
            goto interactive_loop
        )

        set "i_previous_command=%i_command%"

        set /a "i_i=0"
        :i_main_loop
            set /a "i_j=%i_i% + 1"
            call set "i_option=%%i_args[%i_i%]%%"
            call set "i_value=%%i_args[%i_j%]%%"

            set /a "i_is_help=%false%"
            if "%i_option%" == "-h" set /a "i_is_help=%true%"
            if "%i_option%" == "--help" set /a "i_is_help=%true%"

            if "%i_is_help%" == "%true%" (
                echo %i_em_help_option_is_not_available%
                goto interactive_loop
            )

            set /a "i_is_version=%false%"
            if "%i_option%" == "-v" set /a "i_is_version=%true%"
            if "%i_option%" == "--version" set /a "i_is_version=%true%"

            if "%i_is_version%" == "%true%" (
                echo %i_em_version_option_is_not_available%
                goto interactive_loop
            )

            set /a "i_is_interactive=%false%"
            if "%i_option%" == "-i" set /a "i_is_interactive=%true%"
            if "%i_option%" == "--interactive" set /a "i_is_interactive=%true%"

            if "%i_is_interactive%" == "%true%" (
                echo %i_em_interactive_option_is_not_available%
                goto interactive_loop
            )

            set /a "i_is_width=%false%"
            if "%i_option%" == "-w" set /a "i_is_width=%true%"
            if "%i_option%" == "--width" set /a "i_is_width=%true%"

            if "%i_is_width%" == "%true%" (
                set /a "width=%i_value%"
                set /a "i_i+=2"
                goto i_main_loop
            )

            set /a "i_is_debug_mode=%false%"
            if "%i_option%" == "-dm" set /a "i_is_debug_mode=%true%"
            if "%i_option%" == "--debug-mode" set /a "i_is_debug_mode=%true%"

            if "%i_is_debug_mode%" == "%true%" (
                set /a "debug_mode=%true%"
                set /a "i_i+=1"
                goto i_main_loop
            )

            if "%debug_mode%" == "%true%" call :print_array i_args "Expansion result: "

            call :parse_chart_data i_i i_args i_data_value i_data_color i_data_char i_data_placeholder_char
            set /a "i_temp_errorlevel=%errorlevel%"
            if %i_temp_errorlevel% gtr 0 (
                set /a "i_last_errorlevel=%i_temp_error_level%"
                goto interactive_loop
            )

            if "%debug_mode%" == "%true%" (
                call :print_array i_data_value "Data/Values: "
                call :print_array i_data_char "Data/Chars: "
                call :print_array i_data_placeholder_char "Data/Placeholder chars: "
            )

            call :try_draw_chart i_data_value i_data_color i_data_char i_data_placeholder_char
            set /a "i_last_errorlevel=0"
            goto interactive_loop
exit /b %ec_success%

:clear_arguments
    set "ca_array_name=%~1"

    set /a "ca_i=0"
    :ca_clear_arguments_loop
        call set "ca_argument=%%%ca_array_name%[%ca_i%]%%"
        if defined ca_argument (
            set "%ca_array_name%[%ca_i%]="
            set /a "ca_i+=1"
            goto ca_clear_arguments_loop
        )
exit /b %ec_success%

:to_array
    set "ta_array_name=%~1"

    shift
    set /a "ta_i=0"
    :ta_conversion_loop
        set "ta_argument=%~1"
        if defined ta_argument (
            set "%ta_array_name%[%ta_i%]=%ta_argument%"
            set /a "ta_i+=1"
            shift
            goto ta_conversion_loop
        )
exit /b %ec_success%

:expand_sugar_options
    set /a "eso_ec_unexpected_value=20"

    set "eso_em_unexpected_value=Unexpected value instead of nonnegative number while expanding --foreground^|--background^|--char^|--placeholder-char."

    set "eso_args_array_name=%~1"

    set /a "eso_temp_errorlevel=%errorlevel%"
    if %eso_temp_errorlevel% gtr 0 exit /b %eso_temp_errorlevel%

    set "eso_temp_foreground_value="
    set "eso_temp_background_value="
    set /a "eso_temp_foreground_value_is_random_for_all=%false%"
    set /a "eso_temp_background_value_is_random_for_all=%false%"
    set "eso_temp_char_value="
    set "eso_temp_placeholder_char_value="

    set /a "eso_i=0"
    :eso_expand_options_loop
        set /a "eso_j=%eso_i% + 1"

        if not defined %eso_args_array_name%[%eso_i%] exit /b %ec_success%

        call set "eso_option=%%%eso_args_array_name%[%eso_i%]%%"
        call set "eso_value=%%%eso_args_array_name%[%eso_j%]%%"

        set /a "eso_is_foreground=%false%"
        if "%eso_option%" == "-f" set /a "eso_is_foreground=%true%"
        if "%eso_option%" == "--foreground" set /a "eso_is_foreground=%true%"

        if "%eso_is_foreground%" == "%true%" goto eso_if_eso_is_foreground_equal_to_true

        set /a "eso_is_background=%false%"
        if "%eso_option%" == "-b" set /a "eso_is_background=%true%"
        if "%eso_option%" == "--background" set /a "eso_is_background=%true%"

        if "%eso_is_background%" == "%true%" goto eso_if_eso_is_background_equal_to_true

        set /a "eso_is_char=%false%"
        if "%eso_option%" == "-c" set /a "eso_is_char=%true%"
        if "%eso_option%" == "--char" set /a "eso_is_char=%true%"

        if "%eso_is_char%" == "%true%" (
            set "eso_temp_char_value=%eso_value:~0,1%"

            call :remove_array_item "%eso_args_array_name%" "%eso_i%"
            call :remove_array_item "%eso_args_array_name%" "%eso_i%"
            goto eso_expand_options_loop
        )

        set /a "eso_is_placeholder_char=%false%"
        if "%eso_option%" == "-pc" set /a "eso_is_placeholder_char=%true%"
        if "%eso_option%" == "--placeholder-char" set /a "eso_is_placeholder_char=%true%"

        if "%eso_is_placeholder_char%" == "%true%" (
            set "eso_temp_placeholder_char_value=%eso_value:~0,1%"

            call :remove_array_item "%eso_args_array_name%" "%eso_i%"
            call :remove_array_item "%eso_args_array_name%" "%eso_i%"
            goto eso_expand_options_loop
        )

        set /a "eso_is_skippable_option_with_value=%false%"
        if "%eso_option%" == "-w" set /a "eso_is_skippable_option_with_value=%true%"
        if "%eso_option%" == "--width" set /a "eso_is_skippable_option_with_value=%true%"

        if "%eso_is_skippable_option_with_value%" == "%true%" (
            set /a "eso_i+=2"
            goto eso_expand_options_loop
        )

        set /a "eso_is_skippable_option_without_value=%false%"
        if "%eso_option%" == "-h" set /a "eso_is_skippable_option_without_value=%true%"
        if "%eso_option%" == "--help" set /a "eso_is_skippable_option_without_value=%true%"
        if "%eso_option%" == "-v" set /a "eso_is_skippable_option_without_value=%true%"
        if "%eso_option%" == "--version" set /a "eso_is_skippable_option_without_value=%true%"
        if "%eso_option%" == "-i" set /a "eso_is_skippable_option_without_value=%true%"
        if "%eso_option%" == "--interactive" set /a "eso_is_skippable_option_without_value=%true%"
        if "%eso_option%" == "-dm" set /a "eso_is_skippable_option_without_value=%true%"
        if "%eso_option%" == "--debug-mode" set /a "eso_is_skippable_option_without_value=%true%"

        if "%eso_is_skippable_option_without_value%" == "%true%" (
            set /a "eso_i+=1"
            goto eso_expand_options_loop
        )

        call set "eso_value=%%%eso_args_array_name%[%eso_i%]%%"
        call set "eso_next_argument=%%%eso_args_array_name%[%eso_j%]%%"

		call :match_string "%eso_value%" "%number_regex%"
		if %errorlevel% gtr 0 (
			echo %eso_value%
            echo %eso_em_unexpected_value%
            exit /b %eso_ec_unexpected_value%
        )

        if not "%eso_next_argument%" == "{" (
            call :insert_array_item "%eso_args_array_name%" "}" "%eso_j%"
            call :insert_array_item "%eso_args_array_name%" "{" "%eso_j%"
        )

        set /a "eso_i+=2"

        set /a "eso_temp_random_foreground=0"
        set /a "eso_temp_random_background=0"

        call :random_foreground_color_code eso_temp_random_foreground
        call :random_background_color_code eso_temp_random_background

        if defined eso_temp_foreground_value (
            if "%eso_temp_foreground_value_is_random_for_all%" == "%true%" (
                call :insert_array_item "%eso_args_array_name%" "%eso_temp_random_foreground%" "%eso_i%"
            ) else (
                call :insert_array_item "%eso_args_array_name%" "%eso_temp_foreground_value%" "%eso_i%"
            )
            call :insert_array_item "%eso_args_array_name%" "--item-foreground" "%eso_i%"
            set /a "eso_i+=2"
        )
        if defined eso_temp_background_value (
            if "%eso_temp_background_value_is_random_for_all%" == "%true%" (
                call :insert_array_item "%eso_args_array_name%" "%eso_temp_random_background%" "%eso_i%"
            ) else (
                call :insert_array_item "%eso_args_array_name%" "%eso_temp_background_value%" "%eso_i%"
            )
            call :insert_array_item "%eso_args_array_name%" "--item-background" "%eso_i%"
            set /a "eso_i+=2"
        )
        if defined eso_temp_char_value (
            call :insert_array_item "%eso_args_array_name%" "%eso_temp_char_value%" "%eso_i%"
            call :insert_array_item "%eso_args_array_name%" "--item-char" "%eso_i%"
            set /a "eso_i+=2"
        )
        if defined eso_temp_placeholder_char_value (
            call :insert_array_item "%eso_args_array_name%" "%eso_temp_placeholder_char_value%" "%eso_i%"
            call :insert_array_item "%eso_args_array_name%" "--item-placeholder-char" "%eso_i%"
            set /a "eso_i+=2"
        )

        :eso_move_to_closing_brace
            call set "eso_argument=%%%eso_args_array_name%[%eso_i%]%%"
            if not defined eso_argument exit /b %ec_success%
			echo| pause > nul
            if not "%eso_argument%" == "}" (
                set /a "eso_i+=1"
                goto eso_move_to_closing_brace
            )
        
        set /a "eso_i+=1"
        goto eso_expand_options_loop
exit /b %ec_success%

:eso_if_eso_is_foreground_equal_to_true
    if "%eso_value%" == "random-all" (
        set /a "eso_temp_foreground_value_is_random_for_all=%true%"
        set /a "eso_temp_foreground_value=0"
        goto eso_remove_array_items_for_foreground_color_option
    )
    call :to_foreground_color_code eso_temp_foreground_value "%eso_value%"
    set /a "eso_temp_errorlevel=%errorlevel%"
    if %eso_temp_errorlevel% gtr 0 exit /b %eso_temp_errorlevel%
    set /a "eso_temp_foreground_value_is_random_for_all=%false%"

    :eso_remove_array_items_for_foreground_color_option
    call :remove_array_item "%eso_args_array_name%" "%eso_i%"
    call :remove_array_item "%eso_args_array_name%" "%eso_i%"
    goto eso_expand_options_loop

:eso_if_eso_is_background_equal_to_true
    if "%eso_value%" == "random-all" (
        set /a "eso_temp_background_value_is_random_for_all=%true%"
        set /a "eso_temp_background_value=0"
        goto eso_remove_array_items_for_background_color_option
    )
    call :to_background_color_code eso_temp_background_value "%eso_value%"
    set /a "eso_temp_errorlevel=%errorlevel%"
    if %eso_temp_errorlevel% gtr 0 exit /b %eso_temp_errorlevel%
    set /a "eso_temp_background_value_is_random_for_all=%false%"

    :eso_remove_array_items_for_background_color_option
    call :remove_array_item "%eso_args_array_name%" "%eso_i%"
    call :remove_array_item "%eso_args_array_name%" "%eso_i%"
    goto eso_expand_options_loop

:expand_sugar_options_random_colors
    set /a "esorc_ec_unexpected_value=30"

    set "esorc_em_unexpected_value=Unexpected value instead of nonnegative number while expanding random colors."

    set "esorc_args_array_name=%~1"

    set /a "esorc_i=0"
    :esorc_expand_options_loop
        set /a "esorc_j=%esorc_i% + 1"

        if not defined %esorc_args_array_name%[%esorc_i%] exit /b %ec_success%

        call set "esorc_option=%%%esorc_args_array_name%[%esorc_i%]%%"
        call set "esorc_value=%%%esorc_args_array_name%[%esorc_j%]%%"

        set /a "esorc_is_foreground_or_item_foreground=%false%"
        if "%esorc_option%" == "-f" set /a "esorc_is_foreground_or_item_foreground=%true%"
        if "%esorc_option%" == "--foreground" set /a "esorc_is_foreground_or_item_foreground=%true%"
        if "%esorc_option%" == "-if" set /a "esorc_is_foreground_or_item_foreground=%true%"
        if "%esorc_option%" == "--item-foreground" set /a "esorc_is_foreground_or_item_foreground=%true%"

        if "%esorc_is_foreground_or_item_foreground%" == "%true%" (
            if not "%esorc_value%" == "random-all" call :random_foreground_color_code "%esorc_args_array_name%[%esorc_j%]"

            set /a "esorc_i+=2"
            goto esorc_expand_options_loop
        )

        set /a "esorc_is_background_or_item_background=%false%"
        if "%esorc_option%" == "-b" set /a "esorc_is_background_or_item_background=%true%"
        if "%esorc_option%" == "--background" set /a "esorc_is_background_or_item_background=%true%"
        if "%esorc_option%" == "-ib" set /a "esorc_is_background_or_item_background=%true%"
        if "%esorc_option%" == "--item-background" set /a "esorc_is_background_or_item_background=%true%"

        if "%esorc_is_background_or_item_background%" == "%true%" (
            if not "%esorc_value%" == "random-all" call :random_background_color_code "%esorc_args_array_name%[%esorc_j%]"

            set /a "esorc_i+=2"
            goto esorc_expand_options_loop
        )

        set /a "esorc_is_skippable_option_with_value=%false%"
        if "%esorc_option%" == "-w" set /a "esorc_is_skippable_option_with_value=%true%"
        if "%esorc_option%" == "--width" set /a "esorc_is_skippable_option_with_value=%true%"

        if "%esorc_is_skippable_option_with_value%" == "%true%" (
            set /a "esorc_i+=2"
            goto esorc_expand_options_loop
        )

        set /a "esorc_is_skippable_option_without_value_or_brace=%false%"
        if "%esorc_option%" == "-h" set /a "esorc_is_skippable_option_without_value_or_brace=%true%"
        if "%esorc_option%" == "--help" set /a "esorc_is_skippable_option_without_value_or_brace=%true%"
        if "%esorc_option%" == "-v" set /a "esorc_is_skippable_option_without_value_or_brace=%true%"
        if "%esorc_option%" == "--version" set /a "esorc_is_skippable_option_without_value_or_brace=%true%"
        if "%esorc_option%" == "-i" set /a "esorc_is_skippable_option_without_value_or_brace=%true%"
        if "%esorc_option%" == "--interactive" set /a "esorc_is_skippable_option_without_value_or_brace=%true%"
        if "%esorc_option%" == "-dm" set /a "esorc_is_skippable_option_without_value_or_brace=%true%"
        if "%esorc_option%" == "--debug-mode" set /a "esorc_is_skippable_option_without_value_or_brace=%true%"
        if "%esorc_option%" == "{" set /a "esorc_is_skippable_option_without_value_or_brace=%true%"
        if "%esorc_option%" == "}" set /a "esorc_is_skippable_option_without_value_or_brace=%true%"

        if "%esorc_is_skippable_option_without_value_or_brace%" == "%true%" (
            set /a "esorc_i+=1"
            goto esorc_expand_options_loop
        )

        call set "esorc_value=%%%esorc_args_array_name%[%esorc_i%]%%"

		call :match_string "%esorc_value%" "%number_regex%"
		if %errorlevel% gtr 0 (
            echo %esorc_em_unexpected_value%
            exit /b %esorc_ec_unexpected_value%
        )

        set /a "esorc_i+=1"
        goto esorc_expand_options_loop
exit /b %ec_success%

:try_draw_chart
    set /a "tdc_ec_no_data_provided=40"

    set "tdc_em_no_data_provided=No data provided to draw chart."

    set "tdc_data_value_array_name=%~1"
    set "tdc_data_color_array_name=%~2"
    set "tdc_data_char_array_name=%~3"
    set "tdc_data_placeholder_char_array_name=%~4"
    
    set "tdc_temp_file=tmp.txt"

    call find_max.bat tdc_max "%tdc_data_value_array_name%" 2> nul > nul
	if "%errorlevel%" gtr 0 (
        echo %tdc_em_no_data_provided%
        exit /b %tdc_ec_no_data_provided%
    )
	
    set /a "tdc_i=0"
    :tdc_loop
        call set "tdc_value=%%%tdc_data_value_array_name%[%tdc_i%]%%"
        call set "tdc_color=%%%tdc_data_color_array_name%[%tdc_i%]%%"
        call set "tdc_char=%%%tdc_data_char_array_name%[%tdc_i%]%%"
        call set "tdc_placeholder_char=%%%tdc_data_placeholder_char_array_name%[%tdc_i%]%%"

        if not defined tdc_value exit /b %ec_success%

		echo| pause > nul
		if "%is_wine%" == "%false%" (
			powershell -Command  "%tdc_value%/%tdc_max%*%width%" > "%tdc_temp_file%"
		) else (
			gawk -f calculate.awk %tdc_value% %tdc_max% %width% > "%tdc_temp_file%"
		)

        set /p tdc_item_length=<%tdc_temp_file%
        set /a "tdc_space_count=%width% - %tdc_item_length%"
        
        call :repeat_string tdc_item "%tdc_char%" "%tdc_item_length%"
        call :repeat_string tdc_space "%tdc_placeholder_char%" "%tdc_space_count%"

		if "%is_wine%" == "%false%" (
			echo %tdc_color%%tdc_item%%tdc_space% %tdc_value%%esc%[0m
		) else (
			echo %tdc_item%%tdc_space% %tdc_value%
		)

        set /a "tdc_i+=1"
        goto tdc_loop
exit /b %ec_success%

:parse_chart_data
    set /a "pcd_ec_unexpected_value=50"

    set "pcd_em_unexpected_value=Unexpected value instead of nonnegative number."

    set "pcd_index_variable_name=%~1"
    set "pcd_args_array_name=%~2"
    set "pcd_data_value_array_name=%~3"
    set "pcd_data_color_array_name=%~4"
    set "pcd_data_char_array_name=%~5"
    set "pcd_data_placeholder_char_array_name=%~6"

    set /a "pcd_i=%pcd_index_variable_name%"
    set /a "pcd_data_i=0"
    :pcd_loop
        set /a "pcd_j=%pcd_i% + 1"
        call set "pcd_value=%%%pcd_args_array_name%[%pcd_i%]%%"
        call set "pcd_style=%%%pcd_args_array_name%[%pcd_j%]%%"

        if not defined %pcd_args_array_name%[%pcd_i%] exit /b %ec_success%

		call :match_string "%pcd_value%" "%number_regex%"
		if %errorlevel% gtr 0 (
            echo %pcd_em_unexpected_value%
            exit /b %pcd_ec_unexpected_value%
        )

        set "%pcd_data_value_array_name%[%pcd_data_i%]=%pcd_value%"

        set "pcd_color=%default_color_code%"
        set "pcd_char=%default_char%"
        set "pcd_placeholder_char=%default_placeholder_char%"
        
        if not "%pcd_style%" == "{" (
            set "%pcd_data_color_array_name%[%pcd_data_i%]=%pcd_color%"
            set "%pcd_data_char_array_name%[%pcd_data_i%]=%pcd_char%"
            set "%pcd_data_placeholder_char_array_name%[%pcd_data_i%]=%pcd_placeholder_char%"

            set /a "pcd_data_i+=1"
            set /a "pcd_i+=1"
            goto pcd_loop
        )

        set /a "pcd_i+=1"
        call :skip_style_block pcd_i pcd_color pcd_char pcd_placeholder_char "%pcd_args_array_name%"
        set /a "pcd_temp_errorlevel=%errorlevel%"
        if %pcd_temp_errorlevel% gtr 0 exit /b %pcd_temp_errorlevel%

        set "%pcd_data_color_array_name%[%pcd_data_i%]=%pcd_color%"
        set "%pcd_data_char_array_name%[%pcd_data_i%]=%pcd_char%"
        set "%pcd_data_placeholder_char_array_name%[%pcd_data_i%]=%pcd_placeholder_char%"
        set /a "pcd_data_i+=1"
        goto pcd_loop
exit /b %ec_success%

:skip_style_block
    set /a "ssb_ec_missing_opening_curly_brace=60"
    set /a "ssb_ec_missing_closing_curly_brace=61"

    set "ssb_em_missing_opening_curly_brace=Missing opening curly brace ^({^)."
    set "ssb_em_missing_closing_curly_brace=Missing closing curly brace ^(}^)."

    set "ssb_index_variable_name=%~1"
    set "ssb_result_color_variable_name=%~2"
    set "ssb_result_char_variable_name=%~3"
    set "ssb_result_placeholder_char_variable_name=%~4"
    set "ssb_args_array_name=%~5"

    set /a "ssb_i=%ssb_index_variable_name%"

    set "ssb_item_foreground=0"
    set "ssb_item_background=0"
    set "ssb_item_char=%default_char%"
    set "ssb_item_placeholder_char=%default_placeholder_char%"

    call set "ssb_option=%%%ssb_args_array_name%[%ssb_i%]%%"
    if not "%ssb_option%" == "{" (
        echo %ssb_em_missing_opening_curly_brace%
        exit /b %ssb_ec_missing_opening_curly_brace%
    )
    
    set /a "ssb_i+=1"
    :ssb_loop
        set /a "ssb_j=%ssb_i% + 1"
        call set "ssb_option=%%%ssb_args_array_name%[%ssb_i%]%%"
        call set "ssb_value=%%%ssb_args_array_name%[%ssb_j%]%%"

        set /a "ssb_is_item_foreground=%false%"
        if "%ssb_option%" == "-if" set /a "ssb_is_item_foreground=%true%"
        if "%ssb_option%" == "--item-foreground" set /a "ssb_is_item_foreground=%true%"

        if "%ssb_is_item_foreground%" == "%true%" (
            set "ssb_item_foreground=%ssb_value%"
            set /a "ssb_i+=2"
            goto ssb_loop
        )

        set /a "ssb_is_item_background=%false%"
        if "%ssb_option%" == "-ib" set /a "ssb_is_item_background=%true%"
        if "%ssb_option%" == "--item-background" set /a "ssb_is_item_background=%true%"

        if "%ssb_is_item_background%" == "%true%" (
            set "ssb_item_background=%ssb_value%"
            set /a "ssb_i+=2"
            goto ssb_loop
        )

        set /a "ssb_is_item_char=%false%"
        if "%ssb_option%" == "-ic" set /a "ssb_is_item_char=%true%"
        if "%ssb_option%" == "--item-char" set /a "ssb_is_item_char=%true%"

        if "%ssb_is_item_char%" == "%true%" (
            set "ssb_item_char=%ssb_value:~0,1%"
            set /a "ssb_i+=2"
            goto ssb_loop
        )

        set /a "ssb_is_item_placeholder_char=%false%"
        if "%ssb_option%" == "-ipc" set /a "ssb_is_item_placeholder_char=%true%"
        if "%ssb_option%" == "--item-placeholder-char" set /a "ssb_is_item_placeholder_char=%true%"

        if "%ssb_is_item_placeholder_char%" == "%true%" (
            set "ssb_item_placeholder_char=%ssb_value:~0,1%"
            set /a "ssb_i+=2"
            goto ssb_loop
        )

        if not "%ssb_option%" == "}" (
            echo %ssb_em_missing_closing_curly_brace%
            exit /b %ssb_ec_missing_closing_curly_brace%
        )

        call :to_color_code "%ssb_result_color_variable_name%" "%ssb_item_foreground%" "%ssb_item_background%"
        set /a "ssb_error_level=%errorlevel%"
        if %ssb_error_level% gtr 0 exit /b %ssb_error_level%
        set "%ssb_result_char_variable_name%=%ssb_item_char%"
        set "%ssb_result_placeholder_char_variable_name%=%ssb_item_placeholder_char%"
        set /a "%ssb_index_variable_name%=%ssb_i% + 1"
exit /b %ec_success%

:to_color_code
    set "tcc_variable_name=%~1"
    set "tcc_foreground_color=%~2"
    set "tcc_background_color=%~3"

    set "%tcc_variable_name%=%esc%[0m"

    call :to_foreground_color_code tcc_foreground_color "%tcc_foreground_color%"
    set /a "tcc_error_level=%errorlevel%"
    if %tcc_error_level% gtr 0 exit /b %tcc_error_level%

    call :to_background_color_code tcc_background_color "%tcc_background_color%"
    set /a "tcc_error_level=%errorlevel%"
    if %tcc_error_level% gtr 0 exit /b %tcc_error_level%

    if %tcc_foreground_color% neq 0 (
        if %tcc_background_color% neq 0 (
            set "%tcc_variable_name%=%esc%[%tcc_foreground_color%;%tcc_background_color%m"
        ) else (
            set "%tcc_variable_name%=%esc%[%tcc_foreground_color%m"
        )
    ) else (
        if %tcc_background_color% neq 0 (
            set "%tcc_variable_name%=%esc%[%tcc_background_color%m"
        ) else (
            set "%tcc_variable_name%=%default_color_code%"
        )
    )
    
exit /b %ec_success%

:to_foreground_color_code
    set "tfcc_variable_name=%~1"
    set "tfcc_color=%~2"

	call :match_string "%tfcc_color%" "%number_regex%"
	if %errorlevel% equ 0 (
        set "%tfcc_variable_name%=%tfcc_color%"
        exit /b %ec_success%
    )

    call :name_to_foreground_color_code "%tfcc_variable_name%" "%tfcc_color%"
    set /a "tfcc_error_level=%errorlevel%"
    if %tfcc_error_level% gtr 0 exit /b %tfcc_error_level%
exit /b %ec_success%

:to_background_color_code
    set "tbcc_variable_name=%~1"
    set "tbcc_color=%~2"

	call :match_string "%tbcc_color%" "%number_regex%"
	if %errorlevel% equ 0 (
        set "%tbcc_variable_name%=%tbcc_color%"
        exit /b %ec_success%
    )

    call :name_to_background_color_code "%tbcc_variable_name%" "%tbcc_color%"
    set /a "tbcc_error_level=%errorlevel%"
    if %tbcc_error_level% gtr 0 exit /b %tbcc_error_level%
exit /b %ec_success%

:name_to_foreground_color_code
    set /a "ntfcc_ec_wrong_color_name=70"

    set "ntfcc_em_wrong_color_name=Unexpected foreground color name. Valid color name set is: black (default), red, green, yellow, blue, purple, cyan, white, random."

    set "ntfcc_variable_name=%~1"
    set "ntfcc_color_name=%~2"

    set "ntfcc_default_color=30"

    if "%ntfcc_color_name%" == "black" (
		set /a "%ntfcc_variable_name%=30"
		exit /b %ec_success%
	)
    if "%ntfcc_color_name%" == "red" (
		set "%ntfcc_variable_name%=31"
		exit /b %ec_success%
	)
    if "%ntfcc_color_name%" == "green" (
		set /a "%ntfcc_variable_name%=32"
		exit /b %ec_success%
	)
    if "%ntfcc_color_name%" == "yellow" (
		set /a "%ntfcc_variable_name%=33"
		exit /b %ec_success%
	)
    if "%ntfcc_color_name%" == "blue" (
		set /a "%ntfcc_variable_name%=34"
		exit /b %ec_success%
	)
    if "%ntfcc_color_name%" == "purple" (
		set /a "%ntfcc_variable_name%=35"
		exit /b %ec_success%
	)
    if "%ntfcc_color_name%" == "cyan" (
		set /a "%ntfcc_variable_name%=36"
		exit /b %ec_success%
	)
    if "%ntfcc_color_name%" == "white" (
		set /a "%ntfcc_variable_name%=37"
		exit /b %ec_success%
	)
    if "%ntfcc_color_name%" == "default" (
		set /a "%ntfcc_variable_name%=%ntfcc_default_color%"
		exit /b %ec_success%
	)
    if "%ntfcc_color_name%" == "random" (
        call :random_foreground_color_code "%ntfcc_variable_name%"
        exit /b %ec_success%
    )

    set /a "%ntfcc_variable_name%=0"
    echo %ntfcc_em_wrong_color_name%
exit /b %ntfcc_ec_wrong_color_name%

:name_to_background_color_code
    set /a "ntbcc_ec_wrong_color_name=80"

    set "ntbcc_em_wrong_color_name=Unexpected background color name. Valid color name set is: black (default), red, green, yellow, blue, purple, cyan, white, random."

    set "ntbcc_variable_name=%~1"
    set "ntbcc_color_name=%~2"

    set "ntbcc_default_color=40"

    if "%ntbcc_color_name%" == "black" (
		set /a "%ntbcc_variable_name%=40"
		exit /b %ec_success%
	)
    if "%ntbcc_color_name%" == "red" (
		set /a "%ntbcc_variable_name%=41"
		exit /b %ec_success%
	)
    if "%ntbcc_color_name%" == "green" (
		set /a "%ntbcc_variable_name%=42"
		exit /b %ec_success%
	)
    if "%ntbcc_color_name%" == "yellow" (
		set /a "%ntbcc_variable_name%=43"
		exit /b %ec_success%
	)
    if "%ntbcc_color_name%" == "blue" (
		set /a "%ntbcc_color_name%=44"
		exit /b %ec_success%
	)
    if "%ntbcc_color_name%" == "purple" (
		set /a "%ntbcc_variable_name%=45"
		exit /b %ec_success%
	)
    if "%ntbcc_color_name%" == "cyan" (
		set /a "%ntbcc_variable_name%=46"
		exit /b %ec_success%
	)
    if "%ntbcc_color_name%" == "white" (
		set /a "%ntbcc_variable_name%=47"
		exit /b %ec_success%
	)
    if "%ntbcc_color_name%" == "default" (
		set /a "%ntbcc_variable_name%=%ntbcc_default_color%"
		exit /b %ec_success%
	)
    if "%ntbcc_color_name%" == "random" (
        call :random_background_color_code "%ntbcc_variable_name%"
        exit /b %ec_success%
    )

    set /a "%ntbcc_variable_name%=0"
    echo %ntbcc_em_wrong_color_name%
exit /b %ntbcc_ec_wrong_color_name%

:random_foreground_color_code
    set "rfcc_variable_name=%~1"

    set /a "%rfcc_variable_name%=30 + %random% %% 8"
exit /b %ec_success%

:random_background_color_code
    set "rbcc_variable_name=%~1"
    
    set /a "%rbcc_variable_name%=40 + %random% %% 8"
exit /b %ec_success%

:insert_array_item
    set "iai_array_name=%~1"
    set "iai_item_value=%~2"
    set /a "iai_item_index=%~3"

    set /a "iai_i=%iai_item_index%"
    :iai_moving_to_last_item
        set "iai_item_name=%iai_array_name%[%iai_i%]"
        if defined %iai_item_name% (
            set /a "iai_i+=1"
            goto iai_moving_to_last_item
        )
    
    :iai_shifting_items_to_right
        set /a "iai_j=%iai_i% - 1"
        set "iai_item_name=%iai_array_name%[%iai_i%]"
        set "iai_previous_item_name=%iai_array_name%[%iai_j%]"

        if %iai_j% geq %iai_item_index% (
            call set "%iai_item_name%=%%%iai_previous_item_name%%%"
            set /a "iai_i-=1"
            goto iai_shifting_items_to_right
        )

    set "%iai_array_name%[%iai_i%]=%iai_item_value%"
exit /b %ec_success%

:remove_array_item
    set "rai_array_name=%~1"
    set /a "rai_item_index=%~2"

    set /a "rai_i=%rai_item_index%"
    :rai_remove_loop
        set /a "rai_j=%rai_i% + 1"
        set "rai_item_name=%rai_array_name%[%rai_i%]"
        set "rai_next_item_name=%rai_array_name%[%rai_j%]"

        if defined %rai_item_name% (
            call set "%rai_item_name%=%%%rai_next_item_name%%%"
            set /a "rai_i+=1"
            goto rai_remove_loop
        )
exit /b %ec_success%

:print_array
    set "pa_array_name=%~1"
    set "pa_note=%~2"

    echo| set /p "=%pa_note%" >&2
    set /a "pa_i=0"
    :pa_print_loop
        set "pa_item_name=%pa_array_name%[%pa_i%]"
        if defined %pa_item_name% (
            echo| call set /p "=item-%pa_i%=[%%%pa_item_name%%%] " >&2
            set /a "pa_i+=1"
            goto pa_print_loop
        )
    echo [stderr stream] >&2
exit /b %ec_success%

:repeat_string
    set "rs_variable_name=%~1"
    set "rs_string=%~2"
    set /a "rs_count=%~3"

	if %rs_count% lss 1 (
		set "%rs_variable_name%="
		exit /b %ec_success%
	)

	set /a "rs_actual_count=1"
	
	:rs_repetition_loop
		if %rs_actual_count% lss %rs_count% (
			set "rs_string=%rs_string%%rs_string%"
			set /a "rs_actual_count=%rs_actual_count% * 2"
			goto rs_repetition_loop
		)
	
	call set "%rs_variable_name%=%%rs_string:~0,%rs_count%%%"
exit /b %ec_success%

:perform_substitutions
    set "ps_variable_name=%~1"
    set "ps_value=%~2"

    :ps_substitute_loop
        set "ps_value_before_substitution=%ps_value%"
        call set "ps_value=%ps_value%"
        if not "%ps_value_before_substitution%" == "%ps_value%" goto ps_substitute_loop
    
    set "%ps_variable_name%=%ps_value%"
exit /b %ec_success%

:match_string
    set "ms_value=%~1"
    set "ms_regex=%~2"
	
	if "%is_wine%" == "%false%" (
		goto ms_windows_match
	) else (
		goto ms_wine_match
	)
	
	:ms_windows_match
		echo %ms_value%| findstr /r "%ms_regex%" 2> nul > nul
		exit /b %errorlevel%
	:ms_wine_match
		echo %ms_value%| grep "%ms_regex%" 2> nul > nul
		exit /b %errorlevel%
exit /b %ec_success%

:set_esc
    for /f "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
        set "esc=%%b"
        exit /b 0
    )
exit /b %ec_success%
