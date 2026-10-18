# Kế hoạch tách repo frontend PharmaChat

> Bổ sung cho "Kế hoạch migrate backend PharmaChat sang Go". Kế hoạch đó để riêng phần frontend (dòng 4) và chỉ định nghĩa hợp đồng API ở mục 8.
> Trạng thái: đã chốt ngày 2026-10-18 (mục 9). Repo: https://github.com/ngoctb61/pharmachat-web

## 1. Hiện trạng (đã kiểm tra trong repo cũ)

Repo .NET có hai thư mục frontend. Cả hai đều chưa build được và chưa nối với backend thật:

|                | `src/pharmachat-web`                                                                                                    | `src/frontend/pharmachat-web`                                                                                                                                                                                          |
| -------------- | ----------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Có gì          | 5 component inbox (`features/inbox/*`), `LoginPage`, `App.tsx`, `main.tsx`                                              | `lib/api.ts`, `stores/authStore.ts`, `types/index.ts`, `Layout`, `Sidebar`, `LoginPage`                                                                                                                                |
| Dung lượng     | 425 dòng TS/TSX                                                                                                         | 368 dòng TS/TSX                                                                                                                                                                                                        |
| Lỗi chặn build | `index.html` nạp `src/main.ts` (file mẫu của Vite), không phải `main.tsx`. `package.json` thiếu `react` và `react-dom`. | Giống bên trái, và thiếu cả `@vitejs/plugin-react` dù `vite.config.ts` có import. `api.ts` mất hết template literal (`fetch(${API_BASE}, ...`, `Bearer ` rỗng), cùng kiểu lỗi PowerShell mà HANDOFF_TASK10 đã ghi lại. |
| Dữ liệu        | Inbox dùng dữ liệu cứng (`useState('1')`)                                                                               | Gọi API, nhưng đường dẫn và kiểu dữ liệu theo backend .NET                                                                                                                                                             |
| Bảo mật        |                                                                                                                         | JWT để trong `localStorage`, trái với SPEC-01 (refresh token qua cookie httpOnly)                                                                                                                                      |

Cả hai thư mục chỉ có trong 2 commit đầu của repo cũ, nên không còn lịch sử git nào đáng giữ.

**Kết luận:** dựng repo mới từ đầu, không dùng `git filter-repo`. Từ code cũ chỉ lấy bố cục 3 cột và markup Tailwind của các component inbox làm tham khảo giao diện. Không lấy `api.ts`, `authStore.ts` và `types/`, vì kiểu dữ liệu sẽ sinh từ OpenAPI của backend Go.

## 2. Mục tiêu

- Repo riêng `ngoctb61/pharmachat-web` (public), nhánh mặc định `master`, cùng quy trình với backend: nhánh `feat/PHA-n-*`, PR theo template, squash merge.
- Một SPA phục vụ cả sale (inbox, tiếp quản) và admin (KB, cấu hình AI, Meta, user, dashboard). Route nào hiện ra tùy theo role trong JWT.
- Kiểu dữ liệu và client API **sinh từ `api/openapi.yaml`** của backend, không viết tay.
- Chạy cùng origin với backend qua Caddy. Không cần CORS, và cookie refresh dùng được `SameSite=Strict`.

## 3. Stack

Giữ lựa chọn của code cũ cho đỡ phải chọn lại, và pin version chính xác:

| Hạng mục       | Chọn                                          | Ghi chú                                                                                                          |
| -------------- | --------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Build          | Vite + TypeScript strict, Node 24 LTS         | `npm` với `package-lock.json` commit và `save-exact`. Không dùng pnpm vì Node 25 trở lên không còn kèm corepack. |
| UI             | React 19, Tailwind 4, lucide-react            |                                                                                                                  |
| Router         | react-router 7 (chế độ SPA)                   |                                                                                                                  |
| Dữ liệu server | TanStack Query                                | Cache theo key, WS event sẽ invalidate hoặc patch cache                                                          |
| State cục bộ   | zustand                                       | Chỉ giữ access token (trong bộ nhớ) và trạng thái UI                                                             |
| Client API     | `openapi-typescript` + `openapi-fetch`        | Sinh kiểu từ spec. Client mỏng, không cần runtime lớn.                                                           |
| Mock           | MSW, handler dựa trên kiểu sinh ra            | Dev được trước khi backend có endpoint                                                                           |
| Test           | Vitest + Testing Library; Playwright cho E2E  | E2E chạy với stack docker compose của backend                                                                    |
| Lint           | ESLint flat config + Prettier, `tsc --noEmit` |                                                                                                                  |

## 4. Hợp đồng với backend

**Vấn đề:** theo kế hoạch backend, `api/openapi.yaml` đến GO-47 (cuối giai đoạn 7) mới hoàn chỉnh. Nếu chờ đến lúc đó thì frontend bị chặn suốt.

**Đã chốt (F-3):**

1. Backend tạo `api/openapi.yaml` ngay ở giai đoạn 1 (GO-07). PR nào thêm hoặc đổi endpoint thì cập nhật spec trong cùng PR (template PR đã có checkbox này). GO-47 chỉ còn rà lại cho đủ.
2. Backend thêm job CI: chạy `vacuum lint` (hoặc `redocly lint`) trên spec, và chạy test đối chiếu route chi với spec để không lệch.
3. Tài liệu sự kiện WS nằm ở `api/websocket.md` (kế hoạch backend mục 8). Frontend viết kiểu TS cho các sự kiện từ tài liệu này.
4. Frontend có `contract/openapi.yaml` là bản copy ghim theo một commit của backend. Lệnh `make sync-contract REF=<sha>` dùng `gh api` để kéo về. Khi spec đổi, diff hiện ngay trong PR của frontend, người review thấy được hợp đồng thay đổi những gì.

Cách này không cần token đọc chéo repo trong CI, vì spec đã được commit sẵn trong repo frontend.

### Những điểm frontend cần backend chốt trước khi làm GO-08 và GO-29

- **Xác thực WebSocket.** Trình duyệt không gắn được header `Authorization` cho WebSocket. Có hai cách:
  - (a) `POST /api/ws/ticket` trả về một ticket dùng một lần, sống 30 giây, client gửi kèm `?ticket=`.
  - (b) Gửi JWT trong message đầu tiên ngay sau khi kết nối.

  Đã chốt (a) theo F-5: JWT không lọt vào log truy cập, và server từ chối kết nối ngay khi bắt tay. GO-29 cần ghi rõ cách đã chọn.

- **Luồng token.** `POST /api/auth/login` trả access token (15 phút) trong body và đặt cookie refresh `httpOnly; Secure; SameSite=Strict; Path=/api/auth`. Frontend giữ access token trong bộ nhớ. Khi tải lại trang hoặc gặp 401, frontend gọi `/api/auth/refresh` một lần (các request đang chờ dùng chung một promise refresh), sau đó retry.
- **Lỗi.** Mọi lỗi trả về theo envelope `{errorCode, message, requestId}` (đã có trong `httpx`). Frontend ánh xạ `errorCode` sang câu tiếng Việt và hiện `requestId` để người dùng báo lỗi.
- **Phân trang.** Danh sách hội thoại dùng cursor (GO-28), nên frontend dùng `useInfiniteQuery`.

## 5. Triển khai

```
Internet ── Caddy (TLS 1.3) ──┬── /api/*, /ws/*  → api:8080
                              └── /*            → web (file tĩnh, fallback index.html)
```

- Repo frontend build image `ghcr.io/ngoctb61/pharmachat-web:<sha>`: bước build bằng Node, image chạy là `caddy:2.10.2` chỉ phục vụ `dist/`. Header CSP, `X-Frame-Options` và cache dài cho `/assets/*` (tên file đã có hash) đặt tại đây.
- Backend thêm service `web` vào `deploy/docker-compose.yml`, khai báo `WEB_IMAGE` trong `.env`, và trong `Caddyfile` thêm `handle` để chuyển phần còn lại sang `web`. Thay đổi này thuộc repo backend và cần một issue PHA riêng.
- Repo public nên image trên GHCR để public, VPS pull không cần đăng nhập. Image chỉ chứa file tĩnh, không có bí mật.
- Dev local: `vite` cổng 3000 proxy `/api` và `/ws` (có `ws: true`) sang `localhost:8080`, hoặc chạy hoàn toàn bằng MSW.

## 6. Cấu trúc repo

```
pharmachat-web/
├── contract/openapi.yaml       # bản copy ghim, cập nhật bằng make sync-contract
├── src/
│   ├── api/                    # schema.d.ts (sinh ra, không sửa tay), client.ts, ws.ts
│   ├── auth/                   # luồng token, guard theo role
│   ├── features/
│   │   ├── inbox/              # 3 cột, tiếp quản, soạn tin
│   │   ├── kb/                 # module, version, deploy, rollback, gợi ý
│   │   └── admin/              # user, LLM/embedding, Meta, dashboard
│   ├── components/             # UI dùng chung
│   └── mocks/                  # handler MSW
├── e2e/                        # Playwright
├── deploy/Dockerfile, Caddyfile
├── .claude/                    # rules, guard-push, gofmt đổi thành prettier
├── .github/workflows/ci.yml    # lint, typecheck, test, gen-check, build image
├── CLAUDE.md, AGENTS.md, README.md
```

CI có bước `gen-check`: sinh lại `schema.d.ts` từ `contract/openapi.yaml`, và báo lỗi nếu kết quả khác với bản đã commit (giống `sqlc diff` ở backend).

## 7. Task

Đặt trong Jira PHA (F-2). Mỗi giai đoạn là một epic, tiền tố `FE-xx · `. Cột "Cần backend" ghi task GO phải xong trước. Nếu chưa xong thì frontend vẫn làm được bằng MSW, nhưng chỉ đóng task khi đã chạy với backend thật.

### Giai đoạn F0: Nền tảng

| Task  | Nội dung                                                                                                                        | Cần backend                          |
| ----- | ------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| FE-00 | Tạo repo, `master`, Vite + TS strict + Tailwind + ESLint/Prettier, pin version                                                  |                                      |
| FE-01 | CI: lint, typecheck, Vitest, build, docker build                                                                                |                                      |
| FE-02 | `.claude/` (workflow, guard-push, hook prettier), `CLAUDE.md`, `AGENTS.md`, template PR                                         |                                      |
| FE-03 | `make sync-contract`, sinh `schema.d.ts`, `gen-check` trong CI, client `openapi-fetch` có middleware auth và xử lý envelope lỗi | openapi.yaml tồn tại (đề xuất mục 4) |
| FE-04 | Image Caddy tĩnh với CSP và cache; service `web` và route trong Caddyfile của backend (issue PHA phía backend)                  |                                      |

**Điều kiện xong:** `https://localhost/` trên stack compose của backend hiện được trang login. CI xanh.

### Giai đoạn F1: Đăng nhập và khung app (SPEC-01)

| Task  | Nội dung                                                                                                          | Cần backend  |
| ----- | ----------------------------------------------------------------------------------------------------------------- | ------------ |
| FE-05 | Trang login, access token trong bộ nhớ, refresh khi tải lại trang và khi gặp 401 (dùng chung một promise), logout | GO-07, GO-08 |
| FE-06 | Layout 3 cột, sidebar theo role, route guard, trang 403/404                                                       | GO-09        |
| FE-07 | Bảng `errorCode` sang câu tiếng Việt, hiện `requestId`                                                            |              |

**Điều kiện xong:** đăng nhập, tải lại trang vẫn còn phiên, sau 15 phút vẫn dùng tiếp được, logout xong thì cookie bị hủy. Có test E2E cho cả bốn.

### Giai đoạn F2: Inbox và tiếp quản (SPEC-06, B-1)

| Task  | Nội dung                                                                                                                                                      | Cần backend   |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- |
| FE-08 | Danh sách hội thoại: lọc theo trạng thái, kênh và "Tôi xử lý", phân trang cursor                                                                              | GO-28, GO-30a |
| FE-09 | Khung chat: lịch sử tin nhắn, nhãn AI/sale/khách, badge compliance                                                                                            | GO-28         |
| FE-10 | Panel trí nhớ khách                                                                                                                                           | GO-28         |
| FE-11 | Client WS: lấy ticket, tự kết nối lại có backoff, khi kết nối lại thì refetch; xử lý `ReceiveMessage`, `TypingIndicator`, `NewConversation`, `HandoffChanged` | GO-29, GO-30  |
| FE-12 | Tiếp quản và trả lại cho AI, ô soạn tin (chỉ hiện khi `handling_mode = human` và hội thoại do mình xử lý), hiện lý do chuyển (triệu chứng nặng, ảnh, hạn mức) | GO-30a        |

**Điều kiện xong:** gửi webhook giả lập, tin nhắn hiện trong inbox trong vòng 1 giây và không cần tải lại trang. Sale tiếp quản rồi gửi tin được. Đăng nhập bằng user của tenant B thì không thấy hội thoại của tenant A.

### Giai đoạn F3: Knowledge base (SPEC-02)

| Task  | Nội dung                                                                                        | Cần backend |
| ----- | ----------------------------------------------------------------------------------------------- | ----------- |
| FE-13 | Danh sách module và version, trình soạn Markdown, upload .txt/.md (kiểm tra 10MB ngay ở client) | GO-11       |
| FE-14 | Deploy và rollback, trạng thái deploy realtime qua WS                                           | GO-12..14   |

### Giai đoạn F4: Admin (SPEC-04, SPEC-07)

| Task  | Nội dung                                                                                          | Cần backend  |
| ----- | ------------------------------------------------------------------------------------------------- | ------------ |
| FE-15 | Quản lý user và role                                                                              | GO-36        |
| FE-16 | Cấu hình LLM và embedding: key chỉ hiện dạng che, nút thử kết nối, hạn mức chi phí và mức đã dùng | GO-37, GO-20 |
| FE-17 | Kết nối Meta: luồng OAuth, danh sách page, trạng thái token, cảnh báo `reconnect_required`        | GO-31, GO-34 |
| FE-18 | Dashboard                                                                                         | GO-38        |
| FE-19 | Self-learning: bật/tắt, duyệt hoặc bỏ gợi ý                                                       | GO-39..41    |

### Giai đoạn F5: Hoàn thiện

| Task  | Nội dung                                                                                                   | Cần backend |
| ----- | ---------------------------------------------------------------------------------------------------------- | ----------- |
| FE-20 | E2E Playwright cho luồng webhook → AI → inbox → tiếp quản → gửi tin, chạy trong CI với compose của backend | GO-46       |
| FE-21 | Rà accessibility (bàn phím, contrast), giao diện mobile cho inbox (F-4: không ưu tiên trong MVP)           |             |

## 8. Dọn repo cũ

- Không sửa gì `src/pharmachat-web` và `src/frontend/pharmachat-web` trong repo cũ. Repo đó sẽ được archive.
- README trỏ sang repo mới (việc đang chờ, cần chủ repo NguyenTung309 đồng ý) ghi thêm link `pharmachat-web`.

## 9. Quyết định đã chốt (2026-10-18)

| #   | Câu hỏi      | Chốt                                                                                                               |
| --- | ------------ | ------------------------------------------------------------------------------------------------------------------ |
| F-1 | Tên repo     | `ngoctb61/pharmachat-web`, public, nhánh `master` có branch protection                                             |
| F-2 | Jira         | Dùng chung project PHA. Mỗi giai đoạn F0..F5 là một epic, issue con có tiền tố `FE-xx · `.                         |
| F-3 | Hợp đồng sớm | Backend tạo `api/openapi.yaml` từ GO-07 và cập nhật trong từng PR đổi endpoint. GO-47 chỉ còn rà lại cho đủ.       |
| F-4 | Mobile       | Không ưu tiên trong MVP. FE-21 giữ ở F5.                                                                           |
| F-5 | Xác thực WS  | Ticket dùng một lần: `POST /api/ws/ticket` (sống 30 giây), client kết nối với `?ticket=`. GO-29 làm theo cách này. |
