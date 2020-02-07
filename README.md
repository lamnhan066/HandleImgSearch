# HandleImgSearch cho AutoIt
> UDF sử dụng với mục đích tìm ảnh trong Handle của cửa sổ. Cải tiến từ UDF ImageSearchEX.au3 và BmpSearch.au3. 
UDF này được tổng hợp và bổ sung từ nhiều nguồn, đầu mỗi Func sưu tầm mình đều giữ lại thông tin tác giả.

### Hàm sử dụng cho global:
    _GlobalImgInit($Hwnd = 0, $X = 0, $Y = 0, $Width = -1, $Height = -1, $IsUser32 = False, $IsDebug = False)
    _GlobalImgCapture($Hwnd = 0)
    _GlobalGetBitmap()
    _GlobalImgSearchRandom($BmpLocal, $IsReCapture = False, $BmpSource = 0, $IsRandom = True)
    _GlobalImgSearch($BmpLocal, $IsReCapture = False, $BmpSource = 0, $maximg = 5000)
    _GlobalGetPixel($X, $Y, $IsReCapture = False, $BmpSource = 0)
    _GlobalPixelCompare($X, $Y, $PixelColor, $Tolerance = 20, $IsReCapture = False, $BmpSource = 0)
### Hàm sử dụng cho Handle
    _HandleImgSearch($hwnd, $bmpLocal, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $maximg = 5000)
    _BmpImgSearch($SourceBmp, $FindBmp, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $maximg = 5000)
    _HandleGetPixel($hwnd, $getX, $getY, $x = 0, $y = 0, $Width = -1, $Height = -1)
    _HandlePixelCompare($hwnd, $getX, $getY, $pixelColor, $tolerance = 20, $x = 0, $y = 0, $Width = -1, $Height = -1)
    _HandleCapture($hwnd, $x = 0, $y = 0, $Width = -1, $Height = -1, $IsBMP = False, $SavePath = "", $IsUser32 = False)

### Cách sử dụng từng hàm đã được chú thích trong HandleImgSearch.au3.
### Ví dụ có sẵn trong Example.au3 cho từng hàm.
### Lưu ý: 
    - Ảnh để tìm kiếm nên lưu dạng "24-bit Bitmap".
    - Trong hàm _GlobalImgInit và _HandleCapture đều có tham số $IsUser32. Với cách kiểm tra của mình thì True sẽ sử 
    dụng tốt hơn khi làm việc với cửa sổ của Explorer, False sẽ làm việc tốt hơn với các giả lập. Tuỳ mọi người kiểm 
    tra và sử dụng.
