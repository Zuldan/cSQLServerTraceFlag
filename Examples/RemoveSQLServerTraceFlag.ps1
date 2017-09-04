#requires -Version 5

Configuration SQLServerTraceFlagRemoveExample
{
    Import-DscResource -ModuleName cSQLServerTraceFlag

    Node $AllNodes.NodeName
    {
        cSQLServerTraceFlag SQLTraceFlagRemove
        {
            Ensure            = 'Absent'
            SQLInstanceName   = $Node.SQLInstanceName
            TraceFlag         = 'T1118','T2371'
            RestartSQLService = $True
        }
    }
}

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true
        }
        @{
            NodeName = "SCDB.contoso.com"
            SQLInstanceName = 'MSSQLSERVER'
        }
    )
}

SQLServerTraceFlagRemoveExample -ConfigurationData $ConfigurationData
Set-DscLocalConfigurationManager -Path .\SQLServerTraceFlagRemoveExample -Verbose
Start-DscConfiguration -Path .\SQLServerTraceFlagRemoveExample -Verbose -Wait -Force
