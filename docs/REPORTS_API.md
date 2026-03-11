# Reports API

The Reports API enables users to report abuse, inappropriate content, or safety concerns. Admins can manage and track all reports through dedicated endpoints.

## Table of Contents

- [User Endpoints](#user-endpoints)
- [Admin Endpoints](#admin-endpoints)
- [Report Types](#report-types)
- [Report Status](#report-status)
- [Examples](#examples)

---

## User Endpoints

### Create Report

Submit a new report for concerning content or behavior.

**Endpoint:** `POST /api/reports`  
**Auth Required:** Yes (JWT)  
**Rate Limit:** Standard

**Request Body:**

```json
{
  "reportedUserId": "uuid",
  "reportType": "HARASSMENT | INAPPROPRIATE_CONTENT | CSAE | SPAM | IMPERSONATION | OTHER",
  "description": "Detailed description of the issue (max 2000 chars)",
  "chatRequestId": "uuid (optional - if related to a specific chat)",
  "sessionContext": "string (optional - additional context, max 255 chars)"
}
```

**Validation:**
- Cannot report yourself
- `reportedUserId` must be a valid UUID
- `reportType` must be one of the enum values
- `description` is required and limited to 2000 characters

**Response:** `201 Created`

```json
{
  "id": "report-uuid",
  "reporterId": "your-uuid",
  "reportedUserId": "reported-user-uuid",
  "reportType": "HARASSMENT",
  "description": "User sent threatening messages",
  "chatRequestId": null,
  "sessionContext": null,
  "status": "PENDING",
  "createdAt": "2026-03-11T10:30:00.000Z",
  "updatedAt": "2026-03-11T10:30:00.000Z"
}
```

**Errors:**
- `400` - Cannot report yourself
- `400` - Invalid reportType or missing required fields
- `401` - Not authenticated

---

## Admin Endpoints

All admin endpoints require the `AdminGuard` (user must have admin role).

### List All Reports

Get all reports with optional filtering.

**Endpoint:** `GET /api/reports/admin`  
**Auth Required:** Yes (Admin)  
**Rate Limit:** Admin throttle

**Query Parameters:**

```
?status=PENDING|UNDER_REVIEW|RESOLVED|DISMISSED
&reportType=HARASSMENT|INAPPROPRIATE_CONTENT|CSAE|SPAM|IMPERSONATION|OTHER
&reportedUserId=uuid
&reporterId=uuid
```

All parameters are optional and can be combined.

**Response:** `200 OK`

```json
[
  {
    "id": "report-uuid",
    "reporterId": "reporter-uuid",
    "reporter": {
      "id": "reporter-uuid",
      "displayName": "@username",
      "email": "user@example.com"
    },
    "reportedUserId": "reported-uuid",
    "reportedUser": {
      "id": "reported-uuid",
      "displayName": "@badactor",
      "email": "bad@example.com"
    },
    "reportType": "HARASSMENT",
    "description": "User sent threatening messages",
    "chatRequestId": null,
    "sessionContext": null,
    "status": "PENDING",
    "adminNotes": null,
    "resolvedBy": null,
    "resolver": null,
    "resolvedAt": null,
    "createdAt": "2026-03-11T10:30:00.000Z",
    "updatedAt": "2026-03-11T10:30:00.000Z"
  }
]
```

### Get Report Statistics

Get aggregated report counts by status.

**Endpoint:** `GET /api/reports/admin/stats`  
**Auth Required:** Yes (Admin)  
**Rate Limit:** Admin throttle

**Response:** `200 OK`

```json
{
  "total": 156,
  "pending": 12,
  "underReview": 8,
  "resolved": 130,
  "dismissed": 6
}
```

### Get Single Report

Get detailed information about a specific report.

**Endpoint:** `GET /api/reports/admin/:id`  
**Auth Required:** Yes (Admin)  
**Rate Limit:** Admin throttle

**Response:** `200 OK`

Returns the same structure as individual reports in the list endpoint.

**Errors:**
- `404` - Report not found

### Update Report Status

Update the status of a report and add admin notes.

**Endpoint:** `PATCH /api/reports/admin/:id`  
**Auth Required:** Yes (Admin)  
**Rate Limit:** Admin throttle

**Request Body:**

```json
{
  "status": "UNDER_REVIEW | RESOLVED | DISMISSED | PENDING",
  "adminNotes": "Optional notes about the resolution (max 2000 chars)"
}
```

**Response:** `200 OK`

```json
{
  "id": "report-uuid",
  "status": "RESOLVED",
  "adminNotes": "User was warned and blocked for 7 days",
  "resolvedBy": "admin-uuid",
  "resolvedAt": "2026-03-11T11:00:00.000Z",
  ...
}
```

**Notes:**
- When status is set to `RESOLVED` or `DISMISSED`, the system automatically sets:
  - `resolvedBy` to the current admin's userId
  - `resolvedAt` to current timestamp
- Moving back to `PENDING` or `UNDER_REVIEW` clears resolution data

**Errors:**
- `404` - Report not found

### Delete Report

Permanently delete a report from the database.

**Endpoint:** `DELETE /api/reports/admin/:id`  
**Auth Required:** Yes (Admin)  
**Rate Limit:** Admin throttle

**Response:** `204 No Content`

**Errors:**
- `404` - Report not found

---

## Report Types

| Type | Description |
|------|-------------|
| `INAPPROPRIATE_CONTENT` | Offensive, graphic, or otherwise inappropriate content |
| `HARASSMENT` | Bullying, threats, or unwanted contact |
| `CSAE` | Child Sexual Abuse and Exploitation (highest priority) |
| `SPAM` | Spam, advertisement, or bot behavior |
| `IMPERSONATION` | Pretending to be someone else |
| `OTHER` | Other violations not covered above |

## Report Status

| Status | Description |
|--------|-------------|
| `PENDING` | Newly created, awaiting admin review |
| `UNDER_REVIEW` | Admin is actively investigating |
| `RESOLVED` | Issue has been addressed |
| `DISMISSED` | Report was invalid or not actionable |

---

## Examples

### User Reports Harassment

```bash
curl -X POST https://api.drawback.app/api/reports \
  -H "Authorization: Bearer <jwt-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "reportedUserId": "abc-123-def",
    "reportType": "HARASSMENT",
    "description": "User has been sending me threatening messages repeatedly despite being blocked",
    "chatRequestId": "request-uuid",
    "sessionContext": "Session ID: session-123"
  }'
```

### Admin Views All Pending Reports

```bash
curl -X GET "https://api.drawback.app/api/reports/admin?status=PENDING" \
  -H "Authorization: Bearer <admin-jwt-token>"
```

### Admin Filters CSAE Reports

```bash
curl -X GET "https://api.drawback.app/api/reports/admin?reportType=CSAE" \
  -H "Authorization: Bearer <admin-jwt-token>"
```

### Admin Resolves a Report

```bash
curl -X PATCH https://api.drawback.app/api/reports/admin/report-uuid \
  -H "Authorization: Bearer <admin-jwt-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "RESOLVED",
    "adminNotes": "User was permanently banned. NCMEC report filed. Case #12345"
  }'
```

### Admin Gets Report Statistics

```bash
curl -X GET https://api.drawback.app/api/reports/admin/stats \
  -H "Authorization: Bearer <admin-jwt-token>"
```

---

## Database Schema

```sql
reports (
  id                  VARCHAR(36) PRIMARY KEY,
  reporterId          VARCHAR(36) NOT NULL → users.id (CASCADE),
  reportedUserId      VARCHAR(36) NOT NULL → users.id (CASCADE),
  reportType          ENUM(...) NOT NULL,
  description         TEXT NOT NULL,
  chatRequestId       VARCHAR(36) NULL,
  sessionContext      VARCHAR(255) NULL,
  status              ENUM(...) DEFAULT 'PENDING',
  adminNotes          TEXT NULL,
  resolvedBy          VARCHAR(36) NULL → users.id (SET NULL),
  resolvedAt          TIMESTAMP NULL,
  createdAt           DATETIME(6) NOT NULL,
  updatedAt           DATETIME(6) NOT NULL
)
```

**Indexes:**
- `reporterId` - Fast lookup of user's reports
- `reportedUserId` - Fast lookup of reports against a user
- `status` - Filter by status
- `reportType` - Filter by type
- `createdAt` - Chronological ordering

---

## Integration with CSAE Standards

Reports are a key component of Drawback's CSAE compliance:

1. **Evidence Preservation**: All reports are stored with complete audit trail
2. **24-Hour Review**: Admins committed to reviewing reports within 24 hours
3. **NCMEC Reporting**: CSAE-type reports trigger mandatory NCMEC CyberTipline filing
4. **Legal Compliance**: Report data available for law enforcement requests
5. **User Safety**: Enables community-driven safety monitoring

For complete CSAE policies, see `/docs/CSAE_STANDARDS.md`.

---

## Best Practices

### For Users
- Provide detailed, specific descriptions
- Include session context when relevant
- Use appropriate report type for faster triage
- Do not use reports for non-safety disputes

### For Admins
- Review CSAE reports immediately
- Document all actions in adminNotes
- Preserve evidence before taking action
- Follow escalation procedures for serious violations
- Update status promptly to maintain user trust

---

## Rate Limiting

- User reporting: Standard throttle (configured in app.module.ts)
- Admin endpoints: Admin throttle (100 requests/60 seconds)

## Privacy & Security

- Reporter identity is never disclosed to reported user
- Admin notes are excluded from API responses to non-admins (`@Exclude()` decorator)
- Resolution details (resolvedBy, resolvedAt, adminNotes) hidden from regular users
- All endpoints require authentication
- Deletion is permanent and cannot be undone
