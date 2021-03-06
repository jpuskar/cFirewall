<#
Author  : Serge Nikalaichyk (https://www.linkedin.com/in/nikalaichyk)
Version : 1.0.1
Date    : 2015-10-15
#>


function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Allow', 'Block')]
        [String]
        $Action,

        [Parameter(Mandatory = $false)]
        [String]
        $Description,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Inbound', 'Outbound')]
        [String]
        $Direction,

        [Parameter(Mandatory = $false)]
        [Boolean]
        $Enabled,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Absent', 'Present')]
        [String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $false)]
        [String]
        $Group,

        [Parameter(Mandatory = $false)]
        [String[]]
        $LocalAddress,

        [Parameter(Mandatory = $false)]
        [String[]]
        $LocalPort,

        [Parameter(Mandatory = $false)]
        [ValidateScript({$_ | Where-Object {$_ -in @('All', 'Domain', 'Private', 'Public')}})]
        [String[]]
        $Profile,

        [Parameter(Mandatory = $false)]
        [String]
        $Program,

        [Parameter(Mandatory = $false)]
        [ValidateScript({($_ -in [System.Net.Sockets.ProtocolType].GetEnumNames()) -or ($_ -in @('*', 'Any', 'All'))})]
        [String]
        $Protocol,

        [Parameter(Mandatory = $false)]
        [String[]]
        $RemoteAddress,

        [Parameter(Mandatory = $false)]
        [String[]]
        $RemotePort,

        [Parameter(Mandatory = $false)]
        [String]
        $Service
    )

    $PSBoundParameters.GetEnumerator() |
    ForEach-Object -Begin {
        $Width = $PSBoundParameters.Keys.Length | Sort-Object -Descending | Select-Object -First 1
    } -Process {
        "{0,-$($Width)} : '{1}'" -f $_.Key, ($_.Value -join ', ') |
        Write-Verbose
    }

    $PSBoundParameters.Remove('Ensure')

    $MatchingRules = @(Get-cFirewallRule @PSBoundParameters -ErrorAction Stop)

    if ($MatchingRules.Count -eq 0)
    {
        Write-Verbose -Message 'A matching firewall rule was not found.'

        $EnsureResult = 'Absent'
    }
    elseif ($MatchingRules.Count -eq 1)
    {
        Write-Verbose -Message 'A matching firewall rule was found.'

        $EnsureResult = 'Present'
    }
    else
    {
        Write-Verbose -Message "Multiple matching firewall rules were found (Count: $($MatchingRules.Count))."

        $EnsureResult = 'Present'
    }

    $ReturnValue = @{
            Name          = $Name
            Action        = $(if ($MatchingRules) {$MatchingRules[0].Action})
            Description   = $(if ($MatchingRules) {$MatchingRules[0].Description})
            Direction     = $(if ($MatchingRules) {$MatchingRules[0].Direction})
            Enabled       = [Boolean]$(if ($MatchingRules) {$MatchingRules[0].Enabled})
            Ensure        = $EnsureResult
            Group         = $(if ($MatchingRules) {$MatchingRules[0].Group})
            LocalAddress  = [String[]]@($(if ($MatchingRules) {$MatchingRules[0].LocalAddress -split ','}))
            LocalPort     = [String[]]@($(if ($MatchingRules) {$MatchingRules[0].LocalPort -split ','}))
            Profile       = [String[]]@($(if ($MatchingRules) {$MatchingRules[0].Profile.ToString() -replace '\s' -split ','}))
            Program       = $(if ($MatchingRules) {$MatchingRules[0].Program})
            Protocol      = $(if ($MatchingRules) {$MatchingRules[0].Protocol})
            RemoteAddress = [String[]]@($(if ($MatchingRules) {$MatchingRules[0].RemoteAddress -split ','}))
            RemotePort    = [String[]]@($(if ($MatchingRules) {$MatchingRules[0].RemotePort -split ','}))
            Service       = $(if ($MatchingRules) {$MatchingRules[0].Service})
        }

    return $ReturnValue

}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Allow', 'Block')]
        [String]
        $Action,

        [Parameter(Mandatory = $false)]
        [String]
        $Description,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Inbound', 'Outbound')]
        [String]
        $Direction,

        [Parameter(Mandatory = $false)]
        [Boolean]
        $Enabled,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Absent', 'Present')]
        [String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $false)]
        [String]
        $Group,

        [Parameter(Mandatory = $false)]
        [String[]]
        $LocalAddress,

        [Parameter(Mandatory = $false)]
        [String[]]
        $LocalPort,

        [Parameter(Mandatory = $false)]
        [ValidateScript({$_ | Where-Object {$_ -in @('All', 'Domain', 'Private', 'Public')}})]
        [String[]]
        $Profile,

        [Parameter(Mandatory = $false)]
        [String]
        $Program,

        [Parameter(Mandatory = $false)]
        [ValidateScript({($_ -in [System.Net.Sockets.ProtocolType].GetEnumNames()) -or ($_ -in @('*', 'Any', 'All'))})]
        [String]
        $Protocol,

        [Parameter(Mandatory = $false)]
        [String[]]
        $RemoteAddress,

        [Parameter(Mandatory = $false)]
        [String[]]
        $RemotePort,

        [Parameter(Mandatory = $false)]
        [String]
        $Service
    )

    $TargetResource = Get-TargetResource @PSBoundParameters

    $InDesiredState = $Ensure -eq $TargetResource.Ensure

    if ($InDesiredState -eq $true)
    {
        Write-Verbose -Message 'The target resource is already in the desired state. No action is required.'
    }
    else
    {
        Write-Verbose -Message 'The target resource is not in the desired state.'
    }

    return $InDesiredState

}


function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Allow', 'Block')]
        [String]
        $Action,

        [Parameter(Mandatory = $false)]
        [String]
        $Description,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Inbound', 'Outbound')]
        [String]
        $Direction,

        [Parameter(Mandatory = $false)]
        [Boolean]
        $Enabled,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Absent', 'Present')]
        [String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $false)]
        [String]
        $Group,

        [Parameter(Mandatory = $false)]
        [String[]]
        $LocalAddress,

        [Parameter(Mandatory = $false)]
        [String[]]
        $LocalPort,

        [Parameter(Mandatory = $false)]
        [ValidateScript({$_ | Where-Object {$_ -in @('All', 'Domain', 'Private', 'Public')}})]
        [String[]]
        $Profile,

        [Parameter(Mandatory = $false)]
        [String]
        $Program,

        [Parameter(Mandatory = $false)]
        [ValidateScript({($_ -in [System.Net.Sockets.ProtocolType].GetEnumNames()) -or ($_ -in @('*', 'Any', 'All'))})]
        [String]
        $Protocol,

        [Parameter(Mandatory = $false)]
        [String[]]
        $RemoteAddress,

        [Parameter(Mandatory = $false)]
        [String[]]
        $RemotePort,

        [Parameter(Mandatory = $false)]
        [String]
        $Service
    )

    if (-not $PSCmdlet.ShouldProcess($Name))
    {
        return
    }

    if ($Ensure -eq 'Absent')
    {
        $PSBoundParameters.Remove('Ensure')

        Remove-cFirewallRule @PSBoundParameters -Confirm:$false
    }
    else
    {
        $PSBoundParameters.Remove('Ensure')

        New-cFirewallRule @PSBoundParameters
    }

}


#region Helper Functions

function Initialize-cFirewallRuleType
{
    $TypeDefinition = @'
using System;

namespace FwRule
{
    public enum Action
    {
        Block = 0,
        Allow = 1
    }

    public enum Direction
    {
        Inbound = 1,
        Outbound = 2
    }

    [FlagsAttribute]
    public enum Profiles
    {
        Domain = 1,
        Private = 2,
        Public = 4,
        All = Domain | Private | Public | 2147483647
    }
}
'@

    if (-not ('FwRule.Action' -as [Type]))
    {
        Add-Type -TypeDefinition $TypeDefinition
    }

    <#
    .NOTES
        Each time you change a property of a rule, Windows Firewall commits the rule and verifies it for correctness.
        As a result, when you edit a rule, you must perform the steps in a specific order.
        For example, the Protocol property must be set before the LocalPorts or RemotePorts properties or an error will be returned.
    .LINK
        https://msdn.microsoft.com/en-us/library/windows/desktop/aa365344%28v=vs.85%29.aspx
    #>

    if (-not (Get-Variable -Name FwRulePropertyData -Scope Script -ErrorAction Ignore))
    {
        New-Variable -Name FwRulePropertyData -Force -Option ReadOnly -Scope Script -Value @(
            [PSCustomObject]@{Order = 0;  ParameterName = 'Name';          PropertyName = 'Name';            PropertyType = [String]}
            [PSCustomObject]@{Order = 1;  ParameterName = 'Description';   PropertyName = 'Description';     PropertyType = [String]}
            [PSCustomObject]@{Order = 2;  ParameterName = 'Program';       PropertyName = 'ApplicationName'; PropertyType = [String]}
            [PSCustomObject]@{Order = 3;  ParameterName = 'Service';       PropertyName = 'ServiceName';     PropertyType = [String]}
            [PSCustomObject]@{Order = 4;  ParameterName = 'Protocol';      PropertyName = 'Protocol';        PropertyType = [System.Net.Sockets.ProtocolType]}
            [PSCustomObject]@{Order = 5;  ParameterName = 'LocalPort';     PropertyName = 'LocalPorts';      PropertyType = [String]}
            [PSCustomObject]@{Order = 6;  ParameterName = 'RemotePort';    PropertyName = 'RemotePorts';     PropertyType = [String]}
            [PSCustomObject]@{Order = 7;  ParameterName = 'LocalAddress';  PropertyName = 'LocalAddresses';  PropertyType = [String]}
            [PSCustomObject]@{Order = 8;  ParameterName = 'RemoteAddress'; PropertyName = 'RemoteAddresses'; PropertyType = [String]}
            [PSCustomObject]@{Order = 9;  ParameterName = 'Direction';     PropertyName = 'Direction';       PropertyType = [FwRule.Direction]}
            [PSCustomObject]@{Order = 10; ParameterName = 'Enabled';       PropertyName = 'Enabled';         PropertyType = [Boolean]}
            [PSCustomObject]@{Order = 11; ParameterName = 'Group';         PropertyName = 'Grouping';        PropertyType = [String]}
            [PSCustomObject]@{Order = 12; ParameterName = 'Profile';       PropertyName = 'Profiles';        PropertyType = [FwRule.Profiles]}
            [PSCustomObject]@{Order = 13; ParameterName = 'Action';        PropertyName = 'Action';          PropertyType = [FwRule.Action]}
        )
    }
}


function Get-cFirewallRule
{
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Allow', 'Block')]
        [String]
        $Action,

        [Parameter(Mandatory = $false)]
        [String]
        $Description,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Inbound', 'Outbound')]
        [String]
        $Direction,

        [Parameter(Mandatory = $false)]
        [Boolean]
        $Enabled,

        [Parameter(Mandatory = $false)]
        [String]
        $Group,

        [Parameter(Mandatory = $false)]
        [String[]]
        $LocalAddress,

        [Parameter(Mandatory = $false)]
        [String[]]
        $LocalPort,

        [Parameter(Mandatory = $false)]
        [ValidateSet('All', 'Domain', 'Private', 'Public')]
        [String[]]
        $Profile,

        [Parameter(Mandatory = $false)]
        [String]
        $Program,

        [Parameter(Mandatory = $false)]
        [ValidateScript({($_ -in [System.Net.Sockets.ProtocolType].GetEnumNames()) -or ($_ -in @('*', 'Any', 'All'))})]
        [String]
        $Protocol,

        [Parameter(Mandatory = $false)]
        [String[]]
        $RemoteAddress,

        [Parameter(Mandatory = $false)]
        [String[]]
        $RemotePort,

        [Parameter(Mandatory = $false)]
        [String]
        $Service
    )
    begin
    {
        Initialize-cFirewallRuleType

        $FwPolicy = New-Object -ComObject HNetCfg.FwPolicy2 -ErrorAction Stop
    }
    process
    {
        if ($Protocol -in @('*', 'Any', 'All'))
        {
            $PSBoundParameters.Item('Protocol') = [String]$Protocol = '256'
        }

        $PSBoundParameters.Keys.Where({$_ -in $Script:FwRulePropertyData.ParameterName}) |
        ForEach-Object -Begin {

            [String[]]$FilterConditions = @('($_ -ne $null)')

        } -Process {

            $ParameterName = $_
            $PropertyData = $Script:FwRulePropertyData.Where({$_.ParameterName -eq $ParameterName})

            if ($ParameterName -in @('LocalAddress', 'RemoteAddress'))
            {
                $PSBoundParameters.Item($ParameterName) = (
                        $PSBoundParameters.Item($ParameterName) |
                        Where-Object {[String]::IsNullOrEmpty($_) -eq $false} |
                        Resolve-cFirewallRuleAddress |
                        Sort-Object
                    ) -join ','

                $FilterConditions += '((($_."{0}" -split "," | Sort-Object) -join ",") -as [{2}]) -eq ($PSBoundParameters.Item("{1}") -as [{2}])' -f
                    $PropertyData.PropertyName,
                    $PropertyData.ParameterName,
                    $PropertyData.PropertyType

                return
            }

            if ($ParameterName -in @('LocalPort', 'RemotePort'))
            {
                $PSBoundParameters.Item($ParameterName) = (
                        $PSBoundParameters.Item($ParameterName) |
                        Where-Object {[String]::IsNullOrEmpty($_) -eq $false} |
                        Sort-Object
                    ) -join ','
            }

            if ($ParameterName -eq 'Program')
            {
                $PSBoundParameters.Item($ParameterName) = [Environment]::ExpandEnvironmentVariables($PSBoundParameters.Item($ParameterName))
            }

            $FilterConditions += '($_."{0}" -as [{2}]) -eq ($PSBoundParameters.Item("{1}") -as [{2}])' -f
                $PropertyData.PropertyName,
                $PropertyData.ParameterName,
                $PropertyData.PropertyType

        } -End {

            $FilterScript = [ScriptBlock]::Create(($FilterConditions -join ' -and '))

        }

        $FwPolicy.Rules |
        Where-Object -FilterScript $FilterScript -PipelineVariable FwRule |
        ForEach-Object {

            $Script:FwRulePropertyData |
            Select-Object -PipelineVariable PropertyData |
            ForEach-Object -Begin {

                $OutputObject = [PSCustomObject]@{}

            } -Process {

                $OutputObject | Add-Member -NotePropertyname $PropertyData.ParameterName `
                    -NotePropertyValue ($FwRule."$($PropertyData.PropertyName)" -as $PropertyData.PropertyType)

            } -End {

                return $OutputObject

            }

        }
    }
}


function New-cFirewallRule
{
    [CmdletBinding(ConfirmImpact = 'Medium', SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Allow', 'Block')]
        [String]
        $Action = 'Allow',

        [Parameter(Mandatory = $false)]
        [String]
        $Description = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Inbound', 'Outbound')]
        [String]
        $Direction = 'Inbound',

        [Parameter(Mandatory = $false)]
        [Boolean]
        $Enabled = $true,

        [Parameter(Mandatory = $false)]
        [String]
        $Group = $null,

        [Parameter(Mandatory = $false)]
        [String[]]
        $LocalAddress = $null,

        [Parameter(Mandatory = $false)]
        [String[]]
        $LocalPort = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet('All', 'Domain', 'Private', 'Public')]
        [String[]]
        $Profile = 'All',

        [Parameter(Mandatory = $false)]
        [String]
        $Program = $null,

        [Parameter(Mandatory = $false)]
        [ValidateScript({($_ -in [System.Net.Sockets.ProtocolType].GetEnumNames()) -or ($_ -in @('*', 'Any', 'All'))})]
        [String]
        $Protocol = 'TCP',

        [Parameter(Mandatory = $false)]
        [String[]]
        $RemoteAddress = $null,

        [Parameter(Mandatory = $false)]
        [String[]]
        $RemotePort = $null,

        [Parameter(Mandatory = $false)]
        [String]
        $Service = $null
    )
    begin
    {
        Initialize-cFirewallRuleType

        $FwPolicy = New-Object -ComObject HNetCfg.FwPolicy2 -ErrorAction Stop
    }
    process
    {
        if (-not $PSCmdlet.ShouldProcess($Name, 'Create Rule'))
        {
            return
        }

        trap
        {
            Write-Error -Message $_.Exception.Message

            return
        }

        $MyInvocation.MyCommand.Parameters.Keys.Where({$_ -in $Script:FwRulePropertyData.ParameterName}) |
        ForEach-Object -Begin {

            $Properties = @{}

        } -Process {

            $ParameterName = $_
            $ParameterValue = Get-Variable -Name $ParameterName -Scope Local -ValueOnly -ErrorAction Ignore

            if (-not $ParameterValue -and -not $PSBoundParameters.ContainsKey($ParameterName))
            {
                return
            }

            if ($ParameterName -in @('LocalAddress', 'RemoteAddress'))
            {
                $ParameterValue = (
                        $ParameterValue |
                        Where-Object {[String]::IsNullOrEmpty($_) -eq $false} |
                        Resolve-cFirewallRuleAddress |
                        Sort-Object
                    ) -join ','
            }

            if ($ParameterName -in @('LocalPort', 'RemotePort'))
            {
                $ParameterValue = (
                        $ParameterValue |
                        Where-Object {[String]::IsNullOrEmpty($_) -eq $false} |
                        Sort-Object
                    ) -join ','
            }

            if ($ParameterName -eq 'Program')
            {
                $ParameterValue = [Environment]::ExpandEnvironmentVariables($ParameterValue);
            }

            if ($ParameterName -eq 'Protocol' -and $ParameterValue -in @('*', 'Any', 'All'))
            {
                $ParameterValue = '256'
            }

            $PropertyData = $Script:FwRulePropertyData.Where({$_.ParameterName -eq $ParameterName})
            $Properties.Add($PropertyData.PropertyName, $ParameterValue)

        }

        $Script:FwRulePropertyData.Where({$_.PropertyName -in $Properties.Keys}) |
        Sort-Object -Property Order |
        ForEach-Object -Begin {

            $FwRule = New-Object -ComObject HNetCfg.FwRule -ErrorAction Stop

        } -Process {

            $PropertyData = $_

            try
            {
                $FwRule."$($PropertyData.PropertyName)" = ($Properties.Item($PropertyData.PropertyName) -as $PropertyData.PropertyType)
            }
            catch
            {
                throw "Failed to set property '$($PropertyData.PropertyName)': '$($_.Exception.Message)'."
            }

        } -End {

            try
            {
                $FwPolicy.Rules.Add($FwRule)
            }
            catch
            {
                throw "Failed to add rule '$Name': '$($_.Exception.Message)'."
            }

        }
    }
}


function Remove-cFirewallRule
{
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Allow', 'Block')]
        [String]
        $Action,

        [Parameter(Mandatory = $false)]
        [String]
        $Description,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Inbound', 'Outbound')]
        [String]
        $Direction,

        [Parameter(Mandatory = $false)]
        [Boolean]
        $Enabled,

        [Parameter(Mandatory = $false)]
        [String]
        $Group,

        [Parameter(Mandatory = $false)]
        [String[]]
        $LocalAddress,

        [Parameter(Mandatory = $false)]
        [String[]]
        $LocalPort,

        [Parameter(Mandatory = $false)]
        [ValidateSet('All', 'Domain', 'Private', 'Public')]
        [String[]]
        $Profile,

        [Parameter(Mandatory = $false)]
        [String]
        $Program,

        [Parameter(Mandatory = $false)]
        [ValidateScript({($_ -in [System.Net.Sockets.ProtocolType].GetEnumNames()) -or ($_ -in @('*', 'Any', 'All'))})]
        [String]
        $Protocol,

        [Parameter(Mandatory = $false)]
        [String[]]
        $RemoteAddress,

        [Parameter(Mandatory = $false)]
        [String[]]
        $RemotePort,

        [Parameter(Mandatory = $false)]
        [String]
        $Service
    )
    begin
    {
        Initialize-cFirewallRuleType

        $FwPolicy = New-Object -ComObject HNetCfg.FwPolicy2 -ErrorAction Stop
    }
    process
    {
        if (-not $PSCmdlet.ShouldProcess($Name, 'Remove Rule'))
        {
            return
        }

        if ($Protocol -in @('*', 'Any', 'All'))
        {
            $PSBoundParameters.Item('Protocol') = [String]$Protocol = '256'
        }

        $PSBoundParameters.Keys.Where({$_ -in $Script:FwRulePropertyData.ParameterName}) |
        ForEach-Object -Begin {

            [String[]]$FilterConditions = @()

        } -Process {

            $ParameterName = $_
            $PropertyData = $Script:FwRulePropertyData.Where({$_.ParameterName -eq $ParameterName})

            if ($ParameterName -in @('LocalAddress', 'RemoteAddress'))
            {
                $PSBoundParameters.Item($ParameterName) = (
                        $PSBoundParameters.Item($ParameterName) |
                        Where-Object {[String]::IsNullOrEmpty($_) -eq $false} |
                        Resolve-cFirewallRuleAddress |
                        Sort-Object
                    ) -join ','

                $FilterConditions += '((($_."{0}" -split "," | Sort-Object) -join ",") -as [{2}]) -eq ($PSBoundParameters.Item("{1}") -as [{2}])' -f
                    $PropertyData.PropertyName,
                    $PropertyData.ParameterName,
                    $PropertyData.PropertyType

                return
            }

            if ($ParameterName -in @('LocalPort', 'RemotePort'))
            {
                $PSBoundParameters.Item($ParameterName) = (
                        $PSBoundParameters.Item($ParameterName) |
                        Where-Object {[String]::IsNullOrEmpty($_) -eq $false} |
                        Sort-Object
                    ) -join ','
            }

            if ($ParameterName -eq 'Program')
            {
                $PSBoundParameters.Item($ParameterName) = [Environment]::ExpandEnvironmentVariables($PSBoundParameters.Item($ParameterName))
            }

            $FilterConditions += '($_."{0}" -as [{2}]) -eq ($PSBoundParameters.Item("{1}") -as [{2}])' -f
                $PropertyData.PropertyName,
                $PropertyData.ParameterName,
                $PropertyData.PropertyType

        } -End {

            $FilterScript = [ScriptBlock]::Create(($FilterConditions -join ' -and '))

        }

        $MatchingRules = @($FwPolicy.Rules | Where-Object -FilterScript $FilterScript)
 
         <#
        .NOTES
            Due to the 'INetFwRules::Remove' method limitations, rules can be removed only by name.
            Workaround is to rename all the matching rules with a random name before removing them.
        .LINKS
            https://msdn.microsoft.com/en-us/library/windows/desktop/aa365349%28v=vs.85%29.aspx
        #>

        if ($MatchingRules.Count -eq 0)
        {
            Write-Verbose -Message "No matching firewall rules could be found."
        }
        else
        {
            $MatchingRules |
            ForEach-Object -Begin {

                Write-Verbose -Message "Removing all the matching firewall rules."

                [String[]]$RuleNamesToRemove = @()

            } -Process {

                $RuleNamesToRemove += $NewRandomName = [Guid]::NewGuid().Guid

                Write-Verbose -Message "Renaming firewall rule '$($_.Name)' to '$NewRandomName'."

                $_.Enabled = $false
                $_.Description = "Disabled and marked for removal: $(Get-Date -Format s)."
                $_.Name = $NewRandomName

            }

            if ($RuleNamesToRemove.Count -ne 0)
            {
                foreach ($RuleName in $RuleNamesToRemove)
                {
                    Write-Verbose -Message "Removing firewall rule '$RuleName'."

                    $FwPolicy.Rules.Remove($RuleName)
                }
            }
        }
    }
}


function Resolve-cFirewallRuleAddress
{
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InputString
    )
    begin
    {
        $IPAddressPattern = '(([01]?\d?\d|2[0-4]\d|25[0-5])\.){3}([01]?\d?\d|2[0-4]\d|25[0-5])'
        $NetworkPrefixPattern = '(\d{1}|[0-2]{1}\d{1}|3[0-2])'

        function Convert-NetworkPrefix
        {
            <#
            .SYNOPSIS
                Converts network prefix (a.k.a. CIDR prefix) to a subnet mask.
            #>
            [CmdletBinding()]
            [OutputType([String])]
            param
            (
                [Parameter(Mandatory = $true)]
                [ValidateRange(0, 32)]
                [Int32]
                $Prefix
            )
            process
            {
                $Array = New-Object -TypeName 'System.Int32[]' -ArgumentList 32

                0..($Prefix - 1) | ForEach-Object {$Array.SetValue(1, $_)}

                $SubnetMask = [System.Convert]::ToUInt64((-join $Array), 2) -as [IPAddress]

                Write-Output -InputObject $SubnetMask.IPAddressToString
            }
        }

        function Test-IPAddressRange
        {
            <#
            .SYNOPSIS
                Tests whether the IP End address is greater than the IP Start address.
            #>
            [CmdletBinding()]
            [OutputType([Boolean])]
            param
            (
                [Parameter(Mandatory = $true)]
                [IPAddress]
                $Start,

                [Parameter(Mandatory = $true)]
                [IPAddress]
                $End
            )
            process
            {
                $StartBytes = $Start.GetAddressBytes()
                $EndBytes = $End.GetAddressBytes()

                [Array]::Reverse($StartBytes)
                [Array]::Reverse($EndBytes)

                $StartInt = [BitConverter]::ToUInt32($StartBytes, 0)
                $EndInt = [BitConverter]::ToUInt32($EndBytes, 0)

                $Result = $EndInt -gt $StartInt

                Write-Output -InputObject $Result
            }
        }
    }
    process
    {
        switch -Regex ($InputString)
        {
            ('^{0}\/{1}$' -f $IPAddressPattern, $NetworkPrefixPattern)
            {
                [IPAddress]$IPAddress, [Int32]$NetworkPrefix = $InputString -split '/'
                $SubnetMask = Convert-NetworkPrefix -Prefix $NetworkPrefix
                $OutputString = $IPAddress.IPAddressToString, $SubnetMask -join '/'
            }

            ('^{0}\/{0}$' -f $IPAddressPattern)
            {
                [IPAddress]$IPAddress, [IPAddress]$SubnetMask = $InputString -split '/'
                $OutputString = $IPAddress.IPAddressToString, $SubnetMask.IPAddressToString -join '/'
            }

            ('^{0}\-{0}$' -f $IPAddressPattern)
            {
                [IPAddress]$StartIPAddress, [IPAddress]$EndIPAddress = $InputString -split '-'

                if ($StartIPAddress.IPAddressToString -eq $EndIPAddress.IPAddressToString)
                {
                    $OutputString = $StartIPAddress.IPAddressToString, '255.255.255.255' -join '/'
                }
                else
                {
                    if (Test-IPAddressRange -Start $StartIPAddress -End $EndIPAddress)
                    {
                        $OutputString = $StartIPAddress.IPAddressToString, $EndIPAddress.IPAddressToString -join '-'
                    }
                    else
                    {
                        "The End address '{0}' is less than the Start address '{1}' in the IP address range '{2}'. Please change the End address." -f
                            $EndIPAddress.IPAddressToString,
                            $StartIPAddress.IPAddressToString,
                            $InputString |
                        Write-Error

                        return
                    }
                }
            }

            ('^{0}$' -f $IPAddressPattern)
            {
                [IPAddress]$IPAddress = $InputString
                $OutputString = $IPAddress.IPAddressToString, '255.255.255.255' -join '/'
            }

            default
            {
                $OutputString = $InputString
            }
        }

        Write-Output -InputObject $OutputString
    }
}


#endregion

