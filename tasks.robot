*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    #auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.RobotLogListener
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Tasks ***
Robot de Ordenes
    ${secret}=    Get Secret    url
    Log    ${secret}[urlbot]
    ${csv_file_path}=    Solicita CSV
    #Descarga csv
    #Descarga csv subido    ${csv_file_path}
    Abre website    ${secret}
    Click ok
    Completar usando CSV    ${csv_file_path}
    Log    Done.

*** Keywords ***
Solicita csv
    Add heading    Subir archivo
    Add file input    label=subir archivo    name=fileupload    file_type= CSV (*.csv)    destination=${CURDIR}${/}output
    ${response}=    Run dialog
    [Return]    ${response.fileupload}[0]
#Descarga csv
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
#Descarga csv subido
    #[Arguments]    ${csv_file_path}
    #Download    ${csv_file_path}    overwrite=True

Abre website
    [Arguments]    ${secret}
    #Open Available Browser    https://robotsparebinindustries.com/#/robot-order    maximized=True
    Open Available Browser    ${secret}[urlbot]    maximized=True

click ok
    Click Button    OK

Completar una orden
    [Arguments]    ${orden}
    Select From List By Value    name:head    ${orden}[Head]
    #Select From List By Value    name:head    2
    #usar label para encontrar el campo en el codigo web
    Select Radio Button    body    ${orden}[Body]
    #capturar xpath luego de probar varias opciones, name y id cambian
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${orden}[Legs]
    Input Text    id:address    ${orden}[Address]
    #Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    2
    #Input Text    id:address    Avenida Uruguay
    #Click Button    Preview
    #Click Button When Visible    order
    Click Button    Preview
    sleep    1s

Your Keyword That You Want To Retry
    Click Button    order

Guardar PDF
    [Arguments]    ${orden}
    Wait Until Element Is Visible    id:receipt
    ${orden_HTML}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${orden_HTML}    ${OUTPUT_DIR}${/}ordenes${orden}[Order number].pdf
    [Return]    ${OUTPUT_DIR}${/}ordenes${orden}[Order number].pdf

 Captura
    [Arguments]    ${orden}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}orden${orden}[Order number].png
    [Return]    ${OUTPUT_DIR}${/}orden${orden}[Order number].png

Screenshot a PDF
    [Arguments]    ${captura}    ${pdf}    ${orden}    ${captura_list}
    Open Pdf    ${pdf}
    Add Files To Pdf    ${captura_list}    ${pdf}    true
    #Close Pdf    ${pdf}

Agregar a ZIP
    Archive Folder With Zip    ${OUTPUT_DIR}    ${OUTPUT_DIR}${/}Robot.zip    include=*.pdf

Completar usando CSV
    [Arguments]    ${csv_file_path}
    ${ordenes} =    Read table from CSV    ${csv_file_path}    header=true
    FOR    ${orden}    IN    @{ordenes}
        Completar una orden    ${orden}
        Wait Until Keyword Succeeds    10x    1s    Enviar    ${orden}
        Log    ${orden}
        #Wait Until Keyword Succeeds    10x    1s    Revisar robot
    END
    Agregar a ZIP

Enviar
    [Arguments]    ${orden}
    ${captura}=    Captura    ${orden}
    ${captura_list}=    Create List    ${captura}
    Click Button When Visible    order
    ${pdf}=    Guardar PDF    ${orden}
    ${pdf_list}=    Create List    ${pdf}
    Log    ${pdf}
    Log    ${captura}
    Screenshot a PDF    ${captura}    ${pdf}    ${orden}    ${captura_list}
    Click Button    order-another
    #Mute Run On Failure    Page Should Contain Element
    #Page Should Contain Element    id:receipt    order
    Click Button    OK
    Sleep    1s
