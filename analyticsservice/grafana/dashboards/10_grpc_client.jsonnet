// Dashboard: gRPC Client (C++ / ServiceLib)
//
// ServiceLib exports cumulative counters and percentile gauges:
//   grpc_client_by_destination_rps{grpc_service,grpc_method,grpc_destination}
//   grpc_client_by_destination_status{...,grpc_code}
//   grpc_client_by_destination_active{...}
//   grpc_client_by_destination_timings{...,percentile} (milliseconds)

local g = import 'github.com/grafana/grafonnet/gen/grafonnet-v11.0.0/main.libsonnet';
local lib = import '_lib.libsonnet';

local jobFilter = 'job=~"$job"';
local methodFilter = '%s, grpc_destination=~"$grpc_destination"' % jobFilter;
local heatmapFilter = '%s, transport="grpc"' % jobFilter;

lib.dashboard(
  title='%s / gRPC Client' % lib.svc,
  uid='%s-grpc-client' % lib.svc,
  tags=['grpc', 'client', 'servicelib'],
  variables=[
    lib.dsVar,
    lib.jobVar('grpc_client_by_destination_rps'),
    lib.labelVar(
      'grpc_destination',
      'grpc_destination',
      'grpc_client_by_destination_rps',
      jobFilter
    ),
  ],
  panels=[
    lib.row('Traffic'),
    lib.ts(
      title='Active RPCs',
      targets=[
        lib.promQ(
          'grpc_client_by_destination_active{%s}' % methodFilter,
          '{{grpc_destination}}'
        ),
      ],
      w=8, h=8,
      unit='short',
    ),
    lib.ts(
      title='RPC Rate',
      targets=[
        lib.rate(
          'grpc_client_by_destination_rps',
          methodFilter,
          '{{grpc_destination}}'
        ),
      ],
      w=16, h=8,
      unit='ops',
    ),

    lib.row('Status'),
    lib.ts(
      title='Status Code Distribution',
      targets=[
        lib.rate(
          'grpc_client_by_destination_status',
          methodFilter,
          '{{grpc_code}} {{grpc_destination}}'
        ),
      ],
      w=24, h=8,
      unit='ops',
    ),

    lib.row('Latency'),
    lib.ts(
      title='Duration p50',
      targets=[
        lib.promQ(
          'grpc_client_by_destination_timings{%s, percentile="p50"} / 1000' % methodFilter,
          'p50 {{grpc_destination}}'
        ),
      ],
      w=8, h=8,
      unit='s',
    ),
    lib.ts(
      title='Duration p95',
      targets=[
        lib.promQ(
          'grpc_client_by_destination_timings{%s, percentile="p95"} / 1000' % methodFilter,
          'p95 {{grpc_destination}}'
        ),
      ],
      w=8, h=8,
      unit='s',
    ),
    lib.ts(
      title='Duration p99',
      targets=[
        lib.promQ(
          'grpc_client_by_destination_timings{%s, percentile="p99"} / 1000' % methodFilter,
          'p99 {{grpc_destination}}'
        ),
      ],
      w=8, h=8,
      unit='s',
    ),

    // ServiceLib publishes rolling percentiles rather than histogram buckets.
    lib.row('Latency Distribution'),
    lib.ts(
      title='Duration Percentile Bands',
      targets=[
        lib.promQ(
          'grpc_client_by_destination_timings{%s, percentile="p50"} / 1000' % methodFilter,
          'p50 {{grpc_destination}}'
        ),
        lib.promQ(
          'grpc_client_by_destination_timings{%s, percentile="p90"} / 1000' % methodFilter,
          'p90 {{grpc_destination}}'
        ),
        lib.promQ(
          'grpc_client_by_destination_timings{%s, percentile="p95"} / 1000' % methodFilter,
          'p95 {{grpc_destination}}'
        ),
        lib.promQ(
          'grpc_client_by_destination_timings{%s, percentile="p99"} / 1000' % methodFilter,
          'p99 {{grpc_destination}}'
        ),
        lib.promQ(
          'grpc_client_by_destination_timings{%s, percentile="p100"} / 1000' % methodFilter,
          'max {{grpc_destination}}'
        ),
      ],
      w=24, h=8,
      unit='s',
    ),

    lib.row('Latency Heatmap'),
    lib.heatmap(
      title='Call Duration Heatmap',
      metric='datasink_endpoint_request_duration_seconds',
      filters=heatmapFilter,
    ),

    lib.row('Errors'),
    lib.ts(
      title='Error Rate (non-OK)',
      targets=[
        lib.rate(
          'grpc_client_by_destination_status',
          '%s, grpc_code!="OK"' % methodFilter,
          '{{grpc_code}} {{grpc_destination}}'
        ),
      ],
      w=24, h=8,
      unit='ops',
    ),
  ]
)
