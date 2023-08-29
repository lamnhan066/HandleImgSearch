; Author: Lâm Thành Nhân
; Email: lamnhan066@gmail.com
; ===============================================================================================================================
; Images to search should be saved as "24-bit Bitmap"
; ===============================================================================================================================
; For instance, searching based on the CLASSNN of Nox.
; ===============================================================================================================================


#include <Array.au3>
#include "..\HandleImgSearch.au3"

HotKeySet("{F1}", "_Test")
HotKeySet("{Esc}", "_Exit")

$_HandleImgSearch_IsDebug = true

Local $Handle = WinGetHandle(@ScriptDir)
While 1
	Sleep(10)
WEnd

Func _Test()
	_TestHandle(1, $Handle)
EndFunc

Func _Exit()
	Exit
EndFunc

Func _TestGlobal($Count, $Handle = "")
	ConsoleWrite("! Test Global Functions" & @CRLF)
	; Init
	_GlobalImgInit($Handle, 0, 0, -1, -1, False, true, 0, 0, 1)

	Local $Result
	For $i = 1 to $Count
		_GlobalImgCapture()

		$Result = _GlobalImgSearchRandom(@ScriptDir & "\Images\test.bmp")
		If not @error Then
			ConsoleWrite("_GlobalImgSearchRandom: " & $Result[0] &" - " & $Result[1] & @CRLF)
		Else
			ConsoleWrite("_GlobalImgSearchRandom: Fail" & @CRLF)
		EndIf

		ConsoleWrite("_GlobalGetBitmap: " &  _GlobalGetBitmap() & @CRLF)

		$Result = _GlobalImgSearch(@ScriptDir & "\Images\NoxBrowser.bmp")
		If not @error Then
			_ArrayDisplay($Result)
			ConsoleWrite("_GlobalImgSearch: (Total: " & $Result[0][0] & "): " & $Result[1][0] &" - " & $Result[1][1] & @CRLF)
		Else
			ConsoleWrite("_GlobalImgSearch: Fail" & @CRLF)
		EndIf

		$Result = _GlobalGetPixel(100, 100)
		If not @error Then
			ConsoleWrite("_GlobalGetPixel1: " & $Result & @CRLF)
		Else
			ConsoleWrite("_GlobalGetPixel1: Fail" & @CRLF)
		EndIf
		$Result = _GlobalGetPixel(101, 101)
		If not @error Then
			ConsoleWrite("_GlobalGetPixel2: " & $Result & @CRLF)
		Else
			ConsoleWrite("_GlobalGetPixel2: Fail" & @CRLF)
		EndIf
		$Result = _GlobalGetPixel(102, 102)
		If not @error Then
			ConsoleWrite("_GlobalGetPixel3: " & $Result & @CRLF)
		Else
			ConsoleWrite("_GlobalGetPixel3: Fail" & @CRLF)
		EndIf

		$Result = _GlobalPixelCompare(100, 100, 20)
		If not @error Then
			ConsoleWrite("_GlobalPixelCompare: " & $Result & @CRLF)
		Else
			ConsoleWrite("_GlobalPixelCompare: Fail" & @CRLF)
		EndIf

		Sleep(10)
	Next
EndFunc

Func _TestHandle($Count, $Handle = "")
	ConsoleWrite("! Test Local Functions" & @CRLF)
	; Use for debug mode
	$_HandleImgSearch_IsDebug = True
	; Test Local Functions

	Local $Result
	For $i = 1 to $Count
		$Result = _HandleImgSearch($Handle, @ScriptDir & "\Images\test.bmp", 0, 0, -1, -1, 50, "000000", 10)
		If not @error Then
			_ArrayDisplay($Result, "_HandleImgSearch")
			ConsoleWrite("_HandleImgSearch (Total: " & $Result[0][0] & "): " & $Result[1][0] &" - " & $Result[1][1] & @CRLF)
		Else
			ConsoleWrite("_HandleImgSearch: Fail" & @CRLF)
		EndIf

;~ 		$Result = _HandleImgWaitExist($Handle, @ScriptDir & "\Images\testWindowFolderTitle.png", 3, 0, 0, -1, -1, 15, 0xFFFFFF, 1000)
;~ 		If not @error Then
;~ 			_ArrayDisplay($Result, "_HandleImgWaitExist")
;~ 			ConsoleWrite("_HandleImgWaitExist (Total: " & $Result[0][0] & "): " & $Result[1][0] &" - " & $Result[1][1] & @CRLF)
;~ 		Else
;~ 			ConsoleWrite("_HandleImgWaitExist: Fail" & @CRLF)
;~ 		EndIf

		$Result = _HandleGetPixel($Handle, 100, 100)
		If not @error Then
			ConsoleWrite("_HandleGetPixel: " & $Result & @CRLF)
		Else
			ConsoleWrite("_HandleGetPixel: Fail" & @CRLF)
		EndIf

		$Result = _HandlePixelCompare($Handle, 100, 100, 20)
		If not @error Then
			ConsoleWrite("_HandlePixelCompare: " & $Result & @CRLF)
		Else
			ConsoleWrite("_HandlePixelCompare: Fail" & @CRLF)
		EndIf

		Sleep(10)
	Next
EndFunc