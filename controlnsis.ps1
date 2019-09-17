$TDMZipfullpath=$args[0]
#$TDMZip = 'TDMWeb-4.8.111.0.zip' 

$TDMVersion = $TDMZipfullpath.SubString($TDMZipfullpath.IndexOf("-") + 1, $TDMZipfullpath.LastIndexOf(".") - $TDMZipfullpath.IndexOf("-") - 1)

$currentlocation = Get-Location
Write-Host "currentlocation is $currentlocation "

$packagefolder = "$currentlocation\packages\"
Write-Host "packagefolder is $packagefolder"

# create a patch 
#New-Item -ItemType Directory -Force -Path $packagefolder

Write-Host "unzipping $TDMZipfullpath ..."
$outputlocation = '-o'+$packagefolder
#unzip 'TDMWeb-4.8.111.0.zip' to extract setup.....exe in D:\apps\nsisinstall\packages
$CMD = 'C:\Program Files\7-Zip\7z.exe'
$arg1 = 'e'
$arg2 = $TDMZipfullpath
$arg3 = $outputlocation
$arg4 = '-r'
$arg5 = '-y'
 
& $CMD $arg1 $arg2 $arg3 $arg4 $arg5 | Out-Null


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
  $generatedfolder = '436D50A'
  $TDMmajorminor = '4.8'
} elseif ($TDMVersion.StartsWith("4.7")) {
  $generatedfolder = '436D50A'
  $TDMmajorminor = '4.7'
} elseif ($TDMVersion.StartsWith("4.6")) {
  $generatedfolder = '436D50A'
  $TDMmajorminor = '4.6'
}
$datapathtocreate = $currentlocation.tostring() + '\TDMPortalPatch' + $TDMVersion + '\data'
$pathtocreate = $currentlocation.tostring() + '\TDMPortalPatch' + $TDMVersion

Write-Host "create folder $datapathtocreate"
# create a patch 
New-Item -ItemType Directory -Force -Path $datapathtocreate

Write-Host "copying war files to $datapathtocreate ..."
# copy war files to data area for nsis
$originalwarlocation = $packagefolder + $generatedfolder+'\tomcat\webapps\*.*'
Copy-Item -Filter *.war -Path $originalwarlocation -Destination $datapathtocreate


# create a file and add 
#!define VERSION "4.8.105.0"
#!define MAJORMINOR "4.8"
$versionheader = $pathtocreate+'\version.nsh'

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
Copy-Item -Path $nsifile -Destination $pathtocreate

Set-Location -Path $pathtocreate

$stroutput = "generating the installer $currentlocation\TDMPortalPatch{0}\TDMPortalPatchInstaller - {0}.exe..." -f $TDMVersion
Write-Host $stroutput
#makensis.exe /X"SetCompressor /FINAL lzma" /LICENSE TDMPatch.nsi
$CMD = 'C:\Program Files (x86)\NSIS\Bin\makensis.exe'
$arg1 = '/LICENSE'
$arg2 = 'TDMPatch.nsi'

& $CMD $arg1 $arg2 | Out-Null

Set-Location -Path $currentlocation

