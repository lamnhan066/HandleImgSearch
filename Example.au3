; Author: Lâm Thành Nhân
; ===============================================================================================================================
; Ảnh để tìm kiếm nên lưu dạng "24-bit Bitmap"
; ===============================================================================================================================
; Ví dụ tìm kiếm theo CLASSNN của Nox
; ===============================================================================================================================

#include "HandleImgSearch.au3"
#include <Array.au3>

Local $Handle = ControlGetHandle("NoxPlayer", "", "[CLASSNN:Qt5QWindowIcon5]")

;Test Global Functions
ConsoleWrite("! Test Global Functions" & @CRLF)
_GlobalImgInit($Handle, 0, 0, -1, -1, False, True)

Local $Result
While 1
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
		ConsoleWrite("_GlobalImgSearch: " & $Result[1][0] &" - " & $Result[1][1] & @CRLF)
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

	Sleep(100)
	ExitLoop
WEnd

ConsoleWrite(@CRLF)
ConsoleWrite("! Test Local Functions" & @CRLF)
; Test Local Functions
While 1
	$Result = _HandleImgSearch($Handle, @ScriptDir & "\Images\NoxBrowser.bmp")
	If not @error Then
		ConsoleWrite("_HandleImgSearch: " & $Result[1][0] &" - " & $Result[1][1] & @CRLF)
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

	Sleep(100)
	ExitLoop
WEnd


