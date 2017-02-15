Option Explicit
Dim adoCommand, adoConnection, strBase, strFilter, strAttributes
Dim objRootDSE, strDNSDomain, strQuery, adoRecordset, strName, strCN, strTele
' Setup ADO objects.
Set adoCommand = CreateObject("ADODB.Command")
Set adoConnection = CreateObject("ADODB.Connection")
adoConnection.Provider = "ADsDSOObject"
adoConnection.Open "Active Directory Provider"
adoCommand.ActiveConnection = adoConnection
' Search entire Active Directory domain.
Set objRootDSE = GetObject("LDAP://RootDSE")
strDNSDomain = objRootDSE.Get("defaultNamingContext")
strBase = "<LDAP://" & strDNSDomain & ">"
' Filter on user objects.
strFilter = "(objectCategory=computer)"
' Comma delimited list of attribute values to retrieve.
strAttributes = "name"
' Construct the LDAP syntax query.
strQuery = strBase & ";" & strFilter & ";" & strAttributes & ";subtree"
adoCommand.CommandText = strQuery
adoCommand.Properties("Page Size") = 100
adoCommand.Properties("Timeout") = 30
adoCommand.Properties("Cache Results") = False
' Run the query.
Set adoRecordset = adoCommand.Execute
' Enumerate the resulting recordset.
Do Until adoRecordset.EOF
    ' Retrieve values and display.
    Wscript.Echo adoRecordset.Fields("name").Value
    checkServices(adoRecordset.Fields("name").Value)
    ' Move to the next record in the recordset.
    adoRecordset.MoveNext
Loop
' Clean up.
adoRecordset.Close
adoConnection.Close

Sub checkServices( strServer )
on error resume next
dim strComputer, strStartName, objWMIService, colListOfServices, objService
strComputer = strServer
strStartName = "AD\\99903484" 'The double backslash is required to escape

Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
Set colListOfServices = objWMIService.ExecQuery("Select * from Win32_Service where StartName='" & strStartName & "'")
For Each objService in colListOfServices
Wscript.Echo vbTab & objService.DisplayName & VbTab & objService.State & vbtab & objService.StartName

next	
End Sub

wscript.echo "DONE"