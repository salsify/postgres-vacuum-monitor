# postgres-vacuum-monitor

## v0.17.0
- Increased default `monitor_max_run_time_seconds` to 60 seconds.
- Added `monitor_statement_timeout_seconds` (defaults to 10 seconds) to limit query runtime.
- Eagerly clear connection pools when`ActiveRecord::StatementInvalid` is encounted to attempt
  to clear bad connections.

## v0.16.0
- Add `max_attempts` and `max_run_time` to `Postgres::Vacuum::Jobs::MonitorJob` to avoid backing up the queue. The
  defaults are 1 attempt and 10 seconds, but they can be configured with `monitor_max_attempts` and
  `monitor_max_run_time_seconds`, respectively.

## v0.15.0
- Add support for Rails 7.1

## v0.14.1
- Requires activerecord >= 6.1

## v0.14.0
- Drop support for ruby < 3.0 and Rails < 6.1

## v0.13.1
- Fix epoch reporting in Postgres 14

## v0.13.0
- Add support for ruby 3.2 and Rails 7.0
- Drop support for ruby < 2.7 and Rails < 6.0.

## v0.12.0
- Add support for ruby 3.0
- Drop support for ruby < 2.6

## v0.11.0
- Add support for rails 6.1

## v0.10.1
- Query bug fix.

## v0.10.0
- Add events for connection idle time and state.

## v.0.9.0
- Add the application name in the event.

## v.0.8.0
- Report on queries that are being blocked by another process.

## v.0.7.0
- Lower the default `LongTransactions` threshold from 1 hour to 5 minutes and make this configurable via
  the `long_running_transaction_threshold_seconds` setting.

## v.0.6.0
- Add `wait_event_type`, `transaction_id` and `min_transaction_id` to `LongTransactions` events.

## v.0.5.0
- Renamed `LongQueries` event to `LongTransactions`.
- Renamed `LongTransactions.query` to `LongTransactions.most_recent_query` and added a
  transaction `state` attribute.

## v.0.4.0
  - Add rails 6 support.

## v.0.3.2
  - Monitor non-ActiveRecord::Base database connections

## v.0.3.1
  - Relax pg requirements
