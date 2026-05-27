## ADDED Requirements

### Requirement: Persist job-rss SQLite database
The system SHALL preserve the job-rss SQLite database across reboots via impermanence.

#### Scenario: Database directory is in preservation rules
- **WHEN** the system boots with impermanence
- **THEN** `/home/portfolio/jobs/database` is preserved at `/persistent/home/portfolio/jobs/database` via the preservation module

#### Scenario: Database file survives reboot
- **WHEN** the system is rebooted
- **THEN** the SQLite database at `/home/portfolio/jobs/database/database.sqlite` still exists with its data intact
