#!/usr/bin/env python3
"""Lightweight payroll API for local container runs and smoke testing.

The service keeps everything in memory so it stays dependency-free and easy to
ship inside the current Terraform-backed project.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from datetime import date
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Any, Dict, List
from urllib.parse import parse_qs, urlparse


PROJECT_NAME = os.getenv("PROJECT_NAME", "secure-payroll-platform")
ENVIRONMENT = os.getenv("ENVIRONMENT", "dev")


@dataclass(frozen=True)
class Tenant:
	id: str
	name: str
	prefix: str


@dataclass(frozen=True)
class Employee:
	id: str
	tenant_id: str
	first_name: str
	last_name: str
	job_title: str
	annual_salary_gbp: int


@dataclass(frozen=True)
class PayrollRun:
	id: str
	tenant_id: str
	period_start: str
	period_end: str
	status: str
	employee_count: int
	gross_pay_gbp: int
	net_pay_gbp: int


TENANTS: List[Tenant] = [
	Tenant(id="company", name="Companies", prefix="companies"),
	Tenant(id="bureau", name="Bureaus", prefix="bureaus"),
	Tenant(id="employee", name="Employees", prefix="employees"),
]

EMPLOYEES: List[Employee] = [
	Employee("emp-1001", "company", "Amina", "Patel", "Payroll Manager", 68000),
	Employee("emp-2001", "bureau", "Daniel", "Turner", "Finance Analyst", 52000),
	Employee("emp-3001", "employee", "Sophie", "Green", "Operations Lead", 61000),
]

PAYROLL_RUNS: List[PayrollRun] = [
	PayrollRun("pr-2026-04-company", "company", "2026-04-01", "2026-04-30", "processed", 42, 215000, 168300),
	PayrollRun("pr-2026-04-bureau", "bureau", "2026-04-01", "2026-04-30", "processed", 19, 98000, 76540),
	PayrollRun("pr-2026-04-employee", "employee", "2026-04-01", "2026-04-30", "processing", 11, 58000, 45240),
]


class PayrollAPIHandler(BaseHTTPRequestHandler):
	server_version = "SecurePayrollAPI/1.0"

	def _write_json(self, status_code: int, payload: Dict[str, Any]) -> None:
		body = json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8")
		self.send_response(status_code)
		self.send_header("Content-Type", "application/json")
		self.send_header("Content-Length", str(len(body)))
		self.end_headers()
		self.wfile.write(body)

	def _read_json_body(self) -> Dict[str, Any]:
		content_length = int(self.headers.get("Content-Length", "0"))
		if content_length == 0:
			return {}

		raw_body = self.rfile.read(content_length)
		if not raw_body:
			return {}

		return json.loads(raw_body.decode("utf-8"))

	def _tenant_payload(self, tenant: Tenant) -> Dict[str, Any]:
		return {
			"id": tenant.id,
			"name": tenant.name,
			"prefix": tenant.prefix,
			"s3_prefix": f"s3://{tenant.prefix}/",
		}

	def _employee_payload(self, employee: Employee) -> Dict[str, Any]:
		return {
			"id": employee.id,
			"tenant_id": employee.tenant_id,
			"first_name": employee.first_name,
			"last_name": employee.last_name,
			"job_title": employee.job_title,
			"annual_salary_gbp": employee.annual_salary_gbp,
		}

	def _payroll_run_payload(self, payroll_run: PayrollRun) -> Dict[str, Any]:
		return {
			"id": payroll_run.id,
			"tenant_id": payroll_run.tenant_id,
			"period_start": payroll_run.period_start,
			"period_end": payroll_run.period_end,
			"status": payroll_run.status,
			"employee_count": payroll_run.employee_count,
			"gross_pay_gbp": payroll_run.gross_pay_gbp,
			"net_pay_gbp": payroll_run.net_pay_gbp,
		}

	def _find_tenant(self, tenant_id: str) -> Tenant | None:
		return next((tenant for tenant in TENANTS if tenant.id == tenant_id), None)

	def _find_employee(self, employee_id: str) -> Employee | None:
		return next((employee for employee in EMPLOYEES if employee.id == employee_id), None)

	def _find_payroll_run(self, run_id: str) -> PayrollRun | None:
		return next((run for run in PAYROLL_RUNS if run.id == run_id), None)

	def _summary(self) -> Dict[str, Any]:
		return {
			"project": PROJECT_NAME,
			"environment": ENVIRONMENT,
			"service_date": date.today().isoformat(),
			"tenant_count": len(TENANTS),
			"employee_count": len(EMPLOYEES),
			"payroll_run_count": len(PAYROLL_RUNS),
		}

	def do_GET(self) -> None:
		parsed = urlparse(self.path)
		path = parsed.path.rstrip("/") or "/"
		query = parse_qs(parsed.query)

		if path == "/" or path == "/health":
			self._write_json(
				200,
				{
					"status": "ok",
					"service": "secure-payroll-platform",
					"project": PROJECT_NAME,
					"environment": ENVIRONMENT,
				},
			)
			return

		if path == "/v1":
			self._write_json(
				200,
				{
					"name": "Secure Payroll API",
					"version": "1.0",
					"routes": [
						"/health",
						"/v1/summary",
						"/v1/tenants",
						"/v1/tenants/{tenant_id}",
						"/v1/employees",
						"/v1/employees/{employee_id}",
						"/v1/payroll-runs",
						"/v1/payroll-runs/{run_id}",
						"/v1/payroll-runs?tenant_id=company",
					],
				},
			)
			return

		if path == "/v1/summary":
			self._write_json(200, self._summary())
			return

		if path == "/v1/tenants":
			self._write_json(200, {"items": [self._tenant_payload(tenant) for tenant in TENANTS]})
			return

		if path.startswith("/v1/tenants/"):
			tenant_id = path.split("/", 3)[3]
			tenant = self._find_tenant(tenant_id)
			if tenant is None:
				self._write_json(404, {"error": "tenant_not_found"})
				return

			self._write_json(200, self._tenant_payload(tenant))
			return

		if path == "/v1/employees":
			tenant_id = query.get("tenant_id", [None])[0]
			employees = EMPLOYEES
			if tenant_id:
				employees = [employee for employee in EMPLOYEES if employee.tenant_id == tenant_id]

			self._write_json(200, {"items": [self._employee_payload(employee) for employee in employees]})
			return

		if path.startswith("/v1/employees/"):
			employee_id = path.split("/", 3)[3]
			employee = self._find_employee(employee_id)
			if employee is None:
				self._write_json(404, {"error": "employee_not_found"})
				return

			self._write_json(200, self._employee_payload(employee))
			return

		if path == "/v1/payroll-runs":
			tenant_id = query.get("tenant_id", [None])[0]
			payroll_runs = PAYROLL_RUNS
			if tenant_id:
				payroll_runs = [run for run in PAYROLL_RUNS if run.tenant_id == tenant_id]

			self._write_json(200, {"items": [self._payroll_run_payload(run) for run in payroll_runs]})
			return

		if path.startswith("/v1/payroll-runs/"):
			run_id = path.split("/", 3)[3]
			payroll_run = self._find_payroll_run(run_id)
			if payroll_run is None:
				self._write_json(404, {"error": "payroll_run_not_found"})
				return

			self._write_json(200, self._payroll_run_payload(payroll_run))
			return

		self._write_json(404, {"error": "not_found"})

	def do_POST(self) -> None:
		parsed = urlparse(self.path)
		path = parsed.path.rstrip("/") or "/"

		if path != "/v1/payroll-runs/preview":
			self._write_json(404, {"error": "not_found"})
			return

		try:
			payload = self._read_json_body()
		except json.JSONDecodeError:
			self._write_json(400, {"error": "invalid_json"})
			return

		tenant_id = payload.get("tenant_id")
		tenant = self._find_tenant(tenant_id) if tenant_id else None
		if tenant is None:
			self._write_json(400, {"error": "tenant_id_required"})
			return

		employee_count = int(payload.get("employee_count", 0))
		if employee_count <= 0:
			self._write_json(400, {"error": "employee_count_must_be_positive"})
			return

		gross_pay_gbp = int(payload.get("gross_pay_gbp", employee_count * 2500))
		tax_rate = float(payload.get("tax_rate", 0.24))
		net_pay_gbp = int(round(gross_pay_gbp * (1 - tax_rate)))

		self._write_json(
			200,
			{
				"tenant": self._tenant_payload(tenant),
				"period_start": payload.get("period_start", date.today().replace(day=1).isoformat()),
				"period_end": payload.get("period_end", date.today().isoformat()),
				"employee_count": employee_count,
				"gross_pay_gbp": gross_pay_gbp,
				"tax_rate": tax_rate,
				"net_pay_gbp": net_pay_gbp,
				"note": "preview_only",
			},
		)

	def log_message(self, format: str, *args: Any) -> None:
		return


def main() -> None:
	port = int(os.getenv("PORT", "8080"))
	server = HTTPServer(("0.0.0.0", port), PayrollAPIHandler)
	server.serve_forever()


if __name__ == "__main__":
	main()
