# By mseng3
function Get-RdcmanFileForOu {
	param(
		[string]$OUDN,
		[string]$OutputFilePath
	)
	
	$ous = Get-ADOrganizationalUnit -Filter "*" -SearchBase $OUDN | Select Name,DistinguishedName
	$comps = Get-ADComputer -Filter "*" -SearchBase $OUDN | Select Name,DistinguishedName
	
	function Get-Children($object) {
		$dn = $object.OU.DistinguishedName
		
		$children = $ous | Where { $_.DistinguishedName -eq "OU=$($_.Name),$dn" }
		
		$childObjects = @()
		foreach($child in $children) {
			$childDn = $child.DistinguishedName
			
			$childObject = [PSCustomObject]@{
				"OU" = $child
			}
			$grandChildren = Get-Children $childObject
			$childObject | Add-Member -NotePropertyName "Children" -NotePropertyValue $grandChildren
			
			$childComps = $comps | Where { $_.DistinguishedName -eq "CN=$($_.Name),$childDn" }
			$childObject | Add-Member -NotePropertyName "Computers" -NotePropertyValue $childComps
			
			$childObjects += @($childObject)
		}
		
		$childObjects
	}
	
	function Print-Structure($object) {
		$object | ConvertTo-Json -Depth 3
	}
	
	function Export-Structure($object) {
		
		$name = "$($object.OU.Name) OU"
		
		Export "<?xml version=`"1.0`" encoding=`"utf-8`"?>
<RDCMan programVersion=`"2.7`" schemaVersion=`"3`">
	<file>
		<credentialsProfiles />
		<properties>
			<expanded>True</expanded>
			<name>$name</name>
		</properties>" $false
		
		Export-Children $object 0
		
		Export "	</file>
	<connected />
	<favorites />
	<recentlyUsed />
</RDCMan>"
	}
	
	function Export-Children($object, $depth) {
		
		foreach($child in $object.Children) {
			$childDepth = $depth + 1
			
			$indent = ""
			for($i = 0; $i -lt $childDepth; $i += 1) {
				$indent = "$indent	"
			}
			
			$name = $child.OU.Name
			
			Export "$indent	<group>
$indent		<properties>
$indent			<expanded>False</expanded>
$indent			<name>$name</name>
$indent			<comment>Child OUs of $name OU</comment>
$indent		</properties>"
			
			Export-Children $child $childDepth
			
			Export "$indent	</group>"
		}
	}
	
	function Export($string, $append=$true) {
		if(!(Test-Path -PathType leaf -Path $OutputFilePath)) {
			New-Item -ItemType File -Force -Path $OutputFilePath | Out-Null
		}
		
		if($append) {
			$string | Out-File $OutputFilePath -Encoding ascii -Append
		}
		else {
			$string | Out-File $OutputFilePath -Encoding ascii
		}
	}
	
	function Do-Stuff {
		$object = [PSCustomObject]@{
			"OU" = $ous | Where { $_.DistinguishedName -eq $OUDN }
		}
		
		$children = Get-Children $object
		$object | Add-Member -NotePropertyName "Children" -NotePropertyValue $children
		
		$dn = $object.OU.DistinguishedName
		$childComps = $comps | Where { $_.DistinguishedName -eq "CN=$($_.Name),$dn" }
		$object | Add-Member -NotePropertyName "Computers" -NotePropertyValue $childComps
		
		#Print-Structure $object
		
		if($OutputFilePath) {
			Export-Structure $object
		}
	}
	
	Do-Stuff
}