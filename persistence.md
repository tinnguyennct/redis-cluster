1. Snapshotting - RDB
- Tính liên tục của phương pháp RDB được thực hiện bằng cách snapshot nhanh các data tại thời điểm là các khoảng thời gian được chỉ định (được chỉ định trong tệp cấu hình).
- Trong file redis.conf, các thông số sau sẽ thực hiện việc snapshot data:
  ```bash
  save <seconds> <changes>
  ```
- Khi 2 biến <second>(sau khoảng thời gian này sẽ thực hiện snapshot) và <change>(điều kiện số lần data thay đổi) được cài đặt, snapshot sẽ thực hiện theo yêu cầu.
Ví dụ:
  ```bash
  save 900 1  //Sau 900 giây (15 phút) nếu ít nhất 1 key được thay đổi, thì sẽ thực hiện snapshot
  save 300 10 //Sau 300 giây (5 phút) nếu ít nhất 10 keys được thay đổi, thì sẽ thực hiện snapshot
  save 60 10000 //Sau 60 giây nếu ít nhất 10000 keys được thay đổi, thì sẽ thực hiện snapshot
  ```
- Để disable tính năng RDB này, thì comment # trước các dòng cấu hình "save".
- Để xóa các bản snapshot trước đó thì thêm save với thông số <second> và <change> là trống.
  ```bash
  save ""
  ```
- Theo mặc định, Redis sẽ ngừng ghi nếu RDB được enable(ít nhất 1 điều kiện snapshot) và lần lưu nền gần nhất không thành công(lost power). Điều này sẽ báo cho người dùng biết rằng dữ liệu không tồn tại trên disk đúng cách một cách khó nhận biết; nếu không phát hiện ra có thể sẽ xảy ra lỗi nặng. Nếu quá trình lưu nền chạy lại thì redis sẽ tự động cho phép write data.
- Để tránh điều này, cần monitor redis một cách thích hợp và có cài đặt các phương pháp persistence. Hoặc có thể cài đặt "stop-writes-on-bgsave-error" thành "no" để khi có lỗi xảy ra redis vẫn chấp nhận tiếp tục ghi data:
  ```bash
  stop-writes-on-bgsave-error no
  ```
- Nén file RDB snapshot:
  ```bash
  rdbcompression yes
  ```
- Đặt checksum để tránh hư hỏng file .rdb, nếu tệp zero thì thông số checksum sẽ bỏ qua kiểm tra
  ```bash
  rdbchecksum yes
  ```
- Tên của tệp .rdb được snapshot
  ```bash
  dbfilename dump.rdb
  ```
- Thư mục lưu tệp .rdb và cả tệp append-only file .aof:
  ```bash
  dir ./
  ```
2. Append-Only File
- Với RDB, redis thực hiện dump không đồng bộ dữ liệu trên disk. Chế độ này đủ dùng, nhưng nếu có sự cố với redis(lost power,..) dẫn đến mất vài phút ghi giữa 2 lần snapshot thì có thể mất dữ liệu.
- Với Append Only File thì dữ liệu sẽ được lưu một cách liên tục và persistence hơn. Tính năng RDB và AOF có thể được bật cùng lúc để bổ trợ nhau mà không ảnh hưởng gì.
- AOF ghi lại mọi thao tác ghi mà máy chủ nhận được, thao tác này sẽ được phát lại khi khởi động máy chủ, tạo lại tập dữ liệu ban đầu.
  ```bash
  appendonly no
  ```
- Tên của tệp AOF:
  ```bash
  appendfilename "appendonly.aof"
  ```
- Đồng bộ dữ liệu được ghi:
  ```bash
  appendfsync <option>
  + appendfsync always: fsync mỗi khi các lệnh mới được thêm vào AOF. 
  + appendfsync everysec: fsync mỗi giây. Đủ nhanh (trong 2,4 có thể nhanh như snapshot) và có thể mất chỉ 1 giây dữ liệu nếu có sự cố.
  ```

3. Full cấu hình persistence:
  ```bash
  #RDB - AOF Persistence
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
dbfilename dump.rdb
dir ./

appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 80
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes

  
File .rdb và .aof lưu ở path /var/redis/
Khi restore, chỉ cần copy 2 file này bỏ vào thư mục này, lưu ý phải đúng tên file và đường dẫn đã chỉ định ở cấu hình
```
