import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 10,
  duration: "30s",
  thresholds: {
    http_req_failed: ["rate<0.05"],
    http_req_duration: ["p(95)<1200"],
  },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:8001";

function flightSearchFlow() {
  const res = http.get(`${BASE_URL}/api/v1/flights/search?origin=CAI&destination=DXB`);
  check(res, { "flight search status 200|422": (r) => r.status === 200 || r.status === 422 });
}

function bookingFlow() {
  const res = http.get(`${BASE_URL}/api/v1/reservations/me`);
  check(res, { "booking endpoint reachable": (r) => [200, 401, 403].includes(r.status) });
}

function flightStatusFlow() {
  const res = http.get(`${BASE_URL}/api/v1/health`);
  check(res, { "health endpoint status 200": (r) => r.status === 200 });
}

export default function () {
  flightSearchFlow();
  bookingFlow();
  flightStatusFlow();
  sleep(1);
}
