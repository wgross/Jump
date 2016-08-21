@{
	## Module Info
	ModuleVersion      = '0.2.0.0'
	Description        = 'Directory Jump Module'
	GUID               = 'C49E7DEA-523C-476E-AC8C-A42B7936ECA2'

	## Module Components
	ScriptsToProcess   = @()
	ModuleToProcess    = @("Jump.psm1")
	TypesToProcess     = @()
	FormatsToProcess   = @()
	ModuleList         = @("Jump.psm1")
	FileList           = @()

	## Public Interface
	CmdletsToExport    = ''
	FunctionsToExport  = @('*-Jump')
	VariablesToExport  = ''
	AliasesToExport    = '*'

	## Requirements
	PowerShellVersion      = '2.0'
	PowerShellHostName     = ''
	PowerShellHostVersion  = ''
	RequiredModules        = @()#@("TabExpansionPlusPlus")
	RequiredAssemblies     = @()
	ProcessorArchitecture  = 'None'
	DotNetFrameworkVersion = '2.0'
	CLRVersion             = '2.0'

	## Author
	Author             = 'Wolfgang Gross'
	CompanyName        = ''
	Copyright          = ''

	## Private Data
	PrivateData        = ''
}
