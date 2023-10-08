*** Settings ***
Library             RPA.HTTP
Library             String
Library             RPA.Browser.Playwright
Library             RPA.Robocorp.Vault
Library             RPA.Notifier
Library             RPA.Robocorp.Storage

Task Teardown       Close Browser


*** Variables ***
${BROWSER_URL}      https://app.melcloud.com/
${TIME_API_URL}     http://worldtimeapi.org/api/timezone/Europe/Helsinki


*** Tasks ***
Minimal task
    Get the current price based on the date
    ${temperature_setting}=    Get the current temperature setting
    IF    '${temperature_setting}' == 'Esiasetus 1' and $price < ${10}
        Log To Console    Lets raise the temp
        Set the temperature    Esiasetus 2
    END
    IF    '${temperature_setting}' == 'Esiasetus 2' and $price > ${10}
        Log To Console    Lets set the temp lower
        Set the temperature    Esiasetus 1
    END


*** Keywords ***
Get the current price based on the date
    # Get date and hour via API to control time zones
    ${response}=    GET    ${TIME_API_URL}
    Request Should Be Successful    ${response}
    Status Should Be    200    ${response}
    ${json_response}=    Set Variable    ${response.json()}
    ${datetime}=    Set Variable    ${json_response}[datetime]
    ${date}=    Fetch From Left    ${datetime}    T
    ${hour}=    Fetch From Right    ${datetime}    T
    ${hour}=    Set Variable    ${hour}[0:2]
    # get the price based on the current time
    ${api_url}=    Set Variable    https://api.porssisahko.net/v1/price.json?date=${date}&hour=${hour}
    ${response}=    GET    ${api_url}
    Request Should Be Successful    ${response}
    Status Should Be    200    ${response}
    ${json_response}=    Set Variable    ${response.json()}
    ${price}=    Set Variable    ${json_response}[price]
    Log To Console    \nDate: ${date} \nHour: ${hour} \nPrice: ${price}
    Set Suite Variable    ${price}

Get the current temperature setting
    ${temperature_setting}=    Get Text Asset    Temperature Setting
    RETURN    ${temperature_setting}

Set the temperature
    [Arguments]    ${new_setting}
    Open Browser and login
    Adjust the temperature    ${new_setting}

Open Browser and login
    ${mel_secrets}=    Get Secret    melcloud
    Set Task Variable    ${mel_secrets}
    New Browser    headless=${False}
    New Page    ${BROWSER_URL}
    Click    //a[contains(text(),'Suomi')]
    Fill Text    //input[@id='login-email']    ${mel_secrets}[username]
    Fill Secret    //input[@id='login-pwd']    $mel_secrets['password']
    Click    //a[@id='login-button']
    Click    //span[contains(text(),'Kellari')]

Adjust the temperature
    [Arguments]    ${new_setting}
    Sleep    3
    # Wait until the device data has been loaded.
    ${ele}=    Get Element Count    //*[contains(text(), 'Odotetaan')]
    WHILE    $ele > ${0}
        Sleep    1
        ${ele}=    Get Element Count    //*[contains(text(), 'Odotetaan')]
    END
    Click    //div[text() = '${new_setting}']
    Sleep    3
    Set Text Asset    Temperature Setting    ${new_setting}
    Notify about change    ${new_setting}

Notify about change
    [Arguments]    ${new_setting}
    ${gmail_secrets}=    Get Secret    Gmail
    Notify Gmail
    ...    message=Temperature has been adjusted. \n\nNew value: ${new_setting}. \nCurrent price: ${price} c/kWh.
    ...    to=${mel_secrets}[recipients]
    ...    username=${gmail_secrets}[email_address]
    ...    password=${gmail_secrets}[app_password]
