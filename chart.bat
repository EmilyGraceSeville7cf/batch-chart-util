@echo off
setlocal

call :init
set /a "init_error_level=%errorlevel%"
if %init_error_level% gtr 0 exit /b %init_error_level%

set /a "i=0"
:copy_options
    set "option=%~1"
    if defined option (
        set "args[%i%]=%option%"
        shift
        set /a "i+=1"
        goto copy_options
    )

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

    call :parse_chart_data i args data_value data_color data_char data_placeholder_char
    set /a "temp_errorlevel=%errorlevel%"
    if %temp_errorlevel% gtr 0 exit /b %temp_errorlevel%

    call :try_draw_chart data_value data_color data_char data_placeholder_char
    set /a "temp_error_level=%errorlevel%"
    if %temp_error_level% gtr 0 exit /b %temp_error_level%
    exit /b %ec_success%

:init
    set /a "ec_success=0"
    set /a "ec_bc_not_found=10"

    set "em_bc_not_found=bc utility not found to perform calculations with float numbers."

    set /a "true=0"
    set /a "false=1"

    set "prompt=>>> "

    set /a "default_width=10"
    set /a "width=%default_width%"

    set "default_char=-"
    set "default_placeholder_char= "

    call :set_esc

    set "default_color_code=%esc%[0m"

    bc --version 2> nul > nul || (
        echo %em_bc_not_found%
        exit /b %ec_bc_not_found%
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
    echo.
    echo Style options:
    echo    -if^|--item-foreground - specifies chart item foreground color
    echo    -ib^|--item-background - specifies chart item background color
    echo    -ic^|--item-char - specifies chart item char used to display it
    echo    -ipc^|--item-placeholder-char - specifies chart item placeholder char used to display it
    echo.
    echo If string is specified before some option then it is ignored.
    echo.
    echo Interactive mode commands:
    echo    q^|quit - exits
    echo    c^|clear - clears screen
    echo    h^|help - writes help
    echo.
    echo Examples:
    echo    - chart --help
    echo    - chart 1 5 3
    echo    - chart 1 5 3 --help (--help option is ignored)
    echo    - chart 1 { --item-foreground red } 5 { --item-foreground green } 3 { --item-foreground blue } --help (--help option is ignored)
exit /b %ec_success%

:version
    echo 1.0 ^(c^) 2021 year
exit /b %ec_success%

:interactive
    set "i_em_help_option_is_not_available=--help option is not available in ineractive mode. You have to use help command."
    set "i_em_version_option_is_not_available=--version option is not available in ineractive mode."
    set "i_em_interactive_option_is_not_available=--interactive option is not available in ineractive mode."

    set /a "i_last_errorlevel=0"

    :interactive_loop
        set /a "i_color_code=32"
        if not %i_last_errorlevel% == 0 set /a "i_color_code=31"
        set "i_command="
        call :clear_arguments i_args
        set /p "i_command=%esc%[%i_color_code%m%i_last_errorlevel% %prompt%%esc%[0m"
        
        if not defined i_command goto interactive_loop
        if "%i_command: =%" == "" goto interactive_loop
        
        call :to_array i_args %i_command%
        set "i_first=%i_args[0]%"
        
        set "i_comment_regex=^#.*$"
        echo %i_first%| findstr /r "%i_comment_regex%" 2> nul > nul && goto interactive_loop

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

            call :parse_chart_data i_i i_args i_data_value i_data_color i_data_char i_data_placeholder_char
            set /a "i_temp_errorlevel=%errorlevel%"
            if %i_temp_errorlevel% gtr 0 goto interactive_loop

            call :try_draw_chart i_data_value i_data_color i_data_char i_data_placeholder_char
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

:try_draw_chart
    set "tdc_data_value_array_name=%~1"
    set "tdc_data_color_array_name=%~2"
    set "tdc_data_char_array_name=%~3"
    set "tdc_data_placeholder_char_array_name=%~4"
    
    set "tdc_temp_file=tmp.txt"

    call :find_max tdc_max "%tdc_data_value_array_name%"
    
    set /a "tdc_i=0"
    :tdc_loop
        call set "tdc_value=%%%tdc_data_value_array_name%[%tdc_i%]%%"
        call set "tdc_color=%%%tdc_data_color_array_name%[%tdc_i%]%%"
        call set "tdc_char=%%%tdc_data_char_array_name%[%tdc_i%]%%"
        call set "tdc_placeholder_char=%%%tdc_data_placeholder_char_array_name%[%tdc_i%]%%"

        if not defined tdc_value exit /b %ec_success%

        echo scale=5; part=%tdc_value%/%tdc_max%*%width%; scale=0; part / 1 | bc > "%tdc_temp_file%"

        set /p tdc_item_length=<%tdc_temp_file%
        set /a "tdc_space_count=%width% - %tdc_item_length%"
        
        call :repeat_string tdc_item "%tdc_char%" "%tdc_item_length%"
        call :repeat_string tdc_space "%tdc_placeholder_char%" "%tdc_space_count%"

        echo %tdc_color%%tdc_item%%tdc_space% %tdc_value%%esc%[0m

        set /a "tdc_i+=1"
        goto tdc_loop
exit /b %ec_success%

:parse_chart_data
    set /a "pcd_ec_unexpected_value=1"

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

        set "pcd_value_regex=^[0-9][0-9]*$"
        echo %pcd_value%| findstr /r "%pcd_value_regex%" 2> nul > nul || (
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
    set /a "ssb_ec_missing_opening_curly_brace=1"
    set /a "ssb_ec_missing_closing_curly_brace=1"

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

    set "tfcc_number_regex=^[0-9][0-9]*$"
    echo %tfcc_color%| findstr /r "%tfcc_number_regex%" 2> nul > nul && (
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

    set "tbcc_number_regex=^[0-9][0-9]*$"
    echo %tbcc_color%| findstr /r "%tbcc_number_regex%" 2> nul > nul && (
        set "%tbcc_variable_name%=%tbcc_color%"
        exit /b %ec_success%
    )

    call :name_to_background_color_code "%tbcc_variable_name%" "%tbcc_color%"
    set /a "tbcc_error_level=%errorlevel%"
    if %tbcc_error_level% gtr 0 exit /b %tbcc_error_level%
exit /b %ec_success%

:name_to_foreground_color_code
    set /a "ntfcc_ec_wrong_color_name=1"

    set "ntfcc_em_wrong_color_name=Unexpected color name. Valid color name set is: black, red, green, yellow, blue, purple, cyan, white."

    set "ntfcc_variable_name=%~1"
    set "ntfcc_color_name=%~2"

    if "%ntfcc_color_name%" == "black" set /a "%ntfcc_variable_name%=30" && exit /b %ec_success%
    if "%ntfcc_color_name%" == "red" set /a "%ntfcc_variable_name%=31" && exit /b %ec_success%
    if "%ntfcc_color_name%" == "green" set /a "%ntfcc_variable_name%=32" && exit /b %ec_success%
    if "%ntfcc_color_name%" == "yellow" set /a "%ntfcc_variable_name%=33" && exit /b %ec_success%
    if "%ntfcc_color_name%" == "blue" set /a "%ntfcc_variable_name%=34" && exit /b %ec_success%
    if "%ntfcc_color_name%" == "purple" set /a "%ntfcc_variable_name%=35" && exit /b %ec_success%
    if "%ntfcc_color_name%" == "cyan" set /a "%ntfcc_variable_name%=36" && exit /b %ec_success%
    if "%ntfcc_color_name%" == "white" set /a "%ntfcc_variable_name%=37" && exit /b %ec_success%

    set /a "%ntfcc_variable_name%=0"
    echo %ntfcc_em_wrong_color_name%
exit /b %ntfcc_ec_wrong_color_name%

:name_to_background_color_code
    set /a "ntbcc_ec_wrong_color_name=1"

    set "ntbcc_em_wrong_color_name=Unexpected color name. Valid color name set is: black, red, green, yellow, blue, purple, cyan, white."

    set "ntbcc_variable_name=%~1"
    set "ntbcc_color_name=%~2"

    if "%ntbcc_color_name%" == "black" set /a "%ntbcc_variable_name%=40" && exit /b %ec_success%
    if "%ntbcc_color_name%" == "red" set /a "%ntbcc_variable_name%=41" && exit /b %ec_success%
    if "%ntbcc_color_name%" == "green" set /a "%ntbcc_variable_name%=42" && exit /b %ec_success%
    if "%ntbcc_color_name%" == "yellow" set /a "%ntbcc_variable_name%=43" && exit /b %ec_success%
    if "%ntbcc_color_name%" == "blue" set /a "%ntbcc_variable_name%=44" && exit /b %ec_success%
    if "%ntbcc_color_name%" == "purple" set /a "%ntbcc_variable_name%=45" && exit /b %ec_success%
    if "%ntbcc_color_name%" == "cyan" set /a "%ntbcc_variable_name%=46" && exit /b %ec_success%
    if "%ntbcc_color_name%" == "white" set /a "%ntbcc_variable_name%=47" && exit /b %ec_success%

    set /a "%ntbcc_variable_name%=0"
    echo %ntbcc_em_wrong_color_name%
exit /b %ntbcc_ec_wrong_color_name%

:find_max
    set "fm_variable_name=%~1"
    set "fm_array_name=%~2"

    call set /a "fm_max=%%%fm_array_name%[0]%%"

    set /a "fm_i=1"
    :fm_max_search_loop
        set "fm_item_name=%fm_array_name%[%fm_i%]"
        call set "fm_item=%%%fm_array_name%[%fm_i%]%%"

        if not defined %fm_item_name% (
            set /a "%fm_variable_name%=%fm_max%"
            exit /b %ec_success%
        )

        if %fm_item% gtr %fm_max% set /a "fm_max=%fm_item%"
        set /a "fm_i+=1"
        goto fm_max_search_loop
exit /b %ec_success%

:repeat_string
    set "rs_variable_name=%~1"
    set "rs_string=%~2"
    set "rs_count=%~3"

    set /a "rs_i=0"
    set "rs_string_result="

    :rs_repetition_loop
        if %rs_i% lss %rs_count% (
            set "rs_string_result=%rs_string_result%%rs_string%"
            set /a "rs_i+=1"
            goto rs_repetition_loop
        )

    set "%rs_variable_name%=%rs_string_result%"
exit /b %ec_success%

:set_esc
    for /f "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
        set "esc=%%b"
        exit /b 0
    )
exit /b %ec_success%
