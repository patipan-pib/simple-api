*** Settings ***
Library           RequestsLibrary


*** Keywords ***

Get Calculation JSON
    [Arguments]    ${num1}    ${num2}
    ${resp}=     GET    http://127.0.0.1:5000/calculate/${num1}/${num2}

    # Verify the status code is 200 (OK)
    Should Be Equal    ${resp.status_code}    ${200}

    # Get the response content as a JSON object
    [return]    ${resp.json()}


*** Test Cases ***
Test Calculate Numbers 4 and 2 (ฺBefore Using Keywords)

    ${resp}=     GET    http://127.0.0.1:5000/calculate/4/2

    # Verify the status code is 200 (OK)
    Should Be Equal    ${resp.status_code}    ${200}

    # Get the response content as a JSON object
    ${json_resp}=    Set Variable  ${resp.json()}

    # Verify the response of plus operation
    Should Be Equal    ${json_resp['plus']}    ${6}

    # Verify the response of minus operation
    Should Be Equal    ${json_resp['minus']}    ${2}

    # Verify the response of multiply operation
    Should Be Equal    ${json_resp['multiply']}    ${8}

    # Verify the response of divide operation
    Should Be Equal    ${json_resp['divide']}    ${2}


Test Calculate Numbers 8.4 and 4 (ฺBefore Using Keywords)

    ${resp}=     GET    http://127.0.0.1:5000/calculate/8.4/4

    # Verify the status code is 200 (OK)
    Should Be Equal    ${resp.status_code}    ${200}

    # Get the response content as a JSON object
    ${json_resp}=    Set Variable  ${resp.json()}

    # Verify the response of plus operation
    Should Be Equal    ${json_resp['plus']}    ${12.4}

    # Verify the response of minus operation
    Should Be Equal    ${json_resp['minus']}    ${4.4}

    # Verify the response of multiply operation
    Should Be Equal    ${json_resp['multiply']}    ${33.6}

    # Verify the response of divide operation
    Should Be Equal    ${json_resp['divide']}    ${2.1}


Test Calculate Numbers 4 and 2

    ${json_resp}=    Get Calculation JSON    ${4}    ${2}

    # Verify the response of plus operation
    Should Be Equal    ${json_resp['plus']}    ${6}

    # Verify the response of minus operation
    Should Be Equal    ${json_resp['minus']}    ${2}

    # Verify the response of multiply operation
    Should Be Equal    ${json_resp['multiply']}    ${8}

    # Verify the response of divide operation
    Should Be Equal    ${json_resp['divide']}    ${2}


Test Calculate Numbers 8.4 and 4

    ${json_resp}=    Get Calculation JSON    ${8.4}    ${4}

    # Verify the response of plus operation
    Should Be Equal    ${json_resp['plus']}    ${12.4}

    # Verify the response of minus operation
    Should Be Equal    ${json_resp['minus']}    ${4.4}

    # Verify the response of multiply operation
    Should Be Equal    ${json_resp['multiply']}    ${33.6}

    # Verify the response of divide operation
    Should Be Equal    ${json_resp['divide']}    ${2.1}
