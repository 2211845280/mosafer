# Load Testing Guide

## Scope

The smoke load script validates 3 production-critical flows:

1. Flight search reachability
2. Booking endpoint reachability
3. Flight status/health endpoint responsiveness

Script path: `load_tests/k6_smoke.js`

## Run

Install [k6](https://k6.io/docs/get-started/installation/) and execute:

```bash
k6 run load_tests/k6_smoke.js
```

To run against another environment:

```bash
k6 run -e BASE_URL=https://staging.example.com load_tests/k6_smoke.js
```

## Expected thresholds

- `http_req_failed` < 5%
- `http_req_duration` p95 < 1200 ms

## Reading results

- If failures exceed threshold, inspect failing endpoint statuses in k6 output.
- If latency threshold fails, correlate with `/metrics` histogram and app logs.
- Re-run with lower VUs first to isolate baseline latency before scaling up.
