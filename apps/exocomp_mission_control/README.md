# Exocomp Mission Control

Mission Control is a self-hosted web interface for managing Exocomp clusters and operators.

## Features

- OpenID Connect (OIDC) authentication with PKCE flow
- Secure server-side sessions
- Role-based access control (Viewer, Operator, Admin)
- Real-time updates via Phoenix LiveView
- PostgreSQL-backed persistence

## OIDC Configuration

Mission Control uses the standard OIDC Authorization Code flow with PKCE for secure authentication.

### Environment Variables

Set these environment variables to configure OIDC:

- `OIDC_PROVIDER_URL`: Base URL of your OIDC provider (e.g., `https://auth.example.com`)
- `OIDC_CLIENT_ID`: Client ID issued by your OIDC provider
- `OIDC_CLIENT_SECRET`: Client secret issued by your OIDC provider
- `OIDC_REDIRECT_URI`: Callback URL (default: `http://localhost:4000/auth/callback`)

### Example Configuration

```bash
export OIDC_PROVIDER_URL="https://accounts.google.com"
export OIDC_CLIENT_ID="your-client-id.apps.googleusercontent.com"
export OIDC_CLIENT_SECRET="your-client-secret"
export OIDC_REDIRECT_URI="https://mission-control.example.com/auth/callback"
```

## Authentication Flow

1. User clicks "Login"
2. Browser redirected to OIDC provider with authorization request (includes PKCE challenge)
3. User authenticates with provider
4. Provider redirects back to callback URL with authorization code and state
5. Mission Control server validates state and exchanges code for tokens
6. Mission Control validates ID token and creates secure session
7. User is logged in with session cookie

## Session Security

- **HTTP-Only Cookies**: Session cookies cannot be accessed by JavaScript
- **Secure Flag**: Cookies only sent over HTTPS in production
- **SameSite=Lax**: Protection against CSRF attacks
- **Session Rotation**: New session ID generated on login
- **Expiration**: Sessions expire after 7 days

## Logout

Users can logout via `POST /auth/logout`, which:
1. Clears the local session
2. Redirects to OIDC provider's logout endpoint (if available)
3. Falls back to home page if logout endpoint unavailable

## Testing

### Unit Tests

```bash
make test
```

### With a Fake OIDC Provider

For development and testing, you can use a fake OIDC provider to test the full flow without connecting to a real provider.

## Claims Mapping

Mission Control stores only essential claims needed for authorization:

- `subject`: Stable unique identifier from OIDC provider
- `email`: User's email address
- `name`: User's display name
- `issuer`: OIDC provider issuer URL

Additional claims can be mapped through environment configuration for role assignment (not implemented in this release).

## Secrets Protection

- OIDC client secrets are never logged
- Tokens are never logged or stored in the session
- Authorization codes are single-use and consumed immediately
- PKCE verifiers are stored only in memory during the exchange
