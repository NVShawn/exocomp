# Security Policy

## Supported versions

Until Exocomp publishes its first stable release, security fixes are made on
the `main` branch. After stable releases begin, the latest stable release and
`main` are supported unless a release announcement states otherwise.

| Version | Supported |
|---|---|
| `main` | Yes |
| Latest stable release | Yes |
| Older releases | No |

## Report a vulnerability privately

Use GitHub's
[private vulnerability-reporting form](https://github.com/NVShawn/exocomp/security/advisories/new).
Only repository maintainers and the reporter can see a private report while it
is being assessed.

Do not open a public issue, pull request, discussion, or task for a suspected
vulnerability. If the private form is unavailable, contact a repository
maintainer through their GitHub profile and ask for a private reporting
channel without disclosing vulnerability details publicly.

Include:

- affected version, commit, component, and platform;
- impact and the conditions required to reproduce it;
- minimal reproduction steps or proof of concept;
- any known mitigations; and
- whether the issue is already public or subject to a disclosure deadline.

Never include real credentials, private keys, personal data, or data from a
system you do not own or have permission to test.

## What to expect

Maintainers aim to acknowledge a report within three business days, provide an
initial assessment within seven business days, and keep the reporter informed
until remediation and coordinated disclosure. These are response goals, not
guarantees.

Maintainers will validate the report, establish severity and affected
versions, prepare and test a fix, and coordinate publication of an advisory
and release. Please allow a reasonable remediation window before public
disclosure. Good-faith research that respects privacy, avoids service
disruption, and follows this policy is welcome.

For ordinary defects without security impact, use the public issue tracker.
