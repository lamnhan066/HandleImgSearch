; Author: Lâm Thành Nhân
; Email: ltnhanst94@gmail.com
; ===============================================================================================================================
; Ảnh để tìm kiếm nên lưu dạng "24-bit Bitmap"
; ===============================================================================================================================
; Ví dụ tìm kiếm theo CLASSNN của Nox
; ===============================================================================================================================


#include <Array.au3>
#include "HandleImgSearch.au3"

Local $WindowHandle = ControlGetHandle("NoxPlayer", "", "[CLASSNN:Qt5QWindowIcon5]")

;Test Global Functions
;~ _TestGlobal(100)
_TestGlobal(100, $WindowHandle)

;Test Handle Functions
;~ _TestHandle(100)
_TestHandle(100, $WindowHandle)

Func _TestGlobal($Count, $Handle = "")
	ConsoleWrite("! Test Global Functions" & @CRLF)
	; Init
	_GlobalImgInit($Handle, 0, 0, -1, -1, False, False, 15 , 1000)
	
	Local $Result
	For $i = 1 to $Count
		_GlobalImgCapture()
	
		$Result = _GlobalImgSearchRandom(@ScriptDir & "\Images\NoxBrowser.bmp")
		If not @error Then
			ConsoleWrite("_GlobalImgSearchRandom: " & $Result[0] &" - " & $Result[1] & @CRLF)
		Else
			ConsoleWrite("_GlobalImgSearchRandom: Fail" & @CRLF)
		EndIf
	
		ConsoleWrite("_GlobalGetBitmap: " &  _GlobalGetBitmap() & @CRLF)
	
		$Result = _GlobalImgSearch(@ScriptDir & "\Images\NoxBrowser.bmp")
		If not @error Then
			ConsoleWrite("_GlobalImgSearch: (Total: " & $Result[0][0] & "): " & $Result[1][0] &" - " & $Result[1][1] & @CRLF)
		Else
			ConsoleWrite("_GlobalImgSearch: Fail" & @CRLF)
		EndIf
	
		$Result = _GlobalGetPixel(100, 100)
		If not @error Then
			ConsoleWrite("_GlobalGetPixel: " & $Result & @CRLF)
		Else
			ConsoleWrite("_GlobalGetPixel: Fail" & @CRLF)
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
		$Result = _HandleImgSearch($Handle, @ScriptDir & "\Images\NoxBrowser.bmp", 0, 0, -1, -1, 15, 1000)
	
		If not @error Then
			ConsoleWrite("_HandleImgSearch (Total: " & $Result[0][0] & "): " & $Result[1][0] &" - " & $Result[1][1] & @CRLF)
		Else
			ConsoleWrite("_HandleImgSearch: Fail" & @CRLF)
		EndIf
	
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