import { useStore } from '../store';
import { ETYPE } from '../theme';
import { Avatar, Card, EmptyRow, Pill, SearchInput, SelectBox } from '../ui';
import { IconPlus } from '../icons';

const COLS = '2fr 1.4fr 1fr 1.1fr 1fr 1.3fr 1fr';

export function Employees() {
  const s = useStore();
  let rows = s.emps.slice();
  const q = s.empSearch.trim().toLowerCase();
  if (q) rows = rows.filter((r) => r.name.toLowerCase().includes(q) || r.id.toLowerCase().includes(q) || r.role.toLowerCase().includes(q));
  if (s.empTeam !== 'all') rows = rows.filter((r) => r.team === s.empTeam);

  return (
    <div style={{ animation: 'fade .3s ease both' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 11, marginBottom: 16, flexWrap: 'wrap' }}>
        <SearchInput value={s.empSearch} onChange={s.setEmpSearch} placeholder="Search name, ID or role…" width={280} />
        <SelectBox value={s.empTeam} onChange={s.setEmpTeam}>
          <option value="all">All teams</option>
          <option value="Design">Design</option>
          <option value="Engineering">Engineering</option>
          <option value="Sales">Sales</option>
          <option value="Marketing">Marketing</option>
          <option value="Operations">Operations</option>
          <option value="Finance">Finance</option>
        </SelectBox>
        <div style={{ marginLeft: 'auto', fontSize: 13, color: '#9B9082', fontWeight: 600 }}>{s.emps.length} people</div>
        <button
          onClick={() => s.setAddOpen(true)}
          style={{ display: 'flex', alignItems: 'center', gap: 8, background: '#BE5A36', border: 'none', color: '#fff', borderRadius: 11, padding: '9px 16px', fontSize: 13, fontWeight: 700, cursor: 'pointer', boxShadow: '0 2px 8px rgba(190,90,54,.26)' }}
        >
          <IconPlus /> Add user
        </button>
      </div>

      <Card>
        <div style={{ display: 'grid', gridTemplateColumns: COLS, gap: 12, padding: '14px 22px', borderBottom: '1px solid #F0E8DB', fontSize: 11, fontWeight: 700, letterSpacing: '.5px', color: '#A89C8B' }}>
          <div>EMPLOYEE</div>
          <div>ROLE</div>
          <div>TEAM</div>
          <div>LOCATION</div>
          <div>TYPE</div>
          <div>MANAGER</div>
          <div>JOINED</div>
        </div>
        {rows.map((r) => (
          <div
            key={r.id}
            className="dc-row"
            onClick={() => s.setEmpDrawerId(r.id)}
            style={{ display: 'grid', gridTemplateColumns: COLS, gap: 12, padding: '13px 22px', borderBottom: '1px solid #F4EEE3', alignItems: 'center', cursor: 'pointer', transition: 'background .12s' }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 11, minWidth: 0 }}>
              <Avatar name={r.name} size={38} font={13.5} />
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: 13.5, fontWeight: 700, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.name}</div>
                <div style={{ fontSize: 11.5, color: '#A89C8B', fontWeight: 600 }}>{r.id}</div>
              </div>
            </div>
            <div style={{ fontSize: 13, fontWeight: 600, color: '#5C5448', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.role}</div>
            <div style={{ fontSize: 13, fontWeight: 600, color: '#5C5448' }}>{r.team}</div>
            <div style={{ fontSize: 13, fontWeight: 600, color: '#5C5448' }}>{r.location}</div>
            <div>
              <Pill label={r.empType} tone={ETYPE[r.empType]} />
            </div>
            <div style={{ fontSize: 13, fontWeight: 600, color: '#5C5448', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.manager}</div>
            <div style={{ fontSize: 13, fontWeight: 600, color: '#5C5448' }}>{r.joining}</div>
          </div>
        ))}
        {rows.length === 0 && <EmptyRow text="No employees match your search." />}
      </Card>
    </div>
  );
}
