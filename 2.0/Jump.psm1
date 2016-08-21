if(!(Test-Path $PSScriptRoot\Jumps)) {
    mkdir $PSScriptRoot\Jumps
}

$defaultPath = "$PSScriptRoot\Jumps\$Env:COMPUTERNAME.json"

class JumpRepository {
    [string]$Path
    
    static [JumpRepository] $Default = [JumpRepository]::new($defaultPath)

    [hashtable]$Jumps = @{}

    JumpRepository([string]$Path) {
        $this.Path = $Path
        $this.Read()
    }

    Read() {
        $this.Jumps = @{}
        if(Test-Path $this.Path) {
            $tmp = Get-Content $this.Path | ConvertFrom-Json
            $tmp | Get-Member -MemberType *Property | ForEach-Object {
                $this.Jumps[$_.Name] = $tmp.($_.Name)
            }
        }
    }

    Write() {
        $this.Jumps | ConvertTo-Json | Out-File $this.Path
    }

    Set([string]$Name, [string]$Path) {
        $this.Jumps[$Name]=$Path
        $this.Write()
    }

    [bool]TryGet([string]$Name,[ref]$Destination) {
        $Destination.Value = $this.Jumps[$Name]
        return !([string]::IsNullOrEmpty($Destination.Value))
    }

    [hashtable]GetAll() {
        return $this.Jumps
    }

    [string[]]GetByNamePrefix([string]$Prefix) {
        if([string]::IsNullOrEmpty($Prefix)) {
            return $this.Jumps.Keys
        } else {
            return $this.Jumps.Keys.Where($_.StartWith($Prefix))
        }
    }

    Clear() {
        $this.Jumps = @{}
        $this.Write()
    }

    Remove($Name) {
        if($this.Jumps.Remove($Name)) {
            $this.Write()
        }
    } 
}

class Jump {
    $Name
    $Destination
    Jump($name, $destination) {
        $this.Name = $name
        $this.Destination = $destination
    }
}

function Clear-Jumps {
    [JumpRepository]::Default.Clear()
}

function Set-Jump {
    <#
    .SYNOPSIS
	    Creates or changes a jump alias for the specified directory.
    .DESCRIPTION
	    Aliases are stored in the modules directory in subdirectory Jumps\$Env:COMPUTERNAME
	    if no name is specified the base name of the path leaf is taken as an alias
    .PARAMETER Name
        Name of the created or changed jump destination
    .PARAMETER Destination
        path to the jump destination, may be an absolute path or a relative path
    #>
    param(
        [Parameter(Position=0)]
        [string]$Destination,
        
        [Parameter(Position=1)]
        [string]$Name
    )
    process {
        if([string]::IsNullOrEmpty($Name)) {
            $Name = Split-Path $Destination -Leaf
        }
        [JumpRepository]::Default.Set($Name,$Destination)
    }
}

function Get-Jump {
    <#
    .SYNOPSIS
	    Get specified jump adresses stored or all jumps adresses if the name isn't found    
    .PARAMETER Name
        Name of the created or changed jump destination
    #>
    [CmdletBinding(DefaultParameterSetName="asList")]
    param(
        [Parameter(Position=0,ParameterSetName="byName")]
        [string]$Name
    )
    process {
        switch($PSCmdlet.ParameterSetName) {
            "byName" {
                $destination = $null
                if([JumpRepository]::Default.TryGet($Name,[ref]$destination)) {
                    [Jump]::new($Name, $destination)
                }
            }
            "asList" {
                $jumps = [JumpRepository]::Default.GetAll()
                $jumps.Keys.ForEach({[Jump]::new($_, $jumps[$_])})
                #$jumps.Keys | ForEach-Object {
                #    [Jump]::new($_, $jumps[$_])
                #}
            }
        }
    }
}

function Remove-Jump {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Name
    )
    process {
        [JumpRepository]::Default.Remove($Name)
    }

}

function Invoke-Jump {
    <#
    .SYNOPSIS
	    Jumps to the specifed location.
    .DESCRIPTION
        Destination 'back' allows to jump to the position before the last jump
    .PARAMETER name
        Name of the jump destination. 
    #>
    [CmdletBinding()]
    param(
        [ArgumentCompleter({$wordToComplete = $args[2]; Get-Jump | Select-Object -ExpandProperty Name | Where-Object { $_.StartsWith($wordToComplete) }})]
        [Parameter(ValueFromPipeline,Position=0)]
        $Name    
    )
    process {

        # Empty name means jumping back
        if([string]::IsNullOrEmpty($Name)) {
            $Name = "back"
        }

        $destination = $null
        if([JumpRepository]::Default.TryGet($Name,[ref]$destination)) {

            # Create a 'back' jump for the current directory before jumping 
            [JumpRepository]::Default.Set("back",$PWD)
        
            Set-Location $destination
        }
    }
}

function Import-V1Jump {
    param(
        [ValidateScript({Test-Path $_ -PathType Container })]
        [Parameter(Mandatory)]
        $Directory
    )
    process {
        Get-ChildItem -Path $Directory -File -Recurse | ForEach-Object {
            # get the file name as jump name
            $fileName = $_.BaseName
            Get-Content -Path $_.FullName -TotalCount 1 | ForEach-Object {
                # from each file take the first and only line
                [JumpRepository]::Default.Set($fileName, $_)
            }
        } 
    }
}