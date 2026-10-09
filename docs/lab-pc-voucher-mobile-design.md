# Flutter Student Lab PC Flow

The Lab PC feature is implemented on this branch in the existing Student mobile app. Guard remains a mobile role without PC management, and LabStaff/SAO/Admissions web functions do not move into Flutter.

## Student flow

1. Sign in with the existing authenticator MFA flow. JWT is stored only after verification succeeds.
2. Open **Lab PC**, scan the QR shown on an enrolled SVS Windows client, and confirm the PC name/location returned by the API.
3. Enter the LabStaff-issued voucher and redeem it. The API verifies voucher ownership and creates the timed session.
4. View the active session and end it from the app. Session time shown is based on server timestamps.

The QR scan alone does not authorize a session. The app does not store the PC agent credential. Voucher input is cleared after redemption is attempted.

## Implementation areas

- MFA handling: `DatabaseService`, `AuthProvider`, and `LoginScreen`.
- Lab PC API calls: `LabPcService` and `LabPcSession`.
- Student experience: `LabPcScreen` and the Student dashboard tab.

Before deployment, point the mobile app at the API containing the reviewed lab-PC migration and manually verify successful and rejected scan/redeem cases.