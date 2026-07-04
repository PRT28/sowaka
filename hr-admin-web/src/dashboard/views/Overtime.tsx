import { useStore } from '../store';
import { OTDUR, STAT } from '../theme';
import type { ReqStatus } from '../theme';
import { Avatar, Card, EmptyRow, Pill, SearchInput, StatusTabs, SummaryCard } from '../ui';
import { IconDownload } from '../icons';

const COLS = '1.9fr 1.1fr 1.1fr 1.1fr .9fr 1.1fr';

export function Overtime() {
  const s = useStore();
  const all = s.ots;
  const summary = {
    total: all.length,
    pending: all.filter((r) => r.status === 'Pending').length,
    approved: all.filter((r) => r.status === 'Approved').length,
    declined: all.filter((r) => r.status === 'Declined').length,
  };

  let rows = all.slice();
  const q = s.otSearch.trim().toLowerCase();
  if (q) rows = rows.filter((r) => r.name.toLowerCase().includes(q));
  if (s.otStatus !== 'all') rows = rows.filter((r) => r.status === s.otStatus);
  rows.sort((a, b) => b.ord - a.ord);

  return (
    <div style={{ animation: 'fade .3s ease both' }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 14, marginBottom: 20 }}>
        <SummaryCard label="Total requests" value={summary.total} />
        <SummaryCard label="Pending" value={summary.pending} color="#9A6B25" />
        <SummaryCard label="Approved" value={summary.approved} color="#4F7A52" />
        <SummaryCard label="Declined" value={summary.declined} color="#A8475F" />
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 11, marginBottom: 14, flexWrap: 'wrap' }}>
        <SearchInput value={s.otSearch} onChange={s.setOtSearch} placeholder="Search by employee…" />
        <StatusTabs<ReqStatus | 'all'>
          options={['all', 'Pending', 'Approved', 'Declined']}
          active={s.otStatus}
          onSelect={s.setOtStatus}
        />
        <button
          onClick={() => s.flash(`Exported ${rows.length} overtime rows to CSV`)}
          style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 8, background: '#2A2420', border: 'none', color: '#fff', borderRadius: 11, padding: '9px 15px', fontSize: 12.5, fontWeight: 700, cursor: 'pointer' }}
        >
          <IconDownload /> Export
        </button>
      </div>

      <Card>
        <div style={{ display: 'grid', gridTemplateColumns: COLS, gap: 12, padding: '14px 22px', borderBottom: '1px solid #F0E8DB', fontSize: 11, fontWeight: 700, letterSpacing: '.5px', color: '#A89C8B' }}>
          <div>EMPLOYEE</div>
          <div>APPLIED ON</div>
          <div>OVERTIME DATE</div>
          <div>DURATION</div>
          <div>DAY</div>
          <div>STATUS</div>
        </div>
        {rows.map((r) => (
          <div
            key={r.id}
            className="dc-row"
            onClick={() => s.setOtDrawerId(r.id)}
            style={{ display: 'grid', gridTemplateColumns: COLS, gap: 12, padding: '14px 22px', borderBottom: '1px solid #F4EEE3', alignItems: 'center', cursor: 'pointer', transition: 'background .12s' }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 11, minWidth: 0 }}>
              <Avatar name={r.name} />
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: 13.5, fontWeight: 700, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.name}</div>
                <div style={{ fontSize: 11.5, color: '#A89C8B', fontWeight: 500 }}>{r.team}</div>
              </div>
            </div>
            <div style={{ fontSize: 13, fontWeight: 600, color: '#5C5448' }}>{r.appliedOn}</div>
            <div style={{ fontSize: 13, fontWeight: 600, color: '#5C5448' }}>{r.otDate}</div>
            <div>
              <Pill label={r.duration} tone={OTDUR[r.duration]} />
            </div>
            <div style={{ fontSize: 13, fontWeight: 600, color: '#5C5448' }}>{r.day}</div>
            <div>
              <Pill label={r.status} tone={STAT[r.status]} />
            </div>
          </div>
        ))}
        {rows.length === 0 && <EmptyRow text="No overtime requests match your filters." />}
      </Card>
    </div>
  );
}
