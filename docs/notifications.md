# Firebase notifications and deep links

## Firebase configuration

Backend deployment:

1. Create a Firebase service account with Cloud Messaging permission.
2. Store the complete service-account JSON as the secret `FIREBASE_SERVICE_ACCOUNT_JSON`.
3. Do not commit the JSON key.

Mobile app:

- Android: add `google-services.json` to `mobile-app/android/app/` and enable the Google Services Gradle plugin, or provide the Firebase values with `--dart-define`.
- iOS: add `GoogleService-Info.plist` to the Runner target, enable Push Notifications and Background Modes > Remote notifications, then upload the APNs key in Firebase.

The supported Dart defines are:

```text
FIREBASE_API_KEY
FIREBASE_APP_ID
FIREBASE_MESSAGING_SENDER_ID
FIREBASE_PROJECT_ID
```

## Push data contract

Every Firebase message includes `scenario` and `destination`. Entity identifiers are strings.

| Destination | Required data | Mobile result |
|---|---|---|
| `connect_post` | `postId` | Connect feed/post |
| `connect_comment` | `postId`, `commentId` | Connect post/comment |
| `nomination_submission` | campaign identifiers | Manage nomination flow |
| `nomination_review` | campaign/nomination identifiers | Manage nomination view |
| `grow_feedback` | `employeeUserId`, `period` | Grow feedback record |
| `feedback_session` | session identifiers | Grow feedback area |
| `manage_leave` | optional `leaveId` | Manage leave approvals |
| `profile_leaves` | `leaveId` | Profile leave history |
| `employee_profile` | `employeeUserId` | Employee/Connect fallback |
| `profile_recognition` | recognition identifiers | Profile recognitions |
| `attendance_team` | date | Manage attendance |
| `attendance_report` | report identifiers | Manage attendance report |
| `team_leave_calendar` | date range | Manage leave calendar |

If a precise entity is unavailable or deleted, the destination opens its parent tab, matching the CSV fallback rule.

## Implemented event producers

- Post likes: hourly batched.
- Post comments: immediate.
- Poll votes/responses: hourly batched.
- Manager nominations: daily digest at 6:00 PM IST.
- Feedback shared: immediate.
- Leave requested and decided: immediate.
- Pending leave approvals: daily at 9:00 AM IST.
- Birthday, anniversary, and new joiner: 9:00 AM IST.

The notification API also provides a persistent in-app inbox, device-token registration, invalid-token cleanup, and read state.

The remaining matrix rows depend on domain workflows not currently represented in the database: poll/survey closing timestamps, nomination campaign publication/deadlines and winner announcements, feedback session schedules/read receipts/missed state, and attendance records/reports. Those producers must be connected when their source modules are introduced; their destination contracts are reserved above.
