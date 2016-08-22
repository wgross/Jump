Import-Module Pester
Import-Module $PSScriptRoot\Jump.psm1 -Force 

Describe "Set-Jump cmdlet" {
    
    BeforeEach {
        Clear-Jumps
    }
    
    It "Set-Jump -Name writes an updated jump file to the disk" {
        Set-Jump -Name "test" -Destination "c:\test"           

        Test-Path $PSScriptRoot/Jumps/$env:ComputerName.json | Should Be $true
        
        $content = Get-Content $PSScriptRoot/Jumps/$env:ComputerName.json | ConvertFrom-Json
        $content.test | Should Be "c:\test"
    }

    It "Set-Jump without a name takes the base name of the destination" {
        Set-Jump -Destination "c:\zumsel"           

        $content = Get-Content $PSScriptRoot/Jumps/$env:ComputerName.json | ConvertFrom-Json
        $content.zumsel | Should Be "c:\zumsel"
    }

    It "Set-Jump without a destination take the base name of the current working directory" {
        try {
            mkdir TestDrive:\nodestination
            Set-Location TestDrive:\noDestination
            Set-Jump
            (Get-Jump noDestination).Destination | Should Be "TestDrive:\noDestination"
        } finally {
            Set-Location $PSScriptRoot
        }
    }
}

Describe "Get-Jump cmdlet" {
    
    BeforeEach {
        Clear-Jumps
        Set-Jump -Destination "c:\zumsel"           
    }

    It "Get-jump returns a directory by its name" {
        
        (Get-Jump zumsel).Destination | Should Be "c:\zumsel"
    }

    It "Get-jump returns a list of known jump destinations" {
        $list = Get-Jump
        $list.Length  | Should Be 1
        $list[0].Name | Should Be "zumsel"
        $list[0].Destination | Should Be "c:\zumsel"
    }
}

Describe "Remove-Jump cmdlet" {

    BeforeEach {
        Clear-Jumps
        Set-Jump -Destination "c:\zumsel"           
    }

    It "Remove-jump deletes an alias and its destination from the repository" {
        Remove-Jump "zumsel"
        Get-Jump zumsel | Should Be $null
    }
}

Describe "Invoke-Jump cmdlet" {

    BeforeEach {
        Clear-Jumps
        mkdir TestDrive:\dest -ErrorAction SilentlyContinue
        Set-Jump -Destination "TestDrive:\dest"           
    }

    It "Invoke-Jump changes the location to the destination of the named jump" {
        Push-Location
        Invoke-Jump dest
        (Get-Location).Path | Should Be TestDrive:\dest
        Pop-Location
    }

    It "Invoke-Jump adds a 'back' jump destination with the PWD before jump" {
        $currentLocation = Get-Item $PWD
        Push-Location
        try {
            Invoke-Jump dest
            Invoke-Jump back
            Get-Location | Should Be $currentLocation.FullName
        } finally {
            Pop-Location
        }
    }

    It "Invoke-Jump always jumps back if now name was given" {
        $currentLocation = Get-Item $PWD
        Push-Location
        try {
            Invoke-Jump dest
            Invoke-Jump
            Get-Location | Should Be $currentLocation.FullName
        } finally {
            Pop-Location
        }
    }
}

Describe "Import-V1Jump cmdlet" {
    BeforeAll {
        mkdir TestDrive:\Jumps|Out-Null
        "c:\testImport"|Out-File TestDrive:\Jumps\aJump
    }

    It "Creates a new jump in V2 data from V1 jump definition" {
        Import-V1Jump -Directory TestDrive:\Jumps
        (Get-Jump aJump).Destination | Should Be "c:\testImport"
    }
}