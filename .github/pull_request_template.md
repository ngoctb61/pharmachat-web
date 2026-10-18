<!--
Tiêu đề PR theo conventional commits: <type>(<scope>): <tóm tắt> (PHA-n)
Ví dụ: feat(auth): trang dang nhap va luong refresh token (PHA-75)
Xóa các mục không áp dụng thay vì để trống.
-->

## Task và SPEC

- Task: PHA-n · FE-xx <!-- issue Jira, project PHA -->
- SPEC: SPEC-0x <!-- Confluence space SD -->
- Cần backend: GO-xx (PHA-k) <!-- issue đang chặn; ghi đã chạy với backend thật hay mới chỉ MSW. Xóa nếu không có. -->
- Quyết định liên quan: <!-- B-1..B-6, F-1..F-5 nếu có, hoặc xóa dòng này -->
- Plan và review: `ticketed/PHA-n/`

## Thay đổi gì và tại sao

<!-- 2-5 gạch đầu dòng. Nêu lý do, không liệt kê lại từng file. -->

-

## Kiểm chứng

<!-- Bằng chứng thật: test nào chứng minh điều kiện xong, lệnh đã chạy, kết quả thấy được. -->

- [ ] `npm run lint` sạch
- [ ] `npm run typecheck` sạch
- [ ] `npm test` pass
- [ ] `npm run build` thành công
- [ ] Đã chạy với backend thật <!-- chỉ khi task có issue GO chặn; nếu chưa thì task chưa được Done -->

Chi tiết:

-

## Checklist

**Hợp đồng API**

- [ ] Kiểu dữ liệu và client lấy từ `contract/openapi.yaml`, không viết tay
- [ ] Đổi `contract/` bằng `make sync-contract`, ghi commit backend đã ghim

**Bảo mật** (constitution Art. 3)

- [ ] Access token chỉ trong bộ nhớ, không `localStorage`/`sessionStorage`
- [ ] Không render HTML chưa sanitize từ tin nhắn, câu trả lời AI hay KB
- [ ] Không log hay lưu số điện thoại, email, nội dung tin nhắn, token
- [ ] Không có bí mật trong code hay biến `VITE_*`

**Giao diện và Jira**

- [ ] Chuỗi hiển thị theo quy ước tiếng Việt trong `CLAUDE.md`
- [ ] Có trạng thái loading, lỗi (kèm `requestId`) và rỗng
- [ ] Đã chuyển issue Jira sang In Review và ghi bằng chứng vào comment

## Ngoài phạm vi

<!-- Lỗi hoặc việc phát hiện được nhưng cố ý không làm trong PR này, kèm lý do. Xóa nếu không có. -->
