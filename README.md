[![Build Status](https://travis-ci.org/salsify/postgres-vacuum-monitor.svg?branch=master)](https://travis-ci.org/salsify/postgres-vacuum-monitor)
[![Maintainability](https://api.codeclimate.com/v1/badges/9ced178ca8fee231a935/maintainability)](https://codeclimate.com/github/salsify/postgres-vacuum-monitor/maintainability)
[![Coverage Status](https://coveralls.io/repos/github/salsify/postgres-vacuum-monitor/badge.svg?branch=master)](https://coveralls.io/github/salsify/postgres-vacuum-monitor?branch=master)


# Postgres::Vacuum::Monitor

Postgres::Vacuum::Monitor provides queries that provide information about the number of dead tuples and long running queries.
This information helps to diagnose and monitor two things: 
1) That the current auto vacuum settings are working and keeping up.
2) That there are no long running transactions affecting the auto vacuuming daemon.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'postgres-vacuum-monitor'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install postgres-vacuum-monitor

## Usage

The job itself needs a class to report the information and can be configured by doing:

```ruby
Postgres::Vacuum::Monitor.configure do |config|
  config.monitor_reporter_class_name = 'MetricsReporter'
end
```

The class needs to follow this interface:
```ruby
class MetricsReporter
  def report_event(name, attributes)
  end
end
```

For long running transactions, the event name is `LongTransactions` and the attributes are: 
```ruby 
{
  database_name: # The name of the database.
  start_time: # When the transaction started .
  running_time: # How long has it been running in seconds.
  application_name: # What's the application name that is running the query.
  most_recent_query: # The last query started by the transaction
  state: # The state of the transaction - either "active" or "idle in transaction"
  wait_event_type: # The type of lock the transaction is waiting for if applicable
  transaction_id: # The transaction_id which will be null for read-only transactions
  min_transaction_id: # The mininum transaction id horizon
}
```

For auto vacuum the attributes are the following:

```ruby 
{
  database_name: # The name of the database.
  table: # Table name.
  table_size: # How big is the table.
  dead_tuples: # How many dead tuples are in the table.
  tuples_over_limit: # How many dead tuples are over the auto vacuumer threshold.
}
```

## Testing

To run the rspec tests, you need to create a DB called `postgres_vacuum_monitor_test`.

## New relic queries

I use [New relic](https://rpm.newrelic.com) and use the following NRQL to create dashboards:

#### Tuples over limit
```SQL
SELECT percentile(tuples_over_limit, 95) from AutoVacuumLagging facet table where appName = 'my-app' TIMESERIES 30 minutes since 1 day ago
```

#### Dead tuples
```SQL
SELECT percentile(dead_tuples) FROM AutoVacuumLagging facet table where appName = 'my-app' SINCE 1 DAY AGO TIMESERIES
```     
#### Long running transactions
```SQL
SELECT application_name, state, most_recent_query, running_time, start_time FROM LongTransactions
```

#### Tables that need to be vacuumed
```SQL
SELECT uniques(table) FROM AutoVacuumLagging where appName = 'my-app' since 30 minutes ago
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/salsify/postgres-vacuum-monitor.
