# postgres-vacuum-monitor

## v0.13.1
- Fix long running transaction duration reporting in Postgres 14

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
