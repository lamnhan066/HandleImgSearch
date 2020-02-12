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

### Cách sử dụng và ví dụ: 
    Chú thích đầu mỗi hàm trong HandleImgSearch.au3 và vi dụ cụ thể có trong Example.au3.
### Lưu ý: 
    - Ảnh để tìm kiếm nên lưu dạng "24-bit Bitmap".
    - Trong hàm _GlobalImgInit và _HandleCapture đều có tham số $IsUser32. Với cách kiểm tra của mình thì True sẽ sử 
    dụng tốt hơn khi làm việc với cửa sổ của Explorer, False sẽ làm việc tốt hơn với các giả lập. Tuỳ mọi người kiểm 
    tra và sử dụng.
### Phiên bản khác: [Branch BmpSearch](https://github.com/ltnhanst94/AutoIt_HandleImgSearch/tree/BmpSearch): 
    - Sử dụng UDF BmpSeach (Không hỗ trợ Tolerance, hỗ trợ trả về nhiều vị trí nếu ảnh xuất hiện nhiều lần).
### Cập nhật:
    - 12/02/2020:
      + Bổ sung Param $MaxImg: Số kết quả trả về tối đa nếu có nhiều ảnh trùng nhau (Có thể tốc độ thực thi không 
      nhanh bằng BmpSearch vì hoàn toàn sử dụng vòng lặp của AutoIt).
      + Nếu $Hwnd = "" (Param của một số hàm) sẽ sử dụng ảnh màn hình hiện tại để chụp hoặc tìm kiếm.
      + Cải thiện và sửa một số lỗi.
      + Một số thay đổi có thể ảnh hưởng code:
        - $__HandleImgSearch_IsDebug -> $_HandleImgSearch_IsDebug.
        - $MaxImg mặc định 1000 nếu không khai báo.
      
