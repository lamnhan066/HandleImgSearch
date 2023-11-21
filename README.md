# HandleImgSearch

    Author: Lâm Thành Nhân
    Email: lamnhan066@gmail.com

## English version on [AutoItScript](https://www.autoitscript.com/forum/topic/201757-handleimgsearch-image-search-with-imagesearchdll-embedded/)

## Tìm ảnh trong cửa sổ (inactive) cho AutoIt hỗ trợ tolerance

- UDF HandleImgSearch.au3 sử dụng với mục đích tìm ảnh trong Handle của cửa sổ (cửa sổ không cần active). Cải tiến từ UDF ImageSearchEX.au3 và ImageSearchDLL.au3.

- Mình đã xử lý lại file .dll và đễ sẵn trong UDF này nên UDF sẽ không phụ thuộc vào file .dll.

- UDF này được tổng hợp và bổ sung từ nhiều nguồn, đầu mỗi Func sưu tầm mình đều giữ lại thông tin tác giả.

## Ưu điểm

    - Rất nhanh nhờ embbed ImageSearchDll, không phụ thuộc .dll (Chỉ cần include UDF là đủ).
    - Hỗ trợ Tolerance (Sai số màu sắc) và MaxImg (Tìm nhiều ảnh cùng lúc).
    - Tối ưu tốt, không leak memory (trong giới hạn test của mình).
    - Tìm kiếm qua Handle cửa sổ hoặc toàn màn hình dễ dàng.
    - Hỗ trợ global function, chỉ chụp 1 lần, tái sử dụng nhiều lần để tiết kiệm thời gian chụp ảnh.
    - Có ví dụ kèm theo cho từng hàm.

## Nhược điểm

    - Tốc độ tìm nhiều ảnh sẽ chậm hơn BmpSearch đôi chút (Có Branch BmpSearch kèm theo).
    - Hiện tại chỉ hỗ trợ compile AutoIt 32bit.

## Hàm sử dụng cho Global

Những hàm này bạn có thể sử dụng mà không cần quan tâm tới việc phải giải phóng các biến.

    _GlobalImgInit          ; Khởi tạo tất cả các giá trị ban đầu nếu cần thiết
    _GlobalImgCapture       ; Xóa ảnh đã chụp và bắt đầu chụp màn hình cho lần tìm kiếm hay xử lý hình ảnh
    _GlobalGetBitmap        ; Lấy Handle của ảnh đang được sử dụng (Chụp từ lần dùng _GlobalImgCapture gần nhất)
    _GlobalImgSearch        ; Tìm kiếm ảnh và lấy kết quả trong ảnh đã chụp từ _GlobalImgCapture
    _GlobalImgSearchRandom  ; Tương tự như _GlobalImgSearch nhưng kết quả sẽ lấy ngẫu nhiên trong vùng ảnh tìm được
    _GlobalGetPixel         ; Lấy mã màu tại vị trí cụ thể trong ảnh đã chụp
    _GlobalPixelCompare     ; So sánh màu sắc với màu tại vị trí màu cụ thể trong ảnh đã chụp

## Hàm sử dụng cho Handle

Những hàm này cần phải quản lý biến riêng biệt nhau, với cách dùng này thì bạn cần phải tùy biến nhiều hơn và cần phải quản lý biến cẩn thận để tránh Memory Leaks

    _HandleImgSearch        ; Tìm kiếm ảnh và lấy kết quả trong ảnh chụp từ Handle
    _BmpImgSearch           ; Tìm kiếm ảnh trong ảnh
    _HandleGetPixel         ; Lấy màu tại vị trí cụ thể trong ảnh chụp từ handle
    _HandlePixelCompare     ; So sanh màu với màu tại vị trí cụ thể trong ảnh chụp từ handle
    _HandleCapture          ; Chụp ảnh từ handle cụ thể

### Cách sử dụng và ví dụ

Chú thích đầu mỗi hàm trong HandleImgSearch.au3 và vi dụ cụ thể có trong Example.au3. Hiện tại mình đang dịch ngược các hướng dẫn sang tiếng Anh để mọi người có thể truy cập rộng rãi hơn, bản tiếng Việt bạn có thể đọc từ bản cũ [Tại đây](https://github.com/vnniz/HandleImgSearch/blob/753ee39b4bdb810055e11b9539a805632d782084/HandleImgSearch.au3).

## Lưu ý

    - Ảnh để tìm kiếm nên lưu dạng "24-bit Bitmap".
    - Trong hàm _GlobalImgInit và _HandleCapture đều có tham số $IsUser32. Với cách kiểm tra của mình thì True sẽ sử 
    dụng tốt hơn khi làm việc với cửa sổ của Explorer, False sẽ làm việc tốt hơn với các giả lập. Tuỳ mọi người kiểm 
    tra và sử dụng.
    - Chỉ dùng được khi compile bản AutoIt 32-bit (Vẫn dùng được trên máy chạy 64-bit).

## Lỗi thường gặp

    Chụp trình duyệt (thường xảy ra ở Chrome hoặc Chromium) không thấy ảnh: hãy thử tắt chế độ tăng tốc phần cứng (let try to disable the Hardware Acceleration mode).

## Phiên bản khác

- [BmpSearch](https://github.com/lamnhan066/AutoIt_HandleImgSearch/tree/BmpSearch): Sử dụng UDF BmpSeach (Không hỗ trợ Tolerance, hỗ trợ trả về nhiều vị trí nếu ảnh xuất hiện nhiều lần).

## Cập nhật

    - 12/02/2020:
      + Bổ sung Param $MaxImg: Số kết quả trả về tối đa nếu có nhiều ảnh trùng nhau (Có thể tốc độ thực thi không 
      nhanh bằng BmpSearch vì hoàn toàn sử dụng vòng lặp của AutoIt).
      + Nếu $Hwnd = "" (Param của một số hàm) sẽ sử dụng ảnh màn hình hiện tại để chụp hoặc tìm kiếm.
      + Cải thiện và sửa một số lỗi.
      + Một số thay đổi có thể ảnh hưởng code:
        - $__HandleImgSearch_IsDebug -> $_HandleImgSearch_IsDebug.
        - $MaxImg mặc định 1000 nếu không khai báo.
    - 29/02/2020:
      + Sửa lỗi tìm handle sai khi sử dụng tên cửa sổ.
    - 14/05/2020:
      + Cải thiên tốc độ tìm kiếm.
    - 29/06/2020:
      + Sửa lỗi hàm _GlobalImgWaitExist.
    - 14/04/2023: v2.0.0
      + Thêm tham số $Transparency để đặt màu nền cho ảnh,
      + Tách riêng UDF BinaryCall.au3, MemoryDll.au3.
      + Dịch UDF Header sang tiếng Anh.
    - 30/08/2023: v2.0.1
      + Dịch phần còn lại của UDF sang tiếng Anh.

## Buy me a coffee

- [Paypal](https://paypal.me/lamnhan066)
- [Buy me a coffee](https://www.buymeacoffee.com/lamnhan066)
- [MOMO](https://nhantien.momo.vn/nMu93PhbO97)

## License

    MIT License

    Copyright (c) 2021 lamnhan066

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
