// Web: gọi API same-origin để cookie auth thành first-party (chạy cả trên
// trình duyệt điện thoại). Vercel rewrite /api/* sang backend thật (xem vercel.json).
// Có thể ghi đè bằng --dart-define=API_BASE_URL=... khi chạy local/PRM.
String defaultApiBaseUrl() => Uri.base.origin;
