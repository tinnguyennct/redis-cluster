1. Snapshotting - RDB
- Tính liên tục của phương pháp RDB được thực hiện bằng cách snapshot nhanh các data tại thời điểm là các khoảng thời gian được chỉ định (được chỉ định trong tệp cấu hình).
- Trong file redis.conf, các thông số sau sẽ thực hiện việc snapshot data:
  save <seconds> <changes>
- Khi 2 biến <second>(sau khoảng thời gian này sẽ thực hiện snapshot) và <change>(điều kiện số lần data thay đổi) được cài đặt, snapshot sẽ thực hiện theo yêu cầu.
Ví dụ:
  save 900 1  //Sau 900 giây (15 phút) nếu ít nhất 1 key được thay đổi, thì sẽ thực hiện snapshot
  save 300 10 //Sau 300 giây (5 phút) nếu ít nhất 10 keys được thay đổi, thì sẽ thực hiện snapshot
  save 60 10000 //Sau 60 giây nếu ít nhất 10000 keys được thay đổi, thì sẽ thực hiện snapshot
- Để disable tính năng RDB này, thì comment # trước các dòng cấu hình "save".
- Để xóa các bản snapshot trước đó thì thêm save với thông số <second> và <change> là trống.
  save ""
- Theo mặc định, Redis sẽ ngừng ghi nếu RDB được enable(ít nhất 1 điều kiện snapshot) và lần lưu nền gần nhất không thành công(lost power). Điều này sẽ báo cho người dùng biết rằng dữ liệu không tồn tại trên disk đúng cách một cách khó nhận biết; nếu không phát hiện ra có thể sẽ xảy ra lỗi nặng. Nếu quá trình lưu nền chạy lại thì redis sẽ tự động cho phép write data.
- Để tránh điều này, cần monitor redis một cách thích hợp và có cài đặt các phương pháp persistence. Hoặc có thể cài đặt "stop-writes-on-bgsave-error" thành "no" để khi có lỗi xảy ra redis vẫn chấp nhận tiếp tục ghi data:
  stop-writes-on-bgsave-error no
- Nén file RDB snapshot:
  rdbcompression yes
- Đặt checksum để tránh hư hỏng file .rdb, nếu tệp zero thì thông số checksum sẽ bỏ qua kiểm tra
  rdbchecksum yes
- Tên của tệp .rdb được snapshot
  dbfilename dump.rdb
- Thư mục lưu tệp .rdb và cả tệp append-only file .aof:
  dir ./
2. Append-Only File
