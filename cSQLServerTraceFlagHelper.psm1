function Get-SQLTraceFlag
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    Param
    (
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [System.Int16]
        $SQLVersion,

        [Parameter(Mandatory = $true,
                   Position = 1)]
        [System.String]           
        $SQLInstanceName
    )

    Add-Type -AssemblyName "Microsoft.SqlServer.SqlWmiManagement,Version=$SQLVersion.0.0.0,Culture=neutral,PublicKeyToken=89845dcd8080cc91"
    $SQLManagement = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $env:COMPUTERNAME
    $WMIService = $SQLManagement.Services | Where-Object -FilterScript { $PSItem.Name -eq $SQLInstanceName }
    $ParameterList = $WMIService.StartupParameters.Split(';')
    $ParameterList | Where-Object -FilterScript { $PSItem -like '-T*' } | ForEach-Object {
        $PSItem.TrimStart('-')
    }
}

function Set-SQLTraceFlag
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [System.Int16]            
        $SQLVersion,

        [Parameter(Position = 1)]
        [System.String]
        $SQLInstanceName = 'MSSQLServer',

        [Parameter(Mandatory = $true,
                   Position = 2)]
        [System.String[]]
        $TraceFlag,

        [switch]
        $RestartSQLService
    )

    Add-Type -AssemblyName "Microsoft.SqlServer.SqlWmiManagement,Version=$SQLVersion.0.0.0,Culture=neutral,PublicKeyToken=89845dcd8080cc91"
    $sqlManagement = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $env:COMPUTERNAME
    $wmiService = $sqlManagement.Services | Where-Object -FilterScript { $PSItem.Name -eq $SQLInstanceName }

    # Add '-' dash to flag
    $traceFlagList = $TraceFlag | ForEach-Object {
        "-$PSItem"
    }

    # Extract flags from startup parameters
    [System.Collections.ArrayList]$parameterList = $wmiService.StartupParameters.Split(';')

    # Removing extra flags
    foreach ($parameter in $wmiService.StartupParameters.Split(';')) {
        if ($parameter -like '-T*' -and $parameter -notin $traceFlagList) {
            $parameterList.Remove($parameter) | Out-Null
        }
    }

    # Add missing flags
    foreach ($Flag in $traceFlagList) {
        if ($Flag -notin $parameterList) {
            $parameterList.Add($Flag) | Out-Null
        }
    }

    # Merge flags back into startup parameters
    $wmiService.StartupParameters = $parameterList -join ';'
    $wmiService.Alter()

    if ($RestartSQLService)
    {
        $wmiService.Stop()
        Start-Sleep -Seconds 10
        $wmiService.Start()

        ($sqlManagement.Services | Where-Object -FilterScript { $PSItem.Name -eq 'SQLSERVERAGENT' }).Start()
    }
}

function Remove-SQLTraceFlag
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [System.Int16]            
        $SQLVersion,

        [Parameter(Position = 1)]
        [System.String]
        $SQLInstanceName = 'MSSQLServer',

        [Parameter(Mandatory = $true,
                   Position = 2)]
        [System.String[]]
        $TraceFlag,

        [switch]
        $RestartSQLService
    )

    Add-Type -AssemblyName "Microsoft.SqlServer.SqlWmiManagement,Version=$SQLVersion.0.0.0,Culture=neutral,PublicKeyToken=89845dcd8080cc91"
    $sqlManagement = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $env:COMPUTERNAME
    $wmiService = $sqlManagement.Services | Where-Object -FilterScript { $PSItem.Name -eq $SQLInstanceName }

    # Add '-' dash to flag
    $traceFlagList = $TraceFlag | ForEach-Object {
        "-$PSItem"
    }

    # Extract flags from startup parameters
    [System.Collections.ArrayList]$parameterList = $wmiService.StartupParameters.Split(';')

    # Add missing flags
    foreach ($Flag in $traceFlagList) {
        if ($Flag -in $parameterList) {
            $parameterList.Remove($Flag) | Out-Null
        }
    }

    # Merge flags back into startup parameters
    $wmiService.StartupParameters = $parameterList -join ';'
    $wmiService.Alter()

    if ($RestartSQLService)
    {
        $wmiService.Stop()
        Start-Sleep -Seconds 10
        $wmiService.Start()

        ($sqlManagement.Services | Where-Object -FilterScript { $PSItem.Name -eq 'SQLSERVERAGENT' }).Start()
    }
}