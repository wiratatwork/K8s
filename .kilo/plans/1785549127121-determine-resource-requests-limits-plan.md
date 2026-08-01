# Plan: Kubernetes Resource Requests & Limits Best-Practice Sizing & Tuning

## Goal
Establish a reliable, production-grade methodology to determine and tune container `requests` and `limits` for Kubernetes workloads, preventing resource starvation, OOM kills, and cluster under-utilization.

---

## 1. Core Sizing Principles (Best Practices)

- **CPU (Compressible Resource):**
  - **Request:** Set based on normal average to P95 utilization during regular peak hours.
  - **Limit:** Set 2x to 4x of request (or omitted/higher for batch workloads) to allow bursting while preventing CPU starvation of neighboring pods.
- **Memory (Incompressible Resource):**
  - **Request = Limit (Recommended for stability):** Setting memory request equal to memory limit prevents garbage collection surprises and guarantees dedicated memory reservation.
  - **Buffer:** Set to peak memory usage (P99) plus a **20%–30% buffer** to absorb traffic spikes without triggering `OOMKilled`.

---

## 2. Step-by-Step Implementation Methodology

### Phase 1: Baseline Observation (Metrics-Server / Prometheus)
1. Run application without limits (or with loose guardrails) in staging/pre-prod.
2. Collect metrics over 7–14 days across normal business cycles:
   ```bash
   kubectl top pods -n <namespace>
   ```
3. Query Prometheus for actual P95 CPU usage and P99 Memory usage:
   - CPU: `sum(rate(container_cpu_usage_seconds_total{pod=~"app-.*"}[5m])) by (pod)`
   - Memory: `max(container_memory_working_set_bytes{pod=~"app-.*"}) by (pod)`

### Phase 2: Load Testing (Benchmarking Peak Traffic)
1. Simulate expected peak concurrency and traffic spikes using load testing tools (e.g., `k6`, `Locust`, `jMeter`).
2. Monitor resource usage under stress:
   - Check for CPU throttling: `container_cpu_cfs_throttled_periods_total`
   - Check for memory leaks or high allocation spikes.

### Phase 3: Initial Configuration
Apply initial sizing manifest to Deployment:
```yaml
resources:
  requests:
    cpu: "200m"
    memory: "256Mi"
  limits:
    cpu: "1000m"
    memory: "512Mi"
```

### Phase 4: Continuous Tuning & Automated Recommendations
1. **Vertical Pod Autoscaler (VPA):** Run VPA in `Off` or `Initial` mode to observe recommendations without auto-applying restarts:
   ```yaml
   apiVersion: autoscaling.k8s.io/v1
   kind: VerticalPodAutoscaler
   metadata:
     name: app-vpa
   spec:
     targetRef:
       apiVersion: "apps/v1"
       kind: Deployment
       name: app
     updatePolicy:
       updateMode: "Off"
   ```
2. **Review Recommendations:** Check VPA status for recommended target values:
   ```bash
   kubectl describe vpa app-vpa
   ```

---

## 3. Failure Modes & Mitigations

| Failure Mode | Root Cause | Mitigation |
|--------------|------------|------------|
| **OOMKilled** | Memory limit too low or memory leak | Increase memory limit/request, investigate memory profiling |
| **CPU Throttling / Slow Latency** | CPU limit too restrictive while request is low | Increase CPU limit or adjust application concurrency threads |
| **Pending Pods (Unschedulable)** | CPU/Memory requests exceed available node capacity | Right-size requests or scale out cluster nodes |

---

## 4. Rollout & Validation Plan

1. **Staging Validation:** Apply recommended requests/limits to staging environment and run smoke/load tests.
2. **Production Canary:** Roll out to 10% of production traffic, monitor `kubectl top` and pod restart counts (`kubectl get pods`).
3. **Full Rollout:** Deploy across all production workloads.
4. **Ongoing Monitoring:** Set up Prometheus/Grafana alerts for:
   - Pods restarting due to OOMKilled (`container_terminations_reason{reason="OOMKilled"}`)
   - High CPU throttling (`rate(container_cpu_cfs_throttled_periods_total)`)

---

## 5. Verification Checklist
- [ ] P95 CPU and P99 memory baselines documented.
- [ ] Load testing performed under simulated peak conditions.
- [ ] Requests set based on average/P95 usage; Limits set with safe buffers.
- [ ] VPA recommender enabled for continuous observation.
- [ ] No unexpected OOMKilled or severe CPU throttling observed in staging.
