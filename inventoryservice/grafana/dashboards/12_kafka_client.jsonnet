// Dashboard: userver Kafka Client
//
// Source: the documented kafka::ProducerComponent and
// kafka::ConsumerComponent StatisticsStorage metrics. The framework-owned
// producer registers the same public Producer::DumpMetric writer.

local g = import 'github.com/grafana/grafonnet/gen/grafonnet-v11.0.0/main.libsonnet';
local lib = import '_lib.libsonnet';

local jobFilter = 'job=~"$job"';

lib.dashboard(
  title='%s / Kafka Client (userver)' % lib.svc,
  uid='%s-kafka-client' % lib.svc,
  tags=['kafka', 'cpp', 'userver'],
  variables=[
    lib.dsVar,
    lib.jobVar('service_info'),
  ],
  panels=[
    lib.row('Messages'),

    lib.ts(
      title='Produced Messages',
      targets=[
        lib.rate('kafka_producer_messages_total', jobFilter, '{{topic}} total'),
        lib.rate('kafka_producer_messages_success', jobFilter, '{{topic}} success'),
        lib.rate('kafka_producer_messages_error', jobFilter, '{{topic}} errors'),
      ],
      w=12, h=8,
      unit='ops',
    ),

    lib.ts(
      title='Consumed Messages',
      targets=[
        lib.rate('kafka_consumer_messages_total', jobFilter, '{{topic}} total'),
        lib.rate('kafka_consumer_messages_success', jobFilter, '{{topic}} success'),
        lib.rate('kafka_consumer_messages_error', jobFilter, '{{topic}} errors'),
      ],
      w=12, h=8,
      unit='ops',
    ),

    lib.row('Latency and connectivity'),

    lib.ts(
      title='Average Message Latency',
      targets=[
        lib.promQ('kafka_producer_avg_ms_spent_time{%s}' % jobFilter, 'produce {{topic}}'),
        lib.promQ('kafka_consumer_avg_ms_spent_time{%s}' % jobFilter, 'consume {{topic}}'),
      ],
      w=12, h=8,
      unit='ms',
    ),

    lib.ts(
      title='Broker Connection Errors',
      targets=[
        lib.promQ('kafka_producer_connections_error{%s}' % jobFilter, 'producer {{component_name}}'),
        lib.promQ('kafka_consumer_connections_error{%s}' % jobFilter, 'consumer {{component_name}}'),
      ],
      w=12, h=8,
      unit='short',
    ),
  ]
)
