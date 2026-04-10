# Security Policy

## Supported Versions

Currently, only the latest release of ACE (Autism Care Ecosystem) is actively supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| v4.0.x  | :white_check_mark: |
| v3.x.x  | :x:                |
| v2.x.x  | :x:                |
| < v2.0  | :x:                |

## Reporting a Vulnerability

We take the security of ACE seriously, especially given the sensitive nature of the healthcare data managed within the ecosystem.

If you discover a security vulnerability, please do NOT report it by creating a public GitHub issue.

Instead, please send an email to **singhkhusneet601@gmail.com**

### What to include in your report:

- A description of the vulnerability.
- Steps to reproduce the issue.
- Any potential impact you have identified.

### Security Considerations

ACE handles sensitive healthcare data and implements the following protective measures:

- **On-Device ML**: All behavioral assessment inference (pose estimation, face detection, gaze tracking) runs entirely on the device. No biometric data is transmitted to external servers.
- **Row-Level Security**: All Supabase tables enforce RLS policies, ensuring users can only access their own data.
- **Environment Variable Isolation**: All API keys and credentials are loaded from `.env` files and excluded from version control.
- **Supabase Auth**: Authentication is powered by Supabase Auth with secure session management and token refresh.

### Response Timeline

- We will acknowledge receipt of your vulnerability report within 48 hours.
- We will send you regular updates about our progress in investigating and mitigating the issue.

Thank you for helping keep ACE secure!
