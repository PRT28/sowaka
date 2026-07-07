// Client-side CSV export. Builds a CSV blob from column defs + rows and triggers
// a download. Used by the Leaves / Overtime / Reimbursement / Feedback views.

export type Column<T> = { header: string; value: (row: T) => string | number };

function escapeCell(input: string | number): string {
  const s = String(input ?? '');
  // Quote if the cell contains a comma, quote, or newline; double up quotes.
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

export function toCsv<T>(columns: Column<T>[], rows: T[]): string {
  const head = columns.map((c) => escapeCell(c.header)).join(',');
  const body = rows
    .map((r) => columns.map((c) => escapeCell(c.value(r))).join(','))
    .join('\n');
  return `${head}\n${body}`;
}

export function downloadCsv<T>(filename: string, columns: Column<T>[], rows: T[]): void {
  const csv = toCsv(columns, rows);
  // Prepend BOM so Excel opens UTF-8 (₹ etc.) correctly.
  const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename.endsWith('.csv') ? filename : `${filename}.csv`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
