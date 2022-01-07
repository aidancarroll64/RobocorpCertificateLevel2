*** Settings ***
Documentation     Build and order robots from RobotSpareBin website.
...               Save the order receipt as a PDF file.
...               Save a screenshot of the ordered robot.
...               Embed the screenshot of the robot to the PDF receipt.
...               Create a ZIP archive of the receipts and images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.Tables
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Desktop
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault
Library           Collections
Library           RPA.FileSystem

*** Variables ***
${URL}=           https://robotsparebinindustries.com/#/robot-order
${GLOBAL_RETRY_AMOUNT}=    5x
${GLOBAL_RETRY_INTERVAL}=    1s

*** Tasks ***
Build and order robot on RSB website.
    Open RSB robot order website
    ${result}=    Get username
    ${order_numbers}=    Download and read excel file
    FOR    ${order_number}    IN    @{order_numbers}
        Close pop-up
        Fill data for one order    ${order_number}
        Preview robot
        Submit order and keep checking until successful
        ${pdf}=    Store receipt in PDF    ${order_number}
        ${screenshot}=    Take screenshot of robot    ${order_number}
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order another robot
    END
    Create ZIP file of all PDFs
    [Teardown]    Close browser and finish process
    Success dialog    ${result}

*** Keywords ***
Get secret data
    # Function only works when ran locally.
    # If ran through Control Room comment out code in "Open RSB robot order website" & "Download and read excel file" functions
    ${secret}=    Get Secret    vault_data
    [Return]    ${secret}

Open RSB robot order website
    # When ran locally this code will work
    ${secret}=    Get secret data
    Open Available Browser    ${secret}[url]
    # When ran through Control Room this will work
    # Open Available Browser    ${URL}

Get username
    Add heading    Please enter username to continue
    Add text input    username    label=Username
    ${result}=    Run dialog
    [Return]    ${result}

Close pop-up
    Click Button    OK

Download and read excel file
    # When ran locally this code will work
    ${secret}=    Get secret data
    Download    ${secret}[csv_file_url]    overwrite=True
    # When ran through Control Room this will work
    # Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    Read table from CSV    orders.csv
    ${order_numbers}=    Read table from CSV    orders.csv    header=True
    [Return]    ${order_numbers}

Fill data for one order
    [Arguments]    ${order_number}
    Select From List By Value    head    ${order_number}[Head]
    Click Button    id:id-body-${order_number}[Body]
    Input Text    css:input.form-control    ${order_number}[Legs]
    Input Text    address    ${order_number}[Address]

Preview robot
    Click Button    preview

Submit order and keep checking until successful
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Submit robot order

 Submit robot order
    Click Button    order
    Wait Until Page Contains Element    id:receipt
    Log To Console    Submit successful

Store receipt in PDF
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts/robot_receipt_${order_number}[Order number].pdf
    [Return]    ${OUTPUT_DIR}${/}receipts/robot_receipt_${order_number}[Order number].pdf

Take screenshot of robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview    ${OUTPUT_DIR}${/}screenshots/robot_screenshot_${order_number}[Order number].png
    [Return]    ${OUTPUT_DIR}${/}screenshots/robot_screenshot_${order_number}[Order number].png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${screenshot_file}=    Create List    ${screenshot}
    Add Files To Pdf    ${screenshot_file}    ${pdf}    TRUE

Order another robot
    Click Button    order-another

Create ZIP file of all PDFs
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}myreceipts.zip    include=*.pdf

Success dialog
    [Arguments]    ${result}
    Add icon    Success
    Add heading    Congratulations ${result}[username]! The orders have been processed!
    Run dialog

 Close browser and finish process
    Close Browser
