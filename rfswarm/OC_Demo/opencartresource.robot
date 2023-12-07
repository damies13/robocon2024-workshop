*** Keywords ***
Open Store
	[Documentation] 	TC01 - Open Store
	Open Browser    undefined    ${BROWSER}
	Go To 	${appurl}
	Click Element    //h1

Navigate to Section
	[Documentation] 	TC01 - Navigate to Monitors
	[arguments]		${section}
	Click Link    //a[@href="${appurl}/component/${section}"]
