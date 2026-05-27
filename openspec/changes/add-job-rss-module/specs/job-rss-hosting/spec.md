## ADDED Requirements

### Requirement: Serve Laravel app at jobs.marvielb.com
The system SHALL serve the Job RSS Laravel app at the domain `jobs.marvielb.com` via nginx.

#### Scenario: HTTP request reaches the app
- **WHEN** a client sends an HTTP request to `jobs.marvielb.com`
- **THEN** nginx serves the response from the job-rss package's `public/` directory

#### Scenario: PHP files are processed by PHP-FPM
- **WHEN** nginx receives a request for a `.php` file
- **THEN** the request is forwarded to the `jobs` PHP-FPM pool via Unix socket

### Requirement: PHP-FPM pool runs as portfolio user
The system SHALL run a PHP-FPM pool named `jobs` under the `portfolio` user.

#### Scenario: PHP-FPM pool is configured
- **WHEN** the PHP-FPM service starts
- **THEN** a pool named `jobs` exists with user=`portfolio`, group=`nginx`, using `php83`

#### Scenario: PHP-FPM socket is readable by nginx
- **WHEN** the PHP-FPM pool starts
- **THEN** the Unix socket owner is set to the nginx user

### Requirement: Database connection uses SQLite
The system SHALL configure the app to use a SQLite database at `/home/portfolio/jobs/database/database.sqlite`.

#### Scenario: DB_CONNECTION and DB_DATABASE are set
- **WHEN** the PHP-FPM pool processes a request
- **THEN** the environment variables `DB_CONNECTION=sqlite` and `DB_DATABASE=/home/portfolio/jobs/database/database.sqlite` are available

### Requirement: APP_KEY is set
The system SHALL set a valid `APP_KEY` environment variable for the Laravel app.

#### Scenario: APP_KEY overrides package default
- **WHEN** the PHP-FPM pool processes a request
- **THEN** `APP_KEY` is set as an environment variable, overriding the placeholder from the package build

### Requirement: Nix-built package is the document root
The system SHALL use the Nix-built package from the `job-rss` flake input as the app source.

#### Scenario: Package is available to nginx
- **WHEN** nginx serves a request
- **THEN** the `root` directive points to `${inputs.job-rss.outputs.packages.${pkgs.system}.job-rss}/share/php/job-rss/public`
