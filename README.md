# Summary
Outputs an RDG file (for use with RDCMan) with a group structure mimicking the OU structure in a given AD OU.

Optionally organizes groups or smart groups differently depending on the parameters specified.  

# Usage
1. Download `Get-RdcmanFileForOu.psm1` to `$HOME\Documents\WindowsPowerShell\Modules\Get-RdcmanFileForOu\Get-RdcmanFileForOu.psm1`
2. Download dependency `Get-ADOUStructureObject.psm1` from [here](https://github.com/engrit-illinois/Get-ADOUStructureObject) to `$HOME\Documents\WindowsPowerShell\Modules\Get-ADOUStructureObject\Get-ADOUStructureObject.psm1`.
    - Only required for default value of `-OutputFormat` (`MirrorOuStructure`).
3. Run it using the examples provided below.

# Examples
- Regular groups and computers in a structure mirroring that of the given OU:
    - `Get-RdcmanFileForLabs -OUDN "OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu" -OutputFilePath "C:\ews-rdcman-file.rdg" -OutputFormat "MirrorOuStructure"`
- Smart groups which search for machines named like `<string>-<string>-*`, grouped into groups which contain smart groups named like `<string>-*`. Each group named like `<string>` contains a single group with all computers named like `<string>-*-*`:
    - `Get-RdcmanFileForLabs -OUDN "OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu" -OutputFilePath "C:\ews-rdcman-file.rdg" -OutputFormat "SmartGroupsGrouped"`
- A single group containing all machines in a flat structure, and adjacent to that group, a flat list of smart groups, which search for machines named like `<string>-<string>-*`:
    - `Get-RdcmanFileForLabs -OUDN "OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu" -OutputFilePath "C:\ews-rdcman-file.rdg" -OutputFormat "SmartGroupsFlat" -MinLabSizeForSmartGroups 3`
- A single group containing all machines in a flat structure:
    - `Get-RdcmanFileForLabs -OUDN "OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu" -OutputFilePath "C:\ews-rdcman-file.rdg" -OutputFormat "FlatMachines" -MinLabSizeForSmartGroups 3`

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
Default is `MirrorOuStructure`.  
- `MirrorOuStructure`
  - Groups and computers will be created in a structure mirroring the given OU structure. This option requires the dependency of `Get-ADOUStructureObject.psm1`. The other options do not require the dependency.
- `SmartGroupsFlat`
  - All computers from the given OU will be in a single flat group. Adjacent to that, one smart group will be created for each "lab" (i.e. set of computers with a common name prefix, matching `<string>-<string>-*`). "Lab" smart groups will only be created for "labs" containing at least X computers, given by `-MinLabSizeForSmartGroups`.
- `SmartGroupsGrouped` = Smart groups will be created for each "lab" (i.e. set of computers with a common name prefix, matching `<string>-<string>-*`). Each "lab" smart group will be groupd with other "lab" smart groups that share a common name prefix, matching `<string>-*`. Due to the way RDCMan grouping works, all computers with names matching `<string>-*-*` must be grouped together under the relevant group, so the smart groups will function. This means that this option is not compatible with `-MinLabSizeForSmartGroups`.
- `FlatMachines` = All machines from the given OU will be in a single, flat group.
Frankly `MirrorOusStructure` is the best option. The others are hard to describe, and only relevant for certain scenarios, but they will make more sense if you just open the file generated in RDCMan and take a look.  

### -MinLabSizeForSmartGroups \<int\>
Optional integer.  
The minimum number of discovered computers which must share a name prefix (e.g. `MEL-1001-`) for an associated smart group to be created.  
Only relevant when `-OutputFormat` is specified to be `SmartGroupsFlat`, due to the way RDCMan grouping works.  
Default is `2`.  

# Notes
- RDCMan is [discontinued](https://www.zdnet.com/article/microsoft-discontinues-rdcman-app-following-security-bug/) and the download is no longer even hosted by Microsoft. However it is still perfectly functional, incredibly useful and powerful, and there is no modern replacement for it.
- For whatever reason, RDCMan has a seemingly arbitrary built-in limitation where the GUI will not allow you to add computers and groups (or smart groups) adjacent to each other in the group hierarchy. It _will_ however read an RDG file with such a mixed structure without issue (why Microsoft!?). I guess you can't expect too much from a 10+ year old app which has been abandoned for 7 years.
- An additional limitation (or rather a design decision) which makes the code more complex, is that smart groups will only search for matching computers which are _adjacent to_ or _below_ them in the group hierarchy.
- Yet another idiosyncrasy of RDCMan is that selecting any given group will display (int he right pane) computers in that group _and_ computers in any immediate child groups, but not computers any further down the hierarchy.
- By mseng3. See my other projects here: https://github.com/mmseng/code-compendium.
