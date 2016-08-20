Import-Module Pester
Import-Module Jump2 -Force -Prefix sut

Describe "Set-Jump" {
    
    BeforeEach {
        Clear-sutJumps
    }
    
    It "Set-Jump -Name writes an updated jump file to the disk" {
        Set-sutJump -Name "test" -Destination "c:\test"           

        Test-Path $PSScriptRoot/Jumps/$env:ComputerName.json | Should Be $true
        
        $content = Get-Content $PSScriptRoot/Jumps/$env:ComputerName.json | ConvertFrom-Json
        $content.test | Should Be "c:\test"
    }

    It "Set-Jump without a name takes the base name of the destination" {
        Set-sutJump -Destination "c:\zumsel"           

        $content = Get-Content $PSScriptRoot/Jumps/$env:ComputerName.json | ConvertFrom-Json
        $content.zumsel | Should Be "c:\zumsel"
    }

    It "Get-jump returns a directory by its name" {
        Set-sutJump -Destination "c:\zumsel"           
        (Get-sutJump zumsel).Destination | Should Be "c:\zumsel"
    }

    It "Get-jump returns a list of known jump destinations" {
        Set-sutJump -Destination "c:\zumsel"           
        $list = Get-sutJump
        $list.Length  | Should Be 1
        $list[0].Name | Should Be "zumsel"
        $list[0].Destination | Should Be "c:\zumsel"
    }

    It "Remove-jump deletes an alias and its destination from the repository" {
        Set-sutJump -Destination "c:\zumsel"           
        Remove-sutJump "zumsel"
        Get-sutJump zumsel | Should Be $null
    }

    It "Invoke-Jump changes the location to the destination of the named jump" {
        Push-Location
        Set-sutJump -Destination C:\tmp
        Invoke-sutJump tmp
        (Get-Location).Path | Should Be c:\tmp
        Pop-Location
    }

    It "Invoke-Jump adds a 'back' jump destination with the PWD before jump" {
        $currentLocation = Get-Item $PWD
        Push-Location
        try {
            Set-sutJump -Destination C:\tmp
            Invoke-sutJump tmp
            Invoke-sutJump back
            Get-Location | Should Be $currentLocation.FullName
        } finally {
            Pop-Location
        }
    }

    It "Invoke-Jump always jumps back if now name was given" {
        $currentLocation = Get-Item $PWD
        Push-Location
        try {
            Set-sutJump -Destination C:\tmp
            Invoke-sutJump tmp
            Invoke-sutJump
            Get-Location | Should Be $currentLocation.FullName
        } finally {
            Pop-Location
        }
    }
}