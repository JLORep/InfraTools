@echo off
cls
echo	   KMS batch menu created by Dariusz Kokocinski
echo	   v1.3   (07.05.2010)
echo	   Needs to be run as Administrator
echo	   --------------------------------

pause

rem ver | find "6.1" > nul
rem if %ERRORLEVEL% == 0 goto start

ver | find "XP" > nul
if %ERRORLEVEL% == 0 copy CHOICE.COM c:\windows\system32\CHOICE.COM

:start                         
cls

echo	     Select KMS task:
echo	===========================
echo	 1. Remove Windows 8 ENT MAK
echo	 2. Remove Server 2012 Datacenter MAK
echo	 3. Remove Windows 7 MAK
echo	 4. Reset Server 2008 R2 to default installation key
echo	 5. Activate Windows via KMS
echo	 6. Reset Windows 30 day grace activation period (max 3 times)
echo	 7. Display Windows license/activation Status (NOT XP)
echo	 8. Enable Office 2013 KMS activation
echo	 9. Displays Office 2010 KMS activation history
echo	===========================
echo	Please make selection 1 - 9 (no need to press enter)

choice /c:123456789
if errorlevel 9 goto O2010stat
if errorlevel 8 goto O2010set
if errorlevel 7 goto status
if errorlevel 6 goto rearm
if errorlevel 5 goto KMS
if errorlevel 4 goto 2008R2
if errorlevel 3 goto W7
if errorlevel 2 goto VE
if errorlevel 1 goto VB


:VB
echo ---------------------
echo You selected option 1
echo Remove MAK by installing default Windows 8 ENT key
echo (After installing, Windows will run in grace activation mode)
echo Please wait...
slmgr /ipk 32JNW-9KQ84-P47T8-D8GGY-CWCK7
goto start


:VE
echo ---------------------
echo You selected option 2
echo Remove MAK by installing default Server 2012 Datacenter key
echo (After installing, Windows will run in grace activation mode)
echo Please wait...
slmgr /ipk 48HP8-DN98B-MYWDG-T2DCC-8W83P
goto start


:W7
echo ---------------------
echo You selected option 3
echo Remove MAK by installing default Windows 7 key
echo (After installing, Windows will run in grace activation mode)
echo Please wait...
slmgr /ipk FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4
goto start


:2008R2
echo ---------------------
echo You selected option 4
echo Reset Server 2008 R2 to default installation key
echo (After installing, Windows will run in grace activation mode)
echo Please wait...
slmgr /ipk YC6KT-GKW9T-YTKYR-T4X34-R7VHC
goto start


:KMS
echo ---------------------
echo You selected option 5
echo Sets the KMS server IP address
echo Please wait...
slmgr -skms kms2.ad.mmu.ac.uk
echo ---------------------
echo Attempts to activate windows with KMS server
echo Please wait...
slmgr -ato
echo ---------------------
echo Displays license/activation Status (verbose)
echo Please wait...
slmgr -dlv
goto exit


:rearm
echo ---------------------
echo You selected option 6
echo resets the 30 day grace activation period (can be done 3 times max.)
echo Please wait...
slmgr -rearm
goto exit


:status
echo ---------------------
echo You selected option 7
echo Displays license/activation Status (verbose)
echo Please wait...
slmgr -dlv
goto start


:O2010set
echo ---------------------
echo You selected option 8
echo Enables Office 2013 KMS activation
cscript "C:\Program Files (x86)\Microsoft Office\Office15\ospp.vbs" /sethst:kms2.ad.mmu.ac.uk
cscript "C:\Program Files (x86)\Microsoft Office\Office15\ospp.vbs" /osppsvcauto
pause
goto exit


:O2010stat
echo ---------------------
echo You selected option 9
echo Display Office 2010 KMS activation history
cscript "C:\Program Files (x86)\Microsoft Office\Office14\ospp.vbs" /dhistorykms
pause
goto start


:exit