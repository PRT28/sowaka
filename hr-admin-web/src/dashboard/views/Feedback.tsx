import { useStore } from '../store';
import type { Pill as PillT } from '../theme';
import type { Feedback as FeedbackRow } from '../seed';
import { inDateRange } from '../adapters';
import { downloadCsv } from '../export';
import { Avatar, Card, DateRange, EmptyRow, Pill, SearchInput } from '../ui';
import { IconBell, IconCheck, IconDownload, IconStar } from '../icons';

const COLS = '1.7fr 1.3fr .8fr 1.4fr 1.3fr 1fr';

export function Feedback() {
  const s = useStore();
  const mgrs = s.fbMgrs;
  const totDone = mgrs.reduce((a, m) => a + m.done, 0);
  const totExp = mgrs.reduce((a, m) => a + m.total, 0);
  const mgrsPend = mgrs.filter((m) => m.done < m.total);
  const fbSummary = {
    done: totDone,
    total: totExp,
    pct: totExp ? Math.round((totDone / totExp) * 100) : 0,
    mgrsDone: mgrs.filter((m) => m.done >= m.total).length,
    mgrsCount: mgrs.length,
  };
  const hasPending = mgrsPend.length > 0;

  let rows = s.fbs.slice();
  const q = s.fbSearch.trim().toLowerCase();
  if (q) rows = rows.filter((r) => r.name.toLowerCase().includes(q) || r.parameter.toLowerCase().includes(q));
  rows = rows.filter((r) => inDateRange(r.refISO, s.fbFrom, s.fbTo));
  rows.sort((a, b) => b.ord - a.ord);
  const exportRows = () =>
    downloadCsv<FeedbackRow>(
      'feedback',
      [
        { header: 'Employee', value: (r) => r.name },
        { header: 'Team', value: (r) => r.team },
        { header: 'Parameter', value: (r) => r.parameter },
        { header: 'Rating', value: (r) => r.rating.toFixed(1) },
        { header: 'Rating description', value: (r) => r.ratingDesc },
        { header: 'Note', value: (r) => r.note },
        { header: 'Manager', value: (r) => r.manager },
        { header: 'Date', value: (r) => r.date },
      ],
      rows,
    );

  return (
    <div style={{ animation: 'fade .3s ease both' }}>
      {/* cycle completion tracker */}
      <div style={{ background: '#fff', border: '1px solid #EFE6D8', borderRadius: 18, padding: '20px 22px', marginBottom: 18, display: 'flex', alignItems: 'center', gap: 26 }}>
        <div style={{ flexShrink: 0 }}>
          <div style={{ fontSize: 12, color: '#9B9082', fontWeight: 600, marginBottom: 2 }}>June review cycle · due 5 Jul</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
            <span style={{ fontSize: 30, fontWeight: 800, letterSpacing: '-1px' }}>{fbSummary.pct}%</span>
            <span style={{ fontSize: 13, color: '#8B8378', fontWeight: 600 }}>complete</span>
          </div>
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, fontWeight: 600, color: '#8B8378', marginBottom: 7 }}>
            <span>{fbSummary.done} of {fbSummary.total} reviews submitted</span>
            <span>{fbSummary.mgrsDone}/{fbSummary.mgrsCount} managers done</span>
          </div>
          <div style={{ height: 10, borderRadius: 20, background: '#F0E8DB', overflow: 'hidden' }}>
            <div style={{ width: `${fbSummary.pct}%`, height: '100%', background: '#BE5A36', borderRadius: 20, transition: 'width .3s' }} />
          </div>
        </div>
        {hasPending && (
          <button
            onClick={s.remindAll}
            style={{ flexShrink: 0, display: 'flex', alignItems: 'center', gap: 8, background: '#BE5A36', border: 'none', color: '#fff', borderRadius: 11, padding: '11px 17px', fontSize: 13, fontWeight: 700, cursor: 'pointer', boxShadow: '0 2px 8px rgba(190,90,54,.26)' }}
          >
            <IconBell size={16} stroke="#fff" /> Remind pending
          </button>
        )}
      </div>

      {/* per-manager list */}
      <div style={{ marginBottom: 22 }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '.5px', color: '#A89C8B', padding: '0 2px 10px' }}>MANAGERS · REVIEW COMPLETION</div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2,1fr)', gap: 14 }}>
          {mgrs.map((m) => {
            const done = m.done >= m.total;
            const started = m.done > 0;
            const st: PillT & { label: string } = done
              ? { label: 'Complete', bg: '#E4EDE0', fg: '#4F7A52' }
              : started
                ? { label: 'In progress', bg: '#F6E9D5', fg: '#9A6B25' }
                : { label: 'Not started', bg: '#F4DEE2', fg: '#A8475F' };
            const pct = m.total ? Math.round((m.done / m.total) * 100) : 0;
            return (
              <div key={m.id} style={{ background: '#fff', border: '1px solid #EFE6D8', borderRadius: 16, padding: '16px 18px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14 }}>
                  <Avatar name={m.name} size={40} font={14} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 14, fontWeight: 700 }}>{m.name}</div>
                    <div style={{ fontSize: 11.5, color: '#A89C8B', fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{m.scope}</div>
                  </div>
                  <Pill label={st.label} tone={st} />
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 13 }}>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11.5, fontWeight: 600, color: '#8B8378', marginBottom: 6 }}>
                      <span>{m.done} of {m.total} reviews</span>
                      <span>{pct}%</span>
                    </div>
                    <div style={{ height: 8, borderRadius: 20, background: '#F0E8DB', overflow: 'hidden' }}>
                      <div style={{ width: `${pct}%`, height: '100%', background: '#BE5A36', borderRadius: 20 }} />
                    </div>
                  </div>
                  {done ? (
                    <div style={{ flexShrink: 0, display: 'flex', alignItems: 'center', gap: 6, color: '#4F7A52', fontSize: 12.5, fontWeight: 700 }}>
                      <IconCheck size={16} stroke="#4F7A52" />
                      Done
                    </div>
                  ) : (
                    <button
                      onClick={(e) => { e.stopPropagation(); s.remindMgr(m.id); }}
                      style={{ flexShrink: 0, border: 'none', borderRadius: 9, padding: '8px 14px', fontSize: 12.5, fontWeight: 700, cursor: 'pointer', background: m.reminded ? '#EFEAE1' : '#2A2420', color: m.reminded ? '#9B9082' : '#fff' }}
                    >
                      {m.reminded ? 'Reminded' : 'Remind'}
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '.5px', color: '#A89C8B', padding: '0 2px 10px' }}>SUBMITTED FEEDBACK</div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 11, marginBottom: 14, flexWrap: 'wrap' }}>
        <SearchInput value={s.fbSearch} onChange={s.setFbSearch} placeholder="Search employee or parameter…" />
        <DateRange from={s.fbFrom} to={s.fbTo} onFrom={s.setFbFrom} onTo={s.setFbTo} />
        <button
          onClick={exportRows}
          disabled={rows.length === 0}
          style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 8, background: '#2A2420', border: 'none', color: '#fff', borderRadius: 11, padding: '9px 15px', fontSize: 12.5, fontWeight: 700, cursor: rows.length ? 'pointer' : 'not-allowed', opacity: rows.length ? 1 : 0.5 }}
        >
          <IconDownload /> Export
        </button>
      </div>

      <Card>
        <div style={{ display: 'grid', gridTemplateColumns: COLS, gap: 12, padding: '14px 22px', borderBottom: '1px solid #F0E8DB', fontSize: 11, fontWeight: 700, letterSpacing: '.5px', color: '#A89C8B' }}>
          <div>EMPLOYEE</div>
          <div>PARAMETER</div>
          <div>RATING</div>
          <div>DESCRIPTION</div>
          <div>MANAGER</div>
          <div>DATE</div>
        </div>
        {rows.map((r) => (
          <div
            key={r.id}
            className="dc-row"
            onClick={() => s.setFbDrawerId(r.id)}
            style={{ display: 'grid', gridTemplateColumns: COLS, gap: 12, padding: '14px 22px', borderBottom: '1px solid #F4EEE3', alignItems: 'center', cursor: 'pointer', transition: 'background .12s', background: r.isOverall ? '#FBF8F2' : 'transparent' }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 11, minWidth: 0 }}>
              <Avatar name={r.name} />
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: 13.5, fontWeight: 700, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.name}</div>
                <div style={{ fontSize: 11.5, color: '#A89C8B', fontWeight: 500 }}>{r.team}</div>
              </div>
            </div>
            <div style={{ fontSize: 13, fontWeight: r.isOverall ? 800 : 600, color: r.isOverall ? '#2A2420' : '#5C5448' }}>{r.parameter}</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
              <IconStar />
              <span style={{ fontSize: 13.5, fontWeight: 700 }}>{r.rating > 0 ? r.rating.toFixed(1) : '—'}</span>
            </div>
            <div style={{ fontSize: 12.5, fontWeight: 600, color: '#6E6457', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }} title={r.ratingDesc}>{r.ratingDesc}</div>
            <div style={{ fontSize: 13, fontWeight: 600, color: '#5C5448', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.manager}</div>
            <div style={{ fontSize: 13, fontWeight: 600, color: '#5C5448' }}>{r.date}</div>
          </div>
        ))}
        {rows.length === 0 && <EmptyRow text="No feedback matches your filters." />}
      </Card>
    </div>
  );
}
