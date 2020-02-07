; Author: Lâm Thành Nhân
; Version: 1.0.2

#include-once
#include <GDIPlus.au3>
#include <WinAPI.au3>
#include <WinAPIGdi.au3>
#include <Color.au3>

OnAutoItExitRegister("__HandleImgSearchShutdown")
Opt("WinTitleMatchMode", 1)

Global Const $__BMPSEARCHSRCCOPY 		= 0x00CC0020
Global $__HandleImgSearch_IsDebug 		= False

Global $_HandleImgSearch_BitmapHandle 	= 0

Global $_HandleImgSearch_HWnd 			= 0
Global $_HandleImgSearch_X 				= 0
Global $_HandleImgSearch_Y 				= 0
Global $_HandleImgSearch_Width 			= -1
Global $_HandleImgSearch_Height 		= -1
Global $_HandleImgSearch_IsUser32 		= False

_GDIPlus_Startup()

; ===============================================================================================================================
; Ảnh để tìm kiếm nên lưu dạng "24-bit Bitmap"
; ===============================================================================================================================

; #Global Functions# ============================================================================================================
; _GlobalImgInit($Hwnd = 0, $X = 0, $Y = 0, $Width = -1, $Height = -1)
; _GlobalImgCapture($Hwnd = 0)
; _GlobalGetBitmap()
; _GlobalImgSearchRandom($BmpLocal, $IsReCapture = False, $BmpSource = 0, $IsRandom = True)
; _GlobalImgSearch($BmpLocal, $IsReCapture = False, $BmpSource = 0, $maximg = 5000)
; _GlobalGetPixel($X, $Y, $IsReCapture = False, $BmpSource = 0)
; _GlobalPixelCompare($X, $Y, $PixelColor, $Tolerance = 20, $IsReCapture = False, $BmpSource = 0)

; #Local Functions# =============================================================================================================
; _HandleImgSearch($hwnd, $bmpLocal, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $maximg = 5000)
; _BmpImgSearch($SourceBmp, $FindBmp, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $maximg = 5000)
; _HandleGetPixel($hwnd, $getX, $getY, $x = 0, $y = 0, $Width = -1, $Height = -1)
; _HandlePixelCompare($hwnd, $getX, $getY, $pixelColor, $tolerance = 20, $x = 0, $y = 0, $Width = -1, $Height = -1)
; _HandleCapture($hwnd, $x = 0, $y = 0, $Width = -1, $Height = -1, $IsBMP = False, $SavePath = "", $IsUser32 = False)
; ===============================================================================================================================


; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalImgInit
; Description ...: Khai báo cho Global.
; Syntax ........: _GlobalImgInit([$Hwnd = 0[, $X = 0[, $Y = 0[, $Width = -1[, $Height = -1]]]]])
; Parameters ....: $Hwnd                - Handle của cửa sổ.
;                  $X, $Y, $Width, $Height 	- Vùng ảnh trong handle cần chụp. Mặc định là toàn ảnh chụp từ $hwnd.
;                  $IsUser32 				- Sử dụng DllCall User32.dll thay vì _WinAPI_BitBlt (Thử để tìm cái phù hợp).
; ===============================================================================================================================
Func _GlobalImgInit($Hwnd = 0, $X = 0, $Y = 0, $Width = -1, $Height = -1, $IsUser32 = False, $IsDebug = False)
	$_HandleImgSearch_HWnd 		= $Hwnd
	$_HandleImgSearch_X 		= $X
	$_HandleImgSearch_Y 		= $Y
	$_HandleImgSearch_Width 	= $Width
	$_HandleImgSearch_Height 	= $Height
	$_HandleImgSearch_IsUser32 	= $IsUser32
	$__HandleImgSearch_IsDebug 	= $IsDebug
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalImgCapture
; Description ...: Chụp ảnh Global.
; Syntax ........: _GlobalImgCapture([$Hwnd = 0])
; Parameters ....: $Hwnd                - Handle của cửa sổ nếu không dùng _GlobalImgInit để khai báo.
; Return values .: @error khác 0 nếu có lỗi. Trả về Handle của Bitmap đã chụp.
; ===============================================================================================================================
Func _GlobalImgCapture($Hwnd = 0)
	Local $Handle = $_HandleImgSearch_HWnd

	If $Hwnd <> 0 Then $Handle = $Hwnd
	If $Handle = 0 Then Return SetError(1, 0, 0)

	$_HandleImgSearch_BitmapHandle = _HandleCapture($Handle, _
		$_HandleImgSearch_X, _
		$_HandleImgSearch_Y, _
		$_HandleImgSearch_Width, _
		$_HandleImgSearch_Height, _
		True, _
		$__HandleImgSearch_IsDebug ? @ScriptDir & "\source.bmp" : "")
	Return SetError($_HandleImgSearch_BitmapHandle, 0, 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalGetBitmap
; Description ...: Trả về Handle của Bitmap của Global.
; Syntax ........: _GlobalGetBitmap()
; Parameters ....:
; Return values .: Handle của Bitmap đã khai báo
; ===============================================================================================================================
Func _GlobalGetBitmap()
	Return $_HandleImgSearch_BitmapHandle
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalImgSearchRandom
; Description ...: Trả về toạ độ ngẫu nhiên của ảnh đã tìm được (Chỉ trả về vị trí ảnh đầu tiên tìm được)
; Syntax ........: _GlobalImgSearchRandom($BmpLocal[, $IsReCapture = False[, $BmpSource = 0[, $IsRandom = True[, $maximg = 5000]]]])
; Parameters ....: $BmpLocal            - Đường dẫn của ảnh BMP cần tìm.
;                  $IsReCapture         - [optional] Chụp lại ảnh. Default is False.
;                  $BmpSource           - [optional] Handle của Bitmap nếu không sử dụng Global. Default is 0.
;                  $IsRandom            - [optional] True sẽ trả về toạ độ ngẫu nhiên của ảnh đã tìm được, False sẽ là $X, $Y. Default is True.
; Return values .: @error = 1 nếu có lỗi xảy ra. Trả về toạ độ ngẫu nhiên của ảnh đã tìm được($P[0] = $X, $P[1] = $Y).
; ===============================================================================================================================
Func _GlobalImgSearchRandom($BmpLocal, $IsReCapture = False, $BmpSource = 0, $IsRandom = True)
	Local $Pos = _GlobalImgSearch($BmpLocal, $IsReCapture, $BmpSource, 1)
	If @error Then
		Local $Result[2] = [-1, -1]
		Return SetError(1, 0, $Result)
	EndIf
	Local $Result[2] = [Random($Pos[1][0], $Pos[1][0] + $Pos[1][2], 1), Random($Pos[1][1], $Pos[1][1] + $Pos[1][3], 1)]
	If not $IsRandom Then
		Local $Result[2] = [$Pos[1][0], $Pos[1][1]]
	Else
		Local $Result[2] = [Random($Pos[1][0], $Pos[1][0] + $Pos[1][2], 1), Random($Pos[1][1], $Pos[1][1] + $Pos[1][3], 1)]
	EndIf

	Return SetError(0, 0, $Result)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalImgSearch
; Description ...: Tìm ảnh
; Syntax ........: _GlobalImgSearch($BmpLocal[, $IsReCapture = False[, $BmpSource = 0[, $maximg = 5000]]])
; Parameters ....: $BmpLocal            - Đường dẫn của ảnh BMP cần tìm.
;                  $IsReCapture         - [optional] Chụp lại ảnh. Default is False.
;                  $BmpSource           - [optional] Handle của Bitmap nếu không sử dụng Global. Default is 0.
;                  $maxing           	- [optional] Số lượng ảnh tối đa trả về. Default is 5000 (tối đa).
; Return values .: Thành công: Returns a 2d array with the following format:
;							$aCords[0][0]  		= Tổng số vị trí tìm được
;							$aCords[$i][0]		= Toạ độ X
;							$aCords[$i][1] 		= Toạ độ Y
;							$aCords[$i][2] 		= Width của bitmap
;							$aCords[$i][3] 		= Height của bitmap
;					Lỗi: @error khác 0
; ===============================================================================================================================
Func _GlobalImgSearch($BmpLocal, $IsReCapture = False, $BmpSource = 0, $maximg = 5000)
	Local $BMP24 = $_HandleImgSearch_BitmapHandle

	If $BmpSource <> 0 Then $BMP24 = $BmpSource
	If $BMP24 = 0 or $IsReCapture Then
		_GlobalImgCapture()
		If @error Then Return SetError(1, 0, 0)

		$BMP24 = $_HandleImgSearch_BitmapHandle
	EndIf


	Local $BMP = _GDIPlus_BitmapCloneArea($BMP24, 0, 0, _
					_GDIPlus_ImageGetWidth($BMP24), _
					_GDIPlus_ImageGetHeight($BMP24), _
					$GDIP_PXF04INDEXED)

	Local $Bitmap24 = _GDIPlus_BitmapCreateFromFile($BmpLocal)
	Local $Bitmap = _GDIPlus_BitmapCloneArea($Bitmap24, 0, 0, _
					_GDIPlus_ImageGetWidth($Bitmap24), _
					_GDIPlus_ImageGetHeight($Bitmap24), _
					$GDIP_PXF04INDEXED)
	_GDIPlus_BitmapDispose($Bitmap24)

	Local $hBMP = _GDIPlus_BitmapCreateHBITMAPFromBitmap($BMP)

	Local $hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($Bitmap)
	If $__HandleImgSearch_IsDebug Then _GDIPlus_ImageSaveToFile($Bitmap, @ScriptDir & "\find.bmp")

	Local $pos = _BmpSearch($hBMP, $hBitmap, $maximg)
	Local $Error = @error
	Local $Extended = @extended

	_WinAPI_DeleteObject($hBitmap)
	_GDIPlus_ImageDispose($Bitmap)
	_WinAPI_DeleteObject($hBMP)
	_GDIPlus_ImageDispose($BMP)

	If $Error Then
		Local $result[1][4] = [[0, 0, 0, 0]]
		Return SetError(1, 0, $result)
	EndIf
	Return SetError(0, $Extended, $pos)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalGetPixel
; Description ...:
; Syntax ........: _GlobalGetPixel($X, $Y[, $IsReCapture = False[, $BmpSource = 0]])
; Parameters ....: $X, $Y               - Toạ độ cần lấy màu.
;                  $IsReCapture         - [optional] Chụp lại ảnh. Default is False.
;                  $BmpSource           - [optional] Handle của Bitmap nếu không sử dụng Global. Default is 0.
; Return values .: @error = 1 nếu xảy ra lỗi. Trả về mã màu dạng 0xRRGGBB
; ===============================================================================================================================
Func _GlobalGetPixel($X, $Y, $IsReCapture = False, $BmpSource = 0)
	Local $BMP = $_HandleImgSearch_BitmapHandle
	If $BmpSource <> 0 Then $BMP = $BmpSource

	If $BMP = 0 Or $IsReCapture Then
		_GlobalImgCapture()
		If @error Then Return SetError(1, 0, 0)

		$BMP = $_HandleImgSearch_BitmapHandle
	EndIf

	Local $Result = _GDIPlus_BitmapGetPixel($BMP, $X, $Y)
	If @error Then Return SetError(1, 0, 0)

	Return SetError(0, 0, "0x" & Hex($Result, 6))
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalPixelCompare
; Description ...: So sánh mã màu tại vị trí $X, $Y với tolerance
; Syntax ........: _GlobalPixelCompare($X, $Y, $PixelColor[, $Tolerance = 20[, $IsReCapture = False[, $BmpSource = 0]]])
; Parameters ....: $X, $Y               - Toạ độ cần so sánh.
;                  $PixelColor          - Màu cần so sánh.
;                  $Tolerance           - [optional] Giá trị tolerance. Default is 20.
;                  $IsReCapture         - [optional] Chụp lại ảnh. Default is False.
;                  $BmpSource           - [optional] Handle của Bitmap nếu không sử dụng Global. Default is 0.
; Return values .: @error = 1 nếu xảy ra lỗi. Trả về True nếu tìm thấy, False nếu không tìm thấy.
; ===============================================================================================================================
Func _GlobalPixelCompare($X, $Y, $PixelColor, $Tolerance = 20, $IsReCapture = False, $BmpSource = 0)
	Local $PixelColorSource = _GlobalGetPixel($X, $Y, $IsReCapture, $BmpSource)
	If @error Then Return SetError(1, 0, 0)

	Return _ColorInBounds($PixelColorSource, $PixelColor, $Tolerance)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _HandleImgSearch
; Description ...:
; Syntax ........: _HandleImgSearch($hwnd, $bmpLocal[, $x = 0[, $y = 0[, $iWidth = -1[, $iHeight = -1[, $maximg = 5000]]]]])
; Parameters ....: $hwnd                		- Handle của cửa sổ cần chụp.
;                  $bmpLocal            		- Đường dẫn đến ảnh BMP cần tìm.
;                  $x, $y, $iWidth, $iHeight 	- Vùng tìm kiếm. Mặc định là toàn ảnh chụp từ $hwnd.
;                  $maximg              		- Số ảnh giống nhau tối đa.
; Return values .: Success: Returns a 2d array with the following format:
;							$aCords[0][0]  		= Tổng số vị trí tìm được
;							$aCords[$i][0]		= Toạ độ X
;							$aCords[$i][1] 		= Toạ độ Y
;							$aCords[$i][2] 		= Width của bitmap
;							$aCords[$i][3] 		= Height của bitmap
;
;					Failure: Returns 0 and sets @error to 1
; ===============================================================================================================================
Func _HandleImgSearch($hwnd, $bmpLocal, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $maximg = 5000)
	Local $BMP = _HandleCapture($hwnd, $x, $y, $iWidth, $iHeight, true, $__HandleImgSearch_IsDebug ? @ScriptDir & "\source.bmp" : "")
	If @error Then
		Local $result[1][4] = [[0, 0, 0, 0]]
		SetError(1, 0, $result)
	EndIf
	Local $hBMP = _GDIPlus_BitmapCreateHBITMAPFromBitmap($BMP)

	Local $Bitmap = _GDIPlus_BitmapCreateFromFile($bmpLocal)
	Local $hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($Bitmap)
	If $__HandleImgSearch_IsDebug Then _GDIPlus_ImageSaveToFile($Bitmap, @ScriptDir & "\find.bmp")

	Local $pos = _BmpSearch($hBMP, $hBitmap, $maximg)
	Local $Extended = @extended

	_WinAPI_DeleteObject($hBitmap)
	_GDIPlus_ImageDispose($Bitmap)
	_WinAPI_DeleteObject($hBMP)
	_GDIPlus_ImageDispose($BMP)

	If $pos = 0 Then
		Local $result[1][4] = [[0, 0, 0, 0]]
		Return SetError(1, 0, $result)
	EndIf
	Return SetError(0, $Extended, $pos)
EndFunc   ;==>_HandleImgSearch

; #FUNCTION# ====================================================================================================================
; Name ..........: _BmpImgSearch
; Description ...: Tìm ảnh Bmp trong Bmp
; Syntax ........: _BmpImgSearch($SourceBmp, $FindBmp[, $x = 0[, $y = 0[, $iWidth = -1[, $iHeight = -1[, $maximg = 5000]]]]])
; Parameters ....: $SourceBmp                	- Handle của Bitmap gốc hoặc đường dẫn đến ảnh BMP gốc.
;                  $FindBmp            			- Đường dẫn đến ảnh BMP cần tìm.
;                  $x, $y, $iWidth, $iHeight 	- Vùng tìm kiếm. Mặc định là toàn ảnh chụp từ $hwnd.
;                  $maximg              		- Số ảnh giống nhau tối đa.
; Return values .: Success: Returns a 2d array with the following format:
;							$aCords[0][0]  		= Tổng số vị trí tìm được
;							$aCords[$i][0]		= Toạ độ X
;							$aCords[$i][1] 		= Toạ độ Y
;							$aCords[$i][2] 		= Width của bitmap
;							$aCords[$i][3] 		= Height của bitmap
;
;					Failure: Returns 0 and sets @error to 1
; ===============================================================================================================================
Func _BmpImgSearch($SourceBmp, $FindBmp, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $maximg = 5000)
	Local $BMP = $SourceBmp
	If not IsHWnd($SourceBmp) Then
		$BMP = _GDIPlus_BitmapCreateFromFile($SourceBmp)
	EndIf
	Local $hBMP = _GDIPlus_BitmapCreateHBITMAPFromBitmap($BMP)
	If $__HandleImgSearch_IsDebug Then _GDIPlus_ImageSaveToFile($BMP, @ScriptDir & "\source.bmp")

	Local $Bitmap = _GDIPlus_BitmapCreateFromFile($FindBmp)
	Local $hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($Bitmap)
	If $__HandleImgSearch_IsDebug Then _GDIPlus_ImageSaveToFile($Bitmap, @ScriptDir & "\find.bmp")

	Local $pos = _BmpSearch($hBMP, $hBitmap, $maximg)
	Local $Extended = @extended

	_WinAPI_DeleteObject($hBitmap)
	_GDIPlus_ImageDispose($Bitmap)
	_WinAPI_DeleteObject($hBMP)
	_GDIPlus_ImageDispose($BMP)

	If $pos = 0 Then
		Local $result[1][4] = [[0, 0, 0, 0]]
		Return SetError(1, 0, $result)
	EndIf
	Return SetError(0, $Extended, $pos)
EndFunc   ;==>_BmpImgSearch

; #FUNCTION# ====================================================================================================================
; Name ..........: _HandleGetPixel
; Description ...: Lấy mã màu tại toạ độ nhất định của ảnh
; Syntax ........: _HandleGetPixel($hwnd, $getX, $getY[, $x = 0[, $y = 0[, $Width = -1[, $Height = -1]]]])
; Parameters ....: $hwnd                		- a handle value.
;                  $getX, $getY               	- Toạ độ cần lấy màu.
;                  $x, $y, $iWidth, $iHeight 	- Vùng ảnh trong handle cần chụp. Mặc định là toàn ảnh chụp từ $hwnd.
; Return values .: @error = 1 nếu có lỗi xảy ra.
; Author ........: Lâm Thành Nhân
; ===============================================================================================================================
Func _HandleGetPixel($hwnd, $getX, $getY, $x = 0, $y = 0, $Width = -1, $Height = -1)
	Local $BMP = _HandleCapture($hwnd, $x, $y, $Width, $Height, $__HandleImgSearch_IsDebug ? @ScriptDir & "\source.bmp" : "", True)
	If @error Then
		Local $result[1][4] = [[0, 0, 0, 0]]
		SetError(1, 0, $result)
	EndIf

	Local $result = _GDIPlus_BitmapGetPixel($BMP, $getX, $getY)
	_GDIPlus_ImageDispose($BMP)

	Return SetError(0, 0, "0x" & Hex($result, 6))
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _HandlePixelCompare
; Description ...: So sánh màu điểm ảnh với tolerance
; Syntax ........: _HandlePixelCompare($hwnd, $getX, $getY, $pixelColor[, $x = 0[, $y = 0[, $Width = -1[, $Height = -1]]]])
; Parameters ....: $hwnd                		- a handle value.
;                  $getX, $getY               	- Toạ độ cần lấy màu.
;                  $pixelColor          		- Mã màu cần so sánh.
;                  $x, $y, $iWidth, $iHeight 	- Vùng ảnh trong handle cần chụp. Mặc định là toàn ảnh chụp từ $hwnd.
; Return values .: None
; ===============================================================================================================================
Func _HandlePixelCompare($hwnd, $getX, $getY, $pixelColor, $tolerance = 20, $x = 0, $y = 0, $Width = -1, $Height = -1)
	Local $BMP = _HandleCapture($hwnd, $x, $y, $Width, $Height, $__HandleImgSearch_IsDebug ? @ScriptDir & "\source.bmp" : "", True)
	If @error Then
		Local $result[1][4] = [[0, 0, 0, 0]]
		SetError(1, 0, $result)
	EndIf

	Local $result = _GDIPlus_BitmapGetPixel($BMP, $getX, $getY)
	_GDIPlus_ImageDispose($BMP)

	Return SetError(0, 0, _ColorInBounds($pixelColor, "0x" & Hex($result, 6), $tolerance))
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _HandleCapture
; Description ...:
; Syntax ........: _HandleCapture($hwnd [, $x = 0 [, $y = 0 [, $Width = -1 [, $Height = -1 [, $SavePath = "" [, $IsBMP = False]]]]]])
; Parameters ....: $hwnd                		- Handle của cửa sổ cần chụp.
;                  $x, $y, $iWidth, $iHeight 	- Vùng ảnh trong handle cần chụp. Mặc định là toàn ảnh chụp từ $hwnd.
;                  $SavePath            		- Đường dẫn lưu ảnh.
;                  $IsBMP               		- True: Kết quả trả về là Bitmap.
;												- False: Kết quả trả về là HBitmap.[Mặc định]
;				   $IsUser32					- Sử dụng User32.dll thay vì _WinAPI_BitBlt (Thử để tìm tuỳ chọn phù hợp)
; ===============================================================================================================================
Func _HandleCapture($hwnd, $x = 0, $y = 0, $Width = -1, $Height = -1, $IsBMP = False, $SavePath = "")
	If Not IsHWnd($hwnd) Then $hwnd = HWnd($hwnd)
	If @error Then
		$hwnd = WinGetHandle($hwnd)
		If @error Then
			ConsoleWrite("! _HandleCapture error: Handle error!")
			Return SetError(1, 0, 0)
		EndIf
	EndIf

	Local $hDC = _WinAPI_GetDC($hwnd)
	Local $hCDC = _WinAPI_CreateCompatibleDC($hDC)
	If $Width = -1 Then $Width = _WinAPI_GetWindowWidth($hwnd)
	If $Height = -1 Then $Height = _WinAPI_GetWindowHeight($hwnd)
	Local $hBMP = _WinAPI_CreateCompatibleBitmap($hDC, $Width, $Height)
	_WinAPI_SelectObject($hCDC, $hBMP)
	If $_HandleImgSearch_IsUser32 Then
		DllCall("User32.dll", "int", "PrintWindow", "hwnd", $hwnd, "hwnd", $hCDC, "int", 0)
	Else
		_WinAPI_BitBlt($hCDC, 0, 0, $Width, $Height, $hDC, $x, $y, $__BMPSEARCHSRCCOPY)
	EndIf
	Local $BMP = _GDIPlus_BitmapCreateFromHBITMAP($hBMP)
	_WinAPI_DeleteObject($hBMP)

	If $__HandleImgSearch_IsDebug Then
		_GDIPlus_ImageSaveToFile($BMP, $SavePath = "" ? @ScriptDir & "\HandleCaptue.bmp" : $SavePath)
	EndIf

	_WinAPI_ReleaseDC($hwnd, $hDC)
	_WinAPI_DeleteDC($hCDC)

	If $IsBMP Then Return $BMP

	Local $hBMP = _GDIPlus_BitmapCreateHBITMAPFromBitmap($BMP)
	_GDIPlus_BitmapDispose($BMP)

	Return $hBMP
EndFunc   ;==>_HandleCapture

#Region Internal Functions
Func __HandleImgSearchShutdown()
	_GDIPlus_ImageDispose($_HandleImgSearch_BitmapHandle)
	_GDIPlus_Shutdown()
EndFunc   ;==>__ShutdownGDIPlus

;Author: jvanegmond
Func _ColorInBounds($pMColor, $pTColor, $pVariation)
    Local $lMCBlue = _ColorGetBlue($pMColor)
    Local $lMCGreen = _ColorGetGreen($pMColor)
    Local $lMCRed = _ColorGetRed($pMColor)

    Local $lTCBlue = _ColorGetBlue($pTColor)
    Local $lTCGreen = _ColorGetGreen($pTColor)
    Local $lTCRed = _ColorGetRed($pTColor)

    Local $a = Abs($lMCBlue - $lTCBlue)
    Local $b = Abs($lMCGreen - $lTCGreen)
	Local $c = Abs($lMCRed - $lTCRed)

    If ( ( $a < $pVariation ) AND ( $b < $pVariation ) AND ( $c < $pVariation ) ) Then
        Return True
    Else
        Return False
    EndIf
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _BmpSearch
; Description ...: Searches for Bitmap in a Bitmap
; Syntax ........: _BmpSearch($hSource, $hFind, $iMax=5000)
; Parameters ....: $hSource             - Handle to bitmap to search
;                  $hFind               - Handle to bitmap to find
;                  $iMax               	- Max matches to find
; Return values .: Success: Returns a 2d array with the following format:
;							$aCords[0][0] = Total Matches found
;							$aCords[$i][0] = Width of bitmap
;							$aCords[$i][1] = Hight of bitmap
;							$aCords[$i][2] = X cordinate
;							$aCords[$i][3] = Y cordinate
;
;					Failure: Returns 0 and sets @error to 1
;
; Author ........: Brian J Christy (Beege)
; ===============================================================================================================================
Func _BmpSearch($hSource, $hFind, $iMax = 5000)

	Static Local $aMemBuff, $tMem, $fStartup = True

	If $fStartup Then
		;####### (BinaryStrLen = 490) #### (Base64StrLen = 328 )####################################################################################################
		Local $Opcode = 'yBAAAFCNRfyJRfSNRfiJRfBYx0X8AAAAAItVDP8yj0X4i10Ii0UYKdiZuQQAAAD38YnBi0X4OQN0CoPDBOL36akAAACDfSgAdB1TA10oO10YD4OVAAAAi1UkORN1A1vrBluDwwTrvVOLVSyLRTADGjtdGHd3iwg5C3UhA1oEi0gEO10Yd2Y5C3USA1oIi0gIO10Yc1c5' & _
				'C3UDW+sGW4PDBOuCi1UUid6LfQyLTRCJ2AHIO0UYczfzp4P5AHcLSoP6AHQNA3Uc6+KDwwTpVP///4tFIIkYg0UgBIPDBP9F/ItVNDlV/HQG6Tj///9bi0X8ycIwAA=='

		Local $aDecode = DllCall("Crypt32.dll", "bool", "CryptStringToBinary", "str", $Opcode, "dword", 0, "dword", 1, "struct*", DllStructCreate("byte[254]"), "dword*", 254, "ptr", 0, "ptr", 0)
		If @error Or (Not $aDecode[0]) Then Return SetError(1, 0, 0)
		$Opcode = BinaryMid(DllStructGetData($aDecode[4], 1), 1, $aDecode[5])

		$aMemBuff = DllCall("kernel32.dll", "ptr", "VirtualAlloc", "ptr", 0, "ulong_ptr", BinaryLen($Opcode), "dword", 4096, "dword", 64)
		$tMem = DllStructCreate('byte[' & BinaryLen($Opcode) & ']', $aMemBuff[0])
		DllStructSetData($tMem, 1, $Opcode)
		;####################################################################################################################################################################################
		$fStartup = False
	EndIf

	Local $iTime = TimerInit()

	Local $tSizeSource = _WinAPI_GetBitmapDimension($hSource)
	Local $tSizeFind = _WinAPI_GetBitmapDimension($hFind)

	Local $iRowInc = (DllStructGetData($tSizeSource, 'X') - DllStructGetData($tSizeFind, 'X')) * 4

	Local $tSource = _GetBmpPixelStruct($hSource)
	Local $tFind = _GetBmpPixelStruct($hFind)

	Local $aFD = _FindFirstDiff($tFind)
	Local $iFirstDiffIdx = $aFD[0]
	Local $iFirstDiffPix = $aFD[1]

	Local $iFirst_Diff_Inc = _FirstDiffInc($iFirstDiffIdx, DllStructGetData($tSizeFind, 'X'), DllStructGetData($tSizeSource, 'X'))
	If $iFirst_Diff_Inc < 0 Then $iFirst_Diff_Inc = 0

	Local $tCornerPixs = _CornerPixs($tFind, DllStructGetData($tSizeFind, 'X'), DllStructGetData($tSizeFind, 'Y'))
	Local $tCornerInc = _CornerInc(DllStructGetData($tSizeFind, 'X'), DllStructGetData($tSizeFind, 'Y'), DllStructGetData($tSizeSource, 'X'))

	Local $pStart = DllStructGetPtr($tSource)
	Local $iEndAddress = Int($pStart + DllStructGetSize($tSource))

	Local $tFound = DllStructCreate('dword[' & $iMax & ']')

	Local $ret = DllCallAddress('dword', DllStructGetPtr($tMem), 'struct*', $tSource, 'struct*', $tFind, _
			'dword', DllStructGetData($tSizeFind, 'X'), 'dword', DllStructGetData($tSizeFind, 'Y'), _
			'dword', $iEndAddress, 'dword', $iRowInc, 'struct*', $tFound, _
			'dword', $iFirstDiffPix, 'dword', $iFirst_Diff_Inc, _
			'struct*', $tCornerInc, 'struct*', $tCornerPixs, _
			'dword', $iMax)

	_WinAPI_DeleteObject($hSource)
	_WinAPI_DeleteObject($hFind)
	_WinAPI_EmptyWorkingSet()



	If Not $ret[0] Then Return SetError(1, 0, 0)

;~    Local $aCords = _GetCordsArray($ret[0], $tFound, DllStructGetData($tSizeSource, 'X'), $pStart, DllStructGetData($tSizeFind, 'X'), DllStructGetData($tSizeFind, 'Y'))
	Local $aCords = _GetCordsArray($ret[0], $tFound, DllStructGetData($tSizeSource, 'X'), $pStart, DllStructGetData($tSizeFind, 'X'), DllStructGetData($tSizeFind, 'Y'))
	Return SetError(0, TimerDiff($iTime) / 1000, $aCords)
EndFunc   ;==>_BmpSearch

;Returns a Dllstructure will all pixels
Func _GetBmpPixelStruct($hBMP)

	Local $tSize = _WinAPI_GetBitmapDimension($hBMP)
	Local $tBits = DllStructCreate('dword[' & (DllStructGetData($tSize, 'X') * DllStructGetData($tSize, 'Y')) & ']')

	_WinAPI_GetBitmapBits($hBMP, DllStructGetSize($tBits), DllStructGetPtr($tBits))

	Return $tBits

#Tidy_Off
#cs

	This is how the dllstructure index numbers correspond to the pixel cordinates:

	An 5x5 dimension bmp:
		X0	X1	X2	X3	X4
	Y0 	1   2	3	4	5
	Y1	6	7	8	9	10
	Y2	11	12	13	14	15
	Y3	16	17	18	19	20
	Y4	21	22	23	24	25

	An 8x8 dimension bmp:
		X0	X1	X2	X3	X4	X5	X6	X7
	Y0	1	2	3	4	5	6	7	8
	Y1	9	10	11	12	13	14	15	16
	Y2	17	18	19	20	21	22	23	24
	Y3	25	26	27	28	29	30	31	32
	Y4	33	34	35	36	37	38	39	40
	Y5	41	42	43	44	45	46	47	48
	Y6	49	50	51	52	53	54	55	56
	Y7	57	58	59	60	61	62	63	64

#ce
#Tidy_On

EndFunc   ;==>_GetBmpPixelStruct

;Find first pixel that is diffrent than ....the first pixel
Func _FindFirstDiff($tPix)

	;####### (BinaryStrLen = 106) ########################################################################################################################
	Static Local $Opcode = '0xC80000008B5D0C8B1383C3048B4D103913750C83C304E2F7B800000000EB118B5508FF338F028B451029C883C002EB00C9C20C00'
	Static Local $aMemBuff = DllCall("kernel32.dll", "ptr", "VirtualAlloc", "ptr", 0, "ulong_ptr", BinaryLen($Opcode), "dword", 4096, "dword", 64)
	Static Local $tMem = DllStructCreate('byte[' & BinaryLen($Opcode) & ']', $aMemBuff[0])
	Static Local $fSet = DllStructSetData($tMem, 1, $Opcode)
	;#####################################################################################################################################################

	Local $iMaxLoops = (DllStructGetSize($tPix) / 4) - 1
	Local $aRet = DllCallAddress('dword', DllStructGetPtr($tMem), 'dword*', 0, 'struct*', $tPix, 'dword', $iMaxLoops)

	Return $aRet

EndFunc   ;==>_FindFirstDiff

; Calculates the value to increase pointer by to check first different pixel
Func _FirstDiffInc($iDx, $iFind_Xmax, $iSource_Xmax)

	Local $aFirstDiffCords = _IdxToCords($iDx, $iFind_Xmax)
	Local $iXDiff = ($iDx - ($aFirstDiffCords[1] * $iFind_Xmax)) - 1

	Return (($aFirstDiffCords[1] * $iSource_Xmax) + $iXDiff) * 4

EndFunc   ;==>_FirstDiffInc

;Converts the pointer addresses to cordinates
Func _GetCordsArray($iTotalFound, $tFound, $iSource_Xmax, $pSource, $iFind_Xmax, $iFind_Ymax)

	Local $aRet[$iTotalFound + 1][4]
	$aRet[0][0] = $iTotalFound

	For $i = 1 To $iTotalFound
		$iFoundIndex = ((DllStructGetData($tFound, 1, $i) - $pSource) / 4) + 1
		$aRet[$i][1] = Int(($iFoundIndex - 1) / $iSource_Xmax) ; Y
		$aRet[$i][0] = ($iFoundIndex - 1) - ($aRet[$i][1] * $iSource_Xmax) ; X
		$aRet[$i][2] = $iFind_Xmax
		$aRet[$i][3] = $iFind_Ymax
	Next

	Return $aRet

EndFunc   ;==>_GetCordsArray

;converts cordinates to dllstructure index number
Func _CordsToIdx($iX, $iY, $iMaxX)
	Return ($iY * $iMaxX) + $iX + 1
EndFunc   ;==>_CordsToIdx

;convert dllstructure index number to cordinates
Func _IdxToCords($iDx, $iMaxX)

	Local $aCords[2]
	$aCords[1] = Int(($iDx - 1) / $iMaxX) ; Y
	$aCords[0] = ($iDx - 1) - ($aCords[1] * $iMaxX) ; X

	Return $aCords

EndFunc   ;==>_IdxToCords

;Retrieves the Pixel Values of Right Top, Left Bottom, Right Bottom. Returns dllstructure
Func _CornerPixs(ByRef $tFind, $iFind_Xmax, $iFind_Ymax)

	Local $tCornerPixs = DllStructCreate('dword[3]')

	DllStructSetData($tCornerPixs, 1, DllStructGetData($tFind, 1, $iFind_Xmax), 1) ; top right corner
	DllStructSetData($tCornerPixs, 1, DllStructGetData($tFind, 1, ($iFind_Xmax + ($iFind_Xmax * ($iFind_Ymax - 2)) + 1)), 2) ;  bottom left corner
	DllStructSetData($tCornerPixs, 1, DllStructGetData($tFind, 1, ($iFind_Xmax * $iFind_Ymax)), 3) ;	bottom right corner

	Return $tCornerPixs

EndFunc   ;==>_CornerPixs

;Retrieves the pointer adjust values for Right Top, Left Bottom, Right Bottom. Returns dllstructure
Func _CornerInc($iFind_Xmax, $iFind_Ymax, $iSource_Xmax)

	Local $tCornerInc = DllStructCreate('dword[3]')

	DllStructSetData($tCornerInc, 1, ($iFind_Xmax - 1) * 4, 1)
	DllStructSetData($tCornerInc, 1, (($iSource_Xmax - $iFind_Xmax) + $iSource_Xmax * ($iFind_Ymax - 2) + 1) * 4, 2)
	DllStructSetData($tCornerInc, 1, ($iFind_Xmax - 1) * 4, 3)

	Return $tCornerInc

EndFunc   ;==>_CornerInc
#EndRegion Internal Functions
