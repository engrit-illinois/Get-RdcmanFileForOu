# By mseng3
function Get-RdcmanFileForOu {
	param(
		[Parameter(Position=0,Mandatory=$true)]
		[string]$OUDN,
		
		[Parameter(Position=1,Mandatory=$true)]
		[string]$OutputFilePath,
		
		[ValidateSet("FlatMachines","SmartGroupsFlat","SmartGroupsGrouped","MirrorOuStructure")]
		[string]$OutputFormat = "MirrorOuStructure",
		
		[int]$MinLabSizeForSmartGroups = 2,
		
		[string]$IndentChar = "	"
	)
	
	function Export-File($ou, $comps, $labs) {
		
		$name = "$ou OU"
		
		# Write header
		Export "<?xml version=`"1.0`" encoding=`"utf-8`"?>" 0 $false
		Export "<RDCMan programVersion=`"2.7`" schemaVersion=`"3`">"
		Export "<file>" 1
		Export "<credentialsProfiles />" 2
		Export "<properties>" 2
		Export "<expanded>True</expanded>" 3
		Export "<name>$name</name>" 3
		Export "</properties>" 2
		
		# Write a group containing smart groups for each lab
		switch($OutputFormat) {
			"FlatMachines" {
				Export-Comps "all" $ou $comps 2
			}
			"SmartGroupsFlat" {
				Export-SmartGroups $labs 2
				Export-Comps "all" $ou $comps 2
			}
			"SmartGroupsGrouped" {
				Export-LabGroups $labs $comps
			}
			"MirrorOuStructure" {
				Export-OuGroups 2
			}
		}
		
		# Write footer
		Export "</file>" 1
		Export "<connected />" 1
		Export "<favorites />" 1
		Export "<recentlyUsed />" 1
		Export "</RDCMan>"
	}
	
	function Export-OuChildren($object, $indent) {
		foreach($child in $object.Children) {
			$indent0 = $indent + 1
			$indent1 = $indent + 2
			$indent2 = $indent + 3
			
			$name = $child.OU.Name
			
			Export "<group>" $indent0
			Export "<properties>" $indent1
			Export "<expanded>False</expanded>" $indent2
			Export "<name>$name</name>" $indent2
			Export "<comment>Child OUs of $name OU</comment>" $indent2
			Export "</properties>" $indent1
			
			Export-Comps "structure" $name $child.Computers $indent1
			Export-OuChildren $child $indent1
			
			Export "</group>" $indent0
		}
	}
	
	function Export-OuGroups($indent) {
		# Check if custom Get-ADOUStructureObject module is imported
		if((Get-Module "Get-ADOUStructureObject") -eq $null) {
			throw "Get-ADOUStructureObject module not imported!"
		}
		else {
			$object = Get-ADOUStructureObject -OUDN $OUDN -Silent -OutputObject
			if(!$object) {
				throw "No object received from Get-ADOUStructureObject!"
			}
			else {
				Export-OuChildren $object ($indent + 1)
			}
		}
	}
	
	function Export-LabGroups($labs,$comps) {
		
		# Start writing a group to contain all lab groups
		Export "<group>" 2
		Export "<properties><expanded>True</expanded><name>LabGroups</name></properties>" 3
		
		$labGroups = Get-LabGroups $labs
		foreach($labGroup in $labGroups) {
			Export "<group>" 3
			Export "<properties><expanded>False</expanded><name>$labGroup</name></properties>" 4
			
			$labGroupLabs = $labs | Where { $_ -like "$labGroup-*" } | Sort
			Export-SmartGroups $labGroupLabs 4
			
			$labComps = $comps | Where { $_ -like "$labGroup-*" } | Sort Name
			Export-Comps "lab" $labGroup $labComps 4
			
			Export "</group>" 3
		}
		# Write the end of the group
		Export "</group>" 2
	}
	
	function Export-SmartGroups($labs,$indent) {
		$indent1 = $indent + 1
		
		# For each lab
		foreach($lab in @($labs)) {
			# write a smart group for the lab
			Export "<smartGroup>" $indent
			Export "<properties><expanded>False</expanded><name>$lab</name></properties>" $indent1
			Export "<ruleGroup operator=`"All`"><rule><property>DisplayName</property><operator>Matches</operator><value>$lab</value></rule></ruleGroup>" $indent1
			Export "</smartGroup>" $indent
		}
	}
	
	function Export-Comps($type,$group,$comps,$indent) {
		$indent1 = $indent + 1
		
		switch($type) {
			"all" {
				$groupName = "All $group OU machines"
			}
			"lab" {
				$groupName = "All $group machines"
			}
			"structure" {
				$groupName = "Computers in $group OU"
			}
		}
		
		# Start writing a group to contain all comps
		Export "<group><properties><expanded>False</expanded><name>$groupName</name></properties>" $indent
		
		# For each comp
		foreach($comp in $comps) {
			# Write it to the file in the group
			Export "<server><properties><name>$comp</name></properties></server>" $indent1
		}
		
		# Write the end of the group
		Export "</group>" $indent
	}
	
	function Export($string, $indentSize=0, $append=$true) {
		# Ensure output file exists, if not create it
		if(!(Test-Path -PathType leaf -Path $OutputFilePath)) {
			New-Item -ItemType File -Force -Path $OutputFilePath | Out-Null
		}
		
		$indent = ""
		for($i = 0; $i -lt $indentSize; $i += 1) {
			$indent = "$indent$IndentChar"
		}
		$string = "$indent$string"
		
		if($append) {
			$string | Out-File $OutputFilePath -Encoding ascii -Append
		}
		else {
			$string | Out-File $OutputFilePath -Encoding ascii
		}
	}
	
	function Get-LabGroups($labs) {
		$labGroups = @()
		
		foreach($lab in $labs) {
			$parts = $lab.Split("-")
			$labGroup = $parts[0]
			$labGroups += @($labGroup)
		}
		
		# Remove duplicates
		$labGroups = $labGroups | Select -Unique | Sort
				
		$labGroups
	}
	
	function Get-Labs($comps) {
		$labs = @()
		
		# Only create a lab for computers that match a standard naming format
		# e.g. "<alphanumeric string>-<alphanumeric string>-<alphanumeric string>"
		$regex = "^[A-Z0-9].*-[A-Z0-9].*-[A-Z0-9].*$"
		foreach($comp in $comps) {
			if($comp -match $regex) {
				$parts = $comp.Split("-")
				$lab = "$($parts[0])-$($parts[1])"
				$labs += @($lab)
			}
		}
		
		# Remove duplicates
		$labs = $labs | Select -Unique | Sort
		
		# Filter out labs that are smaller than the given size
		# So we don't have a bunch of smart groups for one-off machines
		$filteredLabs = $labs
		foreach($lab in $labs) {
			$compsInLab = $comps | Where { $_ -like "$($lab)*" }
			$count = @($compsInLab).count
			if($count -lt $MinLabSizeForSmartGroups) {
				$filteredLabs = $filteredLabs | Where { $_ -ne $lab }
			}
		}
		
		$filteredLabs
	}
	
	function Do-Stuff {
		# Get name of given OUDN
		$ou = (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$OUDN'" | Select Name).Name
		
		# Get all comps in OU
		$comps = (Get-ADComputer -Filter "*" -SearchBase $OUDN | Select Name).Name
		$compsUpper = @()
		foreach($comp in $comps) {
			$compsUpper += @($comp.ToUpper())
		}
		$comps = $compsUpper
		
		# Get labs based on computer names
		$labs = Get-Labs $comps
		
		# Create RDG file
		Export-File $ou $comps $labs
	}
	
	Do-Stuff
}