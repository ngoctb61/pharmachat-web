# pharmachat-web

Frontend cho PharmaChat: inbox cho sale (theo dõi và tiếp quản hội thoại AI) và trang quản trị (knowledge base, cấu hình AI, kết nối Meta, user). Backend nằm ở repo [pharmachat-backend](https://github.com/ngoctb61/pharmachat-backend).

- Kế hoạch tách repo và danh sách task FE-00..FE-21: [`docs/FRONTEND_REPO_PLAN.md`](docs/FRONTEND_REPO_PLAN.md)
- Nghiệp vụ và SPEC: Confluence space `SD`, trang [PharmaChat — Tài liệu dự án](https://pharmachat.atlassian.net/wiki/spaces/SD/pages/131076)
- Task: Jira project [PHA](https://pharmachat.atlassian.net/jira/software/projects/PHA/boards), các epic giai đoạn F0..F5

## Chạy local

Cần Node 24 (xem `.nvmrc`). Node 25 không cài được vì `jsdom` không hỗ trợ.

```sh
npm ci
npm run dev        # http://localhost:3000, proxy /api và /ws sang http://localhost:8080
```

Backend chạy ở cổng khác thì đặt `PHARMACHAT_API_URL=http://host:port`.

## Kiểm tra

```sh
npm run typecheck
npm run lint       # eslint + prettier --check
npm test           # vitest
npm run build
```
