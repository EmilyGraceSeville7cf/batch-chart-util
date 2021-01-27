set /a "fm_ec_no_array_provided=80"

set "fm_em_no_array_provided=No array provided to calculate max item."

set "fm_variable_name=%~1"
set "fm_array_name=%~2"

set "fm_item_name=%fm_array_name%[0]"

if not defined %fm_item_name% (
    echo %fm_em_no_array_provided%
    exit /b %fm_ec_no_array_provided%
)

call set /a "fm_max=%%%fm_item_name%%%"

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
