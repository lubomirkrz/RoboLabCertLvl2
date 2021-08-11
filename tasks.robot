*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...             Saves the order HTML receipt as a PDF file.
...             Saves the screenshot of the ordered robot.
...             Embeds the screenshot of the robot to the PDF receipt.
...             Creates ZIP archive of the receipts and the images.
...             Built by Lubomir Krzeminski
Library         RPA.Browser.Selenium
Library         RPA.HTTP
Library         RPA.Tables
Library         RPA.PDF  
Library         RPA.Archive
Library         Dialogs
Library         RPA.Robocloud.Secrets
Library         OperatingSystem
Test Teardown    Close Application



# +
*** Keywords ***

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window
    ${pop up name}=  Set Variable  //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Wait Until Page Contains Element    ${pop up name}

Get orders
    ${secret}=  Get Secret    LinkToOrderFile
    Download    ${secret}[Orders]  overwrite=True
    ${openedTable}=  Read Table From Csv  orders.csv  header=False  
    [Return]   ${openedTable}
    
Close the annoying modal
    Click Button    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    

Fill the form
    [Arguments]  ${csvRow}
    Log  ${csvRow}   
    Select From List By Index    id=head  ${csvRow}[Head]   
    Select Radio Button    body  ${csvRow}[Body]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${csvRow}[Legs]
    Input Text    //input[@placeholder="Shipping address"]    ${csvRow}[Address]
    
Preview the robot
    Click Button    id=preview
    
Submit the order
    Click Button    id=order
    Element Should Be Visible    id=order-another
    
Store the receipt as a PDF file
    [Arguments]  ${csvRow}    
    Wait Until Element Is Visible    id:receipt
    ${receiptPDF}=    Get Element Attribute    id:receipt   outerHTML
    ${pdfPath} =  Set Variable  output${/}temp${/}receipt${csvRow}.pdf
    Html To Pdf    ${receiptPDF}  ${pdfPath}  
    [Return]  ${pdfPath}  

Take a screenshot of the robot
    [Arguments]  ${csvRow}
    Wait Until Element Is Visible    id:receipt
    ${screenshotPath}  Set Variable  output${/}temp${/}receiptImage${csvRow}.jpg
    Screenshot    id:robot-preview   ${screenshotPath}
    [Return]  ${screenshotPath}

Embed the robot screenshot to the receipt PDF file
     [Arguments]  ${screenshotPath}  ${pdfPath}
     Wait Until Created    ${pdfPath}
     Wait Until Created    ${screenshotPath}
     ${screenList}=  Create List  ${pdfPath}  ${screenshotPath}:align=center
     Add Files To Pdf  ${screenList}  ${pdfPath} 
     

Go to order another robot
    Wait Until Page Contains Element    id=order-another
    Click Button    id=order-another

Create a ZIP file of the receipts
    Archive Folder With Zip  output${/}temp  output${/}receipts.zip  include=*.pdf

Close Application
    Close All Browsers
# -

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    @{orders}=    Get orders
    FOR    ${row}    IN    @{orders}
         Log  ${row}
         Close the annoying modal
         Fill the form    ${row}
         Preview the robot
         Wait Until Keyword Succeeds  5 times  3s  Submit the order
         ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
         ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
         Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
         Go to order another robot
    END
    Create a ZIP file of the receipts
