*** Settings ***
Documentation     Test suite to check Selenium commands against Chrome browser and Android app, both running in separate containers
Library           SeleniumLibrary
Library           AppiumLibrary

*** Keywords ***
Run Against Desktop Browser
    Set Library Search Order    SeleniumLibrary

Run Against Mobile App
    Set Library Search Order    AppiumLibrary

*** Test Cases ***
Testing Browser In Container 1
    [Documentation]    This test opens Google Chrome Browser in container 1 and access Google 
    Run Against Desktop Browser
    Open Browser    https://www.google.com/    Chrome    A    http://${WEB_CONTAINER_1}:4444/wd/hub
    Wait Until Element Is Visible    xpath=//img[@alt='Google']
    Page Should Not Contain Element    xpath=//*[text()='Facebook Lite']
    Page Should Not Contain Element    xpath=//*[@text='Hello world!']
    Capture Page Screenshot
    [Teardown]    Close Browser

Testing Browser In Container 2
    [Documentation]    This test opens Google Chrome Browser in container 2 and access Facebook
    Run Against Desktop Browser
    Open Browser    https://www.facebook.com/    Chrome    A    http://${WEB_CONTAINER_2}:4444/wd/hub
    Wait Until Element Is Visible    xpath=//*[text()='Facebook Lite']
    Page Should Not Contain Element    xpath=//img[@alt='Google']
    Page Should Not Contain Element    xpath=//*[@text='Hello world!']
    Capture Page Screenshot
    [Teardown]    Close Browser

Testing Mobile App In Android Container
    [Documentation]    This test opens Hello World app in Android container
    Run Against Mobile App
    Open Application    http://${ANDROID_CONTAINER}:4723/wd/hub    platformName=Android    deviceName=${ANDROID_DEVICE}    app=${APK_FOLDER}${APK_NAME}
    Wait Until Element Is Visible    xpath=//*[@text='Hello world!']
    Page Should Not Contain Element    xpath=//img[@alt='Google']
    Page Should Not Contain Element    xpath=//*[@text='Facebook Lite']
    Capture Page Screenshot
