!include 'LogicLib.nsh'
!include 'TextFunc.nsh'
!include 'WordFunc.nsh'
!include "StrFunc.nsh"
!include /NONFATAL version.nsh

!define serviceStoppedManually "0"
;======================================================
; Installer Information
 
  Name "TestDataManager Portal Patch Launcher - ${VERSION}"
  OutFile "TDMPortalPatchInstaller - ${VERSION}.exe"
  Caption "TDM Portal Patch Launcher - ${VERSION}"
  VIProductVersion "${VERSION}"
  VIAddVersionKey ProductName "TDMPortalPatchInstaller"
  VIAddVersionKey CompanyName Broadcom.com
  VIAddVersionKey LegalCopyright Broadcom.com
  VIAddVersionKey FileVersion "${VERSION}"
  VIAddVersionKey ProductVersion "${VERSION}"
  VIAddVersionKey OriginalFilename "TDMPortalPatchInstaller - ${VERSION}.exe"
  VIAddVersionKey FileDescription "TestDataManager Portal Patch Launcher"

 ; import functions
;!define StrContains

;======================================================
; Variables
var varNewPatchVersion
var varVersionPath
var varMajorMinor
var varserviceStoppedManually
;======================================================
; Sections
Section "Install a Patch to an existing app" installPatchSection
  
  StrCpy $varVersionPath $INSTDIR
  StrCpy $varVersionPath "$INSTDIR\TestDataManager\META-INF\maven\com.ca.tdm\TestDataManager\pom.properties"
  
  StrCpy $varserviceStoppedManually $(serviceStoppedManually)


  ${ConfigRead} $varVersionPath "version=" $R0
  ;$R0=4.8.101.0
  ;MessageBox MB_OK "Installed version '$R0'"
  DetailPrint "Installed version is '$R0'"
  
  StrCmp $R0 "" lbl_noprev lbl_prev
  
  lbl_noprev:
  ; The variable is empty, meaning either the previous install was corrupt or the file wasn't
  ; there, which means they need to do a full install, not just a patch install
  MessageBox MB_OK "No installed version detected. You need to perform a full install"
  ; Abort the install
  DetailPrint "No installed version detected. You need to perform a full install"
  DetailPrint  "Please press Cancel to exit"
  ABORT


  lbl_failedqueryService:
  MessageBox MB_OK "Failed to query/stop Portal service. please stop service manually and rerun patch installer"
  ; Abort the install
  DetailPrint "Failed to query/stop Portal service. please stop service manually and rerun patch installer"
  DetailPrint  "Please press Cancel to exit"
  ABORT
  
  
  lbl_prev:
  
  StrCpy  $varNewPatchVersion  "${VERSION}"
  StrCpy  $varMajorMinor  "${MAJORMINOR}"
  
  DetailPrint "Installing TDM Portal version : $varNewPatchVersion"

${WordFind} "$R0" "$varMajorMinor" "#" $R1

 ${If} "$R1" == "$R0"
  MessageBox MB_OK "Installed version '$R0' detected. However it cannot be patched with $varNewPatchVersion"
  DetailPrint "Installed version '$R0' detected. However it cannot be patched with $varNewPatchVersion"
  ; Abort the install
  DetailPrint  "Please press Cancel to exit"
  ABORT
 ${elseif} $R1 == 1   
   ;MessageBox MB_OK "**** same version "
 ${Endif}

  ; $R2=0  Versions are equal 
  ; $R2=1  Version1 is newer
  ; $R2=2  Version2 is newer
  ${VersionCompare} "$R0" "$varNewPatchVersion" $R2
  
  ${If} $R2 == 0
    MessageBox MB_OKCANCEL|MB_ICONQUESTION "Existing install is at the same version as this installer. Do you want to continue?" IDOK lbl_prevdone IDCANCEL lbl_ABORT
 
          lbl_ABORT:
          ; Abort the install
          DetailPrint "Existing install is at the same version as this installer."
          DetailPrint  "Please press Cancel to exit"
          ABORT
  ${ElseIf} $R2 == 1
    DetailPrint "Should not install an older version '$varNewPatchVersion' on top of '$R0'."
	DetailPrint  "Please press Cancel to exit"
	ABORT
  ${EndIf}

 
  lbl_prevdone:
 
  ; Get the current status of a service
  SimpleSC::GetServiceStatus "CATestDataManagerPortal"
  Pop $3 ; returns an errorcode (<>0) otherwise success (0)
  Pop $4 ; return the status of the service (See "service_status" in the parameters) 
  
  StrCmp $3 "0" 0 lbl_failedqueryService
  
  IntCmp $4 1 lbl_sevicestopped 0
  ; Stop a service and waits for file release. Be sure to pass the service name, not the display name.
  DetailPrint "Stopping TDM Portal Service"
  SimpleSC::StopService "CATestDataManagerPortal" 1 30
  Pop $5 ; returns an errorcode (<>0) otherwise success (0)

  StrCmp $5 "0" 0 lbl_failedqueryService
  ${For} $R0 1 60
    DetailPrint "Querying TDM Portal Service Status"
    SimpleSC::GetServiceStatus "CATestDataManagerPortal"
    Pop $R1
    Pop $R2
    ${If} $R1 == 0
    ${AndIf} $R2 == 1 ; SERVICE_STOPPED
      ${Break}
    ${EndIf}
    Sleep 1000
  ${Next}
  
  ${If} $R2 != 1
    DetailPrint "Service could not be stopped after 1 minute. Please Stop Service manually"
	DetailPrint  "Please press Cancel to exit"
	ABORT
${EndIf}
  
  StrCpy $varserviceStoppedManually "1"
  
  lbl_sevicestopped:
  DetailPrint "TDM Portal Service Stopped"
  DetailPrint "Deleting folders located in $INSTDIR"
  
  ; delete content in location
  RMDir /r $INSTDIR\TDMConnectionProfileService
  RMDir /r $INSTDIR\TDMDataFlowService

  RMDir /r $INSTDIR\TDMDataReservationService
  RMDir /r $INSTDIR\TDMEventService

  RMDir /r $INSTDIR\TDMFindReserveService
  RMDir /r $INSTDIR\TDMGeneratorService
  RMDir /r $INSTDIR\TDMJobService
  RMDir /r "$INSTDIR\TDMLegacyExecuterService"

  RMDir /r "$INSTDIR\TDMMaskingService"
  RMDir /r "$INSTDIR\TDMModelService"

  RMDir /r "$INSTDIR\TDMOrchestrationService"
  RMDir /r "$INSTDIR\TDMProjectService"
  RMDir /r "$INSTDIR\TDMPublisherService"
  RMDir /r "$INSTDIR\TDMService"
  RMDir /r "$INSTDIR\TDMvDataService"
  RMDir /r "$INSTDIR\TestDataManager"
  
  DetailPrint "Deleting war files located in $INSTDIR"
  ; remove war files as well
  Delete "$INSTDIR\*.war" 
  
  ; Perform the actual install
  SetOutPath $INSTDIR
  DetailPrint "Copying war files to $INSTDIR"
  File /r "data\*.*"

  ${If} $varserviceStoppedManually == 1
    DetailPrint "Starting Portal Service"
    SimpleSC::StartService "CATestDataManagerPortal" 1 30
  ${EndIf}

SectionEnd


 Function .onInit
   ReadEnvStr $0 "CATDMWEB_HOME"
   StrCmp $0 "" lblAbort lblNoAbort
   lblAbort:
     MessageBox MB_OK "CATDMWEB_HOME environment variable is not set. Unable to get install path."
     DetailPrint "CATDMWEB_HOME environment variable is not set. Unable to get install path."
     DetailPrint  "Please press Cancel to exit"
     Abort ; causes installer to quit.
   lblNoAbort:

  StrCpy $INSTDIR $0
  StrCpy $INSTDIR "$INSTDIR\tomcat\webapps"
 FunctionEnd
 
 
 
