>> Author: Lâm Thành Nhân\
>> Email: ltnhan.st.94@gmail.com
# Tìm ảnh trong cửa sổ (inactive) cho AutoIt hỗ trợ tolerance
> UDF HandleImgSearch.au3 sử dụng với mục đích tìm ảnh trong Handle của cửa sổ (cửa sổ không cần active). Cải tiến từ UDF ImageSearchEX.au3 và ImageSearchDLL.au3 (không phụ thuộc vào file .dll).\
> UDF này được tổng hợp và bổ sung từ nhiều nguồn, đầu mỗi Func sưu tầm mình đều giữ lại thông tin tác giả.

### Hàm sử dụng cho Global:
    _GlobalImgInit
    _GlobalImgCapture
    _GlobalGetBitmap
    _GlobalImgSearchRandom
    _GlobalImgSearch
    _GlobalGetPixel
    _GlobalPixelCompare
### Hàm sử dụng cho Handle
    _HandleImgSearch
    _BmpImgSearch
    _HandleGetPixel
    _HandlePixelCompare
    _HandleCapture

### Cách sử dụng từng hàm đã được chú thích trong HandleImgSearch.au3.
### Ví dụ có sẵn trong Example.au3 cho từng hàm.
### Lưu ý: 
    - Ảnh để tìm kiếm nên lưu dạng "24-bit Bitmap".
    - Trong hàm _GlobalImgInit và _HandleCapture đều có tham số $IsUser32. Với cách kiểm tra của mình thì True sẽ sử 
    dụng tốt hơn khi làm việc với cửa sổ của Explorer, False sẽ làm việc tốt hơn với các giả lập. Tuỳ mọi người kiểm 
    tra và sử dụng.
### Phiên bản khác: [Branch BmpSearch](https://github.com/ltnhanst94/AutoIt_HandleImgSearch/tree/BmpSearch): 
    - Sử dụng UDF BmpSeach (Không hỗ trợ Tolerance, hỗ trợ trả về nhiều vị trí nếu ảnh xuất hiện nhiều lần).
