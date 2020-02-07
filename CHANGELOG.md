# postgres-vacuum-monitor
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

