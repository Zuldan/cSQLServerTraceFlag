#requires -Version 5

Configuration SQLServerTraceFlagConfigureExample
{
    Import-DscResource -ModuleName cSQLServerTraceFlag

    Node $AllNodes.NodeName
    {
        cSQLServerTraceFlag SQLTraceFlagConfigure
        {
            Ensure            = 'Present'
            SQLInstanceName   = $Node.SQLInstanceName
            TraceFlag         = 'T834','T1117','T1118','T2371','T3226'
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

SQLServerTraceFlagConfigureExample -ConfigurationData $ConfigurationData
Set-DscLocalConfigurationManager -Path .\SQLServerTraceFlagConfigureExample -Verbose
Start-DscConfiguration -Path .\SQLServerTraceFlagConfigureExample -Verbose -Wait -Force