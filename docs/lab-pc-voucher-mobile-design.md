# Flutter Lab PC Voucher Flow — Design

**Status:** Proposed client design; this document does not change the app behavior.

## Student flow

1. Sign in with username/password.
2. Follow the API's MFA next step: show authenticator setup QR/manual key during first setup; submit current six-digit code; show recovery codes once with a save/acknowledge step. Later sign-ins request an authenticator code or one recovery code. Do not store recovery codes or authenticator secrets in the app.
3. Student dashboard offers **Computer Lab**. Guard and SAO navigation remains as it is; the mobile app does not gain LabStaff management.
4. Student taps **Scan PC**, scans the short-lived QR rendered by the kiosk, and sees the PC's name/location for confirmation.
5. Student enters the one-use voucher, submits both voucher and challenge to the API, and sees success only after the server creates the session.
6. Active-session screen shows PC, end time/countdown, and **End session**. The app refreshes from the server; local timer is informational, not authoritative.
7. On expiry/end/rejection, show a clear result and offer to return to the dashboard. Never treat a local QR scan as authorization.

## API integration to implement

- Update `DatabaseService.login` to parse the real MFA response envelope and branch on `data.nextStep`; current source expects `data['token']` and `data['role']` directly and will not handle the new flow.
- Keep the MFA challenge only in short-lived app state. Send it with the code to `POST /api/auth/mfa/verify`. Persist the JWT only after verification succeeds.
- Reuse the existing `mobile_scanner` dependency for the lab PC QR. Validate the QR format and avoid scanning repeatedly while a request is in progress.
- Add typed request/response models and service methods for redeem, active-session lookup, and end-session. Use authenticated API calls and handle 401/403/404/409/429/network errors in plain language.
- Do not put a voucher in logs, analytics, crash reports, or persistent local storage. Clear it from the text field after the redemption attempt.
- Do not store the PC agent credential on the phone. The app never communicates directly with a PC.

## Screens

- **MFA setup:** QR image, manual key fallback, account label, six-digit code input, and recovery-code display after successful initial verification.
- **MFA verify:** six-digit authenticator code, with a deliberate recovery-code alternative.
- **Computer Lab landing:** explain that a LabStaff-issued voucher is needed; button to scan.
- **PC confirmation + voucher:** PC name/location, voucher entry, explicit redeem action.
- **Active lab session:** PC identity, server expiry time, remaining-time display, end-session action.
- **History/error states:** explain expired or already-used voucher, expired QR, PC unavailable, no active session, and network failure without displaying raw server traces.

Keep role navigation accurate: Student and Guard remain mobile users; no LabStaff, Admissions, or SAO web features move into Flutter.

## Accessibility and behavior

Use large touch targets, focus the voucher input after scan, provide manual retry, handle camera permission denial with instructions, and prevent duplicate submits. The timer must refresh from server UTC timestamps when the app returns to the foreground. Logout clears JWT and student/session cached data. No authentication code, token, recovery code, or voucher is included in diagnostic output.

## Acceptance checklist

- MFA setup, verification, and recovery-code login handle the backend envelope; tokens are not saved before MFA.
- Student can scan a valid PC challenge and redeem only their own valid voucher.
- App shows active session from server state and can end only the signed-in student's session.
- Expired/reused QR and voucher, wrong student, role rejection, offline network, and concurrent submit produce clear outcomes.
- Existing student and guard dashboard paths remain separate and work as before.
