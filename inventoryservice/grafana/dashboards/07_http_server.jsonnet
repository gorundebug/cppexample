// Dashboard: HTTP Server (C++ / ServiceLib)
//
// ServiceLib exports cumulative counters and percentile gauges:
//   http_handler_rps{http_handler,http_path}
//   http_handler_reply_codes{http_handler,http_path,http_code}
//   http_handler_in_flight{http_handler,http_path}
//   http_handler_timings{http_handler,http_path,percentile} (milliseconds)

local g = import 'github.com/grafana/grafonnet/gen/grafonnet-v11.0.0/main.libsonnet';
local lib = import '_lib.libsonnet';

local jobFilter = 'job=~"$job"';
local handlerFilter = '%s, http_handler=~"$http_handler"' % jobFilter;
local heatmapFilter = '%s, transport="http"' % jobFilter;

lib.dashboard(
  title='%s / HTTP Server' % lib.svc,
  uid='%s-http-server' % lib.svc,
  tags=['http', 'server', 'servicelib'],
  variables=[
    lib.dsVar,
    lib.jobVar('http_handler_rps'),
    lib.labelVar('http_handler', 'http_handler', 'http_handler_rps', jobFilter),
  ],
  panels=[
    lib.row('Traffic'),
    lib.ts(
      title='Active Requests',
      targets=[
        lib.promQ(
          'http_handler_in_flight{%s}' % handlerFilter,
          '{{http_handler}} {{http_path}}'
        ),
      ],
      w=8, h=8,
      unit='short',
    ),
    lib.ts(
      title='Request Rate',
      targets=[
        lib.rate(
          'http_handler_rps',
          handlerFilter,
          '{{http_handler}} {{http_path}}'
        ),
      ],
      w=16, h=8,
      unit='ops',
    ),

    lib.row('Latency'),
    lib.ts(
      title='Request Duration p50',
      targets=[
        lib.promQ(
          'http_handler_timings{%s, percentile="p50"} / 1000' % handlerFilter,
          'p50 {{http_handler}} {{http_path}}'
        ),
      ],
      w=8, h=8,
      unit='s',
    ),
    lib.ts(
      title='Request Duration p95',
      targets=[
        lib.promQ(
          'http_handler_timings{%s, percentile="p95"} / 1000' % handlerFilter,
          'p95 {{http_handler}} {{http_path}}'
        ),
      ],
      w=8, h=8,
      unit='s',
    ),
    lib.ts(
      title='Request Duration p99',
      targets=[
        lib.promQ(
          'http_handler_timings{%s, percentile="p99"} / 1000' % handlerFilter,
          'p99 {{http_handler}} {{http_path}}'
        ),
      ],
      w=8, h=8,
      unit='s',
    ),

    // ServiceLib exposes rolling percentiles, not histogram buckets. A real
    // heatmap would require information that the exporter does not provide.
    lib.row('Latency Distribution'),
    lib.ts(
      title='Request Duration Percentile Bands',
      targets=[
        lib.promQ(
          'http_handler_timings{%s, percentile="p50"} / 1000' % handlerFilter,
          'p50 {{http_handler}} {{http_path}}'
        ),
        lib.promQ(
          'http_handler_timings{%s, percentile="p90"} / 1000' % handlerFilter,
          'p90 {{http_handler}} {{http_path}}'
        ),
        lib.promQ(
          'http_handler_timings{%s, percentile="p95"} / 1000' % handlerFilter,
          'p95 {{http_handler}} {{http_path}}'
        ),
        lib.promQ(
          'http_handler_timings{%s, percentile="p99"} / 1000' % handlerFilter,
          'p99 {{http_handler}} {{http_path}}'
        ),
        lib.promQ(
          'http_handler_timings{%s, percentile="p100"} / 1000' % handlerFilter,
          'max {{http_handler}} {{http_path}}'
        ),
      ],
      w=24, h=8,
      unit='s',
    ),

    lib.row('Latency Heatmap'),
    lib.heatmap(
      title='Request Duration Heatmap',
      metric='datasource_endpoint_request_duration_seconds',
      filters=heatmapFilter,
    ),

    lib.row('Errors'),
    lib.ts(
      title='Error Rate (4xx + 5xx)',
      targets=[
        lib.rate(
          'http_handler_reply_codes',
          '%s, http_code=~"4..|5.."' % handlerFilter,
          '{{http_code}} {{http_handler}} {{http_path}}'
        ),
      ],
      w=24, h=8,
      unit='ops',
    ),
  ]
)
