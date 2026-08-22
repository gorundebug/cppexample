// Dashboard: userver Runtime
//
// Source: standard userver engine metrics. The dashboard intentionally uses
// only metrics exported by userver itself and does not emulate Go runtime or
// allocator metrics.

local g = import 'github.com/grafana/grafonnet/gen/grafonnet-v11.0.0/main.libsonnet';
local lib = import '_lib.libsonnet';

local jobFilter = 'job=~"$job"';
local taskProcessorFilter = '%s, task_processor=~"$task_processor"' % jobFilter;

lib.dashboard(
  title='%s / userver Runtime' % lib.svc,
  uid='%s-runtime' % lib.svc,
  tags=['runtime', 'cpp', 'userver'],
  variables=[
    lib.dsVar,
    lib.jobVar('engine_task_processors_worker_threads'),
    lib.labelVar(
      'task_processor',
      'task_processor',
      'engine_task_processors_worker_threads',
      jobFilter
    ),
  ],
  panels=[
    lib.row('Task Processors'),

    lib.ts(
      title='Worker Threads',
      targets=[
        lib.promQ(
          'engine_task_processors_worker_threads{%s}' % taskProcessorFilter,
          '{{task_processor}}'
        ),
      ],
      w=8, h=8,
      unit='short',
    ),

    lib.ts(
      title='Tasks Running and Alive',
      targets=[
        lib.promQ(
          'engine_task_processors_tasks_running{%s}' % taskProcessorFilter,
          'running {{task_processor}}'
        ),
        lib.promQ(
          'engine_task_processors_tasks_alive{%s}' % taskProcessorFilter,
          'alive {{task_processor}}'
        ),
      ],
      w=8, h=8,
      unit='short',
    ),

    lib.ts(
      title='Queued Tasks',
      targets=[
        lib.promQ(
          'engine_task_processors_tasks_queued{%s}' % taskProcessorFilter,
          '{{task_processor}}'
        ),
      ],
      w=8, h=8,
      unit='short',
    ),

    lib.row('Event Loop and Coroutines'),

    lib.ts(
      title='Event Thread CPU Load',
      targets=[
        lib.promQ(
          'engine_ev_threads_cpu_load_percent{%s}' % jobFilter,
          '{{ev_thread_name}}'
        ),
      ],
      w=12, h=8,
      unit='percent',
    ),

    lib.ts(
      title='Coroutine Pool',
      targets=[
        lib.promQ(
          'engine_coro_pool_coroutines_active{%s}' % jobFilter,
          'active {{job}}'
        ),
        lib.promQ(
          'engine_coro_pool_coroutines_total{%s}' % jobFilter,
          'total {{job}}'
        ),
      ],
      w=12, h=8,
      unit='short',
    ),

    lib.row('Process'),

    lib.stat(
      title='Uptime',
      targets=[
        lib.promQ('engine_uptime_seconds{%s}' % jobFilter, '{{job}}'),
      ],
      w=24, h=4,
      unit='s',
      reduceCalc='lastNotNull',
    ),
  ]
)
