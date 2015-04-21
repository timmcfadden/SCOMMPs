param($sourceId,$managedEntityId)

#Start by setting up API object and creating a discovery data object.
#Discovery data object requires the MPElement and Target/ID variables.  The first argument in the method is always 0.
$api = New-Object -comObject 'MOM.ScriptAPI'
$discoveryData = $api.CreateDiscoveryData(0, $sourceId, $managedEntityId)

Import-Module -Name "OperationsManager" 
New-SCManagementGroupConnection -ComputerName:"localhost";

$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server = xDB01; Database = CMDB; Integrated Security = True"

$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "select ServerName from ServerList where MonitorGroup = 'Team 3'"
$SqlCmd.Connection = $SqlConnection

$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd

$myDataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($myDataSet)

$SqlConnection.Close()

$Servers = $myDataSet.Tables[0]

#Get the top level folder and then enumerate through each subfolder.

$groupInstance = $discoveryData.CreateClassInstance("$MPElement[Name='SQLBasedGroupDemo.Team2Group']$")

#$myArray = "xSP01.scom2k12.com","xDV01.scom2k12.com"

foreach ($element in $myDataSet.Tables[0].Rows.ServerName)
{
	$class_wincomputer = Get-SCOMClass -name System.Computer 
	$mmcomputerobject = get-scommonitoringobject -Class $class_wincomputer | where{$_.displayname -eq $element} 

		if($mmcomputerobject) 
		{ 
			$serverInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Windows!Microsoft.Windows.Computer']$")
			$serverInstance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$", $element)

			$RelationshipInstance = $discoveryData.CreateRelationshipInstance("$MPElement[Name='SQLBasedGroupDemo.Team2GroupContainsWindowsComputers']$")
			$RelationshipInstance.Source = $groupInstance
			$RelationshipInstance.Target = $serverInstance
			$discoveryData.AddInstance($RelationshipInstance)
		}
		elseif(!$mmcomputerobject)
		{
			Write-Eventlog -Logname 'Windows PowerShell' -Source PowerShell -EventID 600 -EntryType Error -Message "$element Not Found"
		}
}


#Return the discovery data.
$discoveryData