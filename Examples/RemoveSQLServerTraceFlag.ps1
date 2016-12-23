#requires -Version 5

Configuration SQLServerTraceFlagRemoveExample
{
    Import-DscResource -ModuleName cSQLServerTraceFlag

    Node $AllNodes.NodeName
    {
        cSQLServerTraceFlag SQLTraceFlagRemove
        {
            Ensure            = 'Absent'
            SQLVersion        = $Node.SQLVersion
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
            SQLVersion = 13
            SQLInstanceName = 'MSSQLSERVER'
        }
    )
}

SQLServerTraceFlagRemoveExample -ConfigurationData $ConfigurationData
Set-DscLocalConfigurationManager -Path .\SQLServerTraceFlagRemoveExample -Verbose
Start-DscConfiguration -Path .\SQLServerTraceFlagRemoveExample -Verbose -Wait -Force
