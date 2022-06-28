; Author: Lâm Thành Nhân
; Version: 2.0.0
; Email: lamnhan066@gmail.com
; Base on
; - ImageSearchDLL (Author: kangkeng 2008)
; - MemoryCall (Author: Joachim Bauch)
; - BinaryCall (Author: Ward)

#include-once
#include <GDIPlus.au3>
#include <WinAPI.au3>
#include <WinAPIGdi.au3>
#include <Color.au3>
#include <ScreenCapture.au3>
#include "Includes\BinaryCall.au3"
#include "Includes\MemoryDll.au3"

OnAutoItExitRegister("__HandleImgSearch_Shutdown")
Opt("WinTitleMatchMode", 1) ; ;1=start, 2=subStr, 3=exact, 4=advanced, -1 to -4=Nocase

Global Const $__BMPSEARCHSRCCOPY 		= 0x00CC0020

Global $_HandleImgSearch_BitmapHandle	= 0

Global $_HandleImgSearch_HWnd 			= ""
Global $_HandleImgSearch_X				= 0
Global $_HandleImgSearch_Y				= 0
Global $_HandleImgSearch_Width 			= -1
Global $_HandleImgSearch_Height 		= -1
Global $_HandleImgSearch_IsDebug 		= False
Global $_HandleImgSearch_IsUser32 		= False
Global $_HandleImgSearch_Tolerance		= 15
Global $_HandleImgSearch_Transparency	= ""
Global $_HandleImgSearch_MaxImg			= 1000

Global $__BinaryCall_Kernel32dll
Global $__BinaryCall_Msvcrtdll
Global $__HandleImgSearch_Opcode32
Global $__HandleImgSearch_Opcode64
Global $__HandleImgSearch_MemoryDll

; ===============================================================================================================================
; Ảnh để tìm kiếm nên lưu dạng "24-bit Bitmap".
; ===============================================================================================================================

; #Global Functions# ============================================================================================================
; _GlobalImgInit($Hwnd, $X = 0, $Y = 0, $Width = -1, $Height = -1, $IsUser32 = False, $IsDebug = False, $Tolerance = 15, $Transparency = "", $MaxImg = 1000)
; _GlobalImgCapture($Hwnd = 0)
; _GlobalGetBitmap()
; _GlobalImgSearchRandom($BmpLocal, $IsReCapture = False, $BmpSource = 0, $IsRandom = True, $Tolerance = $_HandleImgSearch_Tolerance, $Transparency = $_HandleImgSearch_Transparency, $MaxImg = $_HandleImgSearch_MaxImg)
; _GlobalImgSearch($BmpLocal, $IsReCapture = False, $BmpSource = 0, $Tolerance = $_HandleImgSearch_Tolerance, $Transparency = $_HandleImgSearch_Transparency, $MaxImg = $_HandleImgSearch_MaxImg)
; _GlobalImgWaitExist($BmpLocal, $TimeOutSecs = 5, $Tolerance = $_HandleImgSearch_Tolerance, $Transparency = $_HandleImgSearch_Transparency, $MaxImg = $_HandleImgSearch_MaxImg)
; _GlobalGetPixel($X, $Y, $IsReCapture = False, $BmpSource = 0)
; _GlobalPixelCompare($X, $Y, $PixelColor, $Tolerance = $_HandleImgSearch_Tolerance, $IsReCapture = False, $BmpSource = 0)

; #Local Functions# =============================================================================================================
; _HandleImgSearch($hwnd, $bmpLocal, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $Tolerance = 15, $Transparency = "", $MaxImg = 1000)
; _HandleImgWaitExist($hwnd, $bmpLocal, $timeOutSecs = 5, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $Tolerance = 15, $Transparency = "", $MaxImg = 1000)
; _BmpImgSearch($SourceBmp, $FindBmp, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $Tolerance = 15, $Transparency = "", $MaxImg = 1000)
; _HandleGetPixel($hwnd, $getX, $getY, $x = 0, $y = 0, $Width = -1, $Height = -1)
; _HandlePixelCompare($hwnd, $getX, $getY, $pixelColor, $tolerance = 15, $x = 0, $y = 0, $Width = -1, $Height = -1)
; _HandleCapture($hwnd, $x = 0, $y = 0, $Width = -1, $Height = -1, $IsBMP = False, $SavePath = "", $IsUser32 = False)
; ===============================================================================================================================


; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalImgInit
; Description ...:	Khởi tạo cho global
; Syntax ........: _GlobalImgInit
; Parameters ....: $Hwnd                	- [optional] Handle của cửa sổ.
;                  $X, $Y, $Width, $Height 	- Vùng ảnh trong handle cần chụp. Mặc định là toàn ảnh chụp từ $hwnd.
;                  $IsUser32            	- [optional] Sử dụng DllCall User32.dll thay vì _WinAPI_BitBlt (Thử để tìm cái phù hợp).. Default is False.
;                  $IsDebug             	- [optional] Cho phép Debug. Default is False.
;                  $Tolerance           	- [optional] Giá trị sai số màu. Default is 15.
;                  $MaxImg	           		- [optional] Số ảnh tối đa để tìm kiếm. Default is 15.
; ===============================================================================================================================
Func _GlobalImgInit($Hwnd = $_HandleImgSearch_HWnd, _
		$X = $_HandleImgSearch_X, _
		$Y = $_HandleImgSearch_Y, _
		$Width = $_HandleImgSearch_Width, _
		$Height = $_HandleImgSearch_Height, _
		$IsUser32 = $_HandleImgSearch_IsUser32, _
		$IsDebug = $_HandleImgSearch_IsDebug, _
		$Tolerance = $_HandleImgSearch_Tolerance, _
		$Transparency = $_HandleImgSearch_Transparency, _
		$MaxImg = $_HandleImgSearch_MaxImg)
	$_HandleImgSearch_HWnd 		= $Hwnd
	$_HandleImgSearch_X 		= $X
	$_HandleImgSearch_Y 		= $Y
	$_HandleImgSearch_Width 	= $Width
	$_HandleImgSearch_Height 	= $Height
	$_HandleImgSearch_IsUser32 	= $IsUser32
	$_HandleImgSearch_IsDebug 	= $IsDebug
	$_HandleImgSearch_Tolerance = $Tolerance
	$_HandleImgSearch_Transparency = $Transparency
	$_HandleImgSearch_MaxImg	= $MaxImg
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
	If not IsHWnd($Handle) and $Handle <> "" Then
		Return SetError(1, 0, 0)
	EndIf

	If $_HandleImgSearch_BitmapHandle <> 0 Then
		_GDIPlus_ImageDispose($_HandleImgSearch_BitmapHandle)
		$_HandleImgSearch_BitmapHandle = 0
	EndIf

	$_HandleImgSearch_BitmapHandle = _HandleCapture($Handle, _
		$_HandleImgSearch_X, _
		$_HandleImgSearch_Y, _
		$_HandleImgSearch_Width, _
		$_HandleImgSearch_Height, _
		True, _
		"", _
		$_HandleImgSearch_IsUser32)
	If @error Then Return SetError(2, 0, 0)

	If $_HandleImgSearch_IsDebug Then
		_GDIPlus_ImageSaveToFile($_HandleImgSearch_BitmapHandle, @ScriptDir & "\GlobalImgCapture.bmp")
	EndIf

	Return SetError(0, 0, $_HandleImgSearch_BitmapHandle)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalGetBitmap
; Description ...: Trả về Handle của Bitmap của Global.
; Syntax ........: _GlobalGetBitmap()
; Parameters ....:
; Return values .: Handle của Bitmap đã khai báo
; ===============================================================================================================================
Func _GlobalGetBitmap()
	Return SetError(0, 0, $_HandleImgSearch_BitmapHandle)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalImgSearchRandom
; Description ...: Trả về toạ độ ngẫu nhiên của ảnh đã tìm được (Chỉ trả về vị trí ảnh đầu tiên tìm được)
; Syntax ........: _GlobalImgSearchRandom($BmpLocal[, $IsReCapture = False[, $BmpSource = 0[, $IsRandom = True[, $Tolerance = $_HandleImgSearch_Tolerance]]]])
; Parameters ....: $BmpLocal            - Đường dẫn của ảnh BMP cần tìm.
;                  $IsReCapture         - [optional] Chụp lại ảnh. Default is False.
;                  $Tolerance           - [optional] an unknown value. Default is 15.
;                  $BmpSource           - [optional] Handle của Bitmap nếu không sử dụng Global. Default is 0.
;                  $IsRandom            - [optional] True sẽ trả về toạ độ ngẫu nhiên của ảnh đã tìm được, False sẽ là $X, $Y. Default is True.
; Return values .: @error = 1 nếu có lỗi xảy ra. Trả về toạ độ ngẫu nhiên của ảnh đã tìm được($P[0] = $X, $P[1] = $Y).
; ===============================================================================================================================
Func _GlobalImgSearchRandom($BmpLocal, $IsReCapture = False, $BmpSource = 0, $IsRandom = True, $Tolerance = $_HandleImgSearch_Tolerance, $Transparency = $_HandleImgSearch_Transparency, $MaxImg = $_HandleImgSearch_MaxImg)
	Local $Pos = _GlobalImgSearch($BmpLocal, $IsReCapture, $BmpSource, $Tolerance, $Transparency, $MaxImg)
	If @error Then
		Local $Results[2] = [-1, -1]
		Return SetError(1, 0, $Results)
	EndIf

	If not $IsRandom Then
		Local $Results[2] = [$Pos[1][0], $Pos[1][1]]
	Else
		Local $Results[2] = [Random($Pos[1][0], $Pos[1][0] + $Pos[1][2], 1), Random($Pos[1][1], $Pos[1][1] + $Pos[1][3], 1)]
	EndIf

	Return SetError(0, 0, $Results)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalImgSearch
; Description ...: Tìm ảnh trong Handle đã khai báo
; Syntax ........: _GlobalImgSearch
; Parameters ....: $BmpLocal            - Đường dẫn của ảnh BMP cần tìm.
;                  $IsReCapture         - [optional] Chụp lại ảnh. Default is False.
;                  $BmpSource           - [optional] Handle của Bitmap nếu không sử dụng Global.
;                  $Tolerance           - [optional] Độ lệch màu sắc của ảnh.
;                  $MaxImg          	- [optional] Số kết quả trả về tối đa.
; Return values .: Thành công: Returns a 2d array with the following format:
;							$aCords[0][0]  		= Tổng số vị trí tìm được
;							$aCords[$i][0]		= Toạ độ X
;							$aCords[$i][1] 		= Toạ độ Y
;							$aCords[$i][2] 		= Width của bitmap
;							$aCords[$i][3] 		= Height của bitmap
;					Lỗi: @error khác 0
; ===============================================================================================================================
Func _GlobalImgSearch($BmpLocal, $IsReCapture = False, $BmpSource = 0, $Tolerance = $_HandleImgSearch_Tolerance, $Transparency = $_HandleImgSearch_Transparency, $MaxImg = $_HandleImgSearch_MaxImg)
	Local $BMP = $_HandleImgSearch_BitmapHandle

	If $BmpSource <> 0 Then $BMP = $BmpSource
	If $BMP = 0 or $IsReCapture Then
		_GlobalImgCapture()
		If @error Then Return SetError(1, 0, 0)

		$BMP = $_HandleImgSearch_BitmapHandle
	EndIf

	; Clone Bitmap để tìm kiếm vì sau khi tìm toàn bộ Bitmap đều bị giải phóng.
	Local $Width = _GDIPlus_ImageGetWidth($BMP)
	Local $Height = _GDIPlus_ImageGetHeight($BMP)
	Local $BmpClone = _GDIPlus_BitmapCloneArea($BMP, 0, 0, $Width, $Height, $GDIP_PXF24RGB)
	If @error Then Return SetError(2, 0, 0)

	Local $Results = _HandleImgSearch("*" & $BmpClone, $BmpLocal, 0, 0, -1, -1, $Tolerance, $Transparency, $MaxImg)
	Return SetError(@error, 0, $Results)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalImgWaitExist
; Description ...: Tìm ảnh trong Handle đã khai báo
; Syntax ........: _GlobalImgWaitExist
; Parameters ....: $BmpLocal            - Đường dẫn của ảnh BMP cần tìm.
;                  $TimeOutSecs         - [optional] Thời gian tìm ảnh tối đa (giây). Default is False.
;                  $Tolerance           - [optional] Độ lệch màu sắc của ảnh.
;                  $MaxImg          	- [optional] Số kết quả trả về tối đa.
; Return values .: Thành công: Returns a 2d array with the following format:
;							$aCords[0][0]  		= Tổng số vị trí tìm được
;							$aCords[$i][0]		= Toạ độ X
;							$aCords[$i][1] 		= Toạ độ Y
;							$aCords[$i][2] 		= Width của bitmap
;							$aCords[$i][3] 		= Height của bitmap
;					Lỗi: @error khác 0
; ===============================================================================================================================
Func _GlobalImgWaitExist($BmpLocal, $TimeOutSecs = 5, $Tolerance = $_HandleImgSearch_Tolerance, $Transparency = $_HandleImgSearch_Transparency, $MaxImg = $_HandleImgSearch_MaxImg)
	Local $Handle = $_HandleImgSearch_HWnd

	If not IsHWnd($Handle) and $Handle <> "" Then
		Return SetError(1, 0, 0)
	EndIf

	Local $Results = _HandleImgWaitExist($Handle, $BmpLocal, _
		$_HandleImgSearch_X, _
		$_HandleImgSearch_Y, _
		$_HandleImgSearch_Width, _
		$_HandleImgSearch_Height, _
		$Tolerance, _
		$Transparency, _
		$MaxImg)
	Return SetError(@error, 0, $Results)
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
; Syntax ........: _GlobalPixelCompare($X, $Y, $PixelColor[, $Tolerance = $_HandleImgSearch_Tolerance[, $IsReCapture = False[, $BmpSource = 0]]])
; Parameters ....: $X, $Y               - Toạ độ cần so sánh.
;                  $PixelColor          - Màu cần so sánh.
;                  $Tolerance           - [optional] Giá trị tolerance. Default is 20.
;                  $IsReCapture         - [optional] Chụp lại ảnh. Default is False.
;                  $BmpSource           - [optional] Handle của Bitmap nếu không sử dụng Global. Default is 0.
; Return values .: @error = 1 nếu xảy ra lỗi. Trả về True nếu tìm thấy, False nếu không tìm thấy.
; ===============================================================================================================================
Func _GlobalPixelCompare($X, $Y, $PixelColor, $Tolerance = $_HandleImgSearch_Tolerance, $IsReCapture = False, $BmpSource = 0)
	Local $PixelColorSource = _GlobalGetPixel($X, $Y, $IsReCapture, $BmpSource)
	If @error Then Return SetError(1, 0, False)

	Return _ColorInBounds($PixelColorSource, $PixelColor, $Tolerance)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _HandleImgSearch
; Description ...: Tìm ảnh trong Handle. Nếu $hwnd = "" sẽ tìm trong toàn màn hình hiện tại.
; Syntax ........: _HandleImgSearch
; Parameters ....: $hwnd                		- Handle của cửa sổ cần chụp. Nếu để trống "" sẽ tự chụp ảnh desktop.
;                  $bmpLocal            		- Đường dẫn đến ảnh BMP cần tìm.
;                  $x, $y, $iWidth, $iHeight 	- Vùng tìm kiếm. Mặc định là toàn ảnh chụp từ $hwnd.
;                  $Tolerance              		- Độ lệch màu sắc của ảnh.
;                  $MaxImg              		- Số ảnh tối đa trả về.
; Return values .: Success: Returns a 2d array with the following format:
;							$aCords[0][0]  		= Tổng số vị trí tìm được
;							$aCords[$i][0]		= Toạ độ X
;							$aCords[$i][1] 		= Toạ độ Y
;							$aCords[$i][2] 		= Width của bitmap
;							$aCords[$i][3] 		= Height của bitmap
;
;					Failure: Returns 0 and sets @error to 1
; ===============================================================================================================================
Func _HandleImgSearch($hwnd, $bmpLocal, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $Tolerance = 15, $Transparency = "", $MaxImg = 1000)
	If StringInStr($hwnd, "*") Then
		Local $BMP = Ptr(StringReplace($hwnd, "*", ""))
		If @error Then
			Local $result[1][4] = [[0, 0, 0, 0]]
			Return SetError(1, 0, $result)
		EndIf
	Else
		Local $BMP = _HandleCapture($hwnd, $x, $y, $iWidth, $iHeight, true)
		If @error Then
			Local $result[1][4] = [[0, 0, 0, 0]]
			Return SetError(1, 0, $result)
		EndIf
	EndIf

	Local $pos = __ImgSearch(0, 0, _GDIPlus_ImageGetWidth($BMP), _GDIPlus_ImageGetHeight($BMP), $bmpLocal, $BMP, $Tolerance, $Transparency, $MaxImg)
	Return SetError(@error, 0, $pos)
EndFunc   ;==>_HandleImgSearch

; #FUNCTION# ====================================================================================================================
; Name ..........: _HandleImgWaitExist
; Description ...: Tìm ảnh trong Handle. Nếu $hwnd = "" sẽ tìm trong toàn màn hình hiện tại.
; Syntax ........: _HandleImgWaitExist
; Parameters ....: $hwnd                		- Handle của cửa sổ cần chụp. Nếu để trống "" sẽ tự chụp ảnh desktop.
;                  $bmpLocal            		- Đường dẫn đến ảnh BMP cần tìm.
;                  $timeOutSecs            		- Thời gian tìm tối đa (tính bằng giây).
;                  $x, $y, $iWidth, $iHeight 	- Vùng tìm kiếm. Mặc định là toàn ảnh chụp từ $hwnd.
;                  $Tolerance              		- Độ lệch màu sắc của ảnh.
;                  $MaxImg              		- Số ảnh tối đa trả về.
; Return values .: Success: Returns a 2d array with the following format:
;							$aCords[0][0]  		= Tổng số vị trí tìm được
;							$aCords[$i][0]		= Toạ độ X
;							$aCords[$i][1] 		= Toạ độ Y
;							$aCords[$i][2] 		= Width của bitmap
;							$aCords[$i][3] 		= Height của bitmap
;
;					Failure: Returns 0 and sets @error to 1
; ===============================================================================================================================
Func _HandleImgWaitExist($hwnd, $bmpLocal, $timeOutSecs = 5, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $Tolerance = 15, $Transparency = "", $MaxImg = 1000)
	$timeOutSecs = $timeOutSecs*1000
	Local $timeStart = TimerInit()

	Local $Results
	While TimerDiff($timeStart) < $timeOutSecs
		$Results = _HandleImgSearch($hwnd, $bmpLocal, $x, $y, $iWidth, $iHeight, $Tolerance, $MaxImg)
		If Not @error Then Return SetError(0, 0, $Results)

		Sleep(100)
	WEnd
	Return SetError(1, 0, $Results)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _BmpImgSearch
; Description ...: Tìm ảnh Bmp trong Bmp
; Syntax ........: _BmpImgSearch
; Parameters ....: $SourceBmp                	- Đường dẫn đến ảnh BMP gốc.
;                  $FindBmp            			- Đường dẫn đến ảnh BMP cần tìm.
;                  $x, $y, $iWidth, $iHeight 	- Vùng tìm kiếm. Mặc định là toàn ảnh chụp từ $hwnd.
;                  $Tolerance              		- Độ lệch màu sắc của ảnh.
;                  $MaxImg              		- Số ảnh trả về tối đa.
; Return values .: Success: Returns a 2d array with the following format:
;							$aCords[0][0]  		= Tổng số vị trí tìm được
;							$aCords[$i][0]		= Toạ độ X
;							$aCords[$i][1] 		= Toạ độ Y
;							$aCords[$i][2] 		= Width của bitmap
;							$aCords[$i][3] 		= Height của bitmap
;
;					Failure: Returns 0 and sets @error to 1
; ===============================================================================================================================
Func _BmpImgSearch($SourceBmp, $FindBmp, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $Tolerance = 15, $Transparency = "", $MaxImg = 1000)
	Local $SourceBitmap = _GDIPlus_BitmapCreateFromFile($SourceBmp)
	If @error Then Return SetError(1, 0, 0)

	Local $pos = __ImgSearch(0, 0, _GDIPlus_ImageGetWidth($SourceBitmap), _GDIPlus_ImageGetHeight($SourceBitmap), $FindBmp, $SourceBitmap, $Tolerance, $Transparency, $MaxImg)

	Return SetError(@error, 0, $pos)
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
	Local $BMP = _HandleCapture($hwnd, $x, $y, $Width, $Height, True, "")
	If @error Then Return SetError(1, 0, 0)

	Local $result = _GDIPlus_BitmapGetPixel($BMP, $getX, $getY)
	If @error Then Return SetError(1, 0, 0)
	_GDIPlus_ImageDispose($BMP)

	Return SetError(0, 0, "0x" & Hex($result, 6))
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _HandlePixelCompare
; Description ...: So sánh màu điểm ảnh với tolerance
; Syntax ........: _HandlePixelCompare
; Parameters ....: $hwnd                		- a handle value.
;                  $getX, $getY               	- Toạ độ cần lấy màu.
;                  $pixelColor          		- Mã màu cần so sánh.
;                  $Tolerance          			- Độ lệch màu sắc.
;                  $x, $y, $iWidth, $iHeight 	- Vùng ảnh trong handle cần chụp. Mặc định là toàn ảnh chụp từ $hwnd.
; Return values .: None
; ===============================================================================================================================
Func _HandlePixelCompare($hwnd, $getX, $getY, $pixelColor, $tolerance = 15, $x = 0, $y = 0, $Width = -1, $Height = -1)
	Local $BMP = _HandleCapture($hwnd, $x, $y, $Width, $Height, True, "")
	If @error Then Return SetError(1, 0, False)

	Local $result = _GDIPlus_BitmapGetPixel($BMP, $getX, $getY)
	If @error Then Return SetError(1, 0, False)
	_GDIPlus_ImageDispose($BMP)

	Return SetError(0, 0, _ColorInBounds($pixelColor, "0x" & Hex($result, 6), $tolerance))
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _HandleCapture
; Description ...: Chụp ảnh theo Handle. Nếu Handle = "" sẽ chụp ảnh màn hình hiện tại.
; Syntax ........: _HandleCapture
; Parameters ....: $hwnd                		- Handle của cửa sổ cần chụp. Nếu bỏ trống ("") sẽ chụp ảnh màn hình.
;                  $x, $y, $iWidth, $iHeight 	- Vùng ảnh trong handle cần chụp. Mặc định là toàn ảnh chụp từ $hwnd.
;                  $SavePath            		- Đường dẫn lưu ảnh.
;                  $IsBMP               		- True: Kết quả trả về là Bitmap.
;												- False: Kết quả trả về là HBitmap.[Mặc định]
;				   $IsUser32					- Sử dụng User32.dll thay vì _WinAPI_BitBlt (Thử để tìm tuỳ chọn phù hợp)
; ===============================================================================================================================
Func _HandleCapture($hwnd = "", $x = 0, $y = 0, $Width = -1, $Height = -1, $IsBMP = False, $SavePath = "", $IsUser32 = False)
	If $hwnd = "" Then
		Local $Right = $Width = -1 ? -1 : $x + $Width - 1
		Local $Bottom = $Height = -1 ? -1 : $y + $Height - 1

		Local $hBMP = _ScreenCapture_Capture("", $x, $y, $Right, $Bottom, False)
		If @error Then Return SetError(1, 0, 0)

		If $_HandleImgSearch_IsDebug Then
			Local $BMP = _GDIPlus_BitmapCreateFromHBITMAP($hBMP)
			_GDIPlus_ImageSaveToFile($BMP, $SavePath <> "" ? $SavePath : @ScriptDir & "\HandleCapture0.bmp")
			_GDIPlus_BitmapDispose($BMP)
		EndIf

		If not $IsBMP Then Return SetError(0, 0, $hBMP)

		Local $BMP = _GDIPlus_BitmapCreateFromHBITMAP($hBMP)
		If @error Then Return SetError(1, 0, 0)
		_WinAPI_DeleteObject($hBMP)
		Return SetError(0, 0, $BMP)
	EndIf

	Local $Handle = $Hwnd
	If Not IsHWnd($Handle) Then $Handle = HWnd($Hwnd)
	If @error Then
		$Handle = WinGetHandle($Hwnd)
		If @error Then
			ConsoleWrite("! _HandleCapture error: Handle error!")
			Return SetError(1, 0, 0)
		EndIf
	EndIf

	Local $hDC = _WinAPI_GetDC($Handle)
	Local $hCDC = _WinAPI_CreateCompatibleDC($hDC)
	If $Width = -1 Then $Width = _WinAPI_GetWindowWidth($Handle)
	If $Height = -1 Then $Height = _WinAPI_GetWindowHeight($Handle)

	If $IsUser32 Then
		Local $hBMP = _WinAPI_CreateCompatibleBitmap($hDC, _WinAPI_GetWindowWidth($Handle), _WinAPI_GetWindowHeight($Handle))
		_WinAPI_SelectObject($hCDC, $hBMP)

		DllCall("User32.dll", "int", "PrintWindow", "hwnd", $Handle, "hwnd", $hCDC, "int", 0)

		Local $tempBMP = _GDIPlus_BitmapCreateFromHBITMAP($hBMP)
		_WinAPI_DeleteObject($hBMP)

		Local $BMP = _GDIPlus_BitmapCloneArea($tempBMP, $x, $y, $Width, $Height, $GDIP_PXF24RGB)
		_GDIPlus_BitmapDispose($tempBMP)
	Else
		Local $hBMP = _WinAPI_CreateCompatibleBitmap($hDC, $Width, $Height)
		_WinAPI_SelectObject($hCDC, $hBMP)

		_WinAPI_BitBlt($hCDC, 0, 0, $Width, $Height, $hDC, $x, $y, $__BMPSEARCHSRCCOPY)

		Local $BMP = _GDIPlus_BitmapCreateFromHBITMAP($hBMP)
		_WinAPI_DeleteObject($hBMP)
	EndIf

	If $_HandleImgSearch_IsDebug Then
		_GDIPlus_ImageSaveToFile($BMP, $SavePath = "" ? @ScriptDir & "\HandleCapture1.bmp" : $SavePath)
	EndIf

	_WinAPI_ReleaseDC($Handle, $hDC)
	_WinAPI_DeleteDC($hCDC)

	If $IsBMP Then Return SetError(0, 0, $BMP)

	; Nên tạo lại $hBMP này vì có thể có lỗi nếu sử dụng $hBMP ở trên
	Local $hBMP = _GDIPlus_BitmapCreateHBITMAPFromBitmap($BMP)
	_GDIPlus_BitmapDispose($BMP)

	Return SetError(0, 0, $hBMP)
EndFunc   ;==>_HandleCapture

#Region Internal Functions
; Author: Lâm Thành Nhân
Func __ImgSearch($x, $y, $right, $bottom, $BitmapFind, $BitmapSource, $Tolerance = 15, $Transparency = "", $MaxImg = 1000)
	If $_HandleImgSearch_IsDebug Then
		_GDIPlus_ImageSaveToFile($BitmapSource, @ScriptDir & "\HandleImgSearchSource.bmp")
	EndIf

	Local $hBitmapSource = _GDIPlus_BitmapCreateHBITMAPFromBitmap($BitmapSource)
	Local $Pos, $Error = 0
	Dim $PosAr[1][4] = [[0,0,0,0]]

	; Tính trước giá trị màu sắc pixel cần thay đổi khi tìm được kết quả
	Local $hBitmapFind = _GDIPlus_BitmapCreateFromFile($BitmapFind)

	Local $BitmapFindWidth = _GDIPlus_ImageGetWidth($hBitmapFind)
	Local $BitmapFindHeight = _GDIPlus_ImageGetHeight($hBitmapFind)

	; Tính trước giá trị cho ô cần vẽ
	Local $hBuffer = _GDIPlus_ImageGetGraphicsContext($BitmapSource)

 	; Giải phóng
	_GDIPlus_BitmapDispose($hBitmapFind)

	; Xử lý lại Tolerance và Transparency
	If $Tolerance > 0 Then $BitmapFind = "*" & $Tolerance & " " & $BitmapFind
	If $Transparency <> "" Then $BitmapFind = "*Trans" & $Transparency & " " & $BitmapFind

	For $i = 1 to $MaxImg
		$Pos = MemoryDllCall($__HandleImgSearch_MemoryDll, "str","ImageSearchEx", _
			"int", $x, _
			"int", $y, _
			"int", $right, _
			"int", $bottom, _
			"str", $BitmapFind, _
			"ptr", $hBitmapSource)
		If @error Then
			$Error = $i = 1 ? 1 : 0; Nếu không tìm được sẽ trả về @error 1
			ExitLoop
		EndIf
		If $Pos[0] = 0 Then
			$Error = $i = 1 ? 1 : 0 ; Nếu không tìm được sẽ trả về @error 1
			ExitLoop
		EndIf
		Local $PosSplit = StringSplit($Pos[0], "|", 2)
		Redim $PosAr[$i + 1][4]
		$PosAr[0][0] = $i
		$PosAr[$i][0] = $PosSplit[1]
		$PosAr[$i][1] = $PosSplit[2]
		$PosAr[$i][2] = $PosSplit[3]
		$PosAr[$i][3] = $PosSplit[4]

		; Set lại màu sắc của vị trí ảnh vừa tìm được
		_GDIPlus_GraphicsFillRect($hBuffer, $PosSplit[1], $PosSplit[2], $BitmapFindWidth, $BitmapFindHeight)
		_WinAPI_DeleteObject($hBitmapSource)

		; Xác định lại toạ độ $y để không phải tìm từ đầu nếu tìm nhiều ảnh
		$y = $PosSplit[2]

		; Thao tác với ImageSearchExt đã xoá ảnh $hBitmapFind
		$hBitmapSource = _GDIPlus_BitmapCreateHBITMAPFromBitmap($BitmapSource)
	Next

	If $_HandleImgSearch_IsDebug Then
		_GDIPlus_ImageSaveToFile($BitmapSource, @ScriptDir & "\HandleImgSearchSourceFilter.bmp")
	EndIf

	_GDIPlus_BitmapDispose($BitmapSource)
	_WinAPI_DeleteObject($hBitmapSource)

	_GDIPlus_GraphicsDispose($hBuffer)

	Return SetError($Error, 0, $PosAr)
EndFunc

Func __HandleImgSearch_StartUp()
	_GDIPlus_Startup()
	$__BinaryCall_Kernel32dll = DllOpen('kernel32.dll')
	$__BinaryCall_Msvcrtdll = DllOpen('msvcrt.dll')
	If @AutoItX64 Then
		MsgBox(48,"HandleImgSearch","This UDF currently only supports AutoIt 32bit version!")
		Exit
	Else
		$__HandleImgSearch_MemoryDll = MemoryDllOpen(Binary($__HandleImgSearch_Opcode32))
	EndIf
EndFunc

Func __HandleImgSearch_Shutdown()
	DllClose($__BinaryCall_Kernel32dll)
	DllClose($__BinaryCall_Msvcrtdll)
	_GDIPlus_ImageDispose($_HandleImgSearch_BitmapHandle)
	_GDIPlus_Shutdown()
EndFunc

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

$__HandleImgSearch_Opcode32 = "0x4D5A90000300000004000000FFFF0000B800000000000000400000000000000000000000000000000000000000000000000000000000000000000000F80000000E1FBA0E00B409CD21B8"
$__HandleImgSearch_Opcode32 &= "014CCD21546869732070726F6772616D2063616E6E6F742062652072756E20696E20444F53206D6F64652E0D0D0A24000000000000006D91B07C29F0DE2F29F0DE2F29F0DE2F46867"
$__HandleImgSearch_Opcode32 &= "52F33F0DE2F4686402F3DF0DE2F4686742F4DF0DE2F20885D2F28F0DE2F20884D2F24F0DE2F29F0DF2F40F0DE2F4686712F2AF0DE2F4686452F28F0DE2F4686432F28F0DE2F526963"
$__HandleImgSearch_Opcode32 &= "6829F0DE2F000000000000000000000000000000000000000000000000504500004C010500AF39DA4F0000000000000000E00002210B010A0000E00000004E0000000000002044000"
$__HandleImgSearch_Opcode32 &= "00010000000F000000000001000100000000200000500010000000000050001000000000000700100000400007E910100020040010000100000100000000010000010000000000000"
$__HandleImgSearch_Opcode32 &= "100000004018010096000000540F01008C00000000500100B40100000000000000000000000000000000000000600100D8090000D0F100001C0000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "00000000000000000000000D00B010040000000000000000000000000F00000980100000000000000000000000000000000000000000000000000002E74657874000000FADE000000"
$__HandleImgSearch_Opcode32 &= "10000000E0000000040000000000000000000000000000200000602E72646174610000D628000000F00000002A000000E40000000000000000000000000000400000402E646174610"
$__HandleImgSearch_Opcode32 &= "00000F82E00000020010000120000000E0100000000000000000000000000400000C02E72737263000000B40100000050010000020000002001000000000000000000000000004000"
$__HandleImgSearch_Opcode32 &= "00402E72656C6F630000DE0E0000006001000010000000220100000000000000000000000000400000420000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "000000000000000B801000000C20C00CCCCCCCCCCCCCCCC85F60F84A1010000803E000F849801000068440A011056E88527000083C40885C07501C3684C0A011056E87227000083C4"
$__HandleImgSearch_Opcode32 &= "0885C07506B8C0C0C000C368540A011056E85A27000083C40885C07506B880808000C3685C0A011056E84227000083C40885C07506B8FFFFFF00C368640A011056E82A27000083C40"
$__HandleImgSearch_Opcode32 &= "885C07506B880000000C3686C0A011056E81227000083C40885C07506B8FF000000C368700A011056E8FA26000083C40885C07506B880008000C368780A011056E8E226000083C408"
$__HandleImgSearch_Opcode32 &= "85C07506B8FF00FF00C368800A011056E8CA26000083C40885C07506B800800000C368880A011056E8B226000083C40885C07506B800FF0000C368900A011056E89A26000083C4088"
$__HandleImgSearch_Opcode32 &= "5C07506B880800000C368980A011056E88226000083C40885C07506B8FFFF0000C368A00A011056E86A26000083C40885C07506B800008000C368A80A011056E85226000083C40885"
$__HandleImgSearch_Opcode32 &= "C07506B80000FF00C368B00A011056E83A26000083C40885C07506B800808000C368B80A011056E82226000083C40885C07506B800FFFF00C368C00A011056E80A26000083C408F7D"
$__HandleImgSearch_Opcode32 &= "81BC0257F7F7FFF0580808000C383C8FFC3CCCCCC85C0742B538A1884DB7420EB038D4900BA940B0110B1203AD974128A4A014284C975F48A58014084DB75E533C05BC333C0C3CCCC"
$__HandleImgSearch_Opcode32 &= "CCCCCCCCCCCCCCCCCCCCCCCC8BC68A0880F920740580F909750340EBF18A0884C9743C80F92D740580F92B750140803830752C8A480180F978740580F958751F0FBE400250E88F260"
$__HandleImgSearch_Opcode32 &= "00083C40485C0740E6A106A0056E8D928000083C40CC356E81029000083C404C3CCCCCC558BEC81EC6C040000A10020011033C58945FC8B450853568B75108985B8FBFFFF8B450C57"
$__HandleImgSearch_Opcode32 &= "8BDA50899D9CFBFFFF898DACFBFFFFFF1520F000108BF889BDA8FBFFFF85FF0F84450200008B8DB8FBFFFF33D2528D85C0FBFFFF505252525157C785B4FBFFFF00000000C685BFFBF"
$__HandleImgSearch_Opcode32 &= "FFF00C785C0FBFFFF28000000668995CEFBFFFFFF151CF0001085C00F84CD010000668B85CEFBFFFF0FB7D03B55140F8CBA0100008B8DC4FBFFFF8B95ACFBFFFF6683F8100F94C088"
$__HandleImgSearch_Opcode32 &= "068BB5C8FBFFFF890B89328B030FAFC68985B0FBFFFF03C003C050898598FBFFFFE86829000083C4048985B4FBFFFF85C00F846F0100006683BDCEFBFFFF080F94C08885BEFBFFFF8"
$__HandleImgSearch_Opcode32 &= "4C0750CB820000000668985CEFBFFFF8B8DB8FBFFFF51F7DE5789B5C8FBFFFFFF1518F000108BB5B4FBFFFF6A008D95C0FBFFFF528B95B8FBFFFF8985A0FBFFFF8B85ACFBFFFF8B08"
$__HandleImgSearch_Opcode32 &= "56516A005257FF151CF0001085C00F84EF00000080BDBEFBFFFF000F84DB000000B800040000E83E9600008BC45068000100006A00578985A4FBFFFFFF1514F000108B03250300008"
$__HandleImgSearch_Opcode32 &= "079054883C8FC407409BA040000002BD0EB0233D28B85ACFBFFFF8B008BBD98FBFFFF8BC80FAFCA038DB0FBFFFF8995B8FBFFFF8D4C31FF8D7C37FCC785B0FBFFFF0000000085C07E"
$__HandleImgSearch_Opcode32 &= "648DA4240000000033F62BCA39337E3E0FB6118B85A4FBFFFF8B04908BD0C1EA080FB6D80FB6D2C1E3080BD38B9D9CFBFFFFC1E8100FB6C0C1E2080BD089174683EF04493B337CC88"
$__HandleImgSearch_Opcode32 &= "B95B8FBFFFF8B85B0FBFFFF8BB5ACFBFFFF408985B0FBFFFF3B067CA38BBDA8FBFFFFC685BFFBFFFF018B85A0FBFFFF85C074085057FF1518F0001057FF1510F0001080BDBFFBFFFF"
$__HandleImgSearch_Opcode32 &= "00751D8B85B4FBFFFF85C0741350E81B21000083C404C785B4FBFFFF000000008B85B4FBFFFF8DA588FBFFFF5F5E5B8B4DFC33CDE8E62000008BE55DC3CCCCCCCCCCCCCCCCCCCC558"
$__HandleImgSearch_Opcode32 &= "BEC81EC78020000A10020011033C58945F88B450853568B7510578BDA8985D8FDFFFF8B450C33FF53899DC8FDFFFF898DD4FDFFFF8985DCFDFFFF89BDE4FDFFFFC700FFFFFFFFFF15"
$__HandleImgSearch_Opcode32 &= "0CF0001083F807751C5757575753FF1570F100105F5E5B8B4DF833CDE86D2000008BE55DC3803B0089BDE4FDFFFF0F84D20000003BF77D0233F66A2E53E8A42700008BF883C40885F"
$__HandleImgSearch_Opcode32 &= "F74014783FE017F7A85FF745A68C80A011057E8F721000083C40885C0746468CC0A011057E8E521000083C40885C0745268D00A011057E8D321000083C40885C0744068D40A011057"
$__HandleImgSearch_Opcode32 &= "E8C121000083C40885C0742E68D80A011057E8AF21000083C40885C0741CC685E3FDFFFF0085F67E5F8B8DDCFDFFFFC70101000000E9C20000008B95DCFDFFFFC685E3FDFFFF01C70"
$__HandleImgSearch_Opcode32 &= "20100000085F67E058D46FFEB0233C050A1483D01105350FF1560F100108985E4FDFFFF83F8020F838D00000033C05F5E5B8B4DF833CDE8791F00008BE55DC385FF747068DC0A0110"
$__HandleImgSearch_Opcode32 &= "57E82F21000083C40885C0750E8B95DCFDFFFFC70201000000EB5068E00A011057E80F21000083C40885C0743268E40A011057E8FD20000083C40885C0742068E80A011057E8EB200"
$__HandleImgSearch_Opcode32 &= "00083C40885C0751A8B85DCFDFFFFC70000000000EB0C8B8DDCFDFFFFC701020000008B85E4FDFFFF8B95D8FDFFFF8B8DD4FDFFFF83FAFF740583F9FF751E85D2740485C9751633C9"
$__HandleImgSearch_Opcode32 &= "898DD4FDFFFF898DD8FDFFFF888DEBFDFFFFEB1A83FAFF740E83F9FF7409C685EBFDFFFF00EB07C685EBFDFFFF0185C00F859F0000008B95DCFDFFFF8B1283FAFF0F8E8E000000388"
$__HandleImgSearch_Opcode32 &= "5EBFDFFFF740433C9EB0C8B85D8FDFFFF8B8DD4FDFFFF6810200000515052536A00FF1588F100108985E4FDFFFF85C0741A80BDEBFDFFFF0075525F5E5B8B4DF833CDE84B1E00008B"
$__HandleImgSearch_Opcode32 &= "E55DC353FF1580F0001083F8FF0F84AFFEFFFF85F67E27A1483D01104E565350FF1560F100108985E4FDFFFF83F8020F828DFEFFFFC685E3FDFFFF01EB068B85E4FDFFFFC785D0FDF"
$__HandleImgSearch_Opcode32 &= "FFF0000000085C00F85670100008B8DDCFDFFFF890185FF744268F40A011057E8A61F000083C40885C00F84C901000068F80A011057E8901F000083C40885C00F84B301000068000B"
$__HandleImgSearch_Opcode32 &= "011057E87A1F000083C40885C00F849D01000068EC0A0110FF1588F000108BF085F60F84880100008B3D7CF0001068040B011056FFD768140B0110568BD8FFD768240B0110568985C"
$__HandleImgSearch_Opcode32 &= "4FDFFFFFFD768400B0110568985C0FDFFFFFFD7685C0B0110568985BCFDFFFFFFD78BF833C0C785A8FDFFFF010000008985ACFDFFFF8985B0FDFFFF8985B4FDFFFF3BD80F84870000"
$__HandleImgSearch_Opcode32 &= "00508D95A8FDFFFF528D85B8FDFFFF50FFD385C075728B95C8FDFFFF68040100008D8DECFDFFFF516AFF525050FF1578F000108D85CCFDFFFF508D8DECFDFFFF51FF95C0FDFFFF85C"
$__HandleImgSearch_Opcode32 &= "075308B85CCFDFFFF68808080008D95E4FDFFFF5250FF95BCFDFFFF85C0740AC785E4FDFFFF000000008B8DCCFDFFFF51FFD78B95B8FDFFFF52FF95C4FDFFFF56FF1574F000108B85"
$__HandleImgSearch_Opcode32 &= "E4FDFFFF8B9DC8FDFFFF80BDEBFDFFFF000F847A0200008BB5DCFDFFFF833E00741C8D8DA4FDFFFF5150FF1584F1001085C00F84310200008B85B0FDFFFF8D958CFDFFFF526A1850F"
$__HandleImgSearch_Opcode32 &= "F1524F000108BBDD4FDFFFF83FFFF0F858001000083BD90FDFFFF000F849F010000DB8594FDFFFFDAB590FDFFFFDA8DD8FDFFFFDC05980B0110E868A000008BF8E97B0100006A006A"
$__HandleImgSearch_Opcode32 &= "006A036A006A00680000008053FF1570F000108BF883FFFF0F8460FCFFFF6A0057FF156CF00010506A028985C8FDFFFFFF1568F000108BF085F6751A57FF1564F0001033C05F5E5B8"
$__HandleImgSearch_Opcode32 &= "B4DF833CDE8B41B00008BE55DC356FF1560F0001085C0752157FF1564F0001056FF155CF0001033C05F5E5B8B4DF833CDE8881B00008BE55DC38B95C8FDFFFF6A008D8DC8FDFFFF51"
$__HandleImgSearch_Opcode32 &= "525057FF1540F0001056FF1530F0001057FF1564F000108D85CCFDFFFF506A0056FF1590F1001085C078AC8B85CCFDFFFF85C074A28D8DD0FDFFFF5168ECF100106A006A0050FF155"
$__HandleImgSearch_Opcode32 &= "8F1001085C0790AC785D0FDFFFF000000008B85CCFDFFFF8B10508B4208FFD056FF155CF000108B85D0FDFFFF85C00F8470FBFFFF8B088D95E4FDFFFF52508B410CFFD08B85E4FDFF"
$__HandleImgSearch_Opcode32 &= "FF85C00F854EFEFFFF8B85D0FDFFFF8B088B510850FFD233C05F5E5B8B4DF833CDE8BE1A00008BE55DC383BD94FDFFFF007423DB8590FDFFFFDAB594FDFFFFDA8DD4FDFFFFDC05980"
$__HandleImgSearch_Opcode32 &= "B0110E8EC9E00008985D8FDFFFF833E00747B8B85B4FDFFFF8B3508F0001050FFD68B8DB0FDFFFF51FFD680BDE3FDFFFF00755A8B95E4FDFFFF52FF1580F100108B85D8FDFFFF8B8D"
$__HandleImgSearch_Opcode32 &= "DCFDFFFF8B116A10575052536A00FF1588F100105F5E5B8B4DF833CDE8321A00008BE55DC38B85E4FDFFFF50FF1580F1001033C05F5E5B8B4DF833CDE8121A00008BE55DC38B85E4F"
$__HandleImgSearch_Opcode32 &= "DFFFFEB068BBDD4FDFFFF83BDD0FDFFFF008B95D8FDFFFF743E85D2750985FF75058D4A04EB0233C95157526A0050FF1570F100108BF08B85D0FDFFFF8B088B510850FFD28BC65F5E"
$__HandleImgSearch_Opcode32 &= "5B8B4DF833CDE8B71900008BE55DC385D2750485FF74168B8DDCFDFFFF6A0C57528B115250FF1570F100108BF08B4DF85F5E33CD5BE8881900008BE55DC3CCCCCCCCCCCCCCCCCCCCC"
$__HandleImgSearch_Opcode32 &= "CCC558BEC83EC4CA10020011033C58945FC538BD95657895DE485DB751333C05F5E5B8B4DFC33CDE84D1900008BE55DC36A00C745E800000000FF157CF100108BF857897DE0FF1520"
$__HandleImgSearch_Opcode32 &= "F000108BF085F60F84CB0000008D45B45053FF1584F1001085C00F84B10000008B55C48D4DC8516A1852FF1524F0001085C00F84850000008B45D08B4DCC505157FF1504F00010894"
$__HandleImgSearch_Opcode32 &= "5E885C0746F8BD05256FF1518F000108BD833C03BD8745A8B4DD08945EC8945F08B45CC68808080008945F4894DF8FF1500F000108BF8578D55EC5256FF1568F1001057FF1508F000"
$__HandleImgSearch_Opcode32 &= "108B45D08B4DCC8B55E46A036A006A005051526A006A0056FF1574F100105356FF1518F000108B7DE08B5DE48B45C450FF1508F000108B4DC051FF1508F0001056FF1510F00010576"
$__HandleImgSearch_Opcode32 &= "A00FF1578F1001053FF1580F100108B4DFC8B45E85F5E33CD5BE8391800008BE55DC3CCCCCCCCCCCCCCCCCCCCCCCCCC558BEC8B450803C05DC20400CCCCCCCC558BEC83E4F88B4518"
$__HandleImgSearch_Opcode32 &= "83EC5C535633F6573BC67D05897518EB0E3DFF0000007E07C74518FF0000008B7D1C3BFE741856FF157CF100108BD8895C24643BDE751557FF1508F00010B8700B01105F5E5B8BE55"
$__HandleImgSearch_Opcode32 &= "DC21C006A088D4424175053578D4C24448D542434897424308974244089742438897424648974245889742468C644241D00E808F4FFFF83C410894424143BC60F841E0400008B7D20"
$__HandleImgSearch_Opcode32 &= "3BFE741753FF1520F00010575089442450FF1518F00010894424588B75108B7D142B75082B7D0C534647FF1520F000108944242085C00F84DF030000575653FF1504F000108944243"
$__HandleImgSearch_Opcode32 &= "085C00F84CA0300008B5424208BC85152FF1518F000108944245485C00F84B0030000837D20008B450C8B4D08682000CC005051750E8B54242C5357566A006A0052EB108B5424548B"
$__HandleImgSearch_Opcode32 &= "44242C5257566A006A0050FF1528F0001085C00F84710300008B5424208B4424306A088D4C24165152508D4C24488D542428E82EF3FFFF8BD083C4108954242885D20F84420300008"
$__HandleImgSearch_Opcode32 &= "B7424248B7C24180FAF7424340FAF7C2438807C2413008974242C897C24447507807C241200743333C085FF7E0C812482F8F8F800403BC77CF48B4C241433C085F67E32EB078DA424"
$__HandleImgSearch_Opcode32 &= "00000000812481F8F8F800403BC67CF4EB048B4C241485F67E138D41038BCEEB038D4900C6000083C0044975F78B5D1883FB010F8DFC00000085FF7E108D42038BCF8BFFC6000083C"
$__HandleImgSearch_Opcode32 &= "0044975F733FF897C241C397C24440F8E9C0200008B4C24148B3189742450EB0B8DA424000000008D6424008B5424288D0CBD00000000393411740983FEFF0F85940000008BC799F7"
$__HandleImgSearch_Opcode32 &= "7C24188B5C24382BD8395C24340F8F7D0000008B4424182BC2394424247F7133DB33F6C644240D018BC7395C242C0F8E34020000C644240D018BD7894C24408D6424008B4C24148B0"
$__HandleImgSearch_Opcode32 &= "C998B7C2428390C87740583F9FF752B463B7424247D0340EB158B4C24188D048D000000000144244033F603D18BC2433B5C242C7CC5E9E50100008B7424508B7C241CC644240D0047"
$__HandleImgSearch_Opcode32 &= "897C241C3B7C24440F8C44FFFFFFE9C401000033C08944241C85FF0F8EB60100009099F77C24188B4C24382BC8394C24340F8F8F0100008B4C24188BC12BC2394424240F8F7D01000"
$__HandleImgSearch_Opcode32 &= "08B44241C33FFC644240D01897C243C894424403BF70F8E7301000003C903C98D148500000000C644240D0189442450894C24608954244C8BFF8B7424140FB644BE028A0CBE8A54BE"
$__HandleImgSearch_Opcode32 &= "01884C24133BD87E07C644240E00EB088AC82ACB884C240E0FB6D28954245C3BDA7E07C644241000EB0C8B5D188ACA2A4D18884C24100FB64C24133BD97E07C644241200EB0D8AD12"
$__HandleImgSearch_Opcode32 &= "A5518885424128B54245C8B5D18BEFF0000002BF03BDE7E0BB8FF0000008844240FEB0B02C38844240FB8FF0000008BF02BF23BDE7E0688442411EB0602D3885424118BD02BD13BDA"
$__HandleImgSearch_Opcode32 &= "7E0688442413EB0602CB884C24138B4424288B7424408A4CB0028A54B0018A04B03A4C240E721E3A4C240F77183A54241072123A542411770C3A44241272063A442413760A8B44241"
$__HandleImgSearch_Opcode32 &= "4833CB8FF75458B44243C408944243C3B4424247D074689742440EB208B4C24608B442450014C244C03442418C744243C000000008944245089442440473B7C242C7D298B5D18E9CC"
$__HandleImgSearch_Opcode32 &= "FEFFFF8B5D188B74242C8B7C2444C644240D008B44241C408944241C3BC70F8C4BFEFFFF8B542464526A00FF1578F100108B451C8B1D08F0001050FFD38B7424208B3D10F0001085F"
$__HandleImgSearch_Opcode32 &= "674138B44245485C074085056FF1518F0001056FFD78B74244885F674138B44245885C074085056FF1518F0001056FFD78B44243085C0740350FFD38B44241485C0740950E8041300"
$__HandleImgSearch_Opcode32 &= "0083C4048B44242885C0740950E8F312000083C404807C240D000F8405FBFFFF8B44241C99F77C24188B4C2434518B4C24285103450C035508505268740B0110684C3D0110E8311A0"
$__HandleImgSearch_Opcode32 &= "00083C4185F5EB84C3D01105B8BE55DC21C00CCCCCC558BEC83E4F881ECAC000000A10020011033C4898424A80000008B451C538B5D18565733FF6A2E5389442428897C2418C74424"
$__HandleImgSearch_Opcode32 &= "2CFFFFFFFF897C2448897C2430897C2424E8A71900008BF083C4083BF7744D4668DC0A011056E80314000083C40885C0742468C80A011056E8F113000083C40885C0741268CC0A011"
$__HandleImgSearch_Opcode32 &= "056E8DF13000083C40885C075168B356CF100106A31FFD66A328944242CFFD68944241C53FF150CF0001083F8070F84F70100008BFB8A073C2074043C09750347EBF3803F2A0F85DF"
$__HandleImgSearch_Opcode32 &= "0100000FBE4F014751E8E51A000083C40483F8480F84FD00000083F8570F84E60000006A0468840B011057E8D11B000083C40C85C0751383C7048BF7E8ABEDFFFF89442440E931010"
$__HandleImgSearch_Opcode32 &= "0006A05688C0B011057E8AA1B000083C40C85C0757E6A1F83C7058D9424980000005752E8FB16000083C40C8D842494000000C68424B300000000E824EDFFFF85C07403C600008DB4"
$__HandleImgSearch_Opcode32 &= "2494000000E861EBFFFF83F8FF75186A108BC66A0050E86816000083C40C89442424E9C30000008BC8C1E9080FB6D00FB6C9C1E208C1E8100BCA0FB6C0C1E1080BC8894C2424E99F0"
$__HandleImgSearch_Opcode32 &= "000008BF7E809EDFFFF8944241085C0790DC744241000000000E9830000003DFF0000007E7CC7442410FF000000EB728D7701E8DBECFFFF89442428EB648D77018BC68A0880F92074"
$__HandleImgSearch_Opcode32 &= "0580F909750340EBF18A0884C9743D80F92D740580F92B750140803830752D8A480180F978740580F95875200FBE480251E86113000083C40485C0740F6A106A0056E8AB15000083C"
$__HandleImgSearch_Opcode32 &= "40CEB0956E8E115000083C4048944241C85FF0F84A00000008A1784D20F8496000000B9940B0110B0203AD0742C8A41014184C075F48A57014784D275E5B8700B01105F5E5B8B8C24"
$__HandleImgSearch_Opcode32 &= "A800000033CCE8161000008BE55DC218008D5F018BFB8D49008A073C2074043C09750347EBF3803F2A0F8421FEFFFF8B5424408B4C2428528D44245450518B4C24288BD3E800EFFFF"
$__HandleImgSearch_Opcode32 &= "F8BF033DB83C40C897424643BF3741853FF157CF100108BF8897C24543BFB752356FF1508F00010B8700B01105F5E5B8B8C24A800000033CCE89B0F00008BE55DC21800837C245001"
$__HandleImgSearch_Opcode32 &= "895C2470895C2428895C2448895C2438895C246C895C2440895C2468885C240D75688D9424800000005256FF1584F1001085C074408B8C248C0000006A018D4424125057518D4C242"
$__HandleImgSearch_Opcode32 &= "C8D542440E8B6EBFFFF8B9424A000000083C410528944243CFF1508F000108B84248C00000050FF1508F000108BCEE89CF5FFFF8BF0897424643BF30F8455FFFFFF6A088D4C241251"
$__HandleImgSearch_Opcode32 &= "57568D4C242C8D542440E868EBFFFF83C410894424343BC30F847E040000395C24208B1D20F00010741757FFD38B542420525089442448FF1518F00010894424688B75108B7D148B4"
$__HandleImgSearch_Opcode32 &= "424542B75082B7D0C504647FFD38BD8895C247085DB0F84380400008B4C2454575651FF1504F000108944242885C00F841F0400008BD05253FF1518F000108944246C85C00F840904"
$__HandleImgSearch_Opcode32 &= "0000837C2420008B450C8B4D088B542454682000CC00505174048B54244C5257566A006A0053FF1528F0001085C00F84D70300008B4C24286A088D4424135053518D4C246C8D54243"
$__HandleImgSearch_Opcode32 &= "CE898EAFFFF8BF883C410897C244885FF0F84AC0300008B4C24308B54242C0FAF4C241C0FAF54245C807C240E00894C2420895424507507807C240F00743D837C2424FF7408816424"
$__HandleImgSearch_Opcode32 &= "24F8F8F80033C085D27E0C812487F8F8F800403BC27CF433C085C97E318B7424348D642400812486F8F8F800403BC17CF4EB048B74243485C97E138D46038DA42400000000C600008"
$__HandleImgSearch_Opcode32 &= "3C0044975F78B5C241083FB010F8D3301000085D27E0F8D47038BCA90C6000083C0044975F7C74424180000000085D20F8EFC0200008B5424348B128B7424188B4C242C8954244CEB"
$__HandleImgSearch_Opcode32 &= "078D49008B54244C8B4424488D1CB50000000039140374178B44243885C07405833800750A3B5424240F85BA0000008BC699F7F98B7C245C2BF8397C241C0F8FA50000008BC12BC23"
$__HandleImgSearch_Opcode32 &= "94424300F8F9700000033FFC644240D01897C2444397C24200F8E820200008B4424348B5424388B4C24182BD0C644240D01895C243C895424588BFF8B108B5C24483914B37417837C"
$__HandleImgSearch_Opcode32 &= "243800740A8B5C2458833C030075063B5424247536473B7C24307D0346EB158B54242C8D3495000000000174243C33FF03CA8BF18B5424444283C004895424443B5424207CADE90D0"
$__HandleImgSearch_Opcode32 &= "200008B7424188B4C242CC644240D0046897424183B7424500F8C0CFFFFFFE9EC010000C74424180000000085D20F8EDC0100008DA424000000008B4C24188B74242C8BC199F7FE8B"
$__HandleImgSearch_Opcode32 &= "7C245C2BF8397C241C0F8FA90100002BF2397424300F8F9D01000033C0C644240D018944246089442444894C243C394424200F8E8F0100008B54242C8BC18B4C24348944244C03C00"
$__HandleImgSearch_Opcode32 &= "3C003D2894424748B44243803D22BC1C644240D018BF18954247C894424580FB646028A56013BD87E07C644240E00EB088AC82ACB884C240E0FB6D2895424783BDA7E07C644241700"
$__HandleImgSearch_Opcode32 &= "EB0E8B5C24108ACA2A4C2410884C24170FB60E3BD97E07C644241600EB0E8AD12A542410885424168B5424788B5C2410BFFF0000002BF83BDF7E0BB8FF00000088442415EB0B02C38"
$__HandleImgSearch_Opcode32 &= "8442415B8FF0000008BF82BFA3BDF7E0688442414EB0602D3885424148BD02BD13BDA7E068844240FEB0602CB884C240F8B4424488B7C243C8A4CB8028A54B8018A04B83A4C240E72"
$__HandleImgSearch_Opcode32 &= "1E3A4C241577183A54241772123A542414770C3A44241672063A44240F7619837C243800740A8B442458833C060075088B4C2424390E75518B44246040894424603B4424307D07478"
$__HandleImgSearch_Opcode32 &= "97C243CEB208B54247C8B44244C015424740344242CC7442460000000008944244C8944243C8B4424444083C604894424443B4424207D258B5C2410E9BCFEFFFF8B4C24188B5C2410"
$__HandleImgSearch_Opcode32 &= "C644240D0041894C24183B4C24500F8C2BFEFFFF8B442454506A00FF1578F100108B4C24648B1D08F0001051FFD38B7424708B3D10F0001085F674138B44246C85C074085056FF151"
$__HandleImgSearch_Opcode32 &= "8F0001056FFD78B74244085F674138B44246885C074085056FF1518F0001056FFD78B44242885C0740350FFD38B44243485C0740950E8030A000083C4048B44243885C0740950E8F2"
$__HandleImgSearch_Opcode32 &= "09000083C4048B44244885C0740950E8E109000083C404807C240D000F8413FAFFFF8B44241899F77C242C8B4C241C518B4C24345103450C035508505268740B0110684C3D0110E81"
$__HandleImgSearch_Opcode32 &= "F1100008B8C24CC00000083C4185F5E5B33CCB84C3D0110E8810900008BE55DC21800CCCCCC558BEC83E4F881ECA4000000A10020011033C4898424A00000005356578B7D1833DB33"
$__HandleImgSearch_Opcode32 &= "C06A2E57898424880000008984248C000000895C241CC7442434FFFFFFFF895C2430895C2428895C2424E87E1000008BF083C4083BF3744D4668DC0A011056E8DA0A000083C40885C"
$__HandleImgSearch_Opcode32 &= "0742468C80A011056E8C80A000083C40885C0741268CC0A011056E8B60A000083C40885C075168B356CF100106A31FFD66A3289442424FFD68944241C8BC78D9B000000008A0880F9"
$__HandleImgSearch_Opcode32 &= "20740580F909750340EBF180382A8BD80F85730200008D9B000000000FBE43014350E8BC11000083C40483F8480F848101000083F8570F84110100006A0468840B011053E8A812000"
$__HandleImgSearch_Opcode32 &= "083C40C85C0751383C3048BF3E882E4FFFF89442428E9BC0100006A05688C0B011053E88112000083C40C85C00F859E0000006A1F83C3058D8C24900000005351E8CE0D00008A9424"
$__HandleImgSearch_Opcode32 &= "9800000083C40CC68424AB000000008DB4248C00000084D2742190B9940B0110B0203AD074128A41014184C075F48A56014684D275E5EB03C606008DB4248C000000E814E2FFFF83F"
$__HandleImgSearch_Opcode32 &= "8FF75186A108BD66A0052E81B0D000083C40C8944242CE92A0100008BC8C1E9080FB6D00FB6C9C1E208C1E8100BCA0FB6C0C1E1080BC8894C242CE9060100008BF3E8BCE3FFFF8944"
$__HandleImgSearch_Opcode32 &= "241485C0790DC744241400000000E9EA0000003DFF0000000F8EDF000000C7442414FF000000E9D20000008D73018BC68A0880F920740580F909750340EBF18A0884C9744180F92D7"
$__HandleImgSearch_Opcode32 &= "40580F92B75014080383075318A480180F978740580F95875240FBE480251E81B0A000083C40485C074136A106A0056E8650C000083C40C89442420EB7756E8970C000089442424EB"
$__HandleImgSearch_Opcode32 &= "688D73018BC68D49008A0880F920740580F909750340EBF18A0884C9744180F92D740580F92B75014080383075318A480180F978740580F95875240FBE500252E8B109000083C4048"
$__HandleImgSearch_Opcode32 &= "5C074136A106A0056E8FB0B000083C40C8944241CEB0D56E82D0C00008944242083C4048BFB85DB0F84A00000008A1384D20F8496000000B9940B0110B0208BFF3AD0742C8A410141"
$__HandleImgSearch_Opcode32 &= "84C075F48A57014784D275E3B8700B01105F5E5B8B8C24A000000033CCE85E0600008BE55DC21400478BC78A0880F920740580F909750340EBF180382A8BD80F8493FDFFFF8B44242"
$__HandleImgSearch_Opcode32 &= "88B542420508D4C2444518B4C2424528BD7E849E5FFFF8BF083C40C8974246485F674196A00FF157CF100108BF8897C247485FF752356FF1508F00010B8700B01105F5E5B8B8C24A0"
$__HandleImgSearch_Opcode32 &= "00000033CCE8E50500008BE55DC214008B1D08F0001033C0837C244001894424488944244C8944241C894424348944246C88442411755D8D4424785056FF1584F1001085C074388B9"
$__HandleImgSearch_Opcode32 &= "424840000006A018D4C24165157528D4C24308D542440E803E2FFFF894424448B84249800000083C41050FFD38B8C248400000051FFD38BCEE8F1EBFFFF8BF08944246485F60F8460"
$__HandleImgSearch_Opcode32 &= "FFFFFF6A088D5424165257568D4C24308D542440E8BDE1FFFF83C4108944243C85C00F84450200008B75108B5D142B75082B5D0C574643FF1520F000108944244885C00F842402000"
$__HandleImgSearch_Opcode32 &= "0535657FF1504F000108944244C85C00F840F0200008B4C24485051FF1518F000108944246C85C00F84F70100008B550C8B45088B4C2448682000CC0052505753566A006A0051FF15"
$__HandleImgSearch_Opcode32 &= "28F0001085C00F84D00100008B4424488B4C244C6A088D5424175250518D4C24708D542448E81BE1FFFF8BF883C410897C241C85FF0F84A10100008B4C24308B7424380FAF4C24200"
$__HandleImgSearch_Opcode32 &= "FAF742460807C241200894C2450897424547507807C2413007440837C242CFF74088164242CF8F8F80033C085F67E0C812487F8F8F800403BC67CF433C085C97E348B54243C8DA424"
$__HandleImgSearch_Opcode32 &= "00000000812482F8F8F800403BC17CF4EB048B54243C85C97E138D42038DA42400000000C6000083C0044975F78B5C241483FB010F8D0B02000085F67E0F8D47038BCE90C6000083C"
$__HandleImgSearch_Opcode32 &= "0044975F733F689742424397424540F8EF20000008B54243C8B1A8B4C2438895C2440EB078DA424000000008B44241C8D3CB500000000391C0774178B44243485C07405833800750A"
$__HandleImgSearch_Opcode32 &= "3B5C242C0F85960100008BC699F7F98B7424602BF0397424200F8F7D0100008BC12BC2394424300F8F6F0100008B74242433DBC644241101895C2444395C24507E7C8B44243C8B542"
$__HandleImgSearch_Opcode32 &= "4342BD0C6442411018BCE897C24288954245CEB068D9B000000008B108B7C241C3914B7741B837C243400740A8B7C245C833C0700750A3B54242C0F8506010000433B5C24307D0346"
$__HandleImgSearch_Opcode32 &= "EB158B5424388D3495000000000174242833DB03CA8BF18B5424444283C004895424443B5424507CA98B7424248B542474526A00FF1578F100108B4424648B1D08F0001050FFD38B7"
$__HandleImgSearch_Opcode32 &= "C244885FF74178B44246C85C074085057FF1518F0001057FF1510F000108B44244C85C0740350FFD38B44243C85C0740950E8AA02000083C4048B44243485C0740950E89902000083"
$__HandleImgSearch_Opcode32 &= "C4048B44241C85C0740950E88802000083C404807C2411000F8470FCFFFF8BC699F77C24388B4C2420518B4C24345133C92BC103450C5033C02BD00355085268740B0110BA4C3D011"
$__HandleImgSearch_Opcode32 &= "0E8230200008B8C24C000000083C4145F5E5B33CCB84C3D0110E8220200008BE55DC214008B5C24408B4C2438C6442411008B74242446897424243B7424540F8C34FEFFFFE90AFFFF"
$__HandleImgSearch_Opcode32 &= "FF33F689742424397424540F8EFAFEFFFF8B4C24388BC699F7F98B7C24602BF8397C24200F8F9D0100002BCA394C24300F8F9101000033C0C64424110189442458894424448974242"
$__HandleImgSearch_Opcode32 &= "8394424500F8EB8FEFFFF8B44243C8D0CB500000000894C24688B4C24342BC8C644241101897424408BF8894C245C0FB647028A57013BD87E07C644241200EB088AC82ACB884C2412"
$__HandleImgSearch_Opcode32 &= "0FB6D2895424703BDA7E07C644241A00EB0E8B5C24148ACA2A4C2414884C241A0FB60F3BD97E07C644241B00EB0E8AD12A5424148854241B8B5424708B5C2414BEFF0000002BF03BD"
$__HandleImgSearch_Opcode32 &= "E7E040CFFEB0202C3BEFF0000002BF23BDE7E07C6442419FFEB0602D388542419BAFF0000002BD13BDA7E07C6442413FFEB0602CB884C24138B54241C8B7424288A4CB2028A5CB201"
$__HandleImgSearch_Opcode32 &= "8A14B23A4C2412721C3AC877183A5C241A72123A5C2419770C3A54241B72063A5424137619837C243400740A8B44245C833C070075088B4C242C390F755A8B44245840894424583B4"
$__HandleImgSearch_Opcode32 &= "424307D074689742428EB258B4424388D0C8500000000014C24688B4C244003C8C744245800000000894C2440894C24288B4424444083C704894424443B4424500F8D56FDFFFF8B5C"
$__HandleImgSearch_Opcode32 &= "2414E9BDFEFFFF8B5C24148B742424C64424110046897424243B7424540F8C3BFEFFFFE930FDFFFFCCCCCCCCCC558BEC8B4D088D450C50516A3252E8C60B000083C4105DC33B0D002"
$__HandleImgSearch_Opcode32 &= "001107502F3C3E94C0E00008BFF558BEC837D0800742DFF75086A00FF35FC330110FF1594F0001085C0751856E86E0F00008BF0FF1590F0001050E81E0F00005989065E5DC38BFF55"
$__HandleImgSearch_Opcode32 &= "8BEC8B4508568BF1C6460C0085C07563E88A1B00008946088B486C890E8B4868894E048B0E3B0DE028011074128B0D982601108548707507E83919000089068B46043B05A02501107"
$__HandleImgSearch_Opcode32 &= "4168B46088B0D982601108548707508E8981100008946048B4608F6407002751483487002C6460C01EB0A8B08890E8B40048946048BC65E5DC204008BFF558BEC8B550C568B750857"
$__HandleImgSearch_Opcode32 &= "0FB6068D48BF4683F919770383C0200FB60A8D79BF4283FF19770383C12085C074043BC174DA5F2BC15E5DC38BFF558BEC83EC1053FF75108D4DF0E82CFFFFFF8B5D0885DB7523E87"
$__HandleImgSearch_Opcode32 &= "A0E0000C70016000000E8B4200000385DFC74078B45F8836070FDB8FFFFFF7FEB7F568B750C85F67524E84F0E0000C70016000000E889200000807DFC0074078B45F8836070FDB8FF"
$__HandleImgSearch_Opcode32 &= "FFFF7FEB528B45F083781400750B5653E84DFFFFFF5959EB312BDE570FB604338D4DF05150E8851D00008BF80FB6068D4DF05150E8761D000083C4104685FF74043BF874D72BF88BC"
$__HandleImgSearch_Opcode32 &= "75F807DFC0074078B4DF8836170FD5E5BC9C38BFF558BEC33C039053034011075273945087517E8C10D0000C70016000000E8FB1F0000B8FFFFFF7F5DC339450C74E45DE9D1FEFFFF"
$__HandleImgSearch_Opcode32 &= "50FF750CFF7508E8FEFEFFFF83C40C5DC38BFF558BEC83EC10FF750C8D4DF0E826FEFFFF8B45F083B8AC000000017E138D45F0506A04FF7508E8BB1F000083C40CEB108B80C800000"
$__HandleImgSearch_Opcode32 &= "08B4D080FB7044883E004807DFC0074078B4DF8836170FDC9C38BFF558BEC833D303401100075128B45088B0DD02801100FB7044183E0045DC36A00FF7508E885FFFFFF59595DC38B"
$__HandleImgSearch_Opcode32 &= "FF558BEC83EC10FF750C8D4DF0E8A7FDFFFF8B45F083B8AC000000017E168D45F0506880000000FF7508E8391F000083C40CEB128B80C80000008B4D080FB704482580000000807DF"
$__HandleImgSearch_Opcode32 &= "C0074078B4DF8836170FDC9C38BFF558BEC833D303401100075148B45088B0DD02801100FB7044125800000005DC36A00FF7508E87EFFFFFF59595DC38BFF558BEC83EC1C56FF7508"
$__HandleImgSearch_Opcode32 &= "8D4DE4E820FDFFFF8B45108B750C85C07402893085F67524E8650C0000C70016000000E89F1E0000807DF00074078B45EC836070FD33C0E9E0010000837D1400740C837D14027CD08"
$__HandleImgSearch_Opcode32 &= "37D14247FCA8365FC008B4DE4538A1E578D7E0183B9AC000000017E178D45E4500FB6C36A0850E8631E00008B4DE483C40CEB108B91C80000000FB6C30FB7044283E00885C074058A"
$__HandleImgSearch_Opcode32 &= "1F47EBC780FB2D7506834D1802EB0580FB2B75038A1F478B451485C00F884F01000083F8010F844601000083F8240F8F3D01000085C0752A80FB307409C745140A000000EB368A073"
$__HandleImgSearch_Opcode32 &= "C78740D3C587409C7451408000000EB23C7451410000000EB0A83F810751580FB3075108A073C7874043C5875068A5F0183C70283C8FF33D2F775148BB1C80000008955F80FB6CB0F"
$__HandleImgSearch_Opcode32 &= "B70C4E8BD183E20474080FBECB83E930EB1981E10301000074308D4B9F80F9190FBECB770383E92083C1C93B4D14731A834D18083945FC722875053B4DF87621834D1804837D10007"
$__HandleImgSearch_Opcode32 &= "5238B45184FA8087520837D100074038B7D0C8365FC00EB5B8B55FC0FAF551403D18955FC8A1F47EB8ABEFFFFFF7FA804751BA801753D83E0027409817DFC00000080770985C0752B"
$__HandleImgSearch_Opcode32 &= "3975FC7626E8C50A0000F6451801C700220000007406834DFCFFEB0FF64518026A00580F95C003C68945FC8B451085C074028938F64518027403F75DFC807DF00074078B45EC83607"
$__HandleImgSearch_Opcode32 &= "0FD8B45FCEB188B451085C074028930807DF00074078B45EC836070FD33C05F5B5EC9C38BFF558BEC33C050FF7510FF750CFF7508390530340110750768E4280110EB0150E8AFFDFF"
$__HandleImgSearch_Opcode32 &= "FF83C4145DC38BFF558BEC6A0A6A00FF7508E8C4FFFFFF83C40C5DC38BFF558BEC5DE9DFFFFFFFCCCCCCCCCCCCCCCCCCCCCCCC8B4C240C5785C90F849200000056538BD98B742414F"
$__HandleImgSearch_Opcode32 &= "7C6030000008B7C2410750BC1E9020F8585000000EB278A0683C601880783C70183E901742B84C0742FF7C60300000075E58BD9C1E902756183E30374138A0683C601880783C70184"
$__HandleImgSearch_Opcode32 &= "C0743783EB0175ED8B4424105B5E5FC3F7C7030000007416880783C70183E9010F8498000000F7C70300000075EA8BD9C1E9027574880783C70183EB0175F65B5E8B4424085FC3891"
$__HandleImgSearch_Opcode32 &= "783C70483E901749FBAFFFEFE7E8B0603D083F0FF33C28B1683C604A90001018174DC84D2742C84F6741EF7C20000FF00740CF7C2000000FF75C48917EB1881E2FFFF00008917EB0E"
$__HandleImgSearch_Opcode32 &= "81E2FF0000008917EB0433D2891783C70433C083E901740C33C0890783C70483E90175F683E3030F8577FFFFFF8B4424105B5E5FC38BFF558BEC538B5D0883FBE0776F5657833DFC3"
$__HandleImgSearch_Opcode32 &= "30110007518E8712000006A1EE8BB1E000068FF000000E8F01B0000595985DB74048BC3EB0333C040506A00FF35FC330110FF1598F000108BF885FF75266A0C5E3905943A0110740D"
$__HandleImgSearch_Opcode32 &= "53E8752000005985C075A9EB07E8790800008930E87208000089308BC75F5EEB1453E85420000059E85E080000C7000C00000033C05B5DC3CCCCCCCCCCCCCCCC558BEC578B7D0833C"
$__HandleImgSearch_Opcode32 &= "083C9FFF2AE83C101F7D983EF018A450CFDF2AE83C7013807740433C0EB028BC7FC5FC9C38BFF558BEC83EC20535733DB6A0733C0598D7DE4895DE0F3AB395D0C7515E8FB070000C7"
$__HandleImgSearch_Opcode32 &= "0016000000E8351A000083C8FFEB4D8B45083BC374E4568945E88945E08D45105053FF750C8D45E050C745E4FFFFFF7FC745EC42000000E8E121000083C410FF4DE48BF078078B45E"
$__HandleImgSearch_Opcode32 &= "08818EB0C8D45E05053E8BB1F000059598BC65E5F5BC9C38BFF558BEC83EC1853FF750C8D4DE8E82CF8FFFF8B5D0881FB0001000073548B4DE883B9AC000000017E148D45E8506A02"
$__HandleImgSearch_Opcode32 &= "53E8B81900008B4DE883C40CEB0D8B81C80000000FB7045883E00285C0740F8B81D00000000FB60418E9A7000000807DF40074078B45F0836070FD8BC3E9A00000008B45E883B8AC0"
$__HandleImgSearch_Opcode32 &= "00000017E31895D08C17D08088D45E8508B450825FF00000050E81E2F0000595985C074128A45086A028845FC885DFDC645FE0059EB15E8E5060000C7002A00000033C9885DFCC645"
$__HandleImgSearch_Opcode32 &= "FD00418B45E86A01FF70048D55F86A0352518D4DFC516800020000FF70148D45E850E8872E000083C42485C00F846BFFFFFF83F8010FB645F874090FB64DF9C1E0080BC1807DF4007"
$__HandleImgSearch_Opcode32 &= "4078B4DF0836170FD5BC9C38BFF558BEC833D303401100075108B45088D489F83F919771183C0E05DC36A00FF7508E8C2FEFFFF59595DC38BFF558BEC83EC10837D10005356570F84"
$__HandleImgSearch_Opcode32 &= "C6000000FF75148D4DF0E8DEF6FFFF8B5D0885DB7527E82C060000C70016000000E866180000807DFC0074078B45F8836070FDB8FFFFFF7FE98F0000008B750C85F674D2BFFFFFFF7"
$__HandleImgSearch_Opcode32 &= "F397D107621E8F4050000C70016000000E82E180000807DFC0074078B45F8836070FD8BC7EB5D8B45F083781400751CFF75105653E83A2E000083C40C807DFC0074418B4DF8836170"
$__HandleImgSearch_Opcode32 &= "FDEB382BDE0FB604338D4DF05150E81D1500008BF80FB6068D4DF05150E80E15000083C41046FF4D10740885FF74043BF874D22BF88BC7EBBB33C05F5E5BC9C38BFF558BEC33C0390"
$__HandleImgSearch_Opcode32 &= "53034011075303945087517E85D050000C70016000000E897170000B8FFFFFF7F5DC339450C74E4817D10FFFFFF7F77DB5DE9AC2D000050FF7510FF750CFF7508E8D0FEFFFF83C410"
$__HandleImgSearch_Opcode32 &= "5DC38BFF558BEC83EC20535733DB6A0733C0598D7DE4895DE0F3AB395D147518E800050000C70016000000E83A17000083C8FFE9900000008B7D10568B750C3BFB74193BF37515E8D"
$__HandleImgSearch_Opcode32 &= "9040000C70016000000E81317000083C8FFEB6BB8FFFFFF7F8945E43BF87703897DE4FF751C8D45E0FF7518C745EC42000000FF75148975E8508975E0FF550883C4108945143BF374"
$__HandleImgSearch_Opcode32 &= "353BC37C22FF4DE478078B45E08818EB118D45E05053E8911C0000595983F8FF74058B4514EB0F33C0395DE4885C3EFF0F9DC083E8025E5F5BC9C38BFF558BEC837D10007515E8490"
$__HandleImgSearch_Opcode32 &= "40000C70016000000E88316000083C8FF5DC3568B750885F67406837D0C00770DE826040000C70016000000EB31FF7518FF7514FF7510FF750C5668616E0010E8E4FEFFFF83C41885"
$__HandleImgSearch_Opcode32 &= "C07903C6060083F8FE7513E8F3030000C70022000000E82D16000083C8FF5E5DC38BFF558BECFF75146A00FF7510FF750CFF7508E871FFFFFF83C4145DC36A0868800C0110E8EE3F0"
$__HandleImgSearch_Opcode32 &= "0008B450C83F801757AE8F503000085C0750733C0E938010000E89B11000085C07507E8FA030000EBE9E8713F0000FF15A4F00010A3F44E0110E8CA3E0000A3C4300110E8F7380000"
$__HandleImgSearch_Opcode32 &= "85C07907E8470E0000EBCFE8F53D000085C07820E8763B000085C078176A00E8071700005985C0750BFF05C0300110E9D2000000E8033B0000EBC933FF3BC7755B393DC03001107E8"
$__HandleImgSearch_Opcode32 &= "1FF0DC0300110897DFC393D603401107505E8B9180000397D10750FE8D33A0000E8E20D0000E866030000C745FCFEFFFFFFE807000000E98200000033FF397D10750E833DEC280110"
$__HandleImgSearch_Opcode32 &= "FF7405E8B70D0000C3EB6A83F8027559E8760D000068140200006A01E8AB37000059598BF03BF70F840CFFFFFF56FF35EC280110FF3524340110FF15A0F00010FFD085C074175756E"
$__HandleImgSearch_Opcode32 &= "8AF0D00005959FF159CF000108906834E04FFEB1856E8EAF2FFFF59E9D0FEFFFF83F803750757E8FE0F00005933C040E8DE3E0000C20C006A0C68A00C0110E88A3E00008BF98BF28B"
$__HandleImgSearch_Opcode32 &= "5D0833C0408945E485F6750C3915C03001100F84C50000008365FC003BF0740583FE02752EA1FCF1001085C07408575653FFD08945E4837DE4000F8496000000575653E843FEFFFF8"
$__HandleImgSearch_Opcode32 &= "945E485C00F8483000000575653E86ACCFFFF8945E483FE01752485C07520575053E856CCFFFF576A0053E813FEFFFFA1FCF1001085C07406576A0053FFD085F6740583FE03752657"
$__HandleImgSearch_Opcode32 &= "5653E8F3FDFFFF85C075032145E4837DE4007411A1FCF1001085C07408575653FFD08945E4C745FCFEFFFFFF8B45E4EB1D8B45EC8B088B095051E8EE4000005959C38B65E8C745FCF"
$__HandleImgSearch_Opcode32 &= "EFFFFFF33C0E8E63D0000C38BFF558BEC837D0C017505E8E9400000FF75088B4D108B550CE8ECFEFFFF595DC20C008BFF558BEC81EC28030000A3E0310110890DDC3101108915D831"
$__HandleImgSearch_Opcode32 &= "0110891DD43101108935D0310110893DCC310110668C15F8310110668C0DEC310110668C1DC8310110668C05C4310110668C25C0310110668C2DBC3101109C8F05F03101108B4500A"
$__HandleImgSearch_Opcode32 &= "3E43101108B4504A3E83101108D4508A3F43101108B85E0FCFFFFC7053031011001000100A1E8310110A3E4300110C705D8300110090400C0C705DC30011001000000A10020011089"
$__HandleImgSearch_Opcode32 &= "85D8FCFFFFA1042001108985DCFCFFFFFF15B8F00010A3283101106A01E8A4400000596A00FF15B4F000106800F20010FF15B0F00010833D283101100075086A01E88040000059680"
$__HandleImgSearch_Opcode32 &= "90400C0FF15ACF0001050FF15A8F00010C9C38BFF558BEC8B450833C93B04CD0820011074134183F92D72F18D48ED83F911770E6A0D585DC38B04CD0C2001105DC30544FFFFFF6A0E"
$__HandleImgSearch_Opcode32 &= "593BC81BC023C183C0085DC3E8CA0B000085C07506B870210110C383C008C3E8B70B000085C07506B874210110C383C00CC38BFF558BEC56E8E2FFFFFF8B4D08518908E882FFFFFF5"
$__HandleImgSearch_Opcode32 &= "98BF0E8BCFFFFFF89305E5DC36A0068001000006A00FF15BCF0001033C985C00F95C1A3FC3301108BC1C3FF35FC330110FF15C0F000108325FC33011000C32DA4030000742283E804"
$__HandleImgSearch_Opcode32 &= "741783E80D740C48740333C0C3B804040000C3B812040000C3B804080000C3B811040000C38BFF56578BF0680101000033FF8D461C5750E8743F000033C00FB7C88BC1897E04897E0"
$__HandleImgSearch_Opcode32 &= "8897E0CC1E1100BC18D7E10ABABABB97821011083C40C8D461C2BCEBF010100008A14018810404F75F78D861D010000BE000100008A14088810404E75F75F5EC38BFF558BEC81EC1C"
$__HandleImgSearch_Opcode32 &= "050000A10020011033C58945FC53578D85E8FAFFFF50FF7604FF15C4F00010BF0001000085C00F84FC00000033C0888405FCFEFFFF403BC772F48A85EEFAFFFFC685FCFEFFFF2084C"
$__HandleImgSearch_Opcode32 &= "074308D9DEFFAFFFF0FB6C80FB6033BC877162BC140508D940DFCFEFFFF6A2052E8B13E000083C40C8A430183C30284C075D66A00FF760C8D85FCFAFFFFFF760450578D85FCFEFFFF"
$__HandleImgSearch_Opcode32 &= "506A016A00E8E53F000033DB53FF76048D85FCFDFFFF5750578D85FCFEFFFF5057FF760C53E80526000083C44453FF76048D85FCFCFFFF5750578D85FCFEFFFF506800020000FF760"
$__HandleImgSearch_Opcode32 &= "C53E8E025000083C42433C00FB78C45FCFAFFFFF6C101740E804C061D108A8C05FCFDFFFFEB11F6C1027415804C061D208A8C05FCFCFFFF888C061D010000EB07889C061D01000040"
$__HandleImgSearch_Opcode32 &= "3BC772BFEB528D861D010000C785E4FAFFFF9FFFFFFF33C92985E4FAFFFF8B95E4FAFFFF8D840E1D01000003D08D5A2083FB19770A804C0E1D108D5120EB0D83FA19770C804C0E1D2"
$__HandleImgSearch_Opcode32 &= "08D51E08810EB03C60000413BCF72C68B4DFC5F33CD5BE8C1EDFFFFC9C36A0C68C00C0110E88B390000E8990900008BF8A198260110854770741D837F6C0074178B776885F675086A"
$__HandleImgSearch_Opcode32 &= "20E8E6120000598BC6E8A3390000C36A0DE871400000598365FC008B77688975E43B35A0250110743685F6741A56FF15CCF0001085C0750F81FE78210110740756E85DEDFFFF59A1A"
$__HandleImgSearch_Opcode32 &= "02501108947688B35A02501108975E456FF15C8F00010C745FCFEFFFFFFE805000000EB8E8B75E46A0DE8373F000059C38BFF558BEC83EC105333DB538D4DF0E850EDFFFF891D0034"
$__HandleImgSearch_Opcode32 &= "011083FEFE751EC7050034011001000000FF15D4F00010385DFC74458B4DF8836170FDEB3C83FEFD7512C7050034011001000000FF15D0F00010EBDB83FEFC75128B45F08B4004C70"
$__HandleImgSearch_Opcode32 &= "50034011001000000EBC4385DFC74078B45F8836070FD8BC65BC9C38BFF558BEC83EC20A10020011033C58945FC538B5D0C568B750857E864FFFFFF8BF833F6897D083BFE750E8BC3"
$__HandleImgSearch_Opcode32 &= "E8BAFCFFFF33C0E9A10100008975E433C039B8A82501100F8491000000FF45E483C0303DF000000072E781FFE8FD00000F847401000081FFE9FD00000F84680100000FB7C750FF15D"
$__HandleImgSearch_Opcode32 &= "8F0001085C00F84560100008D45E85057FF15C4F0001085C00F843701000068010100008D431C5650E8D43B000033D24283C40C897B0489730C3955E80F86FC000000807DEE000F84"
$__HandleImgSearch_Opcode32 &= "D30000008D75EF8A0E84C90F84C60000000FB646FF0FB6C9E9A900000068010100008D431C5650E88D3B00008B4DE483C40C6BC9308975E08DB1B82501108975E4EB2B8A460184C07"
$__HandleImgSearch_Opcode32 &= "4290FB63E0FB6C0EB128B45E08A80A425011008443B1D0FB64601473BF876EA8B7D0883C602803E0075D08B75E4FF45E083C608837DE0048975E472E98BC7897B04C7430801000000"
$__HandleImgSearch_Opcode32 &= "E869FBFFFF6A0689430C8D43108D89AC2501105A668B3166893083C10283C0024A75F18BF3E8D7FBFFFFE9B4FEFFFF804C031D04403BC176F683C602807EFF000F8530FFFFFF8D431"
$__HandleImgSearch_Opcode32 &= "EB9FE000000800808404975F98B4304E811FBFFFF89430C895308EB0389730833C00FB7C88BC1C1E1100BC18D7B10ABABABEBA73935003401100F8554FEFFFF83C8FF8B4DFC5F5E33"
$__HandleImgSearch_Opcode32 &= "CD5BE8B8EAFFFFC9C36A1468E00C0110E882360000834DE0FFE88C0600008BF8897DDCE8D8FCFFFF8B5F688B7508E871FDFFFF8945083B43040F84570100006820020000E8BF2E000"
$__HandleImgSearch_Opcode32 &= "0598BD885DB0F8446010000B9880000008B77688BFBF3A583230053FF7508E8B4FDFFFF59598945E085C00F85FC0000008B75DCFF7668FF15CCF0001085C075118B46683D78210110"
$__HandleImgSearch_Opcode32 &= "740750E835EAFFFF59895E68538B3DC8F00010FFD7F64670020F85EA000000F60598260110010F85DD0000006A0DE8EE3C0000598365FC008B4304A3103401108B4308A3143401108"
$__HandleImgSearch_Opcode32 &= "B430CA31834011033C08945E483F8057D10668B4C431066890C450434011040EBE833C08945E43D010100007D0D8A4C181C88889823011040EBE933C08945E43D000100007D108A8C"
$__HandleImgSearch_Opcode32 &= "181D0100008888A024011040EBE6FF35A0250110FF15CCF0001085C07513A1A02501103D78210110740750E87CE9FFFF59891DA025011053FFD7C745FCFEFFFFFFE802000000EB306"
$__HandleImgSearch_Opcode32 &= "A0DE8683B000059C3EB2583F8FF752081FB78210110740753E846E9FFFF59E8D4F8FFFFC70016000000EB048365E0008B45E0E83A350000C3833DEC4E01100075126AFDE856FEFFFF"
$__HandleImgSearch_Opcode32 &= "59C705EC4E01100100000033C0C38BFF558BEC53568B35C8F00010578B7D0857FFD68B87B000000085C0740350FFD68B87B800000085C0740350FFD68B87B400000085C0740350FFD"
$__HandleImgSearch_Opcode32 &= "68B87C000000085C0740350FFD68D5F50C7450806000000817BF89C26011074098B0385C0740350FFD6837BFC00740A8B430485C0740350FFD683C310FF4D0875D68B87D400000005"
$__HandleImgSearch_Opcode32 &= "B400000050FFD65F5E5B5DC38BFF558BEC578B7D0885FF0F848300000053568B35CCF0001057FFD68B87B000000085C0740350FFD68B87B800000085C0740350FFD68B87B40000008"
$__HandleImgSearch_Opcode32 &= "5C0740350FFD68B87C000000085C0740350FFD68D5F50C7450806000000817BF89C26011074098B0385C0740350FFD6837BFC00740A8B430485C0740350FFD683C310FF4D0875D68B"
$__HandleImgSearch_Opcode32 &= "87D400000005B400000050FFD65E5B8BC75F5DC38BFF558BEC53568B75088B86BC00000033DB573BC3746F3D682A011074688B86B00000003BC3745E3918755A8B86B80000003BC37"
$__HandleImgSearch_Opcode32 &= "4173918751350E8A5E7FFFFFFB6BC000000E8913E000059598B86B40000003BC374173918751350E884E7FFFFFFB6BC000000E8073E00005959FFB6B0000000E86CE7FFFFFFB6BC00"
$__HandleImgSearch_Opcode32 &= "0000E861E7FFFF59598B86C00000003BC37444391875408B86C40000002DFE00000050E840E7FFFF8B86CC000000BF800000002BC750E82DE7FFFF8B86D00000002BC750E81FE7FFF"
$__HandleImgSearch_Opcode32 &= "FFFB6C0000000E814E7FFFF83C4108B86D40000003DA0260110741B3998B4000000751350E80D3A0000FFB6D4000000E8EBE6FFFF59598D7E50C7450806000000817FF89C26011074"
$__HandleImgSearch_Opcode32 &= "118B073BC3740B3918750750E8C6E6FFFF59395FFC74128B47043BC3740B3918750750E8AFE6FFFF5983C710FF4D0875C756E8A0E6FFFF595F5E5B5DC38BFF558BEC578B7D0C85FF7"
$__HandleImgSearch_Opcode32 &= "43B8B450885C07434568B303BF77428578938E86AFDFFFF5985F6741B56E8EEFDFFFF833E0059750F81FE08280110740756E873FEFFFF598BC75EEB0233C05F5DC36A0C68000D0110"
$__HandleImgSearch_Opcode32 &= "E80A320000E8180200008BF0A1982601108546707422837E6C00741CE8010200008B706C85F675086A20E8600B0000598BC6E81D320000C36A0CE8EB380000598365FC00FF35E0280"
$__HandleImgSearch_Opcode32 &= "11083C66C56E859FFFFFF59598945E4C745FCFEFFFFFFE802000000EBBE6A0CE8E4370000598B75E4C36A00FF15DCF00010C3FF15E0F00010C204008BFF56FF35F0280110FF15E4F0"
$__HandleImgSearch_Opcode32 &= "00108BF085F6751BFF3520340110FF15A0F000108BF056FF35F0280110FF15E8F000108BC65EC3A1EC28011083F8FF741650FF3528340110FF15A0F00010FFD0830DEC280110FFA1F"
$__HandleImgSearch_Opcode32 &= "028011083F8FF740E50FF15ECF00010830DF0280110FFE9053700006A0868200D0110E80E3100006858F50010FF15F0F000108B7508C7465C100101108366080033FF47897E14897E"
$__HandleImgSearch_Opcode32 &= "70C686C800000043C6864B01000043C74668782101106A0DE8EB370000598365FC00FF7668FF15C8F00010C745FCFEFFFFFFE83E0000006A0CE8CA37000059897DFC8B450C89466C8"
$__HandleImgSearch_Opcode32 &= "5C07508A1E028011089466CFF766CE8BBFBFFFF59C745FCFEFFFFFFE815000000E8C4300000C333FF478B75086A0DE8B336000059C36A0CE8AA36000059C38BFF5657FF1590F00010"
$__HandleImgSearch_Opcode32 &= "FF35EC2801108BF8E8C4FEFFFFFFD08BF085F6754E68140200006A01E8F12800008BF0595985F6743A56FF35EC280110FF3524340110FF15A0F00010FFD085C074186A0056E8F8FEF"
$__HandleImgSearch_Opcode32 &= "FFF5959FF159CF00010834E04FF8906EB0956E833E4FFFF5933F657FF15F4F000105F8BC65EC38BFF56E87FFFFFFF8BF085F675086A10E858090000598BC65EC36A0868480D0110E8"
$__HandleImgSearch_Opcode32 &= "C72F00008B750885F60F84F80000008B462485C0740750E8E6E3FFFF598B462C85C0740750E8D8E3FFFF598B463485C0740750E8CAE3FFFF598B463C85C0740750E8BCE3FFFF598B4"
$__HandleImgSearch_Opcode32 &= "64085C0740750E8AEE3FFFF598B464485C0740750E8A0E3FFFF598B464885C0740750E892E3FFFF598B465C3D10010110740750E881E3FFFF596A0DE85D360000598365FC008B7E68"
$__HandleImgSearch_Opcode32 &= "85FF741A57FF15CCF0001085C0750F81FF78210110740757E854E3FFFF59C745FCFEFFFFFFE8570000006A0CE82436000059C745FC010000008B7E6C85FF742357E8ADFAFFFF593B3"
$__HandleImgSearch_Opcode32 &= "DE0280110741481FF08280110740C833F00750757E82AFBFFFF59C745FCFEFFFFFFE81E00000056E8FCE2FFFF59E8042F0000C204008B75086A0DE8F434000059C38B75086A0CE8E8"
$__HandleImgSearch_Opcode32 &= "34000059C38BFF558BEC833DEC280110FF744B837D0800752756FF35F02801108B35E4F00010FFD685C07413FF35EC280110FF35F0280110FFD6FFD08945085E6A00FF35EC280110F"
$__HandleImgSearch_Opcode32 &= "F3524340110FF15A0F00010FFD0FF7508E878FEFFFFA1F028011083F8FF74096A0050FF15E8F000105DC38BFF576858F50010FF15F0F000108BF885FF7509E8C6FCFFFF33C05FC356"
$__HandleImgSearch_Opcode32 &= "8B357CF000106894F5001057FFD66888F5001057A31C340110FFD6687CF5001057A320340110FFD66874F5001057A324340110FFD6833D1C340110008B35E8F00010A328340110741"
$__HandleImgSearch_Opcode32 &= "6833D2034011000740D833D2434011000740485C07524A1E4F00010A320340110A1ECF00010C7051C3401102C500010893524340110A328340110FF15E0F00010A3F028011083F8FF"
$__HandleImgSearch_Opcode32 &= "0F84C1000000FF352034011050FFD685C00F84B0000000E898040000FF351C3401108B35DCF00010FFD6FF3520340110A31C340110FFD6FF3524340110A320340110FFD6FF3528340"
$__HandleImgSearch_Opcode32 &= "110A324340110FFD6A328340110E8CD32000085C074638B3DA0F0001068ED510010FF351C340110FFD7FFD0A3EC28011083F8FF744468140200006A01E8B32500008BF0595985F674"
$__HandleImgSearch_Opcode32 &= "3056FF35EC280110FF3524340110FFD7FFD085C0741B6A0056E8BEFBFFFF5959FF159CF00010834E04FF890633C040EB07E869FBFFFF33C05E5FC38BFF558BEC83EC185356FF750C8"
$__HandleImgSearch_Opcode32 &= "D4DE8E817E1FFFF8B5D08BE000100003BDE73548B4DE883B9AC000000017E148D45E8506A0153E8A20200008B4DE883C40CEB0D8B81C80000000FB7045883E00185C0740F8B81CC00"
$__HandleImgSearch_Opcode32 &= "00000FB60418E9A3000000807DF40074078B45F0836070FD8BC3E99C0000008B45E883B8AC000000017E31895D08C17D08088D45E8508B450825FF00000050E808180000595985C07"
$__HandleImgSearch_Opcode32 &= "4128A45086A028845FC885DFDC645FE0059EB15E8CFEFFFFFC7002A00000033C9885DFCC645FD00418B45E86A01FF70048D55F86A0352518D4DFC5156FF70148D45E850E875170000"
$__HandleImgSearch_Opcode32 &= "83C42485C00F846FFFFFFF83F8010FB645F874090FB64DF9C1E0080BC1807DF40074078B4DF0836170FD5E5BC9C38BFF558BEC833D303401100075108B45088D48BF83F919771183C"
$__HandleImgSearch_Opcode32 &= "0205DC36A00FF7508E8C3FEFFFF59595DC38BFF558BEC8B4508A32C3401105DC38BFF558BEC81EC28030000A10020011033C58945FC538B5D085783FBFF740753E83A2F00005983A5"
$__HandleImgSearch_Opcode32 &= "E0FCFFFF006A4C8D85E4FCFFFF6A0050E82E2F00008D85E0FCFFFF8985D8FCFFFF8D8530FDFFFF83C40C8985DCFCFFFF8985E0FDFFFF898DDCFDFFFF8995D8FDFFFF899DD4FDFFFF8"
$__HandleImgSearch_Opcode32 &= "9B5D0FDFFFF89BDCCFDFFFF668C95F8FDFFFF668C8DECFDFFFF668C9DC8FDFFFF668C85C4FDFFFF668CA5C0FDFFFF668CADBCFDFFFF9C8F85F0FDFFFF8B45048D4D04898DF4FDFFFF"
$__HandleImgSearch_Opcode32 &= "C78530FDFFFF010001008985E8FDFFFF8B49FC898DE4FDFFFF8B4D0C898DE0FCFFFF8B4D10898DE4FCFFFF8985ECFCFFFFFF15B8F000106A008BF8FF15B4F000108D85D8FCFFFF50F"
$__HandleImgSearch_Opcode32 &= "F15B0F0001085C0751085FF750C83FBFF740753E8452E0000598B4DFC5F33CD5BE86CDEFFFFC9C38BFF566A01BE170400C0566A02E8C5FEFFFF83C40C56FF15ACF0001050FF15A8F0"
$__HandleImgSearch_Opcode32 &= "00105EC38BFF558BECFF352C340110FF15A0F0001085C074035DFFE0FF7518FF7514FF7510FF750CFF7508E8AFFFFFFFCC33C05050505050E8C7FFFFFF83C414C38BFF558BEC83EC1"
$__HandleImgSearch_Opcode32 &= "853FF75108D4DE8E83DDEFFFF8B5D088D43013D00010000770F8B45E88B80C80000000FB70458EB75895D08C17D08088D45E8508B450825FF00000050E87E150000595985C074128A"
$__HandleImgSearch_Opcode32 &= "45086A028845F8885DF9C645FA0059EB0A33C9885DF8C645F900418B45E86A01FF7014FF70048D45FC50518D45F8508D45E86A0150E8B72E000083C42085C075103845F474078B45F"
$__HandleImgSearch_Opcode32 &= "0836070FD33C0EB140FB745FC23450C807DF40074078B4DF0836170FD5BC9C38BFF558BEC6830F60010FF15F0F0001085C074156820F6001050FF157CF0001085C07405FF7508FFD0"
$__HandleImgSearch_Opcode32 &= "5DC38BFF558BECFF7508E8C8FFFFFF59FF7508FF15F8F00010CC6A08E8F92F000059C36A08E8172F000059C38BFF56E82EF7FFFF8BF056E86F04000056E843FDFFFF56E89A3D00005"
$__HandleImgSearch_Opcode32 &= "6E8853D000056E87A3B000056E8633B000083C4185EC38BFF558BEC568B750833C0EB0F85C075108B0E85C97402FFD183C6043B750C72EC5E5DC38BFF558BEC833DA00B0110007419"
$__HandleImgSearch_Opcode32 &= "68A00B0110E8443F00005985C0740AFF7508FF15A00B011059E87C3E000068B4F1001068A0F10010E8A1FFFFFF595985C0755456576896810010E8443E0000B898F10010BE9CF1001"
$__HandleImgSearch_Opcode32 &= "0598BF83BC6730F8B0785C07402FFD083C7043BFE72F1833DF04E0110005F5E741B68F04E0110E8DA3E00005985C0740C6A006A026A00FF15F04E011033C05DC36A2068700D0110E8"
$__HandleImgSearch_Opcode32 &= "D92700006A08E8ED2E0000598365FC0033C0403905643401100F84D8000000A3603401108A4510A25C340110837D0C000F85A0000000FF35E84E01108B35A0F00010FFD68BD8895DD"
$__HandleImgSearch_Opcode32 &= "085DB7468FF35E44E0110FFD68BF8897DD4895DDC897DD883EF04897DD43BFB724BE8D1F5FFFF390774ED3BFB723EFF37FFD68BD8E8BEF5FFFF8907FFD3FF35E84E0110FFD68BD8FF"
$__HandleImgSearch_Opcode32 &= "35E44E0110FFD6395DDC75053945D8740E895DDC895DD08945D88BF8897DD48B5DD0EBABC745E4B8F10010817DE4C4F1001073118B45E48B0085C07402FFD08345E404EBE6C745E0C"
$__HandleImgSearch_Opcode32 &= "8F10010817DE0CCF1001073118B45E08B0085C07402FFD08345E004EBE6C745FCFEFFFFFFE820000000837D10007529C70564340110010000006A08E8052D000059FF7508E8BDFDFF"
$__HandleImgSearch_Opcode32 &= "FF837D100074086A08E8EF2C000059C3E8EB260000C38BFF558BEC6A006A01FF7508E8AFFEFFFF83C40C5DC36A016A006A00E89FFEFFFF83C40CC38BFF558BECE8E9010000FF7508E"
$__HandleImgSearch_Opcode32 &= "8320000005968FF000000E8BEFFFFFFCC8BFF558BEC33C08B4D083B0CC5C8FE0010740A4083F81672EE33C05DC38B04C5CCFE00105DC38BFF558BEC81ECFC010000A10020011033C5"
$__HandleImgSearch_Opcode32 &= "8945FC53568B75085756E8B9FFFFFF8BF833DB5989BD04FEFFFF3BFB0F846C0100006A03E8C94000005983F8010F84070100006A03E8B84000005985C0750D833DD0300110010F84E"
$__HandleImgSearch_Opcode32 &= "E00000081FEFC0000000F843601000068040001106814030000BF6834011057E82240000083C40C85C00F85B80000006804010000BE9A340110565366A3A2360110FF1504F10010BB"
$__HandleImgSearch_Opcode32 &= "FB02000085C0751F68D4FF00105356E8EA3F000083C40C85C0740C33C05050505050E830FBFFFF56E8B63F0000405983F83C762A56E8A93F00008D0445243401108BC82BCE6A03D1F"
$__HandleImgSearch_Opcode32 &= "968CCFF00102BD95350E8BF3E000083C41485C075BD68C4FF0010BE140300005657E8323E000083C40C85C075A5FFB504FEFFFF5657E81E3E000083C40C85C0759168102001006878"
$__HandleImgSearch_Opcode32 &= "FF001057E89B3C000083C40CEB5E5353535353E979FFFFFF6AF4FF1500F100108BF03BF3744683FEFF744133C08A0C47888C0508FEFFFF66391C477408403DF401000072E8538D850"
$__HandleImgSearch_Opcode32 &= "4FEFFFF508D8508FEFFFF50885DFBE88C35000059508D8508FEFFFF5056FF15FCF000108B4DFC5F5E33CD5BE8B7D8FFFFC9C36A03E84E3F00005983F80174156A03E8413F00005985"
$__HandleImgSearch_Opcode32 &= "C0751F833DD030011001751668FC000000E825FEFFFF68FF000000E81BFEFFFF5959C38BFF558BEC8B4508A3903A01105DC38BFF558BECFF35903A0110FF15A0F0001085C0740FFF7"
$__HandleImgSearch_Opcode32 &= "508FFD05985C0740533C0405DC333C05DC38BFF558BEC51568B750C56E8A84A000089450C8B460C59A8827517E8C8E7FFFFC70009000000834E0C2083C8FFE92F010000A840740DE8"
$__HandleImgSearch_Opcode32 &= "ADE7FFFFC70022000000EBE35333DBA8017416895E04A8100F84870000008B4E0883E0FE890E89460C8B460C83E0EF83C80289460C895E04895DFCA90C010000752CE88548000083C"
$__HandleImgSearch_Opcode32 &= "0203BF0740CE87948000083C0403BF0750DFF750CE8144800005985C0750756E8C047000059F7460C08010000570F84800000008B46088B3E8D4801890E8B4E182BF849894E043BFB"
$__HandleImgSearch_Opcode32 &= "7E1D5750FF750CE8BC46000083C40C8945FCEB4D83C82089460C83C8FFEB798B4D0C83F9FF741B83F9FE74168BC183E01F8BD1C1FA05C1E006030495E04D0110EB05B800290110F64"
$__HandleImgSearch_Opcode32 &= "0042074146A02535351E88A3E000023C283C41083F8FF74258B46088A4D088808EB1633FF47578D450850FF750CE84D46000083C40C8945FC397DFC7409834E0C2083C8FFEB088B45"
$__HandleImgSearch_Opcode32 &= "0825FF0000005F5B5EC9C3F6410C407406837908007424FF4904780B8B118802FF010FB6C0EB0C0FBEC05150E876FEFFFF595983F8FF75030906C3FF06C38BFF558BEC5153568BF08"
$__HandleImgSearch_Opcode32 &= "BD9E840E6FFFFF6470C408B008945FC740A837F08007504011EEB4AE826E6FFFF832000EB288B45088A008BCF4BE890FFFFFFFF4508833EFF7513E807E6FFFF83382A750D8BCFB03F"
$__HandleImgSearch_Opcode32 &= "E875FFFFFF85DB7FD4E8F0E5FFFF833800750AE8E6E5FFFF8B4DFC89085E5BC9C38BFF558BEC81EC78020000A10020011033C58945FC538B5D14568B750833C057FF75108B7D0C8D8"
$__HandleImgSearch_Opcode32 &= "DA4FDFFFF89B5C0FDFFFF899DD8FDFFFF8985B8FDFFFF8985F0FDFFFF8985CCFDFFFF8985E8FDFFFF8985D0FDFFFF8985BCFDFFFF8985C8FDFFFFE81CD6FFFF85F6752BE86DE5FFFF"
$__HandleImgSearch_Opcode32 &= "C70016000000E8A7F7FFFF80BDB0FDFFFF00740A8B85ACFDFFFF836070FD83C8FFE9E40A0000F6460C40755E56E80B48000059BA0029011083F8FF741B83F8FE74168BC883E11F8BF"
$__HandleImgSearch_Opcode32 &= "0C1FE05C1E106030CB5E04D0110EB028BCAF641247F759B83F8FF741983F8FE74148BC883E01FC1F905C1E00603048DE04D0110EB028BC2F64024800F8571FFFFFF33F63BFE0F8467"
$__HandleImgSearch_Opcode32 &= "FFFFFF8A1733C989B5DCFDFFFF89B5E0FDFFFF89B5B4FDFFFF8895EFFDFFFF84D20F84390A00004789BDC4FDFFFF39B5DCFDFFFF0F8C260A00008D42E03C58770F0FBEC20FBE80300"
$__HandleImgSearch_Opcode32 &= "0011083E00FEB0233C00FBE84C1500001106A07C1F804598985A0FDFFFF3BC10F87CB090000FF24853A6B0010838DE8FDFFFFFF89B594FDFFFF89B5BCFDFFFF89B5CCFDFFFF89B5D0"
$__HandleImgSearch_Opcode32 &= "FDFFFF89B5F0FDFFFF89B5C8FDFFFFE9940900000FBEC283E820744A83E803743683E80874254848741583E8030F8575090000838DF0FDFFFF08E969090000838DF0FDFFFF04E95D0"
$__HandleImgSearch_Opcode32 &= "90000838DF0FDFFFF01E951090000818DF0FDFFFF80000000E942090000838DF0FDFFFF02E93609000080FA2A752C83C304899DD8FDFFFF8B5BFC899DCCFDFFFF3BDE0F8D17090000"
$__HandleImgSearch_Opcode32 &= "838DF0FDFFFF04F79DCCFDFFFFE9050900008B85CCFDFFFF6BC00A0FBECA8D4408D08985CCFDFFFFE9EA08000089B5E8FDFFFFE9DF08000080FA2A752683C304899DD8FDFFFF8B5BF"
$__HandleImgSearch_Opcode32 &= "C899DE8FDFFFF3BDE0F8DC0080000838DE8FDFFFFFFE9B40800008B85E8FDFFFF6BC00A0FBECA8D4408D08985E8FDFFFFE99908000080FA49745580FA68744480FA6C741880FA770F"
$__HandleImgSearch_Opcode32 &= "8581080000818DF0FDFFFF00080000E972080000803F6C751647818DF0FDFFFF0010000089BDC4FDFFFFE957080000838DF0FDFFFF10E94B080000838DF0FDFFFF20E93F0800008A0"
$__HandleImgSearch_Opcode32 &= "73C36751E807F0134751883C702818DF0FDFFFF0080000089BDC4FDFFFFE91B0800003C33751E807F0132751883C70281A5F0FDFFFFFF7FFFFF89BDC4FDFFFFE9F90700003C640F84"
$__HandleImgSearch_Opcode32 &= "F10700003C690F84E90700003C6F0F84E10700003C750F84D90700003C780F84D10700003C580F84C907000089B5A0FDFFFF83A5C8FDFFFF008D85A4FDFFFF500FB6C250E86B0A000"
$__HandleImgSearch_Opcode32 &= "05985C08A85EFFDFFFF5974228B8DC0FDFFFF8DB5DCFDFFFFE8AEFBFFFF8A074789BDC4FDFFFF84C00F84AFFCFFFF8B8DC0FDFFFF8DB5DCFDFFFFE88CFBFFFFE9680700000FBEC283"
$__HandleImgSearch_Opcode32 &= "F8640F8FE80100000F847902000083F8530F8FF20000000F848000000083E8417410484874584848740848480F858C05000080C220C78594FDFFFF010000008895EFFDFFFF838DF0F"
$__HandleImgSearch_Opcode32 &= "DFFFF408DBDF4FDFFFFB80002000089BDE4FDFFFF89859CFDFFFF39B5E8FDFFFF0F8D48020000C785E8FDFFFF06000000E9A3020000F785F0FDFFFF300800000F8598000000818DF0"
$__HandleImgSearch_Opcode32 &= "FDFFFF00080000E989000000F785F0FDFFFF30080000750A818DF0FDFFFF000800008B8DE8FDFFFF83F9FF7505B9FFFFFF7F83C304F785F0FDFFFF10080000899DD8FDFFFF8B5BFC8"
$__HandleImgSearch_Opcode32 &= "99DE4FDFFFF0F84AB0400003BDE750BA1FC2801108985E4FDFFFF8B85E4FDFFFFC785C8FDFFFF01000000E97904000083E8580F84D3020000484874792BC10F8427FFFFFF48480F85"
$__HandleImgSearch_Opcode32 &= "9804000083C304F785F0FDFFFF10080000899DD8FDFFFF74300FB743FC5068000200008D85F4FDFFFF508D85E0FDFFFF50E81045000083C41085C0741FC785BCFDFFFF01000000EB1"
$__HandleImgSearch_Opcode32 &= "38A43FC8885F4FDFFFFC785E0FDFFFF010000008D85F4FDFFFF8985E4FDFFFFE92F0400008B0383C304899DD8FDFFFF3BC6743B8B48043BCE7434F785F0FDFFFF000800000FBF0089"
$__HandleImgSearch_Opcode32 &= "8DE4FDFFFF7414992BC2D1F8C785C8FDFFFF01000000E9EA03000089B5C8FDFFFFE9DF030000A1F82801108985E4FDFFFF50E8322D000059E9C803000083F8700F8FF40100000F84D"
$__HandleImgSearch_Opcode32 &= "C01000083F8650F8CB603000083F8670F8E34FEFFFF83F869747183F86E742883F86F0F859A030000F685F0FDFFFF80C785E0FDFFFF080000007461818DF0FDFFFF00020000EB558B"
$__HandleImgSearch_Opcode32 &= "3383C304899DD8FDFFFFE8AA42000085C00F843AFAFFFFF685F0FDFFFF20740C668B85DCFDFFFF668906EB088B85DCFDFFFF8906C785BCFDFFFF01000000E9C1040000838DF0FDFFF"
$__HandleImgSearch_Opcode32 &= "F40C785E0FDFFFF0A0000008B8DF0FDFFFFF7C1008000000F84A20100008B038B530483C308E9CE010000751180FA677563C785E8FDFFFF01000000EB573985E8FDFFFF7E068985E8"
$__HandleImgSearch_Opcode32 &= "FDFFFF81BDE8FDFFFFA30000007E3D8BB5E8FDFFFF81C65D01000056E8B71300008A95EFFDFFFF598985B4FDFFFF85C074108985E4FDFFFF89B59CFDFFFF8BF8EB0AC785E8FDFFFFA"
$__HandleImgSearch_Opcode32 &= "30000008B038B35A0F0001083C308898588FDFFFF8B43FC89858CFDFFFF8D85A4FDFFFF50FFB594FDFFFF0FBEC2FFB5E8FDFFFF899DD8FDFFFF50FFB59CFDFFFF8D8588FDFFFF5750"
$__HandleImgSearch_Opcode32 &= "FF35E82A0110FFD6FFD08B9DF0FDFFFF83C41C81E380000000741D83BDE8FDFFFF0075148D85A4FDFFFF5057FF35F42A0110FFD6FFD0595980BDEFFDFFFF67751885DB75148D85A4F"
$__HandleImgSearch_Opcode32 &= "DFFFF5057FF35F02A0110FFD6FFD05959803F2D7511818DF0FDFFFF000100004789BDE4FDFFFF57E90AFEFFFFC785E8FDFFFF08000000898DB8FDFFFFEB2483E8730F84BDFCFFFF48"
$__HandleImgSearch_Opcode32 &= "480F8490FEFFFF83E8030F85B7010000C785B8FDFFFF27000000F685F0FDFFFF80C785E0FDFFFF100000000F8470FEFFFF8A85B8FDFFFF0451C685D4FDFFFF308885D5FDFFFFC785D"
$__HandleImgSearch_Opcode32 &= "0FDFFFF02000000E94CFEFFFFF7C1001000000F8552FEFFFF83C304F6C1207418899DD8FDFFFFF6C14074060FBF43FCEB040FB743FC99EB138B43FCF6C140740399EB0233D2899DD8"
$__HandleImgSearch_Opcode32 &= "FDFFFFF6C140741B85D27F177C0485C07311F7D883D200F7DA818DF0FDFFFF00010000F785F0FDFFFF009000008BDA8BF8750233DB83BDE8FDFFFF007D0CC785E8FDFFFF01000000E"
$__HandleImgSearch_Opcode32 &= "B1A83A5F0FDFFFFF7B8000200003985E8FDFFFF7E068985E8FDFFFF8BC70BC375062185D0FDFFFF8D75F38B85E8FDFFFFFF8DE8FDFFFF85C07F068BC70BC3742D8B85E0FDFFFF9952"
$__HandleImgSearch_Opcode32 &= "505357E80B2B000083C130899D9CFDFFFF8BF88BDA83F9397E06038DB8FDFFFF880E4EEBBD8D45F32BC646F785F0FDFFFF000200008985E0FDFFFF89B5E4FDFFFF746285C074078BC"
$__HandleImgSearch_Opcode32 &= "E8039307457FF8DE4FDFFFF8B8DE4FDFFFFC6013040EB3F49663930740783C0023BCE75F32B85E4FDFFFFD1F8EB283BDE750BA1F82801108985E4FDFFFF8B85E4FDFFFFEB07498038"
$__HandleImgSearch_Opcode32 &= "007405403BCE75F52B85E4FDFFFF8985E0FDFFFF83BDBCFDFFFF000F857D0100008B85F0FDFFFFA8407432A9000100007409C685D4FDFFFF2DEB18A8017409C685D4FDFFFF2BEB0BA"
$__HandleImgSearch_Opcode32 &= "8027411C685D4FDFFFF20C785D0FDFFFF010000008B9DCCFDFFFF2B9DE0FDFFFF2B9DD0FDFFFF899D9CFDFFFFA80C75278BFB85DB7E218B8DC0FDFFFF8DB5DCFDFFFFB0204FE846F5"
$__HandleImgSearch_Opcode32 &= "FFFF83BDDCFDFFFFFF740485FF7FDF8BBDC0FDFFFF8B8DD0FDFFFF8D85D4FDFFFF508D85DCFDFFFFE84EF5FFFFF685F0FDFFFF08597428F685F0FDFFFF04751FEB198DB5DCFDFFFF8"
$__HandleImgSearch_Opcode32 &= "BCFB0304BE8F6F4FFFF83BDDCFDFFFFFF740485DB7FE383BDC8FDFFFF008B9DE0FDFFFF745485DB7E508BB5E4FDFFFF0FB706506A068D45F4508D8590FDFFFF504B83C602E89B3F00"
$__HandleImgSearch_Opcode32 &= "0083C41085C075208B8D90FDFFFF85C974168D45F4508D85DCFDFFFFE8C9F4FFFF5985DB75C1EB1D838DDCFDFFFFFFEB14FFB5E4FDFFFF8D85DCFDFFFF8BCBE8A6F4FFFF5983BDDCF"
$__HandleImgSearch_Opcode32 &= "DFFFF007C2EF685F0FDFFFF0474258B9D9CFDFFFFEB198DB5DCFDFFFF8BCFB0204BE848F4FFFF83BDDCFDFFFFFF740485DB7FE383BDB4FDFFFF007413FFB5B4FDFFFFE817CBFFFF83"
$__HandleImgSearch_Opcode32 &= "A5B4FDFFFF00598BBDC4FDFFFF8A078885EFFDFFFF84C074158B8DA0FDFFFF8B9DD8FDFFFF33F68AD0E9C7F5FFFF80BDB0FDFFFF00740A8B85ACFDFFFF836070FD8B85DCFDFFFF8B4"
$__HandleImgSearch_Opcode32 &= "DFC5F5E33CD5BE8B3CAFFFFC9C38D4900256300102461001054610010B2610010FE610010096200104F620010806300108BFF558BEC8B450885C0741283E8088138DDDD0000750750"
$__HandleImgSearch_Opcode32 &= "E880CAFFFF595DC38BFF558BEC83EC10A10020011033C58945FC8B55185333DB56573BD37E1F8B45148BCA4938187408403BCB75F683C9FF8BC22BC1483BC27D0140894518895DF83"
$__HandleImgSearch_Opcode32 &= "95D24750B8B45088B008B40048945248B3578F0001033C0395D285353FF75180F95C0FF75148D04C50100000050FF7524FFD68BF8897DF03BFB750733C0E9520100007E436AE033D2"
$__HandleImgSearch_Opcode32 &= "58F7F783F80272378D443F083D000400007713E8F53D00008BC43BC3741CC700CCCC0000EB1150E875D0FFFF593BC37409C700DDDD000083C0088945F4EB03895DF4395DF474AC57F"
$__HandleImgSearch_Opcode32 &= "F75F4FF7518FF75146A01FF7524FFD685C00F84E00000008B350CF10010535357FF75F4FF7510FF750CFFD68945F83BC30F84C1000000B900040000854D1074298B45203BC30F84AC"
$__HandleImgSearch_Opcode32 &= "0000003945F80F8FA300000050FF751C57FF75F4FF7510FF750CFFD6E98E0000008B7DF83BFB7E426AE033D258F7F783F80272368D443F083BC17716E83B3D00008BFC3BFB7468C70"
$__HandleImgSearch_Opcode32 &= "7CCCC000083C708EB1A50E8B8CFFFFF593BC37409C700DDDD000083C0088BF8EB0233FF3BFB743FFF75F857FF75F0FF75F4FF7510FF750CFFD685C074225353395D2075045353EB06"
$__HandleImgSearch_Opcode32 &= "FF7520FF751CFF75F85753FF7524FF1508F100108945F857E818FEFFFF59FF75F4E80FFEFFFF8B45F8598D65E45F5E5B8B4DFC33CDE889C8FFFFC9C38BFF558BEC83EC10FF75088D4"
$__HandleImgSearch_Opcode32 &= "DF0E8BDC8FFFFFF75288D45F0FF7524FF7520FF751CFF7518FF7514FF7510FF750C50E8E5FDFFFF83C424807DFC0074078B4DF8836170FDC9C38BFF558BEC83EC10FF750C8D4DF0E8"
$__HandleImgSearch_Opcode32 &= "77C8FFFF0FB645088B4DF08B89C80000000FB704412500800000807DFC0074078B4DF8836170FDC9C38BFF558BEC6A00FF7508E8B9FFFFFF59595DC3CCCCCCCCCCCCCCCCCCCCCCCCC"
$__HandleImgSearch_Opcode32 &= "CCC558BEC5756538B4D100BC9744D8B75088B7D0CB741B35AB6208D49008A260AE48A0774270AC0742383C60183C7013AE772063AE3770202E63AC772063AC3770202C63AE0750B83"
$__HandleImgSearch_Opcode32 &= "E90175D133C93AE07409B9FFFFFFFF7202F7D98BC15B5E5FC9C38BFF558BEC81EC78020000A10020011033C58945FC538B5D14568B750833C057FF75108B7D0C8D8DB0FDFFFF89B5A"
$__HandleImgSearch_Opcode32 &= "8FDFFFF899DD8FDFFFF8985A0FDFFFF8985F0FDFFFF8985CCFDFFFF8985E8FDFFFF8985D0FDFFFF8985A4FDFFFF8985C8FDFFFFE869C7FFFF85F6752BE8BAD6FFFFC70016000000E8"
$__HandleImgSearch_Opcode32 &= "F4E8FFFF80BDBCFDFFFF00740A8B85B8FDFFFF836070FD83C8FFE9090B0000F6460C40755E56E85839000059BA0029011083F8FF741B83F8FE74168BC883E11F8BF0C1FE05C1E1060"
$__HandleImgSearch_Opcode32 &= "30CB5E04D0110EB028BCAF641247F759B83F8FF741983F8FE74148BC883E01FC1F905C1E00603048DE04D0110EB028BC2F64024800F8571FFFFFF33F63BFE0F8467FFFFFF8A1789B5"
$__HandleImgSearch_Opcode32 &= "DCFDFFFF89B5E0FDFFFF89B5C0FDFFFF89B5ACFDFFFF8895EFFDFFFF84D20F845A0A00004789BDC4FDFFFF39B5DCFDFFFF0F8C310A00008D42E03C58770F0FBEC20FB680900001108"
$__HandleImgSearch_Opcode32 &= "3E00FEB0233C08B8DC0FDFFFF6BC0090FB68408B00001106A08C1E8045E8985C0FDFFFF3BC60F84EFFEFFFF6A07593BC10F87C8090000FF2485117A001033C0838DE8FDFFFFFF8985"
$__HandleImgSearch_Opcode32 &= "94FDFFFF8985A4FDFFFF8985CCFDFFFF8985D0FDFFFF8985F0FDFFFF8985C8FDFFFFE98F0900000FBEC283E820744883E80374342BC674244848741483E8030F857109000009B5F0F"
$__HandleImgSearch_Opcode32 &= "DFFFFE966090000838DF0FDFFFF04E95A090000838DF0FDFFFF01E94E090000818DF0FDFFFF80000000E93F090000838DF0FDFFFF02E93309000080FA2A752C83C304899DD8FDFFFF"
$__HandleImgSearch_Opcode32 &= "8B5BFC899DCCFDFFFF85DB0F8914090000838DF0FDFFFF04F79DCCFDFFFFE9020900008B85CCFDFFFF6BC00A0FBECA8D4408D08985CCFDFFFFE9E708000083A5E8FDFFFF00E9DB080"
$__HandleImgSearch_Opcode32 &= "00080FA2A752683C304899DD8FDFFFF8B5BFC899DE8FDFFFF85DB0F89BC080000838DE8FDFFFFFFE9B00800008B85E8FDFFFF6BC00A0FBECA8D4408D08985E8FDFFFFE99508000080"
$__HandleImgSearch_Opcode32 &= "FA49745580FA68744480FA6C741880FA770F857D080000818DF0FDFFFF00080000E96E080000803F6C751647818DF0FDFFFF0010000089BDC4FDFFFFE953080000838DF0FDFFFF10E"
$__HandleImgSearch_Opcode32 &= "947080000838DF0FDFFFF20E93B0800008A073C36751E807F0134751883C702818DF0FDFFFF0080000089BDC4FDFFFFE9170800003C33751E807F0132751883C70281A5F0FDFFFFFF"
$__HandleImgSearch_Opcode32 &= "7FFFFF89BDC4FDFFFFE9F50700003C640F84ED0700003C690F84E50700003C6F0F84DD0700003C750F84D50700003C780F84CD0700003C580F84C507000083A5C0FDFFFF0083A5C8F"
$__HandleImgSearch_Opcode32 &= "DFFFF008D85B0FDFFFF500FB6C250E89EFBFFFF5985C08A85EFFDFFFF5974228B8DA8FDFFFF8DB5DCFDFFFFE8E1ECFFFF8A074789BDC4FDFFFF84C00F8495FCFFFF8B8DA8FDFFFF8D"
$__HandleImgSearch_Opcode32 &= "B5DCFDFFFFE8BFECFFFFE9630700000FBEC283F8640F8FEA0100000F847702000083F8530F8FF30000000F848100000083E8417410484874594848740848480F858705000080C220C"
$__HandleImgSearch_Opcode32 &= "78594FDFFFF010000008895EFFDFFFF838DF0FDFFFF4083BDE8FDFFFF008DBDF4FDFFFFB80002000089BDE4FDFFFF89859CFDFFFF0F8D45020000C785E8FDFFFF06000000E9A00200"
$__HandleImgSearch_Opcode32 &= "00F785F0FDFFFF300800000F8598000000818DF0FDFFFF00080000E989000000F785F0FDFFFF30080000750A818DF0FDFFFF000800008B8DE8FDFFFF83F9FF7505B9FFFFFF7F83C30"
$__HandleImgSearch_Opcode32 &= "4F785F0FDFFFF10080000899DD8FDFFFF8B5BFC899DE4FDFFFF0F84A504000085DB750BA1FC2801108985E4FDFFFF8B85E4FDFFFFC785C8FDFFFF01000000E97304000083E8580F84"
$__HandleImgSearch_Opcode32 &= "CC020000484874792BC10F8426FFFFFF48480F859204000083C304F785F0FDFFFF10080000899DD8FDFFFF74300FB743FC5068000200008D85F4FDFFFF508D85E0FDFFFF50E842360"
$__HandleImgSearch_Opcode32 &= "00083C41085C0741FC785A4FDFFFF01000000EB138A43FC8885F4FDFFFFC785E0FDFFFF010000008D85F4FDFFFF8985E4FDFFFFE9290400008B0383C304899DD8FDFFFF85C0743C8B"
$__HandleImgSearch_Opcode32 &= "480485C97435F785F0FDFFFF000800000FBF00898DE4FDFFFF7414992BC2D1F8C785C8FDFFFF01000000E9E403000083A5C8FDFFFF00E9D8030000A1F82801108985E4FDFFFF50E86"
$__HandleImgSearch_Opcode32 &= "31E000059E9C103000083F8700F8FEC0100000F84D801000083F8650F8CAF03000083F8670F8E32FEFFFF83F869746D83F86E742483F86F0F8593030000F685F0FDFFFF8089B5E0FD"
$__HandleImgSearch_Opcode32 &= "FFFF7461818DF0FDFFFF00020000EB558B3383C304899DD8FDFFFFE8DF33000085C00F8422FAFFFFF685F0FDFFFF20740C668B85DCFDFFFF668906EB088B85DCFDFFFF8906C785A4F"
$__HandleImgSearch_Opcode32 &= "DFFFF01000000E9BE040000838DF0FDFFFF40C785E0FDFFFF0A0000008B8DF0FDFFFFF7C1008000000F849E01000003DE8B43F88B53FCE9CA010000751180FA677563C785E8FDFFFF"
$__HandleImgSearch_Opcode32 &= "01000000EB573985E8FDFFFF7E068985E8FDFFFF81BDE8FDFFFFA30000007E3D8BB5E8FDFFFF81C65D01000056E8EC0400008A95EFFDFFFF598985ACFDFFFF85C074108985E4FDFFF"
$__HandleImgSearch_Opcode32 &= "F89B59CFDFFFF8BF8EB0AC785E8FDFFFFA30000008B038B35A0F0001083C308898588FDFFFF8B43FC89858CFDFFFF8D85B0FDFFFF50FFB594FDFFFF0FBEC2FFB5E8FDFFFF899DD8FD"
$__HandleImgSearch_Opcode32 &= "FFFF50FFB59CFDFFFF8D8588FDFFFF5750FF35E82A0110FFD6FFD08B9DF0FDFFFF83C41C81E380000000741D83BDE8FDFFFF0075148D85B0FDFFFF5057FF35F42A0110FFD6FFD0595"
$__HandleImgSearch_Opcode32 &= "980BDEFFDFFFF67751885DB75148D85B0FDFFFF5057FF35F02A0110FFD6FFD05959803F2D7511818DF0FDFFFF000100004789BDE4FDFFFF57E90EFEFFFF89B5E8FDFFFF898DA0FDFF"
$__HandleImgSearch_Opcode32 &= "FFEB2483E8730F84C4FCFFFF48480F8494FEFFFF83E8030F85B8010000C785A0FDFFFF27000000F685F0FDFFFF80C785E0FDFFFF100000000F8474FEFFFF8A85A0FDFFFF0451C685D"
$__HandleImgSearch_Opcode32 &= "4FDFFFF308885D5FDFFFFC785D0FDFFFF02000000E950FEFFFFF7C1001000000F8556FEFFFF83C304F6C1207418899DD8FDFFFFF6C14074060FBF43FCEB040FB743FC99EB138B43FC"
$__HandleImgSearch_Opcode32 &= "F6C140740399EB0233D2899DD8FDFFFFF6C140741B85D27F177C0485C07311F7D883D200F7DA818DF0FDFFFF00010000F785F0FDFFFF009000008BDA8BF8750233DB83BDE8FDFFFF0"
$__HandleImgSearch_Opcode32 &= "07D0CC785E8FDFFFF01000000EB1A83A5F0FDFFFFF7B8000200003985E8FDFFFF7E068985E8FDFFFF8BC70BC375062185D0FDFFFF8D75F38B85E8FDFFFFFF8DE8FDFFFF85C07F068B"
$__HandleImgSearch_Opcode32 &= "C70BC3742D8B85E0FDFFFF9952505357E8441C000083C130899D9CFDFFFF8BF88BDA83F9397E06038DA0FDFFFF880E4EEBBD8D45F32BC646F785F0FDFFFF000200008985E0FDFFFF8"
$__HandleImgSearch_Opcode32 &= "9B5E4FDFFFF746385C074078BCE8039307458FF8DE4FDFFFF8B8DE4FDFFFFC6013040EB404966833800740783C00285C975F22B85E4FDFFFFD1F8EB2885DB750BA1F82801108985E4"
$__HandleImgSearch_Opcode32 &= "FDFFFF8B85E4FDFFFFEB074980380074054085C975F52B85E4FDFFFF8985E0FDFFFF83BDA4FDFFFF000F857D0100008B85F0FDFFFFA8407432A9000100007409C685D4FDFFFF2DEB1"
$__HandleImgSearch_Opcode32 &= "8A8017409C685D4FDFFFF2BEB0BA8027411C685D4FDFFFF20C785D0FDFFFF010000008B9DCCFDFFFF2B9DE0FDFFFF2B9DD0FDFFFF899D9CFDFFFFA80C75278BFB85DB7E218B8DA8FD"
$__HandleImgSearch_Opcode32 &= "FFFF8DB5DCFDFFFFB0204FE87EE6FFFF83BDDCFDFFFFFF740485FF7FDF8BBDA8FDFFFF8B8DD0FDFFFF8D85D4FDFFFF508D85DCFDFFFFE886E6FFFFF685F0FDFFFF08597428F685F0F"
$__HandleImgSearch_Opcode32 &= "DFFFF04751FEB198DB5DCFDFFFF8BCFB0304BE82EE6FFFF83BDDCFDFFFFFF740485DB7FE383BDC8FDFFFF008B9DE0FDFFFF745485DB7E508BB5E4FDFFFF0FB706506A068D45F4508D"
$__HandleImgSearch_Opcode32 &= "8590FDFFFF504B83C602E8D330000083C41085C075208B8D90FDFFFF85C974168D45F4508D85DCFDFFFFE801E6FFFF5985DB75C1EB1D838DDCFDFFFFFFEB14FFB5E4FDFFFF8D85DCF"
$__HandleImgSearch_Opcode32 &= "DFFFF8BCBE8DEE5FFFF5983BDDCFDFFFF007C2EF685F0FDFFFF0474258B9D9CFDFFFFEB198DB5DCFDFFFF8BCFB0204BE880E5FFFF83BDDCFDFFFFFF740485DB7FE383BDACFDFFFF00"
$__HandleImgSearch_Opcode32 &= "7413FFB5ACFDFFFFE84FBCFFFF83A5ACFDFFFF00598BBDC4FDFFFF8A078885EFFDFFFF84C0740F8B9DD8FDFFFF33F68AD0E9BCF5FFFF83BDC0FDFFFF00740D83BDC0FDFFFF070F85E"
$__HandleImgSearch_Opcode32 &= "5F4FFFF80BDBCFDFFFF00740A8B85B8FDFFFF836070FD8B85DCFDFFFF8B4DFC5F5E33CD5BE8DBBBFFFFC9C38BFFF2710010EF6F0010217000107D700010C9700010D57000101B7100"
$__HandleImgSearch_Opcode32 &= "104D7200108BFF558BEC565733F6FF7508E862C2FFFF8BF85985FF75273905983A0110761F56FF1510F100108D86E80300003B05983A0110760383C8FF8BF083F8FF75CA8BC75F5E5"
$__HandleImgSearch_Opcode32 &= "DC38BFF558BEC565733F66A00FF750CFF7508E8B02F00008BF883C40C85FF75273905983A0110761F56FF1510F100108D86E80300003B05983A0110760383C8FF8BF083F8FF75C38B"
$__HandleImgSearch_Opcode32 &= "C75F5E5DC38BFF558BEC565733F6FF750CFF7508E8E82F00008BF8595985FF752C39450C74273905983A0110761F56FF1510F100108D86E80300003B05983A0110760383C8FF8BF08"
$__HandleImgSearch_Opcode32 &= "3F8FF75C18BC75F5E5DC38BFF558BEC83EC4C568D45B450FF1520F100106A406A205E56E848FFFFFF595933C93BC1750883C8FFE90F0200008D9000080000A3E04D01108935CC4D01"
$__HandleImgSearch_Opcode32 &= "103BC2733683C0058348FBFF66C740FF000A89480366C7401F000AC640210A89483388482F8B35E04D011083C0408D50FB81C6000800003BD672CD535766394DE60F840E0100008B4"
$__HandleImgSearch_Opcode32 &= "5E83BC10F84030100008B1883C0048945FC03C3BE000800008945F83BDE7C028BDE391DCC4D01107D6BBFE44D01106A406A20E8A8FEFFFF595985C074518305CC4D0110208D880008"
$__HandleImgSearch_Opcode32 &= "000089073BC1733183C0058348FBFF8360030080601F808360330066C740FF000A66C740200A0AC6402F008B0F83C04003CE8D50FB3BD172D283C704391DCC4D01107CA2EB068B1DC"
$__HandleImgSearch_Opcode32 &= "C4D011033FF85DB7E728B45F88B0083F8FF745C83F8FE74578B4DFC8A09F6C101744DF6C108750B50FF151CF1001085C0743D8BF783E61F8BC7C1F805C1E606033485E04D01108B45"
$__HandleImgSearch_Opcode32 &= "F88B0089068B45FC8A0088460468A00F00008D460C50FF1518F1001085C00F84BC000000FF46088345F80447FF45FC3BFB7C8E33DB8BF3C1E6060335E04D01108B0683F8FF740B83F"
$__HandleImgSearch_Opcode32 &= "8FE7406804E0480EB71C646048185DB75056AF658EB0A8D43FFF7D81BC083C0F550FF1500F100108BF883FFFF744285FF743E57FF151CF1001085C0743325FF000000893E83F80275"
$__HandleImgSearch_Opcode32 &= "06804E0440EB0983F8037504804E040868A00F00008D460C50FF1518F1001085C0742CFF4608EB0A804E0440C706FEFFFFFF4383FB030F8C68FFFFFFFF35CC4D0110FF1514F100103"
$__HandleImgSearch_Opcode32 &= "3C05F5B5EC9C383C8FFEBF68BFF5657BFE04D01108B0785C074368D88000800003BC173218D700C837EFC00740756FF1524F100108B0783C64005000800008D4EF43BC872E2FF37E8"
$__HandleImgSearch_Opcode32 &= "61B8FFFF8327005983C70481FFE04E01107CB95F5EC3833DEC4E0110007505E816CFFFFF568B35C43001105733FF85F6751883C8FFE9910000003C3D74014756E8C9140000598D740"
$__HandleImgSearch_Opcode32 &= "6018A0684C075EA6A044757E88BFCFFFF8BF85959893D4434011085FF74CB8B35C430011053EB3356E898140000803E3D598D580174226A0153E85DFCFFFF5959890785C0743F5653"
$__HandleImgSearch_Opcode32 &= "50E80D10000083C40C85C0754783C70403F3803E0075C8FF35C4300110E8B2B7FFFF8325C430011000832700C705E04E01100100000033C0595B5F5EC3FF3544340110E88CB7FFFF8"
$__HandleImgSearch_Opcode32 &= "325443401100083C8FFEBE433C05050505050E8FBD8FFFFCC8BFF558BEC518B4D105333C05689078BF28B550CC7010100000039450874098B5D088345080489138945FC803E227510"
$__HandleImgSearch_Opcode32 &= "33C03945FCB3220F94C0468945FCEB3CFF0785D274088A0688024289550C8A1E0FB6C35046E8E02C00005985C07413FF07837D0C00740A8B4D0C8A06FF450C8801468B550C8B4D108"
$__HandleImgSearch_Opcode32 &= "4DB7432837DFC0075A980FB20740580FB09759F85D27404C642FF008365FC00803E000F84E90000008A063C2074043C09750646EBF34EEBE3803E000F84D0000000837D080074098B"
$__HandleImgSearch_Opcode32 &= "4508834508048910FF0133DB4333C9EB024641803E5C74F9803E227526F6C101751F837DFC00740C8D460180382275048BF0EB0D33C033DB3945FC0F94C08945FCD1E985C97412498"
$__HandleImgSearch_Opcode32 &= "5D27404C6025C42FF0785C975F189550C8A0684C07455837DFC0075083C20744B3C09744785DB743D0FBEC05085D27423E8FB2B00005985C0740D8A068B4D0CFF450C880146FF078B"
$__HandleImgSearch_Opcode32 &= "4D0C8A06FF450C8801EB0DE8D82B00005985C0740346FF07FF078B550C46E956FFFFFF85D27407C602004289550CFF078B4D10E90EFFFFFF8B45085E5B85C07403832000FF01C9C38"
$__HandleImgSearch_Opcode32 &= "BFF558BEC83EC0C5333DB5657391DEC4E01107505E894CCFFFF6804010000BEA03A01105653881DA43B0110FF1528F10010A1F44E01108935543401103BC374078945FC3818750389"
$__HandleImgSearch_Opcode32 &= "75FC8B55FC8D45F85053538D7DF4E80AFEFFFF8B45F883C40C3DFFFFFF3F734A8B4DF483F9FF73428BF8C1E7028D040F3BC1723650E890F9FFFF8BF0593BF374298B55FC8D45F8500"
$__HandleImgSearch_Opcode32 &= "3FE57568D7DF4E8C9FDFFFF8B45F883C40C48A33834011089353C34011033C0EB0383C8FF5F5E5BC9C38BFF558BEC83EC0C5356FF1530F100108BD833F63BDE750433C0EB77663933"
$__HandleImgSearch_Opcode32 &= "741083C00266393075F883C00266393075F0578B3D08F100105656562BC356D1F840505356568945F4FFD78945F83BC6743850E801F9FFFF598945FC3BC6742A5656FF75F850FF75F"
$__HandleImgSearch_Opcode32 &= "4535656FFD785C0750CFF75FCE8A5B4FFFF598975FC53FF152CF100108B45FCEB0953FF152CF1001033C05F5E5BC9C38BFF56B8700C0110BE700C0110578BF83BC6730F8B0785C074"
$__HandleImgSearch_Opcode32 &= "02FFD083C7043BFE72F15F5EC38BFF56B8780C0110BE780C0110578BF83BC6730F8B0785C07402FFD083C7043BFE72F15F5EC3CCCCCCCC682082001064FF35000000008B442410896"
$__HandleImgSearch_Opcode32 &= "C24108D6C24102BE0535657A1002001103145FC33C5508965E8FF75F88B45FCC745FCFEFFFFFF8945F88D45F064A300000000C38B4DF064890D00000000595F5F5E5B8BE55D51C3CC"
$__HandleImgSearch_Opcode32 &= "CCCCCCCCCCCC8BFF558BEC83EC18538B5D0C568B7308333500200110578B06C645FF00C745F4010000008D7B1083F8FE740D8B4E0403CF330C38E88FB3FFFF8B4E0C8B460803CF330"
$__HandleImgSearch_Opcode32 &= "C38E87FB3FFFF8B4508F64004660F85190100008B4D108D55E88953FC8B5B0C8945E8894DEC83FBFE745F8D49008D045B8B4C86148D4486108945F08B008945F885C974148BD7E824"
$__HandleImgSearch_Opcode32 &= "2A0000C645FF0185C078407F478B45F88BD883F8FE75CE807DFF0074248B0683F8FE740D8B4E0403CF330C38E80CB3FFFF8B4E0C8B560803CF330C3AE8FCB2FFFF8B45F45F5E5B8BE"
$__HandleImgSearch_Opcode32 &= "55DC3C745F400000000EBC98B4D08813963736DE07529833DC84D011000742068C84D0110E88315000083C40485C0740F8B55086A0152FF15C84D011083C4088B4D0C8B5508E8C429"
$__HandleImgSearch_Opcode32 &= "00008B450C39580C74126800200110578BD38BC8E8C62900008B450C8B4DF889480C8B0683F8FE740D8B4E0403CF330C38E876B2FFFF8B4E0C8B560803CF330C3AE866B2FFFF8B45F"
$__HandleImgSearch_Opcode32 &= "08B48088BD7E85A290000BAFEFFFFFF39530C0F844FFFFFFF6800200110578BCBE871290000E919FFFFFF8BFF558BEC56E8A0CDFFFF8BF085F60F84320100008B4E5C8B55088BC157"
$__HandleImgSearch_Opcode32 &= "3910740D83C00C8DB9900000003BC772EF81C1900000003BC173043910740233C085C074078B500885D2750733C0E9F500000083FA05750C8360080033C040E9E400000083FA010F8"
$__HandleImgSearch_Opcode32 &= "4D80000008B4D0C538B5E60894E608B480483F9080F85B60000006A24598B7E5C836439080083C10C81F9900000007CED8B008B7E643D8E0000C07509C7466483000000EB7E3D9000"
$__HandleImgSearch_Opcode32 &= "00C07509C7466481000000EB6E3D910000C07509C7466484000000EB5E3D930000C07509C7466485000000EB4E3D8D0000C07509C7466482000000EB3E3D8F0000C07509C74664860"
$__HandleImgSearch_Opcode32 &= "00000EB2E3D920000C07509C746648A000000EB1E3DB50200C07509C746648D000000EB0E3DB40200C07507C746648E000000FF76646A08FFD259897E64EB078360080051FFD25989"
$__HandleImgSearch_Opcode32 &= "5E605B83C8FF5F5E5DC38BFF558BECB863736DE0394508750DFF750C50E89EFEFFFF59595DC333C05DC38BFF558BEC83EC10A1002001108365F8008365FC005357BF4EE640BBBB000"
$__HandleImgSearch_Opcode32 &= "0FFFF3BC7740D85C37409F7D0A304200110EB65568D45F850FF1540F100108B75FC3375F8FF153CF1001033F0FF159CF0001033F0FF1538F1001033F08D45F050FF1534F100108B45"
$__HandleImgSearch_Opcode32 &= "F43345F033F03BF77507BE4FE640BBEB1085F3750C8BC60D11470000C1E0100BF0893500200110F7D68935042001105E5F5BC9C38325C44D011000C3CCCCCCCC8B54240C8B4C24048"
$__HandleImgSearch_Opcode32 &= "5D2746933C08A44240884C0751681FA80000000720E833DB03D0110007405E946270000578BF983FA047231F7D983E103740C2BD1880783C70183E90175F68BC8C1E00803C18BC8C1"
$__HandleImgSearch_Opcode32 &= "E01003C18BCA83E203C1E9027406F3AB85D2740A880783C70183EA0175F68B4424085FC38B442404C38BFF558BEC5151A10020011033C58945FC5333DB5657895DF8395D1C750B8B4"
$__HandleImgSearch_Opcode32 &= "5088B008B400489451C8B3578F0001033C0395D205353FF75140F95C0FF75108D04C50100000050FF751CFFD68BF83BFB750433C0EB7F7E3C81FFF0FFFF7F77348D443F083D000400"
$__HandleImgSearch_Opcode32 &= "007713E8662300008BC43BC3741CC700CCCC0000EB1150E8E6B5FFFF593BC37409C700DDDD000083C0088BD885DB74BA8D043F506A0053E8E2FEFFFF83C40C5753FF7514FF75106A0"
$__HandleImgSearch_Opcode32 &= "1FF751CFFD685C07411FF75185053FF750CFF1544F100108945F853E84FE4FFFF8B45F8598D65EC5F5E5B8B4DFC33CDE8C9AEFFFFC9C38BFF558BEC83EC10FF75088D4DF0E8FDAEFF"
$__HandleImgSearch_Opcode32 &= "FFFF75248D45F0FF751CFF7518FF7514FF7510FF750C50E8EBFEFFFF83C41C807DFC0074078B4DF8836170FDC9C38BFF565733F6BFA83B0110833CF54429011001751D8D04F540290"
$__HandleImgSearch_Opcode32 &= "110893868A00F0000FF3083C718FF1518F1001085C0740C4683FE247CD333C0405F5EC38324F5402901100033C0EBF18BFF538B1D24F1001056BE40290110578B3E85FF7413837E04"
$__HandleImgSearch_Opcode32 &= "01740D57FFD357E827AEFFFF8326005983C60881FE602A01107CDCBE402901105F8B0685C07409837E0401750350FFD383C60881FE602A01107CE65E5BC38BFF558BEC8B4508FF34C"
$__HandleImgSearch_Opcode32 &= "540290110FF1548F100105DC36A0C68900D0110E89BF9FFFF33FF47897DE433DB391DFC3301107518E8F9D4FFFF6A1EE843D3FFFF68FF000000E878D0FFFF59598B75088D34F54029"
$__HandleImgSearch_Opcode32 &= "0110391E74048BC7EB6D6A18E8CBF1FFFF598BF83BFB750FE819BDFFFFC7000C00000033C0EB506A0AE85800000059895DFC391E752B68A00F000057FF1518F1001085C0751757E85"
$__HandleImgSearch_Opcode32 &= "6ADFFFF59E8E4BCFFFFC7000C000000895DE4EB0B893EEB0757E83BADFFFF59C745FCFEFFFFFFE8090000008B45E4E834F9FFFFC36A0AE829FFFFFF59C38BFF558BEC8B4508568D34"
$__HandleImgSearch_Opcode32 &= "C540290110833E00751350E823FFFFFF5985C075086A11E83ED2FFFF59FF36FF154CF100105E5DC38BFF558BEC568B750885F60F8463030000FF7604E8D0ACFFFFFF7608E8C8ACFFF"
$__HandleImgSearch_Opcode32 &= "FFF760CE8C0ACFFFFFF7610E8B8ACFFFFFF7614E8B0ACFFFFFF7618E8A8ACFFFFFF36E8A1ACFFFFFF7620E899ACFFFFFF7624E891ACFFFFFF7628E889ACFFFFFF762CE881ACFFFFFF"
$__HandleImgSearch_Opcode32 &= "7630E879ACFFFFFF7634E871ACFFFFFF761CE869ACFFFFFF7638E861ACFFFFFF763CE859ACFFFF83C440FF7640E84EACFFFFFF7644E846ACFFFFFF7648E83EACFFFFFF764CE836ACF"
$__HandleImgSearch_Opcode32 &= "FFFFF7650E82EACFFFFFF7654E826ACFFFFFF7658E81EACFFFFFF765CE816ACFFFFFF7660E80EACFFFFFF7664E806ACFFFFFF7668E8FEABFFFFFF766CE8F6ABFFFFFF7670E8EEABFF"
$__HandleImgSearch_Opcode32 &= "FFFF7674E8E6ABFFFFFF7678E8DEABFFFFFF767CE8D6ABFFFF83C440FFB680000000E8C8ABFFFFFFB684000000E8BDABFFFFFFB688000000E8B2ABFFFFFFB68C000000E8A7ABFFFFF"
$__HandleImgSearch_Opcode32 &= "FB690000000E89CABFFFFFFB694000000E891ABFFFFFFB698000000E886ABFFFFFFB69C000000E87BABFFFFFFB6A0000000E870ABFFFFFFB6A4000000E865ABFFFFFFB6A8000000E8"
$__HandleImgSearch_Opcode32 &= "5AABFFFFFFB6BC000000E84FABFFFFFFB6C0000000E844ABFFFFFFB6C4000000E839ABFFFFFFB6C8000000E82EABFFFFFFB6CC000000E823ABFFFF83C440FFB6D0000000E815ABFFF"
$__HandleImgSearch_Opcode32 &= "FFFB6B8000000E80AABFFFFFFB6D8000000E8FFAAFFFFFFB6DC000000E8F4AAFFFFFFB6E0000000E8E9AAFFFFFFB6E4000000E8DEAAFFFFFFB6E8000000E8D3AAFFFFFFB6EC000000"
$__HandleImgSearch_Opcode32 &= "E8C8AAFFFFFFB6D4000000E8BDAAFFFFFFB6F0000000E8B2AAFFFFFFB6F4000000E8A7AAFFFFFFB6F8000000E89CAAFFFFFFB6FC000000E891AAFFFFFFB600010000E886AAFFFFFFB"
$__HandleImgSearch_Opcode32 &= "604010000E87BAAFFFFFFB608010000E870AAFFFF83C440FFB60C010000E862AAFFFFFFB610010000E857AAFFFFFFB614010000E84CAAFFFFFFB618010000E841AAFFFFFFB61C0100"
$__HandleImgSearch_Opcode32 &= "00E836AAFFFFFFB620010000E82BAAFFFFFFB624010000E820AAFFFFFFB628010000E815AAFFFFFFB62C010000E80AAAFFFFFFB630010000E8FFA9FFFFFFB634010000E8F4A9FFFFF"
$__HandleImgSearch_Opcode32 &= "FB638010000E8E9A9FFFFFFB63C010000E8DEA9FFFFFFB640010000E8D3A9FFFFFFB644010000E8C8A9FFFFFFB648010000E8BDA9FFFF83C440FFB64C010000E8AFA9FFFFFFB65001"
$__HandleImgSearch_Opcode32 &= "0000E8A4A9FFFFFFB654010000E899A9FFFFFFB658010000E88EA9FFFFFFB65C010000E883A9FFFFFFB660010000E878A9FFFF83C4185E5DC38BFF558BEC568B750885F674598B063"
$__HandleImgSearch_Opcode32 &= "B05682A0110740750E855A9FFFF598B46043B056C2A0110740750E843A9FFFF598B46083B05702A0110740750E831A9FFFF598B46303B05982A0110740750E81FA9FFFF598B76343B"
$__HandleImgSearch_Opcode32 &= "359C2A0110740756E80DA9FFFF595E5DC38BFF558BEC568B750885F60F84EA0000008B460C3B05742A0110740750E8E7A8FFFF598B46103B05782A0110740750E8D5A8FFFF598B461"
$__HandleImgSearch_Opcode32 &= "43B057C2A0110740750E8C3A8FFFF598B46183B05802A0110740750E8B1A8FFFF598B461C3B05842A0110740750E89FA8FFFF598B46203B05882A0110740750E88DA8FFFF598B4624"
$__HandleImgSearch_Opcode32 &= "3B058C2A0110740750E87BA8FFFF598B46383B05A02A0110740750E869A8FFFF598B463C3B05A42A0110740750E857A8FFFF598B46403B05A82A0110740750E845A8FFFF598B46443"
$__HandleImgSearch_Opcode32 &= "B05AC2A0110740750E833A8FFFF598B46483B05B02A0110740750E821A8FFFF598B764C3B35B42A0110740756E80FA8FFFF595E5DC3CCCCCCCC558BEC5633C050505050505050508B"
$__HandleImgSearch_Opcode32 &= "550C8D49008A020AC0740983C2010FAB0424EBF18B750883C9FF8D490083C1018A060AC0740983C6010FA3042473EE8BC183C4205EC9C38BFF558BEC8B5508565785D274078B7D0C8"
$__HandleImgSearch_Opcode32 &= "5FF7513E83BB7FFFF6A165E8930E876C9FFFF8BC6EB338B451085C075048802EBE28BF22BF08A08880C064084C974034F75F385FF7511C60200E805B7FFFF6A225989088BF1EBC633"
$__HandleImgSearch_Opcode32 &= "C05F5E5DC3CCCCCCCCCCCCCCCCCCCCCC8B5424048B4C2408F7C203000000753C8B023A01752E0AC074263A610175250AE4741DC1E8103A410275190AC074113A6103751083C10483C"
$__HandleImgSearch_Opcode32 &= "2040AE475D28BFF33C0C3901BC0D1E083C001C3F7C20100000074188A0283C2013A0175E783C1010AC074DCF7C20200000074A4668B0283C2023A0175CE0AC074C63A610175C50AE4"
$__HandleImgSearch_Opcode32 &= "74BD83C102EB88CCCCCCCCCCCCCCCC558BEC57568B750C8B4D108B7D088BC18BD103C63BFE76083BF80F82A001000081F980000000721C833DB03D0110007413575683E70F83E60F3"
$__HandleImgSearch_Opcode32 &= "BFE5E5F7505E9881E0000F7C7030000007514C1E90283E20383F9087229F3A5FF2495A09000108BC7BA0300000083E904720C83E00303C8FF2485B48F0010FF248DB090001090FF24"
$__HandleImgSearch_Opcode32 &= "8D3490001090C48F0010F08F00101490001023D18A0688078A46018847018A4602C1E90288470283C60383C70383F90872CCF3A5FF2495A09000108D490023D18A0688078A4601C1E"
$__HandleImgSearch_Opcode32 &= "90288470183C60283C70283F90872A6F3A5FF2495A09000109023D18A06880783C601C1E90283C70183F9087288F3A5FF2495A09000108D490097900010849000107C900010749000"
$__HandleImgSearch_Opcode32 &= "106C900010649000105C900010549000108B448EE489448FE48B448EE889448FE88B448EEC89448FEC8B448EF089448FF08B448EF489448FF48B448EF889448FF88B448EFC89448FF"
$__HandleImgSearch_Opcode32 &= "C8D048D0000000003F003F8FF2495A09000108BFFB0900010B8900010C4900010D89000108B45085E5FC9C3908A0688078B45085E5FC9C3908A0688078A46018847018B45085E5FC9"
$__HandleImgSearch_Opcode32 &= "C38D49008A0688078A46018847018A46028847028B45085E5FC9C3908D7431FC8D7C39FCF7C7030000007524C1E90283E20383F908720DFDF3A5FCFF24953C9200108BFFF7D9FF248"
$__HandleImgSearch_Opcode32 &= "DEC9100108D49008BC7BA0300000083F904720C83E0032BC8FF248540910010FF248D3C9200109050910010749100109C9100108A460323D188470383EE01C1E90283EF0183F90872"
$__HandleImgSearch_Opcode32 &= "B2FDF3A5FCFF24953C9200108D49008A460323D18847038A4602C1E90288470283EE0283EF0283F9087288FDF3A5FCFF24953C920010908A460323D18847038A46028847028A4601C"
$__HandleImgSearch_Opcode32 &= "1E90288470183EE0383EF0383F9080F8256FFFFFFFDF3A5FCFF24953C9200108D4900F0910010F89100100092001008920010109200101892001020920010339200108B448E1C8944"
$__HandleImgSearch_Opcode32 &= "8F1C8B448E1889448F188B448E1489448F148B448E1089448F108B448E0C89448F0C8B448E0889448F088B448E0489448F048D048D0000000003F003F8FF24953C9200108BFF4C920"
$__HandleImgSearch_Opcode32 &= "0105492001064920010789200108B45085E5FC9C3908A46038847038B45085E5FC9C38D49008A46038847038A46028847028B45085E5FC9C3908A46038847038A46028847028A4601"
$__HandleImgSearch_Opcode32 &= "8847018B45085E5FC9C3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC8B4C2404F7C10300000074248A0183C10184C0744EF7C10300000075EF05000000008DA424000000008DA4240000000"
$__HandleImgSearch_Opcode32 &= "08B01BAFFFEFE7E03D083F0FF33C283C104A90001018174E88B41FC84C0743284E47424A90000FF007413A9000000FF7402EBCD8D41FF8B4C24042BC1C38D41FE8B4C24042BC1C38D"
$__HandleImgSearch_Opcode32 &= "41FD8B4C24042BC1C38D41FC8B4C24042BC1C3CCCCCCCCCC558BEC5633C050505050505050508B550C8D49008A020AC0740983C2010FAB0424EBF18B75088BFF8A060AC0740C83C60"
$__HandleImgSearch_Opcode32 &= "10FA3042473F18D46FF83C4205EC9C38B4424088B4C24100BC88B4C240C75098B442404F7E1C2100053F7E18BD88B442408F764241403D88B442408F7E103D35BC21000CCCCCCCCCC"
$__HandleImgSearch_Opcode32 &= "CCCCCCCCCCCCCC568B4424140BC075288B4C24108B44240C33D2F7F18BD88B442408F7F18BF08BC3F76424108BC88BC6F764241003D1EB478BC88B5C24108B54240C8B442408D1E9D"
$__HandleImgSearch_Opcode32 &= "1DBD1EAD1D80BC975F4F7F38BF0F76424148BC88B442410F7E603D1720E3B54240C7708720F3B44240876094E2B4424101B54241433DB2B4424081B54240CF7DAF7D883DA008BCA8B"
$__HandleImgSearch_Opcode32 &= "D38BD98BC88BC65EC210006A0868B00D0110E86FEDFFFFE87DBDFFFF8B407885C074168365FC00FFD0EB0733C040C38B65E8C745FCFEFFFFFFE8871A0000E888EDFFFFC3684594001"
$__HandleImgSearch_Opcode32 &= "0FF15DCF00010A3003D0110C38BFF558BEC8B4508A3043D0110A3083D0110A30C3D0110A3103D01105DC38BFF558BEC8B45088B0DAC01011056395004740F8BF16BF60C03750883C0"
$__HandleImgSearch_Opcode32 &= "0C3BC672EC6BC90C034D085E3BC17305395004740233C05DC3FF350C3D0110FF15A0F00010C36A2068D00D0110E8C3ECFFFF33FF897DE4897DD88B5D0883FB0B7F4B74158BC36A025"
$__HandleImgSearch_Opcode32 &= "92BC174222BC174082BC174592BC17543E831BCFFFF8BF8897DD885FF751483C8FFE954010000BE043D0110A1043D0110EB55FF775C8BD3E85DFFFFFF598D70088B06EB518BC383E8"
$__HandleImgSearch_Opcode32 &= "0F743283E8067421487412E81FB0FFFFC70016000000E859C2FFFFEBB9BE0C3D0110A10C3D0110EB16BE083D0110A1083D0110EB0ABE103D0110A1103D0110C745E40100000050FF1"
$__HandleImgSearch_Opcode32 &= "5A0F000108945E033C0837DE0010F84D60000003945E075076A03E857C5FFFF3945E4740750E80CF3FFFF5933C08945FC83FB08740A83FB0B740583FB04751B8B4F60894DD4894760"
$__HandleImgSearch_Opcode32 &= "83FB08753E8B4F64894DD0C747648C00000083FB08752C8B0DA0010110894DDC8B0DA4010110030DA0010110394DDC7D198B4DDC6BC90C8B575C89441108FF45DCEBDDE8EEB9FFFF8"
$__HandleImgSearch_Opcode32 &= "906C745FCFEFFFFFFE81500000083FB08751FFF776453FF55E059EB198B5D088B7DD8837DE40074086A00E89DF1FFFF59C353FF55E05983FB08740A83FB0B740583FB0475118B45D4"
$__HandleImgSearch_Opcode32 &= "89476083FB0875068B45D089476433C0E872EBFFFFC38BFF558BEC8B4508A3183D01105DC38BFF558BEC8B4508A31C3D01105DC38BFF558BEC5153568B35A0F0001057FF35E84E011"
$__HandleImgSearch_Opcode32 &= "0FFD6FF35E44E01108BD8895DFCFFD68BF03BF30F82810000008BFE2BFB8D470483F804727553E8401800008BD88D4704593BD87348B8000800003BD873028BC303C33BC3720F50FF"
$__HandleImgSearch_Opcode32 &= "75FCE8ACE3FFFF595985C075168D43103BC3723E50FF75FCE896E3FFFF595985C0742FC1FF02508D34B8FF15DCF00010A3E84E0110FF75088B3DDCF00010FFD7890683C60456FFD7A"
$__HandleImgSearch_Opcode32 &= "3E44E01108B4508EB0233C05F5E5BC9C38BFF566A046A20E802E3FFFF59598BF056FF15DCF00010A3E84E0110A3E44E011085F675056A18585EC383260033C05EC36A0C68F00D0110"
$__HandleImgSearch_Opcode32 &= "E81BEAFFFFE831C1FFFF8365FC00FF7508E8FCFEFFFF598945E4C745FCFEFFFFFFE8090000008B45E4E837EAFFFFC3E810C1FFFFC38BFF558BECFF7508E8B7FFFFFFF7D81BC0F7D85"
$__HandleImgSearch_Opcode32 &= "9485DC38BFF565733FFFFB7D02A0110FF15DCF000108987D02A011083C70483FF2872E65F5EC3CC8BFF558BEC8B4D08B84D5A0000663901740433C05DC38B413C03C1813850450000"
$__HandleImgSearch_Opcode32 &= "75EF33D2B90B010000663948180F94C28BC25DC3CCCCCCCCCCCCCCCCCCCCCC8BFF558BEC8B45088B483C03C80FB7411453560FB7710633D2578D44081885F6741B8B7D0C8B480C3BF"
$__HandleImgSearch_Opcode32 &= "972098B580803D93BFB720A4283C0283BD672E833C05F5E5B5DC3CCCCCCCCCCCCCCCCCCCCCCCC8BFF558BEC6AFE68100E0110682082001064A1000000005083EC08535657A1002001"
$__HandleImgSearch_Opcode32 &= "103145F833C5508D45F064A3000000008965E8C745FC000000006800000010E82AFFFFFF83C40485C074548B45082D00000010506800000010E850FFFFFF83C40885C0743A8B4024C"
$__HandleImgSearch_Opcode32 &= "1E81FF7D083E001C745FCFEFFFFFF8B4DF064890D00000000595F5E5B8BE55DC38B45EC8B0833D28139050000C00F94C28BC2C38B65E8C745FCFEFFFFFF33C08B4DF064890D000000"
$__HandleImgSearch_Opcode32 &= "00595F5E5B8BE55DC38BFF558BEC83EC24A10020011033C58945FC8B4508538945E08B450C56578945E4E8A1B6FFFF8365EC00833D203D0110008945E8757D681C0A0110FF158CF00"
$__HandleImgSearch_Opcode32 &= "0108BD885DB0F84100100008B3D7CF0001068100A011053FFD785C00F84FA0000008B35DCF0001050FFD668000A011053A3203D0110FFD750FFD668EC09011053A3243D0110FFD750"
$__HandleImgSearch_Opcode32 &= "FFD668D009011053A3283D0110FFD750FFD6A3303D011085C0741068B809011053FFD750FFD6A32C3D0110A12C3D01108B4DE88B35A0F000103BC17447390D303D0110743F50FFD6F"
$__HandleImgSearch_Opcode32 &= "F35303D01108BF8FFD68BD885FF742C85DB7428FFD785C074198D4DDC516A0C8D4DF0516A0150FFD385C07406F645F8017509814D1000002000EB33A1243D01103B45E8742950FFD6"
$__HandleImgSearch_Opcode32 &= "85C07422FFD08945EC85C07419A1283D01103B45E8740F50FFD685C07408FF75ECFFD08945ECFF35203D0110FFD685C07410FF7510FF75E4FF75E0FF75ECFFD0EB0233C08B4DFC5F5"
$__HandleImgSearch_Opcode32 &= "E33CD5BE8229BFFFFC9C38BFF558BEC568B75085785F674078B7D0C85FF7515E8A9AAFFFF6A165E8930E8E4BCFFFF8BC65F5E5DC38B4D1085C9750733C0668906EBDD8BD666833A00"
$__HandleImgSearch_Opcode32 &= "740683C2024F75F485FF74E72BD10FB7016689040A83C1026685C074034F75EE33C085FF75C2668906E857AAFFFF6A225989088BF1EBAA8BFF558BEC8B5508538B5D14565785DB751"
$__HandleImgSearch_Opcode32 &= "085D2751039550C751233C05F5E5B5DC385D274078B7D0C85FF7513E81CAAFFFF6A165E8930E857BCFFFF8BC6EBDD85DB750733C0668902EBD08B4D1085C9750733C0668902EBD48B"
$__HandleImgSearch_Opcode32 &= "C283FBFF75188BF22BF10FB7016689040E83C1026685C074274F75EEEB228BF12BF20FB70C0666890883C0026685C974064F74034B75EB85DB750533C966890885FF0F8579FFFFFF3"
$__HandleImgSearch_Opcode32 &= "3C083FBFF75108B4D0C6A506689444AFE58E964FFFFFF668902E88DA9FFFF6A225989088BF1E96AFFFFFF8BFF558BEC8B4508668B0883C0026685C975F52B4508D1F8485DC38BFF55"
$__HandleImgSearch_Opcode32 &= "8BEC568B75085785F674078B7D0C85FF7515E84CA9FFFF6A165E8930E887BBFFFF8BC65F5E5DC38B451085C07505668906EBDF8BD62BD00FB70866890C0283C0026685C974034F75E"
$__HandleImgSearch_Opcode32 &= "E33C085FF75D4668906E80CA9FFFF6A225989088BF1EBBC8BFF558BEC8B4D0885C9781E83F9027E0C83F9037514A1CC3001105DC3A1CC300110890DCC3001105DC3E8D4A8FFFFC700"
$__HandleImgSearch_Opcode32 &= "16000000E80EBBFFFF83C8FF5DC38BFF558BEC51518B450C568B75088945F88B451057568945FCE80F13000083CFFF593BC77511E899A8FFFFC700090000008BC78BD7EB4AFF75148"
$__HandleImgSearch_Opcode32 &= "D4DFC51FF75F850FF1558F000108945F83BC77513FF1590F0001085C0740950E88BA8FFFF59EBCF8BC6C1F8058B0485E04D011083E61FC1E6068D4430048020FD8B45F88B55FC5F5E"
$__HandleImgSearch_Opcode32 &= "C9C36A1468300E0110E868E4FFFF83CBFF895DDC895DE08B450883F8FE751CE830A8FFFF832000E815A8FFFFC700090000008BC38BD3E9A100000085C078083B05CC4D0110721AE80"
$__HandleImgSearch_Opcode32 &= "8A8FFFF832000E8EDA7FFFFC70009000000E827BAFFFFEBD18BC8C1F9058D3C8DE04D01108BF083E61FC1E6068B0F0FBE4C310483E10174C650E88C120000598365FC008B07F64430"
$__HandleImgSearch_Opcode32 &= "0401741CFF7514FF7510FF750CFF7508E8D7FEFFFF83C4108945DC8955E0EB19E88BA7FFFFC70009000000E893A7FFFF832000895DDC895DE0C745FCFEFFFFFFE80C0000008B45DC8"
$__HandleImgSearch_Opcode32 &= "B55E0E8DAE3FFFFC3FF7508E8C812000059C38BFF558BECB8E41A0000E85B140000A10020011033C58945FC8B450C568B75085733FF898534E5FFFF89BD38E5FFFF89BD30E5FFFF39"
$__HandleImgSearch_Opcode32 &= "7D10750733C0E9AE0600003BC7751FE81EA7FFFF8938E804A7FFFFC70016000000E83EB9FFFF83C8FFE98B0600008BC6C1F8058BFE538D1C85E04D01108B0383E71FC1E7068A4C382"
$__HandleImgSearch_Opcode32 &= "402C9D0F9899D24E5FFFF888D3FE5FFFF80F902740580F90175278B4D10F7D1F6C101751DE8C0A6FFFF832000E8A5A6FFFFC70016000000E8DFB8FFFFE91D060000F644380420740F"
$__HandleImgSearch_Opcode32 &= "6A026A006A0056E8BEFDFFFF83C41056E83E0700005985C00F84990200008B03F6440704800F848C020000E8A6B2FFFF8B406C33C93948148D8520E5FFFF0F94C1508B03FF34078BF"
$__HandleImgSearch_Opcode32 &= "1FF1550F0001033C93BC10F84600200003BF1740C388D3FE5FFFF0F8450020000FF1554F000108B9D34E5FFFF898520E5FFFF33C089852CE5FFFF3945100F8623050000898540E5FF"
$__HandleImgSearch_Opcode32 &= "FF8A853FE5FFFF84C00F85670100008A0B8BB524E5FFFF33C080F90A0F94C089851CE5FFFF8B0603C78378380074158A50348855F4884DF5836038006A028D45F450EB4B0FBEC150E"
$__HandleImgSearch_Opcode32 &= "804CEFFFF5985C0743A8B8D34E5FFFF2BCB034D1033C0403BC80F86A50100006A028D8544E5FFFF5350E87612000083C40C83F8FF0F849204000043FF8540E5FFFFEB1B6A01538D85"
$__HandleImgSearch_Opcode32 &= "44E5FFFF50E85212000083C40C83F8FF0F846E04000033C050506A058D4DF4516A018D8D44E5FFFF5150FFB520E5FFFF43FF8540E5FFFFFF1508F100108BF085F60F843D0400006A0"
$__HandleImgSearch_Opcode32 &= "08D852CE5FFFF50568D45F4508B8524E5FFFF8B00FF3407FF15FCF0001085C00F840A0400008B8540E5FFFF8B8D30E5FFFF03C1898538E5FFFF39B52CE5FFFF0F8CF603000083BD1C"
$__HandleImgSearch_Opcode32 &= "E5FFFF000F84CD0000006A008D852CE5FFFF506A018D45F4508B8524E5FFFF8B00C645F40DFF3407FF15FCF0001085C00F84B103000083BD2CE5FFFF010F8CB0030000FF8530E5FFF"
$__HandleImgSearch_Opcode32 &= "FFF8538E5FFFFE9830000003C0174043C0275210FB73333C983FE0A0F94C183C302838540E5FFFF0289B544E5FFFF898D1CE5FFFF3C0174043C027552FFB544E5FFFFE8E30F000059"
$__HandleImgSearch_Opcode32 &= "663B8544E5FFFF0F8549030000838538E5FFFF0283BD1CE5FFFF0074296A0D5850898544E5FFFFE8B60F000059663B8544E5FFFF0F851C030000FF8538E5FFFFFF8530E5FFFF8B451"
$__HandleImgSearch_Opcode32 &= "0398540E5FFFF0F82F9FDFFFFE9080300008B0E8A13FF8538E5FFFF88540F348B0E89440F38E9EF02000033C98B03F6443804800F84A102000080BD3FE5FFFF00898D44E5FFFF0F85"
$__HandleImgSearch_Opcode32 &= "A80000008B9D34E5FFFF394D100F86FD0200008BCB33F62B8D34E5FFFF8D8548E5FFFF3B4D1073268A134341899D20E5FFFF80FA0A750BFF8530E5FFFFC6000D40468810404681FEF"
$__HandleImgSearch_Opcode32 &= "F13000072D58BF08D8548E5FFFF2BF06A008D8528E5FFFF50568D8548E5FFFF508B8524E5FFFF8B00FF3407FF15FCF0001085C00F84430200008B8528E5FFFF018538E5FFFF3BC60F"
$__HandleImgSearch_Opcode32 &= "8C3B0200008BC32B8534E5FFFF3B45100F826CFFFFFFE92502000080BD3FE5FFFF020F85CD0000008B9D34E5FFFF394D100F864802000083A540E5FFFF008BCB2B8D34E5FFFF6A028"
$__HandleImgSearch_Opcode32 &= "D8548E5FFFF5E3B4D1073430FB71303DE03CE899D20E5FFFF83FA0A751A01B530E5FFFF6A0D5B6689188B9D20E5FFFF03C601B540E5FFFF01B540E5FFFF66891003C681BD40E5FFFF"
$__HandleImgSearch_Opcode32 &= "FE13000072B88BF08D8548E5FFFF2BF06A008D8528E5FFFF50568D8548E5FFFF508B8524E5FFFF8B00FF3407FF15FCF0001085C00F84690100008B8528E5FFFF018538E5FFFF3BC60"
$__HandleImgSearch_Opcode32 &= "F8C610100008BC32B8534E5FFFF3B45100F8247FFFFFFE94B0100008B8534E5FFFF89852CE5FFFF394D100F86750100008B8D2CE5FFFF83A540E5FFFF002B8D34E5FFFF6A028D8548"
$__HandleImgSearch_Opcode32 &= "F9FFFF5E3B4D10733B8B952CE5FFFF0FB71201B52CE5FFFF03CE83FA0A750E6A0D5B66891803C601B540E5FFFF01B540E5FFFF66891003C681BD40E5FFFFA806000072C033F656566"
$__HandleImgSearch_Opcode32 &= "8550D00008D8DF0EBFFFF518D8D48F9FFFF2BC1992BC2D1F8508BC1505668E9FD0000FF1508F100108BD83BDE0F84970000006A008D8528E5FFFF508BC32BC6508D8435F0EBFFFF50"
$__HandleImgSearch_Opcode32 &= "8B8524E5FFFF8B00FF3407FF15FCF0001085C0740C03B528E5FFFF3BDE7FCBEB0CFF1590F00010898544E5FFFF3BDE7F5C8B852CE5FFFF2B8534E5FFFF898538E5FFFF3B45100F820"
$__HandleImgSearch_Opcode32 &= "BFFFFFFEB3F518D8D28E5FFFF51FF7510FFB534E5FFFFFF3438FF15FCF0001085C074158B8528E5FFFF83A544E5FFFF00898538E5FFFFEB0CFF1590F00010898544E5FFFF83BD38E5"
$__HandleImgSearch_Opcode32 &= "FFFF00756C83BD44E5FFFF00742D6A055E39B544E5FFFF7514E8C6A0FFFFC70009000000E8CEA0FFFF8930EB3FFFB544E5FFFFE8D2A0FFFF59EB318B8524E5FFFF8B00F6440704407"
$__HandleImgSearch_Opcode32 &= "40F8B8534E5FFFF80381A750433C0EB24E886A0FFFFC7001C000000E88EA0FFFF83200083C8FFEB0C8B8538E5FFFF2B8530E5FFFF5B8B4DFC5F33CD5EE8B790FFFFC9C36A1068500E"
$__HandleImgSearch_Opcode32 &= "0110E881DCFFFF8B5D0883FBFE751BE852A0FFFF832000E837A0FFFFC7000900000083C8FFE99400000085DB78083B1DCC4D0110721AE82BA0FFFF832000E810A0FFFFC7000900000"
$__HandleImgSearch_Opcode32 &= "0E84AB2FFFFEBD28BC3C1F8058D3C85E04D01108BF383E61FC1E6068B070FBE44300483E00174C653E8AF0A0000598365FC008B07F6443004017414FF7510FF750C53E86EF8FFFF83"
$__HandleImgSearch_Opcode32 &= "C40C8945E4EB17E8B69FFFFFC70009000000E8BE9FFFFF832000834DE4FFC745FCFEFFFFFFE80C0000008B45E4E80ADCFFFFC38B5D0853E8F70A000059C38BFF558BECFF05343D011"
$__HandleImgSearch_Opcode32 &= "06800100000E815D4FFFF598B4D0889410885C0740D83490C08C7411800100000EB1183490C048D4114894108C74118020000008B41088361040089015DC38BFF558BEC8B450883F8"
$__HandleImgSearch_Opcode32 &= "FE750FE8299FFFFFC7000900000033C05DC385C078083B05CC4D01107212E80E9FFFFFC70009000000E848B1FFFFEBDE8BC883E01FC1F9058B0C8DE04D0110C1E0060FBE44010483E"
$__HandleImgSearch_Opcode32 &= "0405DC3B8F82A0110C3A1C04D0110566A145E85C07507B800020000EB063BC67D078BC6A3C04D01106A0450E8A3D3FFFF5959A3B43D011085C0751E6A04568935C04D0110E88AD3FF"
$__HandleImgSearch_Opcode32 &= "FF5959A3B43D011085C075056A1A585EC333D2B9F82A0110EB05A1B43D0110890C0283C12083C20481F9782D01107CEA6AFE5E33D2B9082B0110578BC2C1F8058B0485E04D01108BF"
$__HandleImgSearch_Opcode32 &= "A83E71FC1E7068B040783F8FF74083BC6740485C07502893183C1204281F9682B01107CCE5F33C05EC3E88F0D0000803D5C340110007405E85B0B0000FF35B43D0110E87C8EFFFF59"
$__HandleImgSearch_Opcode32 &= "C38BFF558BEC568B7508B8F82A01103BF0722281FE582D0110771A8BCE2BC8C1F90583C11051E834E1FFFF814E0C0080000059EB0A83C62056FF154CF100105E5DC38BFF558BEC8B4"
$__HandleImgSearch_Opcode32 &= "50883F8147D1683C01050E807E1FFFF8B450C81480C00800000595DC38B450C83C02050FF154CF100105DC38BFF558BEC8B4508B9F82A01103BC1721F3D582D0110771881600CFF7F"
$__HandleImgSearch_Opcode32 &= "FFFF2BC1C1F80583C01050E8E5DFFFFF595DC383C02050FF1548F100105DC38BFF558BEC8B4D088B450C83F9147D1381600CFF7FFFFF83C11051E8B6DFFFFF595DC383C02050FF154"
$__HandleImgSearch_Opcode32 &= "8F100105DC38BFF558BEC8B450885C07515E81F9DFFFFC70016000000E859AFFFFF83C8FF5DC38B40105DC3A10020011083C80133C93905383D01100F94C18BC1C38BFF558BEC83EC"
$__HandleImgSearch_Opcode32 &= "1053568B750C33DB578B7D103BF375113BFB760D8B45083BC37402891833C0EB7B8B45083BC374038308FF81FFFFFFFF7F7613E8B59CFFFF6A165E8930E8F0AEFFFF8BC6EB56FF751"
$__HandleImgSearch_Opcode32 &= "88D4DF0E8428DFFFF8B45F03958140F8590000000668B4514B9FF000000663BC176363BF3740F3BFB760B575356E8A7DCFFFF83C40CE86A9CFFFFC7002A000000E85F9CFFFF8B0038"
$__HandleImgSearch_Opcode32 &= "5DFC74078B4DF8836170FD5F5E5BC9C33BF374263BFB7720E83F9CFFFF6A225E8930E87AAEFFFF385DFC74858B45F8836070FDE979FFFFFF88068B45083BC37406C70001000000385"
$__HandleImgSearch_Opcode32 &= "DFC0F843CFFFFFF8B45F8836070FDE930FFFFFF8D4D0C515357566A018D4D145153895D0CFF7004FF1508F100103BC37414395D0C0F856AFFFFFF8B4D083BCB74BD8901EBB9FF1590"
$__HandleImgSearch_Opcode32 &= "F0001083F87A0F8550FFFFFF3BF30F8473FFFFFF3BFB0F866BFFFFFF575356E8DCDBFFFF83C40CE95BFFFFFF8BFF558BEC6A00FF7514FF7510FF750CFF7508E893FEFFFF83C4145DC"
$__HandleImgSearch_Opcode32 &= "3CCCCCCCCCCCCCC518D4C24082BC883E10F03C11BC90BC159E97A080000518D4C24082BC883E10703C11BC90BC159E9640800008BFF558BEC8B4D0885C9741B6AE033D258F7F13B45"
$__HandleImgSearch_Opcode32 &= "0C730FE8329BFFFFC7000C00000033C05DC30FAF4D0C568BF185F675014633C083FEE07713566A08FF35FC330110FF1598F0001085C07532833D943A011000741C56E8E3B2FFFF598"
$__HandleImgSearch_Opcode32 &= "5C075D28B451085C07406C7000C00000033C0EB0D8B4D1085C97406C7010C0000005E5DC38BFF558BEC837D0800750BFF750CE8D391FFFF595DC3568B750C85F6750DFF7508E8138B"
$__HandleImgSearch_Opcode32 &= "FFFF5933C0EB4D57EB3085F675014656FF75086A00FF35FC330110FF154CF000108BF885FF755E3905943A0110744056E864B2FFFF5985C0741D83FEE076CB56E854B2FFFF59E85E9"
$__HandleImgSearch_Opcode32 &= "AFFFFC7000C00000033C05F5E5DC3E84D9AFFFF8BF0FF1590F0001050E8FD99FFFF598906EBE2E8359AFFFF8BF0FF1590F0001050E8E599FFFF5989068BC7EBCA8BFF558BEC83EC10"
$__HandleImgSearch_Opcode32 &= "FF75088D4DF0E8B38AFFFF0FB6450C8B4DF48A55148454011D751E837D100074128B4DF08B89C80000000FB70441234510EB0233C085C0740333C040807DFC0074078B4DF8836170F"
$__HandleImgSearch_Opcode32 &= "DC9C38BFF558BEC6A046A00FF75086A00E89AFFFFFF83C4105DC3CCCCCCCCCCCCCCCCCCCC5356578B5424108B4424148B4C241855525051516870AC001064FF3500000000A1002001"
$__HandleImgSearch_Opcode32 &= "1033C489442408648925000000008B4424308B58088B4C242C33198B700C83FEFE743B8B54243483FAFE74043BF2762E8D34768D5CB3108B0B89480C837B040075CC68010100008B4"
$__HandleImgSearch_Opcode32 &= "308E8C2090000B9010000008B4308E8D4090000EBB0648F050000000083C4185F5E5BC38B4C2404F7410406000000B80100000074338B4424088B480833C8E85889FFFF558B6818FF"
$__HandleImgSearch_Opcode32 &= "700CFF7010FF7014E83EFFFFFF83C40C5D8B4424088B5424108902B803000000C3558B4C24088B29FF711CFF7118FF7128E815FFFFFF83C40C5DC20400555657538BEA33C033DB33D"
$__HandleImgSearch_Opcode32 &= "233F633FFFFD15B5F5E5DC38BEA8BF18BC16A01E81F09000033C033DB33C933D233FFFFE6558BEC5356576A00526816AD001051E8A20C00005F5E5B5DC3558B6C24085251FF742414"
$__HandleImgSearch_Opcode32 &= "E8B5FEFFFF83C40C5DC20800660FEFC051538BC183E00F85C0757F8BC283E27FC1E80774378DA42400000000660F7F01660F7F4110660F7F4120660F7F4130660F7F4140660F7F415"
$__HandleImgSearch_Opcode32 &= "0660F7F4160660F7F41708D89800000004875D085D274378BC2C1E804740FEB038D4900660F7F018D49104875F683E20F741C8BC233DBC1EA02740889198D49044A75F883E0037406"
$__HandleImgSearch_Opcode32 &= "8819414875FA5B58C38BD8F7DB83C3102BD333C0528BD383E20374068801414A75FAC1EB02740889018D49044B75F85AE955FFFFFF6A0AFF1544F00010A3B03D011033C0C3578BC68"
$__HandleImgSearch_Opcode32 &= "3E00F85C00F85C10000008BD183E17FC1EA077465EB068D9B00000000660F6F06660F6F4E10660F6F5620660F6F5E30660F7F07660F7F4F10660F7F5720660F7F5F30660F6F664066"
$__HandleImgSearch_Opcode32 &= "0F6F6E50660F6F7660660F6F7E70660F7F6740660F7F6F50660F7F7760660F7F7F708DB6800000008DBF800000004A75A385C974498BD1C1EA0485D274178D9B00000000660F6F066"
$__HandleImgSearch_Opcode32 &= "60F7F078D76108D7F104A75EF83E10F74248BC1C1E902740D8B1689178D76048D7F044975F38BC883E10374098A06880746474975F7585E5F5DC3BA100000002BD02BCA518BC28BC8"
$__HandleImgSearch_Opcode32 &= "83E10374098A16881746474975F7C1E802740D8B1689178D76048D7F044875F359E90BFFFFFFE8E0E5FFFF85C074086A16E8E2E5FFFF59F605802D01100274116A0168150000406A0"
$__HandleImgSearch_Opcode32 &= "3E82EA7FFFF83C40C6A03E8EAABFFFFCC8BFF558BEC837D08007515E84996FFFFC70016000000E883A8FFFF83C8FF5DC3FF75086A00FF35FC330110FF1584F000105DC36A02E8D4AB"
$__HandleImgSearch_Opcode32 &= "FFFF59C38BFF558BEC8B4D085333DB56573BCB7C5B3B0DCC4D011073538BC1C1F8058BF183E61F8D3C85E04D01108B07C1E606F6443004017436833C30FF7430833DD030011001751"
$__HandleImgSearch_Opcode32 &= "D2BCB7410497408497513536AF4EB08536AF5EB03536AF6FF153CF000108B07830C06FF33C0EB15E8AC95FFFFC70009000000E8B495FFFF891883C8FF5F5E5B5DC38BFF558BEC8B45"
$__HandleImgSearch_Opcode32 &= "0883F8FE7518E89895FFFF832000E87D95FFFFC7000900000083C8FF5DC385C078083B05CC4D0110721AE87495FFFF832000E85995FFFFC70009000000E893A7FFFFEBD58BC8C1F90"
$__HandleImgSearch_Opcode32 &= "58B0C8DE04D011083E01FC1E006F64408040174CD8B04085DC36A0C68700E0110E857D1FFFF8B7D088BC7C1F8058BF783E61FC1E606033485E04D0110C745E40100000033DB395E08"
$__HandleImgSearch_Opcode32 &= "75356A0AE846D8FFFF59895DFC395E08751968A00F00008D460C50FF1518F1001085C07503895DE4FF4608C745FCFEFFFFFFE830000000395DE4741D8BC7C1F80583E71FC1E7068B0"
$__HandleImgSearch_Opcode32 &= "485E04D01108D44380C50FF154CF100108B45E4E818D1FFFFC333DB8B7D086A0AE808D7FFFF59C38BFF558BEC8B45088BC883E01FC1F9058B0C8DE04D0110C1E0068D44010C50FF15"
$__HandleImgSearch_Opcode32 &= "48F100105DC38BFF558BEC51833DA02D0110FE7505E800050000A1A02D011083F8FF7507B8FFFF0000C9C36A008D4DFC516A018D4D085150FF1538F0001085C074E2668B4508C9C38"
$__HandleImgSearch_Opcode32 &= "BFF558BEC83EC1053568B750C33DB3BF37415395D107410381E75128B45083BC3740533C966890833C05E5BC9C3FF75148D4DF0E89384FFFF8B45F0395814751E8B45083BC374060F"
$__HandleImgSearch_Opcode32 &= "B60E668908385DFC74078B45F8836070FD33C040EBCB8D45F0500FB60650E8D6BBFFFF595985C0747D8B45F08B88AC00000083F9017E25394D107C2033D2395D080F95C252FF75085"
$__HandleImgSearch_Opcode32 &= "1566A09FF7004FF1578F0001085C08B45F075108B4D103B88AC0000007220385E01741B8B80AC000000385DFC0F8466FFFFFF8B4DF8836170FDE95AFFFFFFE85193FFFFC7002A0000"
$__HandleImgSearch_Opcode32 &= "00385DFC74078B45F8836070FD83C8FFE93BFFFFFF33C0395D080F95C050FF75088B45F06A01566A09FF7004FF1578F0001085C00F853AFFFFFFEBBA8BFF558BEC6A00FF7510FF750"
$__HandleImgSearch_Opcode32 &= "CFF7508E8D5FEFFFF83C4105DC3CCCCCCCCCCCCCCCCCCCCCC518D4C24042BC81BC0F7D023C88BC42500F0FFFF3BC8720A8BC159948B00890424C32D001000008500EBE96A1068900E"
$__HandleImgSearch_Opcode32 &= "0110E8E9CEFFFF33DB895DE46A01E8F8D5FFFF59895DFC6A035F897DE03B3DC04D01107D548BF7A1B43D0110391CB074458B04B0F6400C83740F50E8CA0300005983F8FF7403FF45E"
$__HandleImgSearch_Opcode32 &= "483FF147C28A1B43D01108B04B083C02050FF1524F10010A1B43D0110FF34B0E8BA82FFFF59A1B43D0110891CB047EBA1C745FCFEFFFFFFE8090000008B45E4E8A8CEFFFFC36A01E8"
$__HandleImgSearch_Opcode32 &= "9DD4FFFF59C38BFF558BEC53568B75088B460C8BC880E10333DB80F9027540A90801000074398B4608578B3E2BF885FF7E2C575056E8C0F4FFFF5950E891F1FFFF83C40C3BC7750F8"
$__HandleImgSearch_Opcode32 &= "B460C84C0790F83E0FD89460CEB07834E0C2083CBFF5F8B46088366040089065E8BC35B5DC38BFF558BEC568B750885F6750956E83500000059EB2F56E87CFFFFFF5985C0740583C8"
$__HandleImgSearch_Opcode32 &= "FFEB1FF7460C00400000741456E857F4FFFF50E84403000059F7D8591BC0EB0233C05E5DC36A1468B00E0110E89DCDFFFF33FF897DE4897DDC6A01E8A9D4FFFF59897DFC33F68975E"
$__HandleImgSearch_Opcode32 &= "03B35C04D01100F8D83000000A1B43D01108D04B03938745E8B00F6400C8374565056E85CF3FFFF595933D2428955FCA1B43D01108B04B08B480CF6C183742F395508751150E84AFF"
$__HandleImgSearch_Opcode32 &= "FFFF5983F8FF741EFF45E4EB19397D087514F6C102740F50E82FFFFFFF5983F8FF75030945DC897DFCE80800000046EB8433FF8B75E0A1B43D0110FF34B056E865F3FFFF5959C3C74"
$__HandleImgSearch_Opcode32 &= "5FCFEFFFFFFE812000000837D08018B45E474038B45DCE81ECDFFFFC36A01E813D3FFFF59C36A01E81FFFFFFF59C3CCCCCCCCCCCC558BEC535657556A006A006818B50010FF7508E8"
$__HandleImgSearch_Opcode32 &= "A00400005D5F5E5B8BE55DC38B4C2404F7410406000000B80100000074328B4424148B48FC33C8E8A880FFFF558B68108B5028528B502452E81400000083C4085D8B4424088B54241"
$__HandleImgSearch_Opcode32 &= "08902B803000000C35356578B44241055506AFE6820B5001064FF3500000000A10020011033C4508D44240464A3000000008B4424288B58088B700C83FEFF743A837C242CFF74063B"
$__HandleImgSearch_Opcode32 &= "74242C762D8D34768B0CB3894C240C89480C837CB30400751768010100008B44B308E8490000008B44B308E85F000000EBB78B4C240464890D0000000083C4185F5E5BC333C0648B0"
$__HandleImgSearch_Opcode32 &= "D0000000081790420B5001075108B510C8B520C3951087505B801000000C35351BB902D0110EB0B5351BB902D01108B4C240C894B08894304896B0C55515058595D595BC20400FFD0"
$__HandleImgSearch_Opcode32 &= "C333C050506A03506A03680000004068340A0110FF1534F00010A3A02D0110C3A1A02D011083F8FF740C83F8FE740750FF1564F00010C38BFF558BEC568B75085783CFFF85F67514E"
$__HandleImgSearch_Opcode32 &= "8088FFFFFC70016000000E842A1FFFF0BC7EB44F6460C83743856E8C9FCFFFF568BF8E8E102000056E8AFF1FFFF50E81102000083C41085C0790583CFFFEB128B461C85C0740B50E8"
$__HandleImgSearch_Opcode32 &= "2C7FFFFF83661C005983660C008BC75F5E5DC36A0C68D80E0110E8DACAFFFF834DE4FF33C08B750885F60F95C085C07515E88E8EFFFFC70016000000E8C8A0FFFF83C8FFEB0DF6460"
$__HandleImgSearch_Opcode32 &= "C40740D83660C008B45E4E8E6CAFFFFC356E857F0FFFF598365FC0056E83CFFFFFF598945E4C745FCFEFFFFFFE805000000EBD48B750856E8A4F0FFFF59C36A1068F80E0110E866CA"
$__HandleImgSearch_Opcode32 &= "FFFF8B5D0883FBFE7513E8248EFFFFC7000900000083C8FFE9A100000085DB78083B1DCC4D01107212E8058EFFFFC70009000000E83FA0FFFFEBDA8BC3C1F8058D3C85E04D01108BF"
$__HandleImgSearch_Opcode32 &= "383E61FC1E6068B070FBE44060483E00174CE53E8A4F8FFFF598365FC008B07F644060401743153E827F8FFFF5950FF1550F1001085C0750BFF1590F000108945E4EB048365E40083"
$__HandleImgSearch_Opcode32 &= "7DE4007419E8AB8DFFFF8B4DE48908E88E8DFFFFC70009000000834DE4FFC745FCFEFFFFFFE80C0000008B45E4E8EAC9FFFFC38B5D0853E8D7F8FFFF59C38BFF558BEC568B7508575"
$__HandleImgSearch_Opcode32 &= "6E8BDF7FFFF5983F8FF7450A1E04D011083FE017509F6808400000001750B83FE02751CF640440174166A02E892F7FFFF6A018BF8E889F7FFFF59593BC7741C56E87DF7FFFF5950FF"
$__HandleImgSearch_Opcode32 &= "1564F0001085C0750AFF1590F000108BF8EB0233FF56E8D9F6FFFF8BC6C1F8058B0485E04D011083E61FC1E60659C64430040085FF740C57E8FA8CFFFF5983C8FFEB0233C05F5E5DC"
$__HandleImgSearch_Opcode32 &= "36A1068180F0110E8F1C8FFFF8B5D0883FBFE751BE8C28CFFFF832000E8A78CFFFFC7000900000083C8FFE98400000085DB78083B1DCC4D0110721AE89B8CFFFF832000E8808CFFFF"
$__HandleImgSearch_Opcode32 &= "C70009000000E8BA9EFFFFEBD28BC3C1F8058D3C85E04D01108BF383E61FC1E6068B070FBE44300483E00174C653E81FF7FFFF598365FC008B07F644300401740C53E8D5FEFFFF598"
$__HandleImgSearch_Opcode32 &= "945E4EB0FE82E8CFFFFC70009000000834DE4FFC745FCFEFFFFFFE80C0000008B45E4E88AC8FFFFC38B5D0853E877F7FFFF59C38BFF558BEC568B75088B460CA883741EA808741AFF"
$__HandleImgSearch_Opcode32 &= "7608E8547CFFFF81660CF7FBFFFF33C05989068946088946045E5DC3FF2548F00010B895C50010A3D02A0110C705D42A01108BBC0010C705D82A01103FBC0010C705DC2A011078BC0"
$__HandleImgSearch_Opcode32 &= "010C705E02A0110E1BB0010A3E42A0110C705E82A01100DC50010C705EC2A0110FDBB0010C705F02A01105FBB0010C705F42A0110EBBA0010C38BFF558BECE896FFFFFF837D080074"
$__HandleImgSearch_Opcode32 &= "05E8850B0000DBE25DC3CCCCCCCCCCCCCCCCCC833DB03D011000742D558BEC83EC0883E4F8DD1C24F20F2C0424C9C3833DB03D011000741183EC04D93C24586683E07F6683F87F74D"
$__HandleImgSearch_Opcode32 &= "3558BEC83EC2083E4F0D9C0D9542418DF7C2410DF6C24108B5424188B44241085C0743CDEE985D2791ED91C248B0C2481F10000008081C1FFFFFF7F83D0008B54241483D200EB2CD9"
$__HandleImgSearch_Opcode32 &= "1C248B0C2481C1FFFFFF7F83D8008B54241483DA00EB148B542414F7C2FFFFFF7F75B8D95C2418D95C2418C9C38BFF558BEC83EC1056FF750C8D4DF0E8327BFFFF8B75080FBE0650E"
$__HandleImgSearch_Opcode32 &= "80F9BFFFF83F865EB0C460FB60650E82F7DFFFF85C05975F10FBE0650E8F29AFFFF5983F878750383C6028B4DF08B89BC0000008B098A068A09880E468A0E88068AC18A0E4684C975"
$__HandleImgSearch_Opcode32 &= "F35E384DFC74078B45F8836070FDC9C38BFF558BEC83EC1056FF750C8D4DF0E8BE7AFFFF8B45088A088B75F084C974158B96BC0000008B128A123ACA7407408A0884C975F58A08408"
$__HandleImgSearch_Opcode32 &= "4C97436EB0B80F965740C80F9457407408A0884C975EF8BD04880383074FA8B8EBC0000008B09538A183A195B7501488A0A4042880884C975F6807DFC005E74078B45F8836070FDC9"
$__HandleImgSearch_Opcode32 &= "C38BFF558BECD9EE8B4508DC18DFE0F6C4417A0533C0405DC333C05DC38BFF558BEC5151837D0800FF7514FF751074198D45F850E8C70900008B4DF88B450C89088B4DFC894804EB1"
$__HandleImgSearch_Opcode32 &= "18D450850E8560A00008B450C8B4D08890883C40CC9C38BFF558BEC6A00FF7510FF750CFF7508E8A9FFFFFF83C4105DC38BFF568BF085FF741456E838D6FFFF40505603F756E8BD0A"
$__HandleImgSearch_Opcode32 &= "000083C4105EC38BFF558BEC6A00FF7508E864FEFFFF59595DC38BFF558BEC6A00FF7508E8C5FEFFFF59595DC38BFF558BEC83EC105356FF751C8D4DF08BD8E87C79FFFF33C93BD97"
$__HandleImgSearch_Opcode32 &= "522E8CB88FFFF6A165E8930E8069BFFFF807DFC0074078B45F8836070FD8BC65E5BC9C3394D0876D9394D0C7E058B450CEB0233C083C0093945087709E89088FFFF6A22EBC357384D"
$__HandleImgSearch_Opcode32 &= "18741E8B551433C0394D0C0F9FC033C9833A2D0F94C18BF803CB8BC1E836FFFFFF8B7D14833F2D8BF37506C6032D8D7301837D0C007E158A4E018B45F0880E8B80BC0000008B008A0"
$__HandleImgSearch_Opcode32 &= "046880633C03845180F94C003450C03F0837D08FF750583CBFFEB052BDE035D0868A40B01105356E8BFD0FFFF83C40C85C075748D4E023945107403C606458B470C803830742F8B47"
$__HandleImgSearch_Opcode32 &= "04487906F7D8C646012D83F8647C0B996A645FF7FF0046028BC283F80A7C0B996A0A5FF7FF0046038BC2004604F605AC3D0110015F7414803930750F6A038D41015051E8550900008"
$__HandleImgSearch_Opcode32 &= "3C40C807DFC0074078B45F8836070FD33C0E9E7FEFFFF33C05050505050E88099FFFFCC8BFF558BEC83EC2CA10020011033C58945FC8B450853568B7514578B7D0C6A165B538D4DE4"
$__HandleImgSearch_Opcode32 &= "518D4DD451FF7004FF30E8C40D000083C41485FF7510E84C87FFFF8918E88A99FFFF8BC3EB6D8B451085C074E983F8FF75040BC0EB1433C9837DD42D0F94C12BC133C985F60F9FC12"
$__HandleImgSearch_Opcode32 &= "BC18D4DD4518D4E01515033C0837DD42D0F94C033C985F60F9FC103C703C851E8000C000083C41085C07405C60700EB1AFF751C8D45D46A0050FF75188BC756FF7510E8EAFDFFFF83"
$__HandleImgSearch_Opcode32 &= "C4188B4DFC5F5E33CD5BE82477FFFFC9C38BFF558BEC6A00FF7518FF7514FF7510FF750CFF7508E81EFFFFFF83C4185DC38BFF558BEC83EC245657FF751C8D4DDCC745ECFF0300003"
$__HandleImgSearch_Opcode32 &= "3FFC745FC30000000E82677FFFF397D147D03897D148B750C3BF77523E86C86FFFF6A165E8930E8A798FFFF807DE80074078B45E4836070FD8BC6E91B030000397D1076D88B451483"
$__HandleImgSearch_Opcode32 &= "C00BC606003945107709E83686FFFF6A22EBC88B7D088B078945F48B47048BC8C1E914BAFF0700005323CA33DB3BCA0F859200000085DB0F858A0000008B451083F8FF75040BC0EB0"
$__HandleImgSearch_Opcode32 &= "383C0FE6A00FF75148D5E02505357E824FFFFFF83C41485C07419807DE800C606000F84A10200008B4DE4836170FDE995020000803B2D7504C6062D46837D1800C606300F94C0FEC8"
$__HandleImgSearch_Opcode32 &= "24E004788846016A6583C60256E8577DFFFF595985C00F8455020000837D18000F94C1FEC980E1E080C1708808C6400300E93B020000250000008033C90BC87404C6062D468B5D188"
$__HandleImgSearch_Opcode32 &= "5DB0F94C0FEC824E00478F7DB1BDBC606308846018B4F0483E3E081E10000F07F33C083C32733D20BC17524C64602308B4F048B0781E1FFFF0F0083C6030BC175058955ECEB10C745"
$__HandleImgSearch_Opcode32 &= "ECFE030000EB07C646023183C6038BC64689450C39551475048810EB0F8B4DDC8B89BC0000008B098A0988088B4F048B0781E1FFFF0F00894DF877083BC20F86B40000008955F4C74"
$__HandleImgSearch_Opcode32 &= "5F800000F00837D14007E4C8B57042355F88B070FBF4DFC2345F481E2FFFF0F00E89A0C00006683C0300FB7C083F839760203C38B4DF8836DFC0488068B45F40FACC804C1E90446FF"
$__HandleImgSearch_Opcode32 &= "4D1466837DFC008945F4894DF87DAE66837DFC007C518B57042355F88B070FBF4DFC2345F481E2FFFF0F00E8470C00006683F80876318D46FF8A0880F966740580F9467506C600304"
$__HandleImgSearch_Opcode32 &= "8EBEE3B450C74148A0880F939750780C33A8818EB09FEC18808EB03FE40FF837D14007E11FF75146A3056E84FC4FFFF83C40C0375148B450C80380075028BF0837D1800B1340F94C0"
$__HandleImgSearch_Opcode32 &= "FEC824E0047088068B078B5704E8D40B000033DB25FF07000023D32B45EC53591BD1780F7F043BC37209C646012B83C602EB0DC646012D83C602F7D813D3F7DA8BFEC606303BD37C2"
$__HandleImgSearch_Opcode32 &= "4B9E80300007F043BC1721953515250E8A90A000004308806468955F08BC18BD33BF7750B85D27C1E7F0583F86472176A006A645250E8830A0000043088068955F0468BC18BD33BF7"
$__HandleImgSearch_Opcode32 &= "750B85D27C1F7F0583F80A72186A006A0A5250E85D0A0000043088068955F0468BC1895DF004308806C6460100807DE80074078B45E4836070FD33C05B5F5EC9C38BFF558BEC83EC1"
$__HandleImgSearch_Opcode32 &= "0535657FF75148BF88B77048BD98D4DF04EE8B773FFFF85DB7523E80883FFFF6A165E8930E84395FFFF807DFC0074078B45F8836070FD8BC6E9B9000000837D080076D7807D100074"
$__HandleImgSearch_Opcode32 &= "153B750C751033C0833F2D0F94C003C666C704183000833F2D8BF37506C6032D8D73018B470485C07F1C568D5E01E8C1CFFFFF40505653E848040000C6063083C4108BF3EB0203F08"
$__HandleImgSearch_Opcode32 &= "37D0C007E51568D5E01E89DCFFFFF40505653E8240400008B45F08B80BC0000008B008A0088068B7F0483C41085FF7926F7DF807D10007505397D0C7C03897D0C8B7D0C8BC3E81AF9"
$__HandleImgSearch_Opcode32 &= "FFFF576A3053E878C2FFFF83C40C807DFC0074078B45F8836070FD33C05F5E5BC9C38BFF558BEC83EC2CA10020011033C58945FC8B450856578B7D0C6A165E568D4DE4518D4DD451F"
$__HandleImgSearch_Opcode32 &= "F7004FF30E86808000083C41485FF7510E8F081FFFF8930E82E94FFFF8BC6EB6C538B5D1085DB7510E8D881FFFF8930E81694FFFF8BC6EB5383C8FF3BD8740D33C9837DD42D8BC30F"
$__HandleImgSearch_Opcode32 &= "94C12BC18B75148D4DD4518B4DD803CE515033C0837DD42D0F94C003C750E8A006000083C41085C07405C60700EB14FF75188D45D46A0056538BCFE84EFEFFFF83C4105B8B4DFC5F3"
$__HandleImgSearch_Opcode32 &= "3CD5EE8CA71FFFFC9C38BFF558BEC83EC2CA10020011033C58945FC8B4508568B750C576A165F578D4DE4518D4DD451FF7004FF30E8A707000083C41485F67513E82F81FFFF8938E8"
$__HandleImgSearch_Opcode32 &= "6D93FFFF8BC7E9950000008B4D1085C974E6538B5DD833C04B837DD42D0F94C08D3C3083F9FF75040BC9EB022BC88D45D450FF75145157E8F605000083C41085C07405C60600EB578"
$__HandleImgSearch_Opcode32 &= "B45D8483BD80F9CC183F8FC7C2D3B45147D2884C9740A8A074784C075F98847FEFF751C8D45D46A01FF75148BCEFF7510E87FFDFFFF83C410EB1CFF751C8D45D46A0150FF75188BC6"
$__HandleImgSearch_Opcode32 &= "FF7514FF7510E8A3F7FFFF83C4185B8B4DFC5F33CD5EE8DD70FFFFC9C38BFF558BEC8B451483F865745F83F845745A83F8667519FF7520FF7518FF7510FF750CFF7508E827FEFFFF8"
$__HandleImgSearch_Opcode32 &= "3C4145DC383F861741E83F8417419FF7520FF751CFF7518FF7510FF750CFF7508E8C2FEFFFFEB30FF7520FF751CFF7518FF7510FF750CFF7508E86FF9FFFFEB17FF7520FF751CFF75"
$__HandleImgSearch_Opcode32 &= "18FF7510FF750CFF7508E86FF8FFFF83C4185DC38BFF558BEC6A00FF751CFF7518FF7514FF7510FF750CFF7508E85AFFFFFF83C41C5DC38BFF566800000300680000010033F656E8C"
$__HandleImgSearch_Opcode32 &= "207000083C40C85C0740A5656565656E8A091FFFF5EC38BFF558BEC83EC28A10020011033C58945FC53568B750857FF75108B7D0C8D4DDCE82B70FFFF8D45DC5033DB53535353578D"
$__HandleImgSearch_Opcode32 &= "45D8508D45F050E8721200008945EC8D45F05650E8C307000083C428F645EC03752B83F8017511385DE874078B45E4836070FD6A0358EB2F83F802751C385DE874078B45E4836070F"
$__HandleImgSearch_Opcode32 &= "D6A04EBE8F645EC0175EAF645EC0275CE385DE874078B45E4836070FD33C08B4DFC5F5E33CD5BE8626FFFFFC9C38BFF558BEC83EC28A10020011033C58945FC53568B750857FF7510"
$__HandleImgSearch_Opcode32 &= "8B7D0C8D4DDCE8836FFFFF8D45DC5033DB53535353578D45D8508D45F050E8CA1100008945EC8D45F05650E86C0C000083C428F645EC03752B83F8017511385DE874078B45E483607"
$__HandleImgSearch_Opcode32 &= "0FD6A0358EB2F83F802751C385DE874078B45E4836070FD6A04EBE8F645EC0175EAF645EC0275CE385DE874078B45E4836070FD33C08B4DFC5F5E33CD5BE8BA6EFFFFC9C3558BEC57"
$__HandleImgSearch_Opcode32 &= "568B750C8B4D108B7D088BC18BD103C63BFE76083BF80F82A001000081F980000000721C833DB03D0110007413575683E70F83E60F3BFE5E5F7505E988E6FFFFF7C7030000007514C"
$__HandleImgSearch_Opcode32 &= "1E90283E20383F9087229F3A5FF2495A0C800108BC7BA0300000083E904720C83E00303C8FF2485B4C70010FF248DB0C8001090FF248D34C8001090C4C70010F0C7001014C8001023"
$__HandleImgSearch_Opcode32 &= "D18A0688078A46018847018A4602C1E90288470283C60383C70383F90872CCF3A5FF2495A0C800108D490023D18A0688078A4601C1E90288470183C60283C70283F90872A6F3A5FF2"
$__HandleImgSearch_Opcode32 &= "495A0C800109023D18A06880783C601C1E90283C70183F9087288F3A5FF2495A0C800108D490097C8001084C800107CC8001074C800106CC8001064C800105CC8001054C800108B44"
$__HandleImgSearch_Opcode32 &= "8EE489448FE48B448EE889448FE88B448EEC89448FEC8B448EF089448FF08B448EF489448FF48B448EF889448FF88B448EFC89448FFC8D048D0000000003F003F8FF2495A0C800108"
$__HandleImgSearch_Opcode32 &= "BFFB0C80010B8C80010C4C80010D8C800108B45085E5FC9C3908A0688078B45085E5FC9C3908A0688078A46018847018B45085E5FC9C38D49008A0688078A46018847018A46028847"
$__HandleImgSearch_Opcode32 &= "028B45085E5FC9C3908D7431FC8D7C39FCF7C7030000007524C1E90283E20383F908720DFDF3A5FCFF24953CCA00108BFFF7D9FF248DECC900108D49008BC7BA0300000083F904720"
$__HandleImgSearch_Opcode32 &= "C83E0032BC8FF248540C90010FF248D3CCA00109050C9001074C900109CC900108A460323D188470383EE01C1E90283EF0183F90872B2FDF3A5FCFF24953CCA00108D49008A460323"
$__HandleImgSearch_Opcode32 &= "D18847038A4602C1E90288470283EE0283EF0283F9087288FDF3A5FCFF24953CCA0010908A460323D18847038A46028847028A4601C1E90288470183EE0383EF0383F9080F8256FFF"
$__HandleImgSearch_Opcode32 &= "FFFFDF3A5FCFF24953CCA00108D4900F0C90010F8C9001000CA001008CA001010CA001018CA001020CA001033CA00108B448E1C89448F1C8B448E1889448F188B448E1489448F148B"
$__HandleImgSearch_Opcode32 &= "448E1089448F108B448E0C89448F0C8B448E0889448F088B448E0489448F048D048D0000000003F003F8FF24953CCA00108BFF4CCA001054CA001064CA001078CA00108B45085E5FC"
$__HandleImgSearch_Opcode32 &= "9C3908A46038847038B45085E5FC9C38D49008A46038847038A46028847028B45085E5FC9C3908A46038847038A46028847028A46018847018B45085E5FC9C38BFF558BEC8B4D1453"
$__HandleImgSearch_Opcode32 &= "8B590C568B750833C03BF07516E8DF7AFFFF6A165E8930E81A8DFFFF8BC6E98300000039450C76E58B551088063BD07E028BC24039450C770EE8B37AFFFF6A225989088BF1EBD0578"
$__HandleImgSearch_Opcode32 &= "D7E01C606308BC785D27E1A8A0B84C974060FBEC943EB036A30598808404A85D27FE98B4D14C6000085D27812803B357C0DEB03C600304880383974F7FE00803E317505FF4104EB12"
$__HandleImgSearch_Opcode32 &= "57E86FC7FFFF40505756E8F6FBFFFF83C41033C05F5E5B5DC38BFF558BEC518B4D0C0FB74106538BD8C1EB04250080000056BAFF07000023DA5789450C8B41048B090FB7FBBE00000"
$__HandleImgSearch_Opcode32 &= "08025FFFF0F008975FC85FF74133BFA740881C3003C0000EB28BFFF7F0000EB2433D23BC275123BCA750E8B4508668B4D0C8950048910EB4281C3013C00008955FC0FB7FB8BD1C1EA"
$__HandleImgSearch_Opcode32 &= "15C1E00B0BD00B55FC8B4508C1E10BEB138B088BD9C1EB1F03D20BD303C981C7FFFF0000890889500485D674E48B4D0C0BCF5F5E668948085BC9C38BFF558BEC83EC30A1002001103"
$__HandleImgSearch_Opcode32 &= "3C58945FC8B4514538B5D10568945DC578D4508508D45D050E822FFFFFF59598D45E0506A006A1183EC0C8D75D08BFCA5A566A5E82F1300008B75DC8943080FBE45E289030FBF45E0"
$__HandleImgSearch_Opcode32 &= "8943048D45E450FF751856E8D9C1FFFF83C42485C075148B4DFC5F89730C5E8BC333CD5BE87269FFFFC9C333C05050505050E8FA8AFFFFCCCCCCCCCCCCCCCCCCCCCCCC57565533FF3"
$__HandleImgSearch_Opcode32 &= "3ED8B4424140BC07D1547458B542410F7D8F7DA83D80089442414895424108B44241C0BC07D14478B542418F7D8F7DA83D8008944241C895424180BC075288B4C24188B44241433D2"
$__HandleImgSearch_Opcode32 &= "F7F18BD88B442410F7F18BF08BC3F76424188BC88BC6F764241803D1EB478BD88B4C24188B5424148B442410D1EBD1D9D1EAD1D80BDB75F4F7F18BF0F764241C8BC88B442418F7E60"
$__HandleImgSearch_Opcode32 &= "3D1720E3B5424147708720F3B44241076094E2B4424181B54241C33DB2B4424101B5424144D7907F7DAF7D883DA008BCA8BD38BD98BC88BC64F7507F7DAF7D883DA005D5E5FC21000"
$__HandleImgSearch_Opcode32 &= "CC80F940731580F92073060FADD0D3EAC38BC233D280E11FD3E8C333C033D2C38BFF558BEC8B45108B4D0C25FFFFF7FF23C8568B7508F7C1E0FCF0FC742485F6740D6A006A00E8D81"
$__HandleImgSearch_Opcode32 &= "B000059598906E8C877FFFF6A165E8930E8038AFFFF8BC6EB1A50FF750C85F67409E8B41B00008906EB05E8AB1B0000595933C05E5DC38BFF558BEC83EC38A10020011033C58945FC"
$__HandleImgSearch_Opcode32 &= "8B45088B4D0C894DCC0FB7480A538BD981E100800000894DC88B4806894DF08B48020FB70081E3FF7F000081EBFF3F0000C1E01057894DF48945F881FB01C0FFFF752733DB33C0395"
$__HandleImgSearch_Opcode32 &= "C85F0750D4083F8037CF433C0E99804000033C08D7DF0ABAB6A02AB58E9880400008365DC00568D75F08D7DE4A5A5A58B3DB82D01104F8D47019983E21F03C2C1F8058D570181E21F"
$__HandleImgSearch_Opcode32 &= "000080895DD48945D879054A83CAE0428D7485F06A1F33C0592BCA40D3E0894DD085060F848D0000008B45D883CAFFD3E2F7D2855485F0EB05837C85F00075084083F8037CF3EB6E8"
$__HandleImgSearch_Opcode32 &= "BC7996A1F5923D103C2C1F80581E71F00008079054F83CFE0478365DC002BCF33D242D3E28D4C85F08B3903FA897DE08B39397DE072223955E0EB1B85C9742B8365DC008D4C85F08B"
$__HandleImgSearch_Opcode32 &= "118D7A01897DE03BFA720583FF017307C745DC01000000488B55E089118B4DDC79D1894DDC8B4DD083C8FFD3E06A035921068B45D8403BC17D0A8D7C85F02BC833C0F3AB837DDC007"
$__HandleImgSearch_Opcode32 &= "40143A1B42D01108BC82B0DB82D01103BD97D0D33C08D7DF0ABABABE9090200003BD80F8F0B0200002B45D48D75E48BC88D7DF0A59983E21F03C2A58BD1C1F80581E21F000080A579"
$__HandleImgSearch_Opcode32 &= "054A83CAE0428365D8008365E00083CFFF8BCAD3E7C745DC200000002955DCF7D78B5DE08D5C9DF08B338BCE23CF894DD48BCAD3EE8B4DDC0B75D889338B75D4D3E6FF45E0837DE00"
$__HandleImgSearch_Opcode32 &= "38975D87CD38BF06A02C1E6028D4DF85A2BCE3BD07C088B31897495F0EB05836495F00083E9044A79E98B35B82D01104E8D46019983E21F03C2C1F8058D560181E21F0000808945D0"
$__HandleImgSearch_Opcode32 &= "79054A83CAE0426A1F592BCA33D242D3E28D5C85F0894DD485130F848200000083CAFFD3E2F7D2855485F0EB05837C85F00075084083F8037CF3EB668BC6996A1F5923D103C2C1F80"
$__HandleImgSearch_Opcode32 &= "581E61F00008079054E83CEE0468365D80033D22BCE42D3E28D4C85F08B318D3C163BFE72043BFA7307C745D80100000089398B4DD8EB1F85C9741E8D4C85F08B118D720133FF3BF2"
$__HandleImgSearch_Opcode32 &= "720583FE01730333FF4789318BCF4879DE8B4DD483C8FFD3E021038B45D04083F8037D0D6A03598D7C85F02BC833C0F3AB8B0DBC2D01108D41019983E21F03C28D5101C1F80581E21"
$__HandleImgSearch_Opcode32 &= "F00008079054A83CAE0428365D8008365E00083CFFF8BCAD3E7C745DC200000002955DCF7D78B5DE08D5C9DF08B338BCE23CF894DD48BCAD3EE8B4DDC0B75D889338B75D4D3E6FF45"
$__HandleImgSearch_Opcode32 &= "E0837DE0038975D87CD38BF06A02C1E6028D4DF85A2BCE3BD07C088B31897495F0EB05836495F00083E9044A79E96A0233DB58E9530100008B0DBC2D01103B1DB02D01100F8CA9000"
$__HandleImgSearch_Opcode32 &= "00033C08D7DF0ABABAB814DF0000000808BC19983E21F03C28BD1C1F80581E21F00008079054A83CAE0428365D8008365E00083CFFF8BCAD3E7C745DC200000002955DCF7D78B5DE0"
$__HandleImgSearch_Opcode32 &= "8D5C9DF08B338BCE23CF894DD48BCAD3EE8B4DDC0B75D889338B75D4D3E6FF45E0837DE0038975D87CD38BF06A02C1E6028D4DF85A2BCE3BD07C088B31897495F0EB05836495F0008"
$__HandleImgSearch_Opcode32 &= "3E9044A79E98B1DC42D0110031DB02D011033C040E998000000031DC42D01108165F0FFFFFF7F8BC19983E21F03C28BD1C1F80581E21F00008079054A83CAE0428365D8008365E000"
$__HandleImgSearch_Opcode32 &= "83CEFF8BCAD3E6C745DC200000002955DCF7D68B4DE08B7C8DF08BCF23CE894DD48BCAD3EF8B4DE00B7DD8897C8DF08B7DD48B4DDCD3E7FF45E0837DE003897DD87CD08BF06A02C1E"
$__HandleImgSearch_Opcode32 &= "6028D4DF85A2BCE3BD07C088B31897495F0EB05836495F00083E9044A79E933C05E6A1F592B0DBC2D0110D3E38B4DC8F7D91BC981E1000000800BD98B0DC02D01100B5DF083F94075"
$__HandleImgSearch_Opcode32 &= "0D8B4DCC8B55F48959048911EB0A83F92075058B4DCC89198B4DFC5F33CD5BE8AB62FFFFC9C38BFF558BEC83EC38A10020011033C58945FC8B45088B4D0C894DCC0FB7480A538BD98"
$__HandleImgSearch_Opcode32 &= "1E100800000894DC88B4806894DF08B48020FB70081E3FF7F000081EBFF3F0000C1E01057894DF48945F881FB01C0FFFF752733DB33C0395C85F0750D4083F8037CF433C0E9980400"
$__HandleImgSearch_Opcode32 &= "0033C08D7DF0ABAB6A02AB58E9880400008365DC00568D75F08D7DE4A5A5A58B3DD02D01104F8D47019983E21F03C2C1F8058D570181E21F000080895DD48945D879054A83CAE0428"
$__HandleImgSearch_Opcode32 &= "D7485F06A1F33C0592BCA40D3E0894DD085060F848D0000008B45D883CAFFD3E2F7D2855485F0EB05837C85F00075084083F8037CF3EB6E8BC7996A1F5923D103C2C1F80581E71F00"
$__HandleImgSearch_Opcode32 &= "008079054F83CFE0478365DC002BCF33D242D3E28D4C85F08B3903FA897DE08B39397DE072223955E0EB1B85C9742B8365DC008D4C85F08B118D7A01897DE03BFA720583FF017307C"
$__HandleImgSearch_Opcode32 &= "745DC01000000488B55E089118B4DDC79D1894DDC8B4DD083C8FFD3E06A035921068B45D8403BC17D0A8D7C85F02BC833C0F3AB837DDC00740143A1CC2D01108BC82B0DD02D01103B"
$__HandleImgSearch_Opcode32 &= "D97D0D33C08D7DF0ABABABE9090200003BD80F8F0B0200002B45D48D75E48BC88D7DF0A59983E21F03C2A58BD1C1F80581E21F000080A579054A83CAE0428365D8008365E00083CFF"
$__HandleImgSearch_Opcode32 &= "F8BCAD3E7C745DC200000002955DCF7D78B5DE08D5C9DF08B338BCE23CF894DD48BCAD3EE8B4DDC0B75D889338B75D4D3E6FF45E0837DE0038975D87CD38BF06A02C1E6028D4DF85A"
$__HandleImgSearch_Opcode32 &= "2BCE3BD07C088B31897495F0EB05836495F00083E9044A79E98B35D02D01104E8D46019983E21F03C2C1F8058D560181E21F0000808945D079054A83CAE0426A1F592BCA33D242D3E"
$__HandleImgSearch_Opcode32 &= "28D5C85F0894DD485130F848200000083CAFFD3E2F7D2855485F0EB05837C85F00075084083F8037CF3EB668BC6996A1F5923D103C2C1F80581E61F00008079054E83CEE0468365D8"
$__HandleImgSearch_Opcode32 &= "0033D22BCE42D3E28D4C85F08B318D3C163BFE72043BFA7307C745D80100000089398B4DD8EB1F85C9741E8D4C85F08B118D720133FF3BF2720583FE01730333FF4789318BCF4879D"
$__HandleImgSearch_Opcode32 &= "E8B4DD483C8FFD3E021038B45D04083F8037D0D6A03598D7C85F02BC833C0F3AB8B0DD42D01108D41019983E21F03C28D5101C1F80581E21F00008079054A83CAE0428365D8008365"
$__HandleImgSearch_Opcode32 &= "E00083CFFF8BCAD3E7C745DC200000002955DCF7D78B5DE08D5C9DF08B338BCE23CF894DD48BCAD3EE8B4DDC0B75D889338B75D4D3E6FF45E0837DE0038975D87CD38BF06A02C1E60"
$__HandleImgSearch_Opcode32 &= "28D4DF85A2BCE3BD07C088B31897495F0EB05836495F00083E9044A79E96A0233DB58E9530100008B0DD42D01103B1DC82D01100F8CA900000033C08D7DF0ABABAB814DF000000080"
$__HandleImgSearch_Opcode32 &= "8BC19983E21F03C28BD1C1F80581E21F00008079054A83CAE0428365D8008365E00083CFFF8BCAD3E7C745DC200000002955DCF7D78B5DE08D5C9DF08B338BCE23CF894DD48BCAD3E"
$__HandleImgSearch_Opcode32 &= "E8B4DDC0B75D889338B75D4D3E6FF45E0837DE0038975D87CD38BF06A02C1E6028D4DF85A2BCE3BD07C088B31897495F0EB05836495F00083E9044A79E98B1DDC2D0110031DC82D01"
$__HandleImgSearch_Opcode32 &= "1033C040E998000000031DDC2D01108165F0FFFFFF7F8BC19983E21F03C28BD1C1F80581E21F00008079054A83CAE0428365D8008365E00083CEFF8BCAD3E6C745DC200000002955D"
$__HandleImgSearch_Opcode32 &= "CF7D68B4DE08B7C8DF08BCF23CE894DD48BCAD3EF8B4DE00B7DD8897C8DF08B7DD48B4DDCD3E7FF45E0837DE003897DD87CD08BF06A02C1E6028D4DF85A2BCE3BD07C088B31897495"
$__HandleImgSearch_Opcode32 &= "F0EB05836495F00083E9044A79E933C05E6A1F592B0DD42D0110D3E38B4DC8F7D91BC981E1000000800BD98B0DD82D01100B5DF083F940750D8B4DCC8B55F48959048911EB0A83F92"
$__HandleImgSearch_Opcode32 &= "075058B4DCC89198B4DFC5F33CD5BE85A5DFFFFC9C38BFF558BEC83EC7CA10020011033C58945FC8B450833C95633F68945888B450C46578945908D7DE0894D8C897598894DB4894D"
$__HandleImgSearch_Opcode32 &= "A8894DA4894DA0894D9C894DB0894D94394D247517E8AE6CFFFFC70016000000E8E87EFFFF33C0E93C0600008B55108955AC8A023C20740C3C0974083C0A74043C0D750342EBEB53B"
$__HandleImgSearch_Opcode32 &= "3308A024283F90B0F871C020000FF248D3CDF00108D48CF80F90877066A03594AEBDF8B4D248B098B89BC0000008B093A0175056A0559EBC90FBEC083E82B741D4848740D83E8030F"
$__HandleImgSearch_Opcode32 &= "857C0100008BCEEBB06A0259C7458C00800000EBA483658C006A0259EB9B8D48CF8975A880F90876AB8B4D248B098B89BC0000008B093A0175046A04EBAF3C2B74223C2D741E3AC37"
$__HandleImgSearch_Opcode32 &= "4BB3C430F8E2F0100003C457E0A2C643C010F87210100006A06EB894A6A0BEB848D48CF80F9080F865FFFFFFF8B4D248B098B89BC0000008B093A010F8461FFFFFF3AC30F8473FFFF"
$__HandleImgSearch_Opcode32 &= "FF8B55ACE9100100008975A8EB1A3C397F1A837DB419730AFF45B42AC3880747EB03FF45B08A02423AC37DE28B4D248B098B89BC0000008B093A010F8468FFFFFF3C2B748E3C2D748"
$__HandleImgSearch_Opcode32 &= "AE96BFFFFFF837DB4008975A88975A47526EB06FF4DB08A02423AC374F6EB183C397FD5837DB419730BFF45B42AC3880747FF4DB08A02423AC37DE4EBBB2AC38975A43C090F876EFF"
$__HandleImgSearch_Opcode32 &= "FFFF6A04E9ABFEFFFF8D4AFE894DAC8D48CF80F90877076A09E996FEFFFF0FBEC083E82B74204848741083E8030F853DFFFFFF6A08E991FEFFFF834D98FF6A0759E951FEFFFF6A07E"
$__HandleImgSearch_Opcode32 &= "97EFEFFFF8975A0EB038A02423AC374F92C313C0876B84AEB268D48CF80F90876AD3AC3EBBF837D200074470FBEC083E82B8D4AFF894DAC74C4484874B48BD1837DA8008B45908910"
$__HandleImgSearch_Opcode32 &= "0F84D80300006A18583945B47610807DF7057C03FE45F74FFF45B08945B4837DB4000F86DD030000EB596A0A594A83F90A0F85CFFDFFFFEBBE8975A033C9EB193C397F206BC90A0FB"
$__HandleImgSearch_Opcode32 &= "EF08D4C31D081F9501400007F098A02423AC37DE3EB05B951140000894D9CEB0B3C390F8F5DFFFFFF8A02423AC37DF1E951FFFFFFFF4DB4FF45B04F803F0074F48D45C450FF75B48D"
$__HandleImgSearch_Opcode32 &= "45E050E8041100008B459C33D283C40C3955987D02F7D80345B03955A075030345183955A475032B451C3D501400000F8F210300003DB0EBFFFF0F8C2D030000B9E02D011083E9608"
$__HandleImgSearch_Opcode32 &= "945AC3BC20F84E80200007D0DF7D8B9402F01108945AC83E960395514750633C0668945C43955AC0F84C5020000EB058B4D8433D28B45ACC17DAC0383C15483E007894D843BC20F84"
$__HandleImgSearch_Opcode32 &= "9C0200006BC00C8D1C01B800800000663903720E8BF38D7DB8A5A5A5FF4DBA8D5DB88B55CE33C08945B08945D48945D88945DC0FB7430A8BF03375CEB9FF7F000023D123C181E6008"
$__HandleImgSearch_Opcode32 &= "00000BFFF7F00008D0C108975900FB7C9663BD70F8320020000663BC70F8317020000BFFDBF0000663BCF0F8709020000BEBF3F0000663BCE770D33C08945C88945C4E90D02000033"
$__HandleImgSearch_Opcode32 &= "F6663BD6751F41F745CCFFFFFF7F75153975C875103975C4750B33C0668945CEE9EA010000663BC6752141F74308FFFFFF7F751739730475123933750E8975CC8975C88975C4E9C40"
$__HandleImgSearch_Opcode32 &= "100008975988D7DD8C745A8050000008B45988B55A803C089559C85D27E528D4405C48945A48D43088945A08B45A08B55A40FB7120FB7008365B4000FAFC28B57FC8D34023BF27204"
$__HandleImgSearch_Opcode32 &= "3BF07307C745B401000000837DB4008977FC740366FF078345A402836DA002FF4D9C837D9C007FBB83C702FF4598FF4DA8837DA8007F9081C102C000006685C97E378B7DDC85FF782"
$__HandleImgSearch_Opcode32 &= "B8B75D88B45D4D165D4C1E81F8BD603F60BF0C1EA1F8D043F0BC281C1FFFF00008975D88945DC6685C97FCE6685C97F4D81C1FFFF00006685C979428BC1F7D80FB7F003CEF645D401"
$__HandleImgSearch_Opcode32 &= "7403FF45B08B45DC8B7DD88B55D8D16DDCC1E01FD1EF0BF88B45D4C1E21FD1E80BC24E897DD88945D475D13975B0740566834DD401B800800000663945D477118B55D481E2FFFF010"
$__HandleImgSearch_Opcode32 &= "081FA008001007534837DD6FF752B8365D600837DDAFF751C8365DA00BAFFFF0000663955DE7507668945DE41EB0E66FF45DEEB08FF45DAEB03FF45D6B8FF7F0000663BC8722333C0"
$__HandleImgSearch_Opcode32 &= "33C9663945908945C80F94C18945C44981E10000008081C10080FF7F894DCCEB3B668B45D60B4D90668945C48B45D88945C68B45DC8945CA66894DCEEB1E33C06685F60F94C08365C"
$__HandleImgSearch_Opcode32 &= "800482500000080050080FF7F8365C4008945CC837DAC000F853DFDFFFF8B45CC0FB74DC48B75C68B55CAC1E810EB2FC7459404000000EB1E33F6B8FF7F0000BA0000008033C9C745"
$__HandleImgSearch_Opcode32 &= "9402000000EB0FC745940100000033C933C033D233F68B7D880B458C66890F6689470A8B45948977028957065B8B4DFC5F33CD5EE8B156FFFFC9C38D490020D9001072D90010BDD90"
$__HandleImgSearch_Opcode32 &= "010EED9001033DA00106BDA00107FDA0010D8DA0010C3DA001040DB001035DB0010E4DA00108BFF558BEC83EC74A10020011033C58945FC0FB745100FB75510B90080000023C1538B"
$__HandleImgSearch_Opcode32 &= "5D1C8945A08D41FF5623D066837DA00057895D9CC745D0CCCCCCCCC745D4CCCCCCCCC745D8CCCCFB3FC7458C010000007406C643022DEB04C64302208B750C8B7D086685D2753785F"
$__HandleImgSearch_Opcode32 &= "60F85CF00000085FF0F85C700000033C066394DA06689030F95C0FEC8240D042088430266C743030130C643050033C040E90B080000663BD00F85970000008B4D0C33C040668903B8"
$__HandleImgSearch_Opcode32 &= "000000803BC87506837D0800741BF7C100000040751368C40B0110EB5333C05050505050E83577FFFF33D2663955A0741481F9000000C0750C395508752D68BC0B0110EB0E3BC8752"
$__HandleImgSearch_Opcode32 &= "2395508751D68B40B01108D43046A1650E8B8ADFFFF83C40C85C075B8C6430305EB1B68AC0B01108D43046A1650E89BADFFFF83C40C85C0759BC643030633C0E96B0700000FB7CA8B"
$__HandleImgSearch_Opcode32 &= "D969C9104D00008BC6C1E818C1EB088D04436BC04D8D84080CEDBCECC1F8100FB7C033C966894DE00FBFD8B9E02D011083E960F7DB8945B4668955EA8975E6897DE2894D980F849C0"
$__HandleImgSearch_Opcode32 &= "2000085DB790FB8402F011083E860F7DB89459885DB0F8483020000834598548BCBC1FB0383E1070F84670200006BC90C034D988BC1894DBCB90080000066390872118BF08D7DC4A5"
$__HandleImgSearch_Opcode32 &= "A58D45C4A5FF4DC68945BC33C9894DB8894DF0894DF4894DF80FB7480A8BD13355EABEFF7F000081E2008000008955A88B55EA23D623CE8D34110FB7FEBEFF7F0000663BD60F83A70"
$__HandleImgSearch_Opcode32 &= "20000663BCE0F839E020000BEFDBF0000663BFE0F8790020000BEBF3F0000663BFE771033F68975E88975E48975E0E9D201000033F6663BD6751F47F745E8FFFFFF7F75153975E475"
$__HandleImgSearch_Opcode32 &= "103975E0750B33C0668945EAE9AC010000663BCE751347F74008FFFFFF7F75093970047504393074B42175AC8D75F4C745C0050000008B4DAC8B55C003C98955B085D27E558D4C0DE"
$__HandleImgSearch_Opcode32 &= "083C008894D908945948B45900FB7088B45940FB7008B56FC0FAFC88365A4008D040A3BC272043BC17307C745A401000000837DA4008946FC740366FF0683459002836D9402FF4DB0"
$__HandleImgSearch_Opcode32 &= "837DB0007FBB8B45BC83C602FF45ACFF4DC0837DC0007F8D81C702C000006685FF7E3BF745F800000080752D8B45F48B4DF0D165F08BD003C0C1E91F0BC18945F48B45F8C1EA1F03C"
$__HandleImgSearch_Opcode32 &= "00BC281C7FFFF00008945F86685FF7FCA6685FF7F4D81C7FFFF00006685FF79428BC7F7D80FB7C003F8F645F0017403FF45B88B4DF88B75F48B55F4D16DF8C1E11FD1EE0BF18B4DF0"
$__HandleImgSearch_Opcode32 &= "C1E21FD1E90BCA488975F4894DF075D13945B8740566834DF001B800800000663945F077118B4DF081E1FFFF010081F9008001007534837DF2FF752B8365F200837DF6FF751C8365F"
$__HandleImgSearch_Opcode32 &= "600B9FFFF000066394DFA7507668945FA47EB0E66FF45FAEB08FF45F6EB03FF45F2B8FF7F0000663BF80F82A700000033C033C9663945A88945E40F94C18945E04981E10000008081"
$__HandleImgSearch_Opcode32 &= "C10080FF7F894DE833F63BDE0F857DFDFFFF8B4DE8C1E910BAFF3F0000B8FF7F0000663BCA0F829F0200008B5DDAFF45B433D28955B08955F08955F48955F88B55DA33D923C823D08"
$__HandleImgSearch_Opcode32 &= "1E3008000008D340A895DA40FB7F6663BC80F834C020000663BD00F8343020000B8FDBF0000663BF00F8735020000B8BF3F0000663BF0774B33C08945E48945E0E939020000668B45"
$__HandleImgSearch_Opcode32 &= "F20B7DA8668945E08B45F48945E28B45F88945E666897DEAE95AFFFFFF33C033F6663975A80F94C0482500000080050080FF7F8945E8E961FDFFFF33C0663BC8751D46F745E8FFFFF"
$__HandleImgSearch_Opcode32 &= "F7F75133945E4750E3945E07509668945EAE9DA010000663BD0751846F745D8FFFFFF7F750E3945D475093945D00F8476FFFFFF8945AC8D7DF4C745C0050000008B45AC8B4DC003C0"
$__HandleImgSearch_Opcode32 &= "894DB885C97E4B8D4DD8894DA88D4405E08B4DA80FB7100FB7098365BC000FAFCA8B57FC8D1C0A3BDA72043BD97307C745BC01000000837DBC00895FFC740366FF07836DA80283C00"
$__HandleImgSearch_Opcode32 &= "2FF4DB8837DB8007FBF83C702FF45ACFF4DC0837DC0007F9781C602C000006685F67E378B7DF885FF782B8B45F48B4DF0D165F08BD003C0C1E91F0BC18945F4C1EA1F8D043F0BC281"
$__HandleImgSearch_Opcode32 &= "C6FFFF00008945F86685F67FCE6685F67F4D81C6FFFF00006685F679428BC6F7D80FB7C003F0F645F0017403FF45B08B4DF88B7DF48B55F4D16DF8C1E11FD1EF0BF98B4DF0C1E21FD"
$__HandleImgSearch_Opcode32 &= "1E90BCA48897DF4894DF075D13945B0740566834DF001B800800000663945F077118B4DF081E1FFFF010081F9008001007534837DF2FF752B8365F200837DF6FF751C8365F600B9FF"
$__HandleImgSearch_Opcode32 &= "FF000066394DFA7507668945FA46EB0E66FF45FAEB08FF45F6EB03FF45F2B8FF7F0000663BF0722333C033C9663945A48945E40F94C18945E04981E10000008081C10080FF7F894DE"
$__HandleImgSearch_Opcode32 &= "8EB3B668B45F20B75A4668945E08B45F48945E28B45F88945E6668975EAEB1E33C06685DB0F94C08365E400482500000080050080FF7F8365E0008945E8F64518018B559C8B45B48B"
$__HandleImgSearch_Opcode32 &= "7D1466890274309803F885FF7F2933C0668902B800800000663945A066C7420301300F95C0FEC8240D0420884202C6420500E973F9FFFF83FF157E036A155F8B75E8C1EE1081EEFE3"
$__HandleImgSearch_Opcode32 &= "F000033C0668945EAC745BC080000008B45E08B5DE48B4DE4D165E0C1E81F03DB0BD88B45E8C1E91F03C00BC1FF4DBC895DE48945E875D885F67932F7DE81E6FF0000007E288B45E8"
$__HandleImgSearch_Opcode32 &= "8B5DE48B4DE4D16DE8C1E01FD1EB0BD88B45E0C1E11FD1E80BC14E895DE48945E085F67FD88D47018D5A04895DC08945B485C00F8EB50000008B55E08B45E48D75E08D7DC4A5A5A5D"
$__HandleImgSearch_Opcode32 &= "165E08B7DE0D165E0C1EA1F8D0C000BCA8B55E88BF0C1EE1F03D20BD68BC18D3409C1E81F8D0C128B55C4C1EF1F0BC88B45E00BF78D3C023BF872043BFA73188D460133D23BC67205"
$__HandleImgSearch_Opcode32 &= "83F801730333D2428BF085D27401418B45C88D14308955BC3BD672043BD0730141034DCCC1EA1F03C90BCA8D343F8975E08B75BC894DE8C1E91803F680C1308BC7C1E81F0BF0880B4"
$__HandleImgSearch_Opcode32 &= "3FF4DB4837DB4008975E4C645EB000F8F4BFFFFFF8A43FF83EB023C357D0E8B4DC0EB44803B397509C603304B3B5DC073F28B459C3B5DC073044366FF00FE032AD880EB030FBECB88"
$__HandleImgSearch_Opcode32 &= "5803C6440104008B458C8B4DFC5F5E33CD5BE8C34DFFFFC9C3803B3075054B3BD973F68B459C3BD973CD33D2668910BA00800000663955A0C64003010F95C2FECA80E20D80C220885"
$__HandleImgSearch_Opcode32 &= "002C60130C6400500E9A1F7FFFF33C0F6C310740140F6C308740383C804F6C304740383C808F6C302740383C810F6C301740383C820F7C300000800740383C8028BCBBA0003000023"
$__HandleImgSearch_Opcode32 &= "CA56BE00020000742381F90001000074163BCE740B3BCA75130D000C0000EB0C0D00080000EB050D000400008BCB81E100000300740C81F90000010075060BC6EB020BC25EF7C3000"
$__HandleImgSearch_Opcode32 &= "0040074050D00100000C333C0F6C2107405B880000000535657BB00020000F6C20874020BC3F6C20474050D00040000F6C20274050D00080000F6C20174050D00100000BF00010000"
$__HandleImgSearch_Opcode32 &= "F7C20000080074020BC78BCABE0003000023CE741F3BCF74163BCB740B3BCE75130D00600000EB0C0D00400000EB050D00200000B9000000035F23D15E5B81FA00000001741681FA0"
$__HandleImgSearch_Opcode32 &= "0000002740A3BD1750F0D00800000C383C840C30D40800000C38BFF558BEC83EC145356579BD97DFC668B5DFC33D2F6C30174036A105AF6C304740383CA08F6C308740383CA04F6C3"
$__HandleImgSearch_Opcode32 &= "10740383CA02F6C320740383CA01F6C302740681CA000008000FB7CB8BC1BE000C000023C6BF0003000074243D0004000074173D0008000074083BC675120BD7EB0E81CA00020000E"
$__HandleImgSearch_Opcode32 &= "B0681CA0001000023CF741081F900020000750E81CA00000100EB0681CA000002000FB7C3A900100000740681CA000004008B7D0C8B4D088BC7F7D023C223CF0BC189450C3BC20F84"
$__HandleImgSearch_Opcode32 &= "AE0000008BD8E807FEFFFF0FB7C08945F8D96DF89BD97DF88B5DF833D2F6C30174036A105AF6C304740383CA08F6C308740383CA04F6C310740383CA02F6C320740383CA01F6C3027"
$__HandleImgSearch_Opcode32 &= "40681CA000008000FB7CB8BC123C674283D00040000741B3D00080000740C3BC6751681CA00030000EB0E81CA00020000EB0681CA0001000081E100030000741081F900020000750E"
$__HandleImgSearch_Opcode32 &= "81CA00000100EB0681CA00000200F7C300100000740681CA0000040089550C8BC233F63935B03D01100F848D01000081E71F030803897DEC0FAE5DF08B45F084C079036A105EA9000"
$__HandleImgSearch_Opcode32 &= "20000740383CE08A900040000740383CE04A900080000740383CE02A900100000740383CE01A900010000740681CE000008008BC8BB0060000023CB742A81F900200000741C81F900"
$__HandleImgSearch_Opcode32 &= "400000740C3BCB751681CE00030000EB0E81CE00020000EB0681CE00010000BF4080000023C783E840741C2DC07F0000740D83E840751681CE00000001EB0E81CE00000003EB0681C"
$__HandleImgSearch_Opcode32 &= "E000000028B45EC8BD0234508F7D223D60BD03BD675078BC6E9B0000000E813FDFFFF508945F4E8A0020000590FAE5DF48B4DF433D284C979036A105AF7C100020000740383CA08F7"
$__HandleImgSearch_Opcode32 &= "C100040000740383CA04F7C100080000740383CA02F7C100100000740383CA01BE0001000085CE740681CA000008008BC123C374243D00200000741B3D00400000740C3BC3751281C"
$__HandleImgSearch_Opcode32 &= "A00030000EB0A81CA00020000EB020BD623CF83E940741D81E9C07F0000740D83E940751681CA00000001EB0E81CA00000003EB0681CA000000028BC28BC8334D0C0B450CF7C11F03"
$__HandleImgSearch_Opcode32 &= "080074050D000000805F5E5BC9C38BFF558BEC83EC188B45105333DB5657C745FC4E4000008918895804895808395D0C0F8645010000895D108B088BF08D7DE8A5A5A58BD18D3C09C"
$__HandleImgSearch_Opcode32 &= "1EA1F8D0C1B0BCA8B5510836510008BF38BD9897DF8C1EE1F03D20BD68B75F803C9C1EF1F0BCF8BF9894DF88D0C128B55E803F6C1EB1F0BCB03D689308978048948083BD672053B55"
$__HandleImgSearch_Opcode32 &= "E87307C7451001000000837D1000891074278B75F8836510008D7E013BFE720583FF017307C7451001000000837D10008978047404418948088B75EC836510008D1C373BDF72043BD"
$__HandleImgSearch_Opcode32 &= "E7307C7451001000000837D1000895804740441894808034DF08365F8008BFB03C98BF2C1EF1F0BCFC1EE1F03DB03D20BDE894808894DF4894D108B4D0889108958040FBE318D0C32"
$__HandleImgSearch_Opcode32 &= "8975E83BCA72043BCE7307C745F801000000837DF800890874248D4B0133D23BCB720583F901730333D2428BD989480485D2740A8B4DF441894D10894808FF4D0C8B4D10FF4508837"
$__HandleImgSearch_Opcode32 &= "D0C008958048948080F87C0FEFFFF33DB395808752A8B50048B088145FCF0FF00008BFA8BF1C1EE10C1E210C1EF100BD6C1E11089500489083BFB74DC8978088B7808F7C700800000"
$__HandleImgSearch_Opcode32 &= "75308B48048B188145FCFFFF00008BF18BD3C1EE1F03FFC1EA1F03C90BFE03DB0BCA8918894804897808F7C70080000074D3668B4DFC5F5E6689480A5BC9C36A0868380F0110E82C9"
$__HandleImgSearch_Opcode32 &= "3FFFF33C03905B03D01107456F645084074483905B430011074408945FC0FAE5508EB2E8B45EC8B008B003D050000C0740A3D1D0000C0740333C0C333C040C38B65E88325B4300110"
$__HandleImgSearch_Opcode32 &= "00836508BF0FAE5508C745FCFEFFFFFFEB08836508BF0FAE5508E80C93FFFFC3000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "00000000761301005C1301004C1301003C130100301301001613010006130100FA120100E4120100D61201008A13010000000000341201001218010002180100F217010028120100C"
$__HandleImgSearch_Opcode32 &= "A170100BE170100B01701009E1701008E1701007C1701001A1201000C120100FE110100F0110100E2110100D4110100C6110100B01101009E11010088110100E6170100781101006C"
$__HandleImgSearch_Opcode32 &= "170100EA130100FA130100061401001214010028140100381401004A1401005E140100721401008E140100AC140100C0140100CE140100DC140100E81401000015010018150100221"
$__HandleImgSearch_Opcode32 &= "501002E15010040150100501501005C1501006A150100781501008215010096150100A6150100B4150100C0150100D0150100E6150100FC1501000C16010014160100261601004E16"
$__HandleImgSearch_Opcode32 &= "01005C1601006E160100861601009C160100B6160100D0160100EA160100FA160100101701002A1701003C170100541701002018010000000000A2010080000000009E13010000000"
$__HandleImgSearch_Opcode32 &= "00090120100B6120100521201009C120100AA120100881201007A1201006C1201005E12010000000000BA13010000000000000000000000000000000000CC4C001068970010ACA600"
$__HandleImgSearch_Opcode32 &= "10ECAD0010000000000000000056B600105DA7001000000000000000000000000000000000AF39DA4F000000000200000045000000180C0100180001008009F87B32BF1A108BBB00A"
$__HandleImgSearch_Opcode32 &= "A00300CAB00000000D830011030310110480048003A006D006D003A00730073000000000064006400640064002C0020004D004D004D004D002000640064002C002000790079007900"
$__HandleImgSearch_Opcode32 &= "790000004D004D002F00640064002F00790079000000000050004D000000000041004D000000000044006500630065006D00620065007200000000004E006F00760065006D0062006"
$__HandleImgSearch_Opcode32 &= "5007200000000004F00630074006F006200650072000000530065007000740065006D006200650072000000410075006700750073007400000000004A0075006C007900000000004A"
$__HandleImgSearch_Opcode32 &= "0075006E0065000000000041007000720069006C0000004D006100720063006800000046006500620072007500610072007900000000004A0061006E0075006100720079000000440"
$__HandleImgSearch_Opcode32 &= "06500630000004E006F00760000004F00630074000000530065007000000041007500670000004A0075006C0000004A0075006E0000004D0061007900000041007000720000004D00"
$__HandleImgSearch_Opcode32 &= "61007200000046006500620000004A0061006E00000053006100740075007200640061007900000000004600720069006400610079000000000054006800750072007300640061007"
$__HandleImgSearch_Opcode32 &= "900000000005700650064006E00650073006400610079000000540075006500730064006100790000004D006F006E0064006100790000000000530075006E00640061007900000000"
$__HandleImgSearch_Opcode32 &= "00530061007400000046007200690000005400680075000000570065006400000054007500650000004D006F006E000000530075006E00000048483A6D6D3A7373000000006464646"
$__HandleImgSearch_Opcode32 &= "42C204D4D4D4D2064642C2079797979004D4D2F64642F797900000000504D0000414D0000446563656D626572000000004E6F76656D626572000000004F63746F6265720053657074"
$__HandleImgSearch_Opcode32 &= "656D62657200000041756775737400004A756C79000000004A756E6500000000417072696C0000004D617263680000004665627275617279000000004A616E7561727900446563004"
$__HandleImgSearch_Opcode32 &= "E6F76004F63740053657000417567004A756C004A756E004D617900417072004D617200466562004A616E005361747572646179000000004672696461790000546875727364617900"
$__HandleImgSearch_Opcode32 &= "0000005765646E657364617900000054756573646179004D6F6E646179000053756E646179000053617400467269005468750057656400547565004D6F6E0053756E004B004500520"
$__HandleImgSearch_Opcode32 &= "04E0045004C00330032002E0044004C004C0000000000466C734672656500466C7353657456616C756500466C7347657456616C756500466C73416C6C6F6300000000010203040506"
$__HandleImgSearch_Opcode32 &= "0708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4"
$__HandleImgSearch_Opcode32 &= "F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F00436F724578697450726F6365737300006D00730063006F"
$__HandleImgSearch_Opcode32 &= "007200650065002E0064006C006C000000720075006E00740069006D00650020006500720072006F0072002000000000000D000A000000000054004C004F005300530020006500720"
$__HandleImgSearch_Opcode32 &= "072006F0072000D000A000000530049004E00470020006500720072006F0072000D000A000000000044004F004D00410049004E0020006500720072006F0072000D000A0000000000"
$__HandleImgSearch_Opcode32 &= "520036003000330033000D000A002D00200041007400740065006D0070007400200074006F00200075007300650020004D00530049004C00200063006F00640065002000660072006"
$__HandleImgSearch_Opcode32 &= "F006D0020007400680069007300200061007300730065006D0062006C007900200064007500720069006E00670020006E0061007400690076006500200063006F0064006500200069"
$__HandleImgSearch_Opcode32 &= "006E0069007400690061006C0069007A006100740069006F006E000A005400680069007300200069006E0064006900630061007400650073002000610020006200750067002000690"
$__HandleImgSearch_Opcode32 &= "06E00200079006F007500720020006100700070006C00690063006100740069006F006E002E0020004900740020006900730020006D006F007300740020006C0069006B0065006C00"
$__HandleImgSearch_Opcode32 &= "79002000740068006500200072006500730075006C00740020006F0066002000630061006C006C0069006E006700200061006E0020004D00530049004C002D0063006F006D0070006"
$__HandleImgSearch_Opcode32 &= "9006C0065006400200028002F0063006C00720029002000660075006E006300740069006F006E002000660072006F006D002000610020006E0061007400690076006500200063006F"
$__HandleImgSearch_Opcode32 &= "006E007300740072007500630074006F00720020006F0072002000660072006F006D00200044006C006C004D00610069006E002E000D000A0000000000520036003000330032000D0"
$__HandleImgSearch_Opcode32 &= "00A002D0020006E006F007400200065006E006F00750067006800200073007000610063006500200066006F00720020006C006F00630061006C006500200069006E0066006F007200"
$__HandleImgSearch_Opcode32 &= "6D006100740069006F006E000D000A0000000000520036003000330031000D000A002D00200041007400740065006D0070007400200074006F00200069006E0069007400690061006"
$__HandleImgSearch_Opcode32 &= "C0069007A0065002000740068006500200043005200540020006D006F007200650020007400680061006E0020006F006E00630065002E000A005400680069007300200069006E0064"
$__HandleImgSearch_Opcode32 &= "00690063006100740065007300200061002000620075006700200069006E00200079006F007500720020006100700070006C00690063006100740069006F006E002E000D000A00000"
$__HandleImgSearch_Opcode32 &= "00000520036003000330030000D000A002D00200043005200540020006E006F007400200069006E0069007400690061006C0069007A00650064000D000A0000000000520036003000"
$__HandleImgSearch_Opcode32 &= "320038000D000A002D00200075006E00610062006C006500200074006F00200069006E0069007400690061006C0069007A006500200068006500610070000D000A000000000000000"
$__HandleImgSearch_Opcode32 &= "000520036003000320037000D000A002D0020006E006F007400200065006E006F00750067006800200073007000610063006500200066006F00720020006C006F00770069006F0020"
$__HandleImgSearch_Opcode32 &= "0069006E0069007400690061006C0069007A006100740069006F006E000D000A000000000000000000520036003000320036000D000A002D0020006E006F007400200065006E006F0"
$__HandleImgSearch_Opcode32 &= "0750067006800200073007000610063006500200066006F007200200073007400640069006F00200069006E0069007400690061006C0069007A006100740069006F006E000D000A00"
$__HandleImgSearch_Opcode32 &= "0000000000000000520036003000320035000D000A002D002000700075007200650020007600690072007400750061006C002000660075006E006300740069006F006E00200063006"
$__HandleImgSearch_Opcode32 &= "1006C006C000D000A00000000000000520036003000320034000D000A002D0020006E006F007400200065006E006F00750067006800200073007000610063006500200066006F0072"
$__HandleImgSearch_Opcode32 &= "0020005F006F006E0065007800690074002F0061007400650078006900740020007400610062006C0065000D000A000000000000000000520036003000310039000D000A002D00200"
$__HandleImgSearch_Opcode32 &= "075006E00610062006C006500200074006F0020006F00700065006E00200063006F006E0073006F006C00650020006400650076006900630065000D000A0000000000000000005200"
$__HandleImgSearch_Opcode32 &= "36003000310038000D000A002D00200075006E00650078007000650063007400650064002000680065006100700020006500720072006F0072000D000A00000000000000000052003"
$__HandleImgSearch_Opcode32 &= "6003000310037000D000A002D00200075006E006500780070006500630074006500640020006D0075006C007400690074006800720065006100640020006C006F0063006B00200065"
$__HandleImgSearch_Opcode32 &= "00720072006F0072000D000A000000000000000000520036003000310036000D000A002D0020006E006F007400200065006E006F00750067006800200073007000610063006500200"
$__HandleImgSearch_Opcode32 &= "066006F0072002000740068007200650061006400200064006100740061000D000A000000520036003000310030000D000A002D002000610062006F00720074002800290020006800"
$__HandleImgSearch_Opcode32 &= "6100730020006200650065006E002000630061006C006C00650064000D000A0000000000520036003000300039000D000A002D0020006E006F007400200065006E006F00750067006"
$__HandleImgSearch_Opcode32 &= "800200073007000610063006500200066006F007200200065006E007600690072006F006E006D0065006E0074000D000A000000520036003000300038000D000A002D0020006E006F"
$__HandleImgSearch_Opcode32 &= "007400200065006E006F00750067006800200073007000610063006500200066006F007200200061007200670075006D0065006E00740073000D000A0000000000000052003600300"
$__HandleImgSearch_Opcode32 &= "0300032000D000A002D00200066006C006F006100740069006E006700200070006F0069006E007400200073007500700070006F007200740020006E006F00740020006C006F006100"
$__HandleImgSearch_Opcode32 &= "6400650064000D000A0000000000000000000200000068FE00100800000010FE001009000000B8FD00100A00000070FD00101000000018FD001011000000B8FC00101200000070FC0"
$__HandleImgSearch_Opcode32 &= "0101300000018FC001018000000A8FB00101900000058FB00101A000000E8FA00101B00000078FA00101C00000028FA00101E000000E8F900101F00000020F9001020000000B8F800"
$__HandleImgSearch_Opcode32 &= "1021000000C8F6001078000000A8F60010790000008CF600107A00000070F60010FC00000068F60010FF00000048F600104D006900630072006F0073006F006600740020005600690"
$__HandleImgSearch_Opcode32 &= "07300750061006C00200043002B002B002000520075006E00740069006D00650020004C00690062007200610072007900000000000A000A00000000002E002E002E0000003C007000"
$__HandleImgSearch_Opcode32 &= "72006F006700720061006D0020006E0061006D006500200075006E006B006E006F0077006E003E0000000000520075006E00740069006D00650020004500720072006F00720021000"
$__HandleImgSearch_Opcode32 &= "A000A00500072006F006700720061006D003A002000000028006E0075006C006C00290000000000286E756C6C29000006000006000100001000030600060210044545450505050505"
$__HandleImgSearch_Opcode32 &= "3530005000000000282038505807080037303057500700002020080000000008606860606060000078707878787808070800000700080808000008000800070800000000000000068"
$__HandleImgSearch_Opcode32 &= "0808680818000001003868086828014050545454585858505000030308050808800080028273850578000070037303050508800000020288088808000000060686068686808080778"
$__HandleImgSearch_Opcode32 &= "70707770700808000008000800070800000000000000050000C00B000000000000001D0000C00400000000000000960000C004000000000000008D0000C008000000000000008E000"
$__HandleImgSearch_Opcode32 &= "0C008000000000000008F0000C00800000000000000900000C00800000000000000910000C00800000000000000920000C00800000000000000930000C00800000000000000B40200"
$__HandleImgSearch_Opcode32 &= "C00800000000000000B50200C008000000000000000300000009000000900000000C00000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000002000200020002000200020002000200020002800280028002800280020002000200020002000200020002000200020002000200020002000200020002000200048001000100"
$__HandleImgSearch_Opcode32 &= "0100010001000100010001000100010001000100010001000100084008400840084008400840084008400840084001000100010001000100010001000810081008100810081008100"
$__HandleImgSearch_Opcode32 &= "0100010001000100010001000100010001000100010001000100010001000100010001000100010010001000100010001000100082008200820082008200820002000200020002000"
$__HandleImgSearch_Opcode32 &= "2000200020002000200020002000200020002000200020002000200020002001000100010001000200000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000200020002000200020002000200020002000680028002800280028002000200020002000200020002000200020002000200020002000200020002000200020"
$__HandleImgSearch_Opcode32 &= "0048001000100010001000100010001000100010001000100010001000100010008400840084008400840084008400840084008400100010001000100010001000100081018101810"
$__HandleImgSearch_Opcode32 &= "1810181018101010101010101010101010101010101010101010101010101010101010101010101010101010101011000100010001000100010008201820182018201820182010201"
$__HandleImgSearch_Opcode32 &= "0201020102010201020102010201020102010201020102010201020102010201020102010201100010001000100020002000200020002000200020002000200020002000200020002"
$__HandleImgSearch_Opcode32 &= "0002000200020002000200020002000200020002000200020002000200020002000200020002000480010001000100010001000100010001000100010001000100010001000100010"
$__HandleImgSearch_Opcode32 &= "0010001400140010001000100010001000140010001000100010001000100001010101010101010101010101010101010101010101010101010101010101010101010101010101010"
$__HandleImgSearch_Opcode32 &= "1010101011000010101010101010101010101010102010201020102010201020102010201020102010201020102010201020102010201020102010201020102010201020110000201"
$__HandleImgSearch_Opcode32 &= "0201020102010201020102010201010100000000808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B"
$__HandleImgSearch_Opcode32 &= "4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFC"
$__HandleImgSearch_Opcode32 &= "FDFEFF000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F40616263646"
$__HandleImgSearch_Opcode32 &= "5666768696A6B6C6D6E6F707172737475767778797A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D"
$__HandleImgSearch_Opcode32 &= "8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D"
$__HandleImgSearch_Opcode32 &= "6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E"
$__HandleImgSearch_Opcode32 &= "9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E"
$__HandleImgSearch_Opcode32 &= "7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F"
$__HandleImgSearch_Opcode32 &= "303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F604142434445464748494A4B4C4D4E4F50515253545556575"
$__HandleImgSearch_Opcode32 &= "8595A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0"
$__HandleImgSearch_Opcode32 &= "C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF47657450726F6365737"
$__HandleImgSearch_Opcode32 &= "357696E646F7753746174696F6E00476574557365724F626A656374496E666F726D6174696F6E570000004765744C617374416374697665506F707570000047657441637469766557"
$__HandleImgSearch_Opcode32 &= "696E646F77004D657373616765426F7857005500530045005200330032002E0044004C004C000000000043004F004E004F005500540024000000426C61636B00000053696C7665720"
$__HandleImgSearch_Opcode32 &= "000477261790000000057686974650000004D61726F6F6E000052656400507572706C6500004675636873696100477265656E0000004C696D65000000004F6C69766500000059656C"
$__HandleImgSearch_Opcode32 &= "6C6F7700004E61767900000000426C7565000000005465616C00000000417175610000000044656661756C740065786500646C6C0069636C0063706C007363720069636F006375720"
$__HandleImgSearch_Opcode32 &= "0616E6900626D7000676469706C7573006A7067006A7065670000000067696600476469706C7573537461727475700000476469706C757353687574646F776E004764697043726561"
$__HandleImgSearch_Opcode32 &= "74654269746D617046726F6D46696C650000000047646970437265617465484249544D415046726F6D4269746D61700047646970446973706F7365496D61676500000000300000003"
$__HandleImgSearch_Opcode32 &= "17C25647C25647C25647C256400000049636F6E000000005472616E7300000020090000000000000000E03F1EBA0010652B3030300000003123514E414E00003123494E4600000031"
$__HandleImgSearch_Opcode32 &= "23494E440000003123534E414E00000000000048000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "000000000000000200110600C0110030000005253445304DAEC64EB4B1742A284C6D5E3DE9EFA01000000433A5C496D616765536561726368444C4C5C52656C656173655C496D6167"
$__HandleImgSearch_Opcode32 &= "65536561726368444C4C2E706462000000002082000070AC000020B500000000000000000000000000000000000000000000FEFFFFFF00000000D8FFFFFF00000000FEFFFFFF00000"
$__HandleImgSearch_Opcode32 &= "0009D42001000000000FEFFFFFF00000000D4FFFFFF00000000FEFFFFFFFD4300100E44001000000000FEFFFFFF00000000D4FFFFFF00000000FEFFFFFF00000000C1480010000000"
$__HandleImgSearch_Opcode32 &= "00FEFFFFFF00000000CCFFFFFF00000000FEFFFFFF00000000934C001000000000FEFFFFFF00000000D4FFFFFF00000000FEFFFFFF000000001750001000000000FEFFFFFF0000000"
$__HandleImgSearch_Opcode32 &= "0D8FFFFFF00000000FEFFFFFF0000000042510010FEFFFFFF0000000051510010FEFFFFFF00000000D8FFFFFF00000000FEFFFFFF0000000004530010FEFFFFFF0000000010530010"
$__HandleImgSearch_Opcode32 &= "FEFFFFFF00000000C0FFFFFF00000000FEFFFFFF00000000065B001000000000FEFFFFFF00000000D4FFFFFF00000000FEFFFFFF00000000D288001000000000FEFFFFFF00000000D"
$__HandleImgSearch_Opcode32 &= "8FFFFFF00000000FEFFFFFF659400106994001000000000FEFFFFFF00000000C0FFFFFF00000000FEFFFFFF000000005296001000000000FEFFFFFF00000000D4FFFFFF00000000FE"
$__HandleImgSearch_Opcode32 &= "FFFFFF00000000CF97001000000000FEFFFFFF00000000D8FFFFFF00000000FEFFFFFF2B9900103E99001000000000FEFFFFFF00000000CCFFFFFF00000000FEFFFFFF000000002C9"
$__HandleImgSearch_Opcode32 &= "E001000000000FEFFFFFF00000000D0FFFFFF00000000FEFFFFFF00000000FCA5001000000000FEFFFFFF00000000D4FFFFFF00000000FEFFFFFF00000000EEB0001000000000FEFF"
$__HandleImgSearch_Opcode32 &= "FFFF00000000D0FFFFFF00000000FEFFFFFF000000005EB3001000000000FEFFFFFF00000000CCFFFFFF00000000FEFFFFFF00000000E8B400100000000000000000B4B40010FEFFF"
$__HandleImgSearch_Opcode32 &= "FFF00000000D4FFFFFF00000000FEFFFFFF0000000043B7001000000000FEFFFFFF00000000D0FFFFFF00000000FEFFFFFF000000001CB8001000000000FEFFFFFF00000000D0FFFF"
$__HandleImgSearch_Opcode32 &= "FF00000000FEFFFFFF000000007CB9001000000000FEFFFFFF00000000D8FFFFFF00000000FEFFFFFFB5EE0010D1EE00101010010000000000000000004412010030F000004811010"
$__HandleImgSearch_Opcode32 &= "00000000000000000CA12010068F10000E00F010000000000000000009413010000F00000401101000000000000000000AE13010060F10000701101000000000000000000D2130100"
$__HandleImgSearch_Opcode32 &= "90F10000381101000000000000000000DC13010058F100000000000000000000000000000000000000000000761301005C1301004C1301003C130100301301001613010006130100F"
$__HandleImgSearch_Opcode32 &= "A120100E4120100D61201008A13010000000000341201001218010002180100F217010028120100CA170100BE170100B01701009E1701008E1701007C1701001A1201000C120100FE"
$__HandleImgSearch_Opcode32 &= "110100F0110100E2110100D4110100C6110100B01101009E11010088110100E6170100781101006C170100EA130100FA130100061401001214010028140100381401004A1401005E1"
$__HandleImgSearch_Opcode32 &= "40100721401008E140100AC140100C0140100CE140100DC140100E81401000015010018150100221501002E15010040150100501501005C1501006A15010078150100821501009615"
$__HandleImgSearch_Opcode32 &= "0100A6150100B4150100C0150100D0150100E6150100FC1501000C16010014160100261601004E1601005C1601006E160100861601009C160100B6160100D0160100EA160100FA160"
$__HandleImgSearch_Opcode32 &= "100101701002A1701003C170100541701002018010000000000A2010080000000009E1301000000000090120100B6120100521201009C120100AA120100881201007A1201006C1201"
$__HandleImgSearch_Opcode32 &= "005E12010000000000BA130100000000003C034C6F61644C696272617279410000E50147657446696C6541747472696275746573410000450247657450726F6341646472657373000"
$__HandleImgSearch_Opcode32 &= "067034D756C746942797465546F5769646543686172006201467265654C69627261727900880043726561746546696C654100F00147657446696C6553697A6500B302476C6F62616C"
$__HandleImgSearch_Opcode32 &= "416C6C6F63005200436C6F736548616E646C6500BE02476C6F62616C4C6F636B0000BA02476C6F62616C467265650000C0035265616446696C650000C502476C6F62616C556E6C6F6"
$__HandleImgSearch_Opcode32 &= "36B00004B45524E454C33322E646C6C00005400436F7079496D61676500EE014C6F6164496D616765410000330147657449636F6E496E666F00A30044657374726F7949636F6E0021"
$__HandleImgSearch_Opcode32 &= "01476574444300F60046696C6C526563740000C8004472617749636F6E45780000650252656C656173654443007E0147657453797374656D4D65747269637300005553455233322E6"
$__HandleImgSearch_Opcode32 &= "46C6C0000FB014765744F626A6563744100003000437265617465436F6D70617469626C6544430000CA0147657444494269747300770253656C6563744F626A656374000012024765"
$__HandleImgSearch_Opcode32 &= "7453797374656D50616C65747465456E747269657300E30044656C65746544430000FC014765744F626A6563745479706500E60044656C6574654F626A65637400002F00437265617"
$__HandleImgSearch_Opcode32 &= "465436F6D70617469626C654269746D617000005400437265617465536F6C6964427275736800001300426974426C74000047444933322E646C6C0027004578747261637449636F6E"
$__HandleImgSearch_Opcode32 &= "4100005348454C4C33322E646C6C00860043726561746553747265616D4F6E48476C6F62616C006F6C6533322E646C6C004F4C4541555433322E646C6C000002024765744C6173744"
$__HandleImgSearch_Opcode32 &= "572726F720000CF0248656170467265650000CB0248656170416C6C6F6300C50147657443757272656E7454687265616449640000CA004465636F6465506F696E7465720086014765"
$__HandleImgSearch_Opcode32 &= "74436F6D6D616E644C696E654100C0045465726D696E61746550726F636573730000C00147657443757272656E7450726F6365737300D304556E68616E646C6564457863657074696"
$__HandleImgSearch_Opcode32 &= "F6E46696C7465720000A504536574556E68616E646C6564457863657074696F6E46696C7465720000034973446562756767657250726573656E7400CD024865617043726561746500"
$__HandleImgSearch_Opcode32 &= "00CE024865617044657374726F790072014765744350496E666F00EF02496E7465726C6F636B6564496E6372656D656E740000EB02496E7465726C6F636B656444656372656D656E7"
$__HandleImgSearch_Opcode32 &= "400006801476574414350000037024765744F454D435000000A03497356616C6964436F64655061676500EA00456E636F6465506F696E74657200C504546C73416C6C6F630000C704"
$__HandleImgSearch_Opcode32 &= "546C7347657456616C756500C804546C7353657456616C756500C604546C73467265650018024765744D6F64756C6548616E646C6557000073045365744C6173744572726F7200001"
$__HandleImgSearch_Opcode32 &= "9014578697450726F63657373002505577269746546696C6500640247657453746448616E646C65000014024765744D6F64756C6546696C654E616D65570000110557696465436861"
$__HandleImgSearch_Opcode32 &= "72546F4D756C746942797465002D034C434D6170537472696E67570000B204536C656570006F0453657448616E646C65436F756E740000E302496E697469616C697A6543726974696"
$__HandleImgSearch_Opcode32 &= "3616C53656374696F6E416E645370696E436F756E7400F30147657446696C655479706500630247657453746172747570496E666F5700D10044656C657465437269746963616C5365"
$__HandleImgSearch_Opcode32 &= "6374696F6E0013024765744D6F64756C6546696C654E616D65410000610146726565456E7669726F6E6D656E74537472696E67735700DA01476574456E7669726F6E6D656E7453747"
$__HandleImgSearch_Opcode32 &= "2696E6773570000A7035175657279506572666F726D616E6365436F756E7465720093024765745469636B436F756E740000C10147657443757272656E7450726F6365737349640079"
$__HandleImgSearch_Opcode32 &= "0247657453797374656D54696D65417346696C6554696D65006902476574537472696E675479706557000039034C65617665437269746963616C53656374696F6E0000EE00456E746"
$__HandleImgSearch_Opcode32 &= "572437269746963616C53656374696F6E00003F034C6F61644C696272617279570000660453657446696C65506F696E74657200009A01476574436F6E736F6C6543500000AC014765"
$__HandleImgSearch_Opcode32 &= "74436F6E736F6C654D6F64650000D202486561705265416C6C6F6300180452746C556E77696E64000403497350726F636573736F724665617475726550726573656E7400D40248656"
$__HandleImgSearch_Opcode32 &= "17053697A650000870453657453746448616E646C65000024055772697465436F6E736F6C6557008F0043726561746546696C6557005701466C75736846696C654275666665727300"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000AF39DA4F0000000090180100010000000400000004000000681801007818010088180100C01D0000702C000050230000D01D0000AD18010"
$__HandleImgSearch_Opcode32 &= "0B9180100C7180100A31801000100020003000000496D616765536561726368444C4C2E646C6C00496D6167655465737400496D61676553656172636800496D616765536561726368"
$__HandleImgSearch_Opcode32 &= "457800496D616765536561726368457874000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "00000000000000000000000000000000000000000000000000004EE640BBB119BF440100000016000000020000000200000003000000020000000400000018000000050000000D000"
$__HandleImgSearch_Opcode32 &= "0000600000009000000070000000C000000080000000C000000090000000C0000000A000000070000000B000000080000000C000000160000000D000000160000000F000000020000"
$__HandleImgSearch_Opcode32 &= "00100000000D00000011000000120000001200000002000000210000000D0000003500000002000000410000000D00000043000000020000005000000011000000520000000D00000"
$__HandleImgSearch_Opcode32 &= "0530000000D0000005700000016000000590000000B0000006C0000000D0000006D00000020000000700000001C00000072000000090000000600000016000000800000000A000000"
$__HandleImgSearch_Opcode32 &= "810000000A00000082000000090000008300000016000000840000000D00000091000000290000009E0000000D000000A100000002000000A40000000B000000A70000000D000000B"
$__HandleImgSearch_Opcode32 &= "700000011000000CE00000002000000D70000000B000000180700000C0000000C00000008000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010101010101010101"
$__HandleImgSearch_Opcode32 &= "0101010101010101010101010101000000000000020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000006162636465666768696A6B6C6D6E6F707172737475767778797A0000000000004142434445464748494A4B4C4D4"
$__HandleImgSearch_Opcode32 &= "E4F505152535455565758595A000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010"
$__HandleImgSearch_Opcode32 &= "1010101010101010101010101010101010101010101010000000000000202020202020202020202020202020202020202020202020202000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "00000000000000000000000000000000000000000000000000000000000000000000000000000000000006162636465666768696A6B6C6D6E6F707172737475767778797A00000000"
$__HandleImgSearch_Opcode32 &= "00004142434445464748494A4B4C4D4E4F505152535455565758595A00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "000000000000000000000000000000007821011001020408A4030000608279822100000000000000A6DF000000000000A1A5000000000000819FE0FC00000000407E80FC00000000A"
$__HandleImgSearch_Opcode32 &= "8030000C1A3DAA320000000000000000000000000000000000000000000000081FE00000000000040FE000000000000B5030000C1A3DAA32000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000081FE00000000000041FE000000000000B6030000CFA2E4A21A00E5A2E8A25B000000000000000000000000000000000081FE000000000000407EA1FE00000000510"
$__HandleImgSearch_Opcode32 &= "5000051DA5EDA20005FDA6ADA32000000000000000000000000000000000081D3D8DEE0F90000317E81FE00000000FEFFFFFF4300000054F5001050F500104CF5001048F5001044F5"
$__HandleImgSearch_Opcode32 &= "001040F500103CF5001034F500102CF5001024F5001018F500100CF5001004F50010F8F40010F4F40010F0F40010ECF40010E8F40010E4F40010E0F40010DCF40010D8F40010D4F40"
$__HandleImgSearch_Opcode32 &= "010D0F40010CCF40010C8F40010C0F40010B4F40010ACF40010A4F40010E4F400109CF4001094F400108CF4001080F4001078F400106CF4001060F400105CF4001058F400104CF400"
$__HandleImgSearch_Opcode32 &= "1038F400102CF4001009040000010000000000000024F400101CF4001014F400100CF4001004F40010FCF30010F4F30010E4F30010D4F30010C4F30010B0F300109CF300108CF3001"
$__HandleImgSearch_Opcode32 &= "078F3001070F3001068F3001060F3001058F3001050F3001048F3001040F3001038F3001030F3001028F3001020F3001018F3001008F30010F4F20010E8F20010DCF2001050F30010"
$__HandleImgSearch_Opcode32 &= "D0F20010C4F20010B4F20010A0F2001090F200107CF2001068F2001060F2001058F2001044F200101CF2001008F200100000000001000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009C26011000"
$__HandleImgSearch_Opcode32 &= "00000000000000000000009C2601100000000000000000000000009C2601100000000000000000000000009C2601100000000000000000000000009C2601100000000000000000000"
$__HandleImgSearch_Opcode32 &= "000000100000001000000000000000000000000000000682A01100000000000000000B002011038070110B8080110A0260110082801100828011078210110FFFFFFFFFFFFFFFFB404"
$__HandleImgSearch_Opcode32 &= "01104800011038000110FFFFFFFF800A00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000001000000000000000100000000000000000000000000000001000000000000000100000000000000000000000000000001000000000000000100000000000000010000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000001000000000000000000000000000000010000000000000001000000000000000100000000000000000000000000000001000000000000000100000"
$__HandleImgSearch_Opcode32 &= "0000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002"
$__HandleImgSearch_Opcode32 &= "E0000002E000000602A0110F83C0110F83C0110F83C0110F83C0110F83C0110F83C0110F83C0110F83C0110F83C01107F7F7F7F7F7F7F7F642A0110FC3C0110FC3C0110FC3C0110FC"
$__HandleImgSearch_Opcode32 &= "3C0110FC3C0110FC3C0110FC3C0110682A0110B0020110B2040110010000002E0000000100000065AF001065AF001065AF001065AF001065AF001065AF001065AF001065AF001065A"
$__HandleImgSearch_Opcode32 &= "F001065AF0010C03D011000000000C03D0110010100000000000000000000001000000000000000000000000000000000000002000000010000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000002000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "00000200000000000000000000000000000020059319000000000000000000000000FEFFFFFF7598000073980000000000000004000001FCFFFF350000000B00000040000000FF030"
$__HandleImgSearch_Opcode32 &= "0008000000081FFFFFF1800000008000000200000007F000000000000000000000000A00240000000000000000000C80540000000000000000000FA08400000000000000000409C0C"
$__HandleImgSearch_Opcode32 &= "40000000000000000050C30F40000000000000000024F412400000000000000080969816400000000000000020BCBE1940000000000004BFC91B8E3440000000A1EDCCCE1BC2D34E4"
$__HandleImgSearch_Opcode32 &= "020F09EB5702BA8ADC59D6940D05DFD25E51A8E4F19EB83407196D795430E058D29AF9E40F9BFA044ED81128F8182B940BF3CD5A6CFFF491F78C2D3406FC6E08CE980C947BA93A841"
$__HandleImgSearch_Opcode32 &= "BC856B5527398DF770E07C42BCDD8EDEF99DFBEB7EAA5143A1E676E3CCF2292F84812644281017AAF8AE10E3C5C4FA44EBA7D4F3F7EBE14A7A95CF4565CCC7910EA6AEA019E3A3460"
$__HandleImgSearch_Opcode32 &= "D65170C7581867576C9484D5842E4A793393B35B8B2ED534DA7E55D3DC55D3B8B9E925AFF5DA6F0A120C054A58C3761D1FD8B5A8BD8255D89F9DB67AA95F8F327BFA2C85DDD806E4C"
$__HandleImgSearch_Opcode32 &= "C99B97208A025260C4257500000000CDCCCDCCCCCCCCCCCCCCFB3F713D0AD7A3703D0AD7A3F83F5A643BDF4F8D976E1283F53FC3D32C6519E25817B7D1F13FD00F2384471B47ACC5A"
$__HandleImgSearch_Opcode32 &= "7EE3F40A6B6696CAF05BD3786EB3F333DBC427AE5D594BFD6E73FC2FDFDCE61841177CCABE43F2F4C5BE14DC4BE9495E6C93F92C4533B7544CD14BE9AAF3FDE67BA943945AD1EB1CF"
$__HandleImgSearch_Opcode32 &= "943F2423C6E2BCBA3B31618B7A3F615559C17EB1537C12BB5F3FD7EE2F8D06BE928515FB443F243FA5E939A527EA7FA82A3F7DACA1E4BC647C46D0DD553E637B06CC23547783FF918"
$__HandleImgSearch_Opcode32 &= "13D91FA3A197A63254331C0AC3C2189D138824797B800FDD73BDC8858081BB1E8E386A6033BC684454207B6997537DB2E3A33711CD223DB32EE49905A39A687BEC057DAA582A6A2B5"
$__HandleImgSearch_Opcode32 &= "32E268B211A7529F4459B7102C2549E42D36344F53AECE6B258F5904A4C0DEC27DFBE8C61E9EE7885A57913CBF508322184E4B6562FD838FAF06947D11E42DDE9FCED2C804DDA6D80"
$__HandleImgSearch_Opcode32 &= "A000000000000008010440000010000000000008000300000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "000004000000000001001800000018000080000000000000000004000000000001000200000030000080000000000000000004000000000001000904000048000000585001005A010"
$__HandleImgSearch_Opcode32 &= "000E4040000000000003C617373656D626C7920786D6C6E733D2275726E3A736368656D61732D6D6963726F736F66742D636F6D3A61736D2E763122206D616E696665737456657273"
$__HandleImgSearch_Opcode32 &= "696F6E3D22312E30223E0D0A20203C7472757374496E666F20786D6C6E733D2275726E3A736368656D61732D6D6963726F736F66742D636F6D3A61736D2E7633223E0D0A202020203"
$__HandleImgSearch_Opcode32 &= "C73656375726974793E0D0A2020202020203C72657175657374656450726976696C656765733E0D0A20202020202020203C726571756573746564457865637574696F6E4C6576656C"
$__HandleImgSearch_Opcode32 &= "206C6576656C3D226173496E766F6B6572222075694163636573733D2266616C7365223E3C2F726571756573746564457865637574696F6E4C6576656C3E0D0A2020202020203C2F7"
$__HandleImgSearch_Opcode32 &= "2657175657374656450726976696C656765733E0D0A202020203C2F73656375726974793E0D0A20203C2F7472757374496E666F3E0D0A3C2F617373656D626C793E50415041444449"
$__HandleImgSearch_Opcode32 &= "4E47585850414444494E4750414444494E47585850414444494E4750414444494E47585850414444494E4750414444494E47585850414444494E4750414444494E475858504144001"
$__HandleImgSearch_Opcode32 &= "00000E0000000223035304D3065307D309530AD30C530DD30F5300D3125313D3155316D3185319D31D1316A329632E3328033AF33E533B834BF341A355A356A35B035C235D435E635"
$__HandleImgSearch_Opcode32 &= "F83545364D3678369836AA36BC367937A437B637C037013817382D384338493859385E38663870387E388C38EF384B397D399B39CF39F139053A143A213A3B3A463A4D3A783A7F3A8"
$__HandleImgSearch_Opcode32 &= "63A963AB03ABB3ADE3A4B3B673B893BA53BC33B0E3C4D3C773CAA3CB63CCB3CE33CFA3C0B3D303D3E3D453D623D6A3D7A3D843D8B3D943D9B3D023E133E183E713E7D3E963EAB3EC5"
$__HandleImgSearch_Opcode32 &= "3E083F0000002000006C0000008E329732A432B832D3322E33333342335D33A433B633C833DB33F2333A346134A235BD352236333638368536BB36C9360D37223756376C37A2378E3"
$__HandleImgSearch_Opcode32 &= "B983BA53BB93BD43B403C453C5E3C7D3CCD3CDF3CF13C043D633D8A3DD13D583F753FD83FE93FEE3F003000004C0000000B303830C330D830F0301B3104330E33293330339F33A433"
$__HandleImgSearch_Opcode32 &= "BD33EA3509360F3621365B36633678368336BA3750385C38D438E0383B3B423BB63CE53CEB3CFA3C0E3F000000400000F00000001E307B31C93101320632103244325C3264326D32A"
$__HandleImgSearch_Opcode32 &= "632DA32E032E632FB322D3349336133B433E1334F3455345B34613467346D3474347B3482348934903497349E34A634AE34B634C234CB34D034D634E034E934F4340035053515351A"
$__HandleImgSearch_Opcode32 &= "35203526353C354335563572359535A835DF35EB35F435FA3500366836A536BC362C383D38773884388E389C38A538AF38E338EE38F83811391B392E3952398939BE39D139413A5E3"
$__HandleImgSearch_Opcode32 &= "AA73A163B353BAA3BB63BC93BDB3BF63BFE3B063C1D3C363C523C5B3C613C6A3C6F3C7E3CA53CCE3CDF3CF33C3F3D8E3DD63D2A3EED3E1B3F933FAD3FBE3FF73F0000005000003401"
$__HandleImgSearch_Opcode32 &= "000027302E303A3040304C3052305B3061306A3076307C3084308A3096309C30A930B330B930C330E530FA30203160316631903196319C31B231CA31F0316A328D329732CF32D7322"
$__HandleImgSearch_Opcode32 &= "3333333393345334B335B3361336733763384338E339433AA33AF33B733BD33C433CA33D133D733DF33E633EB33F333FC3308340D34123418341C34223427342D343234413457345D"
$__HandleImgSearch_Opcode32 &= "3465346A34723477347F3484348B349A349F34A534AE34CE34D434EC3421364F36613641374B37583796379D37AA37B0379E38A438AD38B438D6384B3953396639713976398839923"
$__HandleImgSearch_Opcode32 &= "99739B339BD39D339DE39F839033A0B3A1B3A213A323A6B3A753A9B3AA23ABC3AC33AEE3A6B3B7E3B903BD73BEF3BF93B143C1C3C223C303C643C713C863CB73CD43C203D4E3D753D"
$__HandleImgSearch_Opcode32 &= "823D883DA73EAE3EBA3F00000060000048000000523070309630F630053120316E345E35A936EC361837393719393A3B3E3B423B463B4A3B4E3B523B563B833BCC3B653C353D6D3E0"
$__HandleImgSearch_Opcode32 &= "53F233F493FAD3FC53FEB3F00700000740000003C332D347435B735E3350436E137113A153A193A1D3A213A253A293A2D3A4B3A543A603A973AA03AAC3AE53AEE3AFA3A1F3B453B4B"
$__HandleImgSearch_Opcode32 &= "3B753BBA3BC13BD63B1D3C273C523C6A3C883CAC3CDC3CEE3C1C3D3F3D453D5A3D7A3D9F3DAA3DB93DF13DFB3D3C3E473E513E623E6D3E00800000B00000002D303E3046304C30513"
$__HandleImgSearch_Opcode32 &= "05730C330C930E5300D3159316531743179319A319F31C131DE3132320C3314332C3347339E332235453552355E3566356E357A35A335AB35B635E03542366536FE3668376F377937"
$__HandleImgSearch_Opcode32 &= "8B37A237B037B637D937E037F9370D3813381C382F3853389338E7380739963CA83CBA3CCC3CDE3C043D163D283D3A3D4C3D5E3D703D823D943DA63DB83DCA3DDC3D5A3F8C3FA43FA"
$__HandleImgSearch_Opcode32 &= "B3FB33FB83FBC3FC03FE93F000000900000F80000000F302D30343038303C304030443048304C3050309A30A030A430A830AC3012311D3138313F31443148314C316D319731C931D0"
$__HandleImgSearch_Opcode32 &= "31D431D831DC31E031E431E831EC3136323C3240324432483248347F3485348A3498349D34A234A734B734E634EC34F4343B3540357A357F3586358B3592359735A53506360F36153"
$__HandleImgSearch_Opcode32 &= "69D36AC36BC36C336CB363B374037493758377B37803785379C37F437FA370038A838AD38BF38DD38F138F7386539883993399939A939AE39BF39C739CD39D739DD39E739ED39F739"
$__HandleImgSearch_Opcode32 &= "003A0B3A103A193A233A2E3A693A833A9D3A9F3CA63CAC3C0B3D183D313D4F3D8B3DB33D463EA53E483F683F00A000008400000058308130DA3048322233F233233439347A3499343"
$__HandleImgSearch_Opcode32 &= "635683590350E3672369536A736AD36C736D636E336EF36FF360637153721372E3752376437723787379137B737EA37F93702382638553882388D38A139BF397B3A813A8B3AF93AFF"
$__HandleImgSearch_Opcode32 &= "3A0B3B423B5A3BF53B013C0C3DF03DF53D123F593F5F3F813F943FAC3FCC3F00B00000A00000001F30473060307C30A930D630E1300F311D312B3138315731FF316D32CE32EF32F83"
$__HandleImgSearch_Opcode32 &= "21F332C3331333F331A343D3448346B34BA340C3571357D35F5350F36183646364C36513657366836DD3651377B379B37D137DB373E387B3885389D38C638F8382039BA39BF39C439"
$__HandleImgSearch_Opcode32 &= "CA39CE39D439D839DE39E239E839EC39F139F739FB39013A053A0B3A0F3A153A193A423A5E3A6C3DC23D083E000000C000007800000068332934E93591365A378C37A437AB37B337B"
$__HandleImgSearch_Opcode32 &= "837BC37C037E9370F382D38343838383C384038443848384C3850389A38A038A438A838AC3812391D3938393F39443948394C396D399739C939D039D439D839DC39E039E439E839EC"
$__HandleImgSearch_Opcode32 &= "39363A3C3A403A443A483A003CF73D7A3E6E3F763F00D000005800000027300831A031A63147324D325B32F7320E334833CB33BF34C73478355936F136F73698379E37AC3748385F3"
$__HandleImgSearch_Opcode32 &= "899381C39D93BF03B3C3F403F443F483F4C3F503F543F583F5C3F603F643F683F753F000000E000002000000037305F306F308C30DD300131083B8B3E983EA63ED63E000000F00000"
$__HandleImgSearch_Opcode32 &= "44000000A431A831AC31B031BC31C03100320432CC3ED43EDC3EE43EEC3EF43EFC3E043F0C3F143F1C3F243F2C3F343F3C3F443F4C3F543F5C3F643F6C3F743F0000010048000000A"
$__HandleImgSearch_Opcode32 &= "03B0C3C103C983CB43CB83CD83CF83C183D383D443D603D6C3D883DA83DC43DC83DE83D083E243E283E483E683E883EA83EC83ED43EF03E103F303F4C3F503F0020010018010000A0"
$__HandleImgSearch_Opcode32 &= "35A036A436A836AC36B036B436B836BC36C036C436C836CC36D036D436D836DC36E036E436E836EC36F036F436F836FC360037043708370C371037143718371C372037243728372C3"
$__HandleImgSearch_Opcode32 &= "73037343738373C3740374437483758375C376037643768376C377037743778377C378037843788378C379037943798379C37A037A437A837AC37B037B437B837BC37C037C437C837"
$__HandleImgSearch_Opcode32 &= "CC37D037D437D837DC37E037E437E837EC37F037F437F837FC3700386038703880389038A038C438D038D438D838DC38E038E438E838F438F838FC38683A6C3A703A743A783A7C3A8"
$__HandleImgSearch_Opcode32 &= "03A843A883A8C3A983A9C3AA03AA43AA83AAC3AB03AB43AB83ABC3AC03AD03AD43AD83ADC3AE03AE43AE83AEC3AF03AF43AF83A003B00000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
$__HandleImgSearch_Opcode32 &= "000000000000000000000000000000000000000000000000000000000000000000000"

__HandleImgSearch_StartUp()
#EndRegion Internal Functions
