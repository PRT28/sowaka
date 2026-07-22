/**
 * Imports attendance punches from PostgreSQL, MySQL, or SQL Server into MongoDB.
 * All connection details, table/column names, and the incremental window are
 * configured with environment variables; see backend/.env.example.
 */
import { createHash } from 'node:crypto';
import { connectDb, closeDb, getDb, users } from '../config/db';

type Dialect = 'postgres' | 'mysql' | 'mssql';
type SourceRow = Record<string, unknown>;

const dialect = required('ATTENDANCE_SQL_DIALECT').toLowerCase() as Dialect;
const table = identifier(required('ATTENDANCE_SQL_TABLE'));
const employeeColumn = identifier(process.env.ATTENDANCE_SQL_EMPLOYEE_COLUMN ?? 'employee_id');
const dateColumn = identifier(process.env.ATTENDANCE_SQL_DATE_COLUMN ?? 'work_date');
const inColumn = identifier(process.env.ATTENDANCE_SQL_IN_COLUMN ?? 'punch_in');
const outColumn = identifier(process.env.ATTENDANCE_SQL_OUT_COLUMN ?? 'punch_out');
const sourceIdColumn = process.env.ATTENDANCE_SQL_ID_COLUMN
  ? identifier(process.env.ATTENDANCE_SQL_ID_COLUMN) : undefined;
const lookbackDays = positiveInt(process.env.ATTENDANCE_IMPORT_LOOKBACK_DAYS ?? '7');
const batchSize = positiveInt(process.env.ATTENDANCE_IMPORT_BATCH_SIZE ?? '500');

async function main() {
  if (!['postgres', 'mysql', 'mssql'].includes(dialect)) {
    throw new Error('ATTENDANCE_SQL_DIALECT must be postgres, mysql, or mssql');
  }
  await connectDb();
  const since = process.env.ATTENDANCE_IMPORT_FROM ?? isoDate(new Date(Date.now() - lookbackDays * 86_400_000));
  const rows = await readRows(since);
  const employeeIds = [...new Set(rows.map((row) => String(row.employee_id ?? '').trim()).filter(Boolean))];
  const userRows = await users().find({ employeeId: { $in: employeeIds } }).project({ employeeId: 1, userId: 1 }).toArray();
  const userByEmployee = new Map(userRows.map((item) => [item.employeeId, item.userId]));
  const collection = getDb().collection('attendance_records');
  let imported = 0;
  for (let offset = 0; offset < rows.length; offset += batchSize) {
    const operations = rows.slice(offset, offset + batchSize).flatMap((row) => {
      const employeeId = String(row.employee_id ?? '').trim();
      const workDate = normalizeDate(row.work_date);
      if (!employeeId || !workDate) return [];
      const sourceIdentity = sourceIdColumn
        ? String(row.source_id ?? '')
        : `${employeeId}|${workDate}`;
      const sourceKey = createHash('sha256')
        .update(`${dialect}|${table}|${sourceIdentity}`).digest('hex');
      const now = new Date();
      return [{
        updateOne: {
          filter: { sourceKey },
          update: {
            $set: {
              employeeId, userId: userByEmployee.get(employeeId), workDate,
              punchIn: normalizeTimestamp(row.punch_in),
              punchOut: normalizeTimestamp(row.punch_out),
              source: 'sql_import', sourceKey, importedAt: now, updatedAt: now,
            },
          },
          upsert: true,
        },
      }];
    });
    if (operations.length) {
      await collection.bulkWrite(operations, { ordered: false });
      imported += operations.length;
    }
  }
  console.log(`Attendance import complete: ${imported} row(s) upserted from ${since}.`);
}

async function readRows(since: string): Promise<SourceRow[]> {
  const selectedId = sourceIdColumn ? `, ${quote(sourceIdColumn)} AS source_id` : '';
  const sql = `SELECT ${quote(employeeColumn)} AS employee_id, ${quote(dateColumn)} AS work_date, ${quote(inColumn)} AS punch_in, ${quote(outColumn)} AS punch_out${selectedId} FROM ${quotePath(table)} WHERE ${quote(dateColumn)} >= ${dialect === 'postgres' ? '$1' : dialect === 'mysql' ? '?' : '@since'}`;
  if (dialect === 'postgres') {
    const { Client } = await import('pg');
    const client = new Client({ connectionString: required('ATTENDANCE_SQL_URL') });
    await client.connect();
    try { return (await client.query(sql, [since])).rows; } finally { await client.end(); }
  }
  if (dialect === 'mysql') {
    const mysql = await import('mysql2/promise');
    const connection = await mysql.createConnection(required('ATTENDANCE_SQL_URL'));
    try { const [rows] = await connection.query(sql, [since]); return rows as SourceRow[]; }
    finally { await connection.end(); }
  }
  const mssql = await import('mssql');
  const pool = await mssql.connect(required('ATTENDANCE_SQL_URL'));
  try { return (await pool.request().input('since', mssql.Date, new Date(`${since}T00:00:00Z`)).query(sql)).recordset; }
  finally { await pool.close(); }
}

function quote(value: string) { return dialect === 'mysql' ? `\`${value}\`` : dialect === 'mssql' ? `[${value}]` : `"${value}"`; }
function quotePath(value: string) { return value.split('.').map(quote).join('.'); }
function identifier(value: string) {
  if (!/^[A-Za-z_][A-Za-z0-9_.]*$/.test(value)) throw new Error(`Unsafe SQL identifier: ${value}`);
  return value;
}
function required(name: string) { const value = process.env[name]?.trim(); if (!value) throw new Error(`${name} is required`); return value; }
function positiveInt(value: string) { const n = Number(value); if (!Number.isInteger(n) || n < 1) throw new Error(`Expected positive integer, got ${value}`); return n; }
function isoDate(value: Date) { return value.toISOString().slice(0, 10); }
function normalizeDate(value: unknown) { const date = value instanceof Date ? value : new Date(String(value)); return Number.isNaN(date.getTime()) ? undefined : isoDate(date); }
function normalizeTimestamp(value: unknown) { if (value == null || value === '') return undefined; const date = value instanceof Date ? value : new Date(String(value)); return Number.isNaN(date.getTime()) ? undefined : date; }

main().catch((error) => { console.error(error); process.exitCode = 1; }).finally(closeDb);
