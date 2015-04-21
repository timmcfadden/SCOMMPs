 Dim SourceId
    Dim objConnection
    Dim oRS
    Dim sConnectString
    Dim ManagedEntityID
    Dim oAPI
    Dim oDiscoveryData

    SourceId                = WScript.Arguments(0)
    ManagedEntityId         = WScript.Arguments(1)

    Set oAPI                = CreateObject("MOM.ScriptAPI")
    Set oDiscoveryData      = oAPI.CreateDiscoveryData(0,SourceId,ManagedEntityId)

    sConnectString = "Driver={SQL Server}; Server=xDB01; Database=CMDB;"

    Set objConnection = CreateObject("ADODB.Connection")
    objConnection.Open sConnectString

    Set oRS = CreateObject("ADODB.Recordset")
    oRS.Open "select ServerName from ServerList where MonitorGroup = 'Team 1'", objConnection

    Set groupInstance = oDiscoveryData.CreateClassInstance("$MPElement[Name='SQLBasedGroupDemo.Team1Group']$")

    While Not oRS.EOF

    Set serverInstance = oDiscoveryData.CreateClassInstance("$MPElement[Name='Windows!Microsoft.Windows.Computer']$")
    serverInstance.AddProperty "$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$",oRS.Fields("ServerName")
    Set relationshipInstance = oDiscoveryData.CreateRelationshipInstance("$MPElement[Name='SQLBasedGroupDemo.Team1GroupContainsWindowsComputers']$")
    relationshipInstance.Source = groupInstance
    relationshipInstance.Target = serverInstance
    oDiscoveryData.AddInstance relationshipInstance
    oRS.MoveNext

    Wend

    objConnection.Close

    Call oAPI.Return(oDiscoveryData)