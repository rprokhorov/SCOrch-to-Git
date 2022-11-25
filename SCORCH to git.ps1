Start-Transcript -Path "C:\Logs\SCOrch. Export PowerShell scripts to git.log"
function Invoke-SQLQuery($Query)
{
    $SQLServer = "scorch.contoso.com"
    $SQLDBName = "Orchestrator"
    $SqlQuery = $query
    $ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True"
    $Connection = New-Object System.Data.SqlClient.SqlConnection
    $Connection.ConnectionString = $ConnectionString
    $Connection.Open()
    $Command = $Connection.CreateCommand()
    $Command.CommandText = $sqlquery
    $Result = $Command.ExecuteReader()
    $Table = new-object "System.Data.DataTable"
    $Table.Load($Result)
    $Connection.Close()
    return $Table
}

cd '\\servername.contoso.com\Scripts\system-center-orchestrator'

$query = "
/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [OBJECTS].[UniqueID]
      ,[ScriptType]
      ,[ScriptBody]
	  ,[OBJECTS].Name
	  ,[Orchestrator].[Microsoft.SystemCenter.Orchestrator.Internal].[Resources].Name
	  ,Path
	  ,PathFragment
      --,[Dependencies]
      --,[Namespaces]
      --,[ExecutionData]
      --,[PublishedData]
  FROM [RUNDOTNETSCRIPT]
  join [OBJECTS] on [OBJECTS].UniqueID = [RUNDOTNETSCRIPT].UniqueID
  join [Orchestrator].[Microsoft.SystemCenter.Orchestrator.Internal].[Resources] on [Orchestrator].[Microsoft.SystemCenter.Orchestrator.Internal].[Resources].UniqueId = [OBJECTS].ParentID
  where Deleted = 0
"
try{
    $SQLresult = Invoke-SQLQuery -Query $query
    $counter = 0
    foreach ($Item  in $SQLresult)
    {
        $counter++
        Write-Host $counter . ("$(get-location)$($Item.Path)\$($Item.Name).ps1").Length "$(get-location)$($Item.Path)\$($Item.Name).ps1"
        New-Item -ItemType Directory -Name ($Item.Path -replace ':' -replace '\?')  -ErrorAction SilentlyContinue
    
        $Item.ScriptBody | Out-File "$(get-location)$($Item.Path -replace ':' -replace  '\?')\$($Item.Name -replace ':' -replace '\?').ps1" -Force
    }
    git add --all
    git commit -m "$(get-date -Format 'yyyy-MM-dd'). Scheduled update"
    git push -u origin master

}
catch
{
    throw $Error[0]
}
finally
{
    Stop-Transcript 
}