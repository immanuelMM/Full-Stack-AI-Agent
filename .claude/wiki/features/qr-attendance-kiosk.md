# QR scan attendance + kiosk mode

Status: **implemented** — IMMAN_HRIS `d4c2e28` (scan since v1; kiosk, camera switch and layout in U5).

## What it does
- Admin scan page decodes an employee QR with html5-qrcode, posts it to `POST /api/admin/attendance/scan`; the server
  verifies the signature ([signed QR codes](signed-qr-codes.md)) and runs the day's state machine (time in → time out →
  `409` already complete). Feedback text + sounds per outcome.
- Portal self time-in/out (`POST /api/me/time-in`, `/api/me/time-out`). Timestamps pinned to Philippine time.
- Camera: rear by default, Front/Back switch remembered per device (`localStorage` key `hris.scan.camera`); `qrbox`
  scaled to the viewport.
- Kiosk mode: hides nav (class on `<html>`), requests full screen and a screen Wake Lock (best effort — iPhone Safari has
  neither). "Exit kiosk" asks for admin username + password, checked with the admin login endpoint **outside** the shared
  API client's 401 handling; the returned token is discarded. Real lock-down stays Guided Access / screen pinning.

## Reference implementation
- Backend: `IMMAN_HRIS/backend/HRIS.Api/Controllers/AdminAttendanceController.cs`, `IMMAN_HRIS/backend/HRIS.Api/Controllers/MeController.cs`,
  `IMMAN_HRIS/backend/HRIS.Api/Services/AttendanceCalculator.cs`, `IMMAN_HRIS/backend/HRIS.Api/Services/PhilippineTime.cs`;
  tests `IMMAN_HRIS/backend/tests/Hris.Api.IntegrationTests/AttendanceTests.cs`.
- Frontend: `IMMAN_HRIS/frontend/src/pages/admin/ScanAttendancePage.tsx` (`ExitKioskDialog`),
  `IMMAN_HRIS/frontend/src/pages/admin/useKioskMode.ts`, `IMMAN_HRIS/frontend/src/lib/cameraPreference.ts`,
  `IMMAN_HRIS/frontend/src/api/auth.ts` (`verifyAdminCredentials`), `IMMAN_HRIS/frontend/src/utils/attendanceFeedback.ts`,
  `IMMAN_HRIS/frontend/src/utils/sounds.ts`, `IMMAN_HRIS/frontend/src/styles/scan.css`, `IMMAN_HRIS/frontend/src/pages/portal/AttendancePage.tsx`.
- Tests: `IMMAN_HRIS/frontend/src/pages/admin/ScanAttendancePage.test.tsx`, `IMMAN_HRIS/frontend/src/pages/admin/useKioskMode.test.ts`,
  `IMMAN_HRIS/frontend/src/lib/cameraPreference.test.ts`, `IMMAN_HRIS/frontend/src/utils/attendanceFeedback.test.ts`,
  `IMMAN_HRIS/e2e/tests/u5-scan.spec.ts` (fake camera: time-in, time-out, 409, tampered, kiosk exit).

## Port
Copy the scan page, `useKioskMode`, `cameraPreference` and the fake-camera E2E setup
([E2E harness](e2e-playwright-harness.md)); back it with your own signed token service and a unique index on
(person, date) so two fast scans can't create two rows (HRIS fix F1, approved, pending).

## Gotchas
- One-shot actions (a scan allowed once a day) must be reset through the admin API before each E2E test.
- Other specs on the camera page must stub `getUserMedia` to reject.
- Kiosk shares one office IP: size the per-IP rate limits for it.
