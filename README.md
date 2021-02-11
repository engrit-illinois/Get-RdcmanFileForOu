# Summary
Outputs an RDG file (for use with RDCMan) with a group structure mimicking the OU structure in a given AD OU.

Optionally organizes groups or smart groups differently depending on the parameters specified.  

# Usage
1. Download `Get-RdcmanFileForOu.psm1`.
2. Download dependency `Get-ADOUStructureObject.psm1` from [here](https://github.com/engrit-illinois/Get-RdcmanFileForOu).
3. Import both files as modules:
  - `Import-Module "c:\path\to\Get-RdcmanFileForOu.psm1"`
  - `Import-Module "c:\path\to\Get-ADOUStructureObject.psm1"`
4. Run it using the examples provided below.

# Examples
- A single group containing all machines in a flat structure:
  - `Get-RdcmanFileForLabs -OUDN "OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu" -OutputFilePath "C:\ews-rdcman-file.rdg" -OutputFormat "FlatMachines" -MinLabSizeForSmartGroups 3`
- A single group containing all machines in a flat structure, and adjacent to that group, a flat list of smart groups, which search for machines named like `<string>-<string>-*`:
  - `Get-RdcmanFileForLabs -OUDN "OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu" -OutputFilePath "C:\ews-rdcman-file.rdg" -OutputFormat "SmartGroupsFlat" -MinLabSizeForSmartGroups 3`
- Smart groups which search for machines named like `<string>-<string>-*`, grouped into groups which contain smart groups named like `<string>-*`. Each group named like `<string>` contains a single group with all computers named like `<string>-*-*`:
  - `Get-RdcmanFileForLabs -OUDN "OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu" -OutputFilePath "C:\ews-rdcman-file.rdg" -OutputFormat "SmartGroupsGrouped"`
- COMING SOON: Regular groups and computers in a structure mirroring that of the given OU:
  - `Get-RdcmanFileForLabs -OUDN "OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu" -OutputFilePath "C:\ews-rdcman-file.rdg" -OutputFormat "MirrorOuStructure"`

# Parameters

### -OUDN \<string\>
Required string.  
The DistringuishedName of the OU containing the computers you want in the file.  
The switch itself can be ommitted if this is the first parameter given.  

### -OutputFile \<string\>
Required string.  
The full file path to the output file.  
The switch itself can be ommitted if this is the second parameter given.  
Note: any file existing at the given file path will be overwritten.  

### -OutputFormat ["FlatMachines" | "SmartGroupsFlat" | "SmartGroupsGrouped"]
Optional string from a predefinied set of strings.  
The structure of the RDG output file.  
- `FlatMachines` = All machines from the given OU in a single, flat group.
- `SmartGroupsFlat` = All machines from the given OU in a single flat group, and a smart group for each lab containing at least X computers, given by `-MinLabSizeForSmartGroups`, all in a flat structure.
- `SmartGroupsGrouped` = A group for each building, which contains A) a smart group for each lab in that building, and B) a flat group of all machines in that building. Not compatible with `-MinLabSizeForSmartGroups`, due to the way RDCMan grouping works.
- `MirrorOuStructure` = groups in a structure mirroring the given OU structure, with computers where you would expect them. Not implemented yet!
Default is `SmartGroupsGrouped`.  

### -MinLabSizeForSmartGroups \<int\>
Optional integer.  
The minimum number of discovered computers which must share a name prefix (e.g. `MEL-1001-`) for an associated smart group to be created.  
Default is `2`.  
The pre-made file above was generated using a value of `3`.  

# Notes
- For whatever reason, RDCMan has a seemingly arbitrary built-in limitation where the GUI will not allow you to add computers to the same group as other groups or smart groups. However RDCMan _will_ read an RDG file with such a mixed structure without issue (why Microsoft!?). I guess you can't expect too much from a 10+ year old app which has been abandoned for 7 years.
- An additional limitation (or rather more of a design decision) which makes the code more complex, is that smart groups will only search for matching computers which are _adjacent to_ or _below_ them in the group hierarchy.
- By mseng3. See my other projects here: https://github.com/mmseng/code-compendium.