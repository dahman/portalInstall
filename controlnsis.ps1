$ZIPPATH = 'C:\Program Files\7-Zip\7z.exe'
$NSISPATH = 'C:\Program Files (x86)\NSIS\Bin\makensis.exe'

$TDMZipfullpath=$args[0]
#$TDMZip = 'TDMWeb-4.8.111.0.zip' 

$TDMVersion = $TDMZipfullpath.SubString($TDMZipfullpath.IndexOf("-") + 1, $TDMZipfullpath.LastIndexOf(".") - $TDMZipfullpath.IndexOf("-") - 1)

$currentlocation = Get-Location
Write-Host "currentlocation is $currentlocation "

$packagefolder = "$currentlocation\packages\"
Write-Host "packagefolder is $packagefolder"

# remove content of packagefolder. so that any folder created will be used
if (Test-Path $packagefolder) {
  Remove-Item -LiteralPath $packagefolder -Force -Recurse
}

# create a patch 
#New-Item -ItemType Directory -Force -Path $packagefolder

Write-Host "unzipping $TDMZipfullpath ..."
$outputlocation = '-o'+$packagefolder
#unzip 'TDMWeb-4.8.111.0.zip' to extract setup.....exe in D:\apps\nsisinstall\packages
$CMD = $ZIPPATH
$arg1 = 'e'
$arg2 = $TDMZipfullpath
$arg3 = $outputlocation
$arg4 = '-r'
$arg5 = '-y'
 
& $CMD $arg1 $arg2 $arg3 $arg4 $arg5 | Out-Null

$datapathtocreate = $currentlocation.tostring() + '\TDMPortalPatch' + $TDMVersion + '\data'

# delete content of data folder
$datatodelete = $datapathtocreate + '\*.war'
if (Test-Path $datatodelete) { 
   $stroutput = "deleting war files from " +  $datapathtocreate
   Write-Host $stroutput
   Remove-Item -Path $datatodelete -Force  -Recurse
} else {
   Write-Host "create folder $datapathtocreate"
   # create a patch 
   New-Item -ItemType Directory -Force -Path $datapathtocreate
}
#write-host "Press any key to continue..."
#[void][System.Console]::ReadKey($true)

$setupname = 'setup_CA Test Data Manager Portal' + $TDMVersion + '.exe'

# run the extract on setup....exe
$setupfilelocation = $packagefolder + $setupname

Write-Host "extracting files from $setupfilelocation ..."

$CMD = $setupfilelocation
$arg1 = '/extract'
$arg2 = $packagefolder
& $CMD $arg1 $arg2 | Out-Null


$TDMmajorminor = '4.8'
# if 4.8 then use folder 436D50A
if ($TDMVersion.StartsWith("4.8")) {
  $TDMmajorminor = '4.8'
} elseif ($TDMVersion.StartsWith("4.7")) {
  $TDMmajorminor = '4.7'
} elseif ($TDMVersion.StartsWith("4.6")) {
  $TDMmajorminor = '4.6'
}
$patchtocreate = $currentlocation.tostring() + '\TDMPortalPatch' + $TDMVersion

# find the folder created under 
$generatedfolder = Get-ChildItem $packagefolder -filter "???????" -Directory | % { $_.fullname }
Write-Host "generated folder is $generatedfolder"



Write-Host "copying war files to $datapathtocreate ..."
# copy war files to data area for nsis
$originalwarlocation = $generatedfolder+'\tomcat\webapps\*.*'
Copy-Item -Filter *.war -Path $originalwarlocation -Destination $datapathtocreate


# create a file and add 
#!define VERSION "4.8.105.0"
#!define MAJORMINOR "4.8"
$versionheader = $patchtocreate+'\version.nsh'

#delete file firstentry
if (Test-Path $versionheader) { 
   Remove-Item -Path $versionheader -Force
}

New-Item -Path $versionheader -ItemType File
Get-ChildItem -Path $versionheader

$firstentry = '!define VERSION '+ $TDMVersion
$secondentry = '!define MAJORMINOR '+ $TDMmajorminor

Add-Content -Path $versionheader  -Value $firstentry -Force
Add-Content -Path $versionheader  -Value $secondentry -Force

# copy the TDMPatch.nsi file to
$nsifile = $currentlocation.tostring() + '\TDMpatch.nsi'
Copy-Item -Path $nsifile -Destination $patchtocreate

Set-Location -Path $patchtocreate

$stroutput = "generating the installer $currentlocation\TDMPortalPatch{0}\TDMPortalPatchInstaller - {0}.exe..." -f $TDMVersion
Write-Host $stroutput
#makensis.exe /X"SetCompressor /FINAL lzma" /LICENSE TDMPatch.nsi
$CMD = $NSISPATH
$arg1 = '/LICENSE'
$arg2 = 'TDMPatch.nsi'

& $CMD $arg1 $arg2 | Out-Null


$packageexename = "TDMPortalPatchInstaller - {0}.exe" -f $TDMVersion
$packagezipname = "TDMPortalPatchInstaller - {0}.zip" -f $TDMVersion

$outZippackage = $currentlocation.tostring() + '\' + $packagename

$stroutput = "generating the zip file $currentlocation\TDMPortalPatch{0}\TDMPortalPatchInstaller - {0}.zip..." -f $TDMVersion
Write-Host $stroutput
# create a zip file 
$CMD = $ZIPPATH
$arg1 = 'a'
$arg2 = $packagezipname
$arg3 = $packageexename
$arg4 = '-y'
 
& $CMD $arg1 $arg2 $arg3 $arg4 | Out-Null


$stroutput = "deleting the exe file $currentlocation\TDMPortalPatch{0}\TDMPortalPatchInstaller - {0}.exe..." -f $TDMVersion
Write-Host $stroutput
Remove-Item -Path $packageexename -Force


Set-Location -Path $currentlocation
