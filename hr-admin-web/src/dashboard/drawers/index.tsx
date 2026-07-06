import { useStore } from '../store';
import { avColor as avColorOf, ETYPE, FSTAT, initials as initialsOf, OTDUR, STAT, TYPE } from '../theme';
import type { LeaveType } from '../theme';
import { DOCS } from '../seed';
import { Pill } from '../ui';
import { IconExternal, IconFile, IconStar } from '../icons';
import { CloseButton, DrawerHeader, DrawerShell, HrOverrideFooter, InfoGrid, RemarkBlock } from './shell';
import { AddUserModal } from './AddUserModal';

function LeaveDrawer() {
  const s = useStore();
  const d = s.leaves.find((l) => l.id === s.drawerId);
  if (!d) return null;
  const close = () => { s.setDrawerId(null); s.cancelDecline(); };
  return (
    <DrawerShell onClose={close}>
      <DrawerHeader name={d.name} subtitle={`${d.team} · Applied ${d.applied}`} onClose={close} />
      <div style={{ padding: '20px 24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
          <Pill label={d.status} tone={STAT[d.status]} fontSize={13} padding="5px 13px" />
          <span style={{ display: 'flex', alignItems: 'center', gap: 7, fontSize: 13, fontWeight: 600, color: '#5C5448' }}>
            <span style={{ width: 8, height: 8, borderRadius: '50%', background: TYPE[d.type as LeaveType] }} />
            {d.type} leave
          </span>
        </div>
        <InfoGrid
          cells={[
            { label: 'DATES', value: d.from === d.to ? d.from : `${d.from} – ${d.to}` },
            { label: 'DURATION', value: d.days },
            { label: 'MANAGER', value: d.manager },
            { label: 'APPLIED ON', value: d.applied },
          ]}
        />
        <RemarkBlock label="EMPLOYEE REMARK" text={d.eRemark} filled marginBottom={16} />
        <RemarkBlock label="MANAGER REMARK" text={d.mRemark || 'No remark yet.'} filled={!!d.mRemark} marginBottom={8} />
      </div>
      {d.status === 'Pending' && (
        <HrOverrideFooter
          manager={d.manager}
          declineOpen={s.declineId === d.id}
          declineText={s.declineText}
          onDeclineInput={s.setDeclineText}
          onOpenDecline={() => s.openDecline(d.id)}
          onCancelDecline={s.cancelDecline}
          onConfirmDecline={() => s.confirmDecline(d.id)}
          onApprove={() => s.approve(d.id)}
        />
      )}
    </DrawerShell>
  );
}

function OvertimeDrawer() {
  const s = useStore();
  const d = s.ots.find((o) => o.id === s.otDrawerId);
  if (!d) return null;
  const close = () => { s.setOtDrawerId(null); s.otCancelDecline(); };
  return (
    <DrawerShell onClose={close}>
      <DrawerHeader name={d.name} subtitle={`${d.team} · Applied ${d.appliedOn}`} onClose={close} />
      <div style={{ padding: '20px 24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
          <Pill label={d.status} tone={STAT[d.status]} fontSize={13} padding="5px 13px" />
          <Pill label={d.duration} tone={OTDUR[d.duration]} fontSize={12.5} padding="5px 13px" />
        </div>
        <InfoGrid
          cells={[
            { label: 'OVERTIME DATE', value: d.otDate },
            { label: 'DAY', value: d.day },
            { label: 'DURATION', value: d.duration },
            { label: 'MANAGER', value: d.manager },
          ]}
        />
        <RemarkBlock label="MANAGER REMARK" text={d.mRemark || 'No remark yet.'} filled={!!d.mRemark} />
      </div>
      {d.status === 'Pending' && (
        <HrOverrideFooter
          manager={d.manager}
          declineOpen={s.otDeclineId === d.id}
          declineText={s.otDeclineText}
          onDeclineInput={s.setOtDeclineText}
          onOpenDecline={() => s.otOpenDecline(d.id)}
          onCancelDecline={s.otCancelDecline}
          onConfirmDecline={() => s.otConfirmDecline(d.id)}
          onApprove={() => s.otApprove(d.id)}
        />
      )}
    </DrawerShell>
  );
}

function FeedbackDrawer() {
  const s = useStore();
  const d = s.fbs.find((f) => f.id === s.fbDrawerId);
  if (!d) return null;
  const close = () => s.setFbDrawerId(null);
  return (
    <DrawerShell onClose={close}>
      <DrawerHeader name={d.name} subtitle={`${d.team} · Reviewed by ${d.manager}`} onClose={close} />
      <div style={{ padding: '20px 24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
          <Pill label={d.status} tone={FSTAT[d.status]} fontSize={13} padding="5px 13px" />
          <span style={{ fontSize: 13, fontWeight: 600, color: '#5C5448' }}>{d.date}</span>
        </div>
        <InfoGrid
          cells={[
            { label: 'PARAMETER', value: d.parameter },
            {
              label: 'RATING',
              value: (
                <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <IconStar /> {d.rating.toFixed(1)} / 5
                </span>
              ),
            },
          ]}
        />
        <div>
          <div style={{ fontSize: 11.5, color: '#A89C8B', fontWeight: 700, letterSpacing: '.3px', marginBottom: 7 }}>FEEDBACK</div>
          <div style={{ background: '#fff', border: '1px solid #EFE6D8', borderRadius: 12, padding: '14px 15px', fontSize: 13.5, color: '#5C5448', lineHeight: 1.6, fontWeight: 500 }}>{d.text}</div>
        </div>
      </div>
    </DrawerShell>
  );
}

function ReimbursementDrawer() {
  const s = useStore();
  const d = s.rbs.find((r) => r.id === s.rbDrawerId);
  if (!d) return null;
  const close = () => s.setRbDrawerId(null);
  return (
    <DrawerShell onClose={close}>
      <DrawerHeader name={d.name} subtitle={`${d.team} · Applied ${d.applyDate}`} onClose={close} />
      <div style={{ padding: '20px 24px' }}>
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', marginBottom: 18 }}>
          <div>
            <div style={{ fontSize: 11, color: '#A89C8B', fontWeight: 600, marginBottom: 3 }}>{d.type} claim</div>
            <div style={{ fontSize: 30, fontWeight: 800, letterSpacing: '-1px' }}>{d.amount}</div>
          </div>
          <Pill label={d.status} tone={STAT[d.status]} fontSize={13} padding="5px 13px" />
        </div>
        <InfoGrid
          cells={[
            { label: 'BILL DATE', value: d.billDate },
            { label: 'APPLIED ON', value: d.applyDate },
            { label: 'MANAGER', value: d.manager },
            { label: 'TYPE', value: d.type },
          ]}
        />
        <div style={{ marginBottom: 18 }}>
          <div style={{ fontSize: 11.5, color: '#A89C8B', fontWeight: 700, letterSpacing: '.3px', marginBottom: 7 }}>BILL ATTACHMENT</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, background: '#fff', border: '1px solid #EFE6D8', borderRadius: 12, padding: '13px 15px' }}>
            <div style={{ width: 38, height: 38, borderRadius: 9, background: '#F7E7DE', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <IconFile />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13, fontWeight: 700, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{d.bill}</div>
              <div style={{ fontSize: 11.5, color: '#A89C8B', fontWeight: 500 }}>Tap to preview</div>
            </div>
            <IconExternal />
          </div>
        </div>
        <RemarkBlock label="MANAGER REMARK" text={d.mRemark || 'No remark yet.'} filled={!!d.mRemark} />
      </div>
      {d.status === 'Pending' && (
        <div style={{ position: 'sticky', bottom: 0, background: '#FBF7F0', borderTop: '1px solid #ECE2D4', padding: '16px 24px', display: 'flex', gap: 11 }}>
          <button onClick={() => s.rbOpenDecline(d.id)} style={{ flex: 1, border: '1px solid #EBD9DE', background: '#FBF1F3', color: '#A8475F', borderRadius: 12, padding: 13, fontSize: 14, fontWeight: 700, cursor: 'pointer' }}>Decline</button>
          <button onClick={() => s.rbApprove(d.id)} style={{ flex: 1.4, border: 'none', background: '#4F7A52', color: '#fff', borderRadius: 12, padding: 13, fontSize: 14, fontWeight: 700, cursor: 'pointer' }}>Approve claim</button>
        </div>
      )}
    </DrawerShell>
  );
}

function EmployeeDrawer() {
  const s = useStore();
  const d = s.emps.find((e) => e.id === s.empDrawerId);
  if (!d) return null;
  const close = () => s.setEmpDrawerId(null);
  const docList = DOCS.slice(0, d.docs);
  return (
    <DrawerShell width={440} onClose={close}>
      <div style={{ padding: 24, borderBottom: '1px solid #ECE2D4' }}>
        <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: -12 }}>
          <CloseButton onClose={close} />
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
          <div style={{ width: 78, height: 78, borderRadius: '50%', color: '#fff', fontWeight: 800, fontSize: 28, display: 'flex', alignItems: 'center', justifyContent: 'center', background: avColorOf(d.name), marginBottom: 13 }}>
            {initialsOf(d.name)}
          </div>
          <div style={{ fontSize: 19, fontWeight: 800, letterSpacing: '-.3px' }}>{d.name}</div>
          <div style={{ fontSize: 13, color: '#9B9082', fontWeight: 600, marginTop: 3 }}>{d.role} · {d.id}</div>
          <span style={{ marginTop: 11 }}>
            <Pill label={d.empType} tone={ETYPE[d.empType]} fontSize={12} padding="5px 13px" />
          </span>
        </div>
      </div>
      <div style={{ padding: '20px 24px' }}>
        <div style={{ marginBottom: 18 }}>
          <InfoGrid
            cells={[
              { label: 'TEAM', value: d.team },
              { label: 'LOCATION', value: d.location },
              { label: 'DATE OF BIRTH', value: d.dob },
              { label: 'JOINED', value: d.joining },
              { label: 'MANAGER', value: d.manager },
              { label: 'MANAGER ID', value: d.managerId },
            ]}
          />
        </div>
        <div>
          <div style={{ fontSize: 11.5, color: '#A89C8B', fontWeight: 700, letterSpacing: '.3px', marginBottom: 9 }}>DOCUMENTS · {d.docs}</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {docList.map((doc) => (
              <div key={doc} style={{ display: 'flex', alignItems: 'center', gap: 11, background: '#fff', border: '1px solid #EFE6D8', borderRadius: 11, padding: '11px 13px' }}>
                <div style={{ width: 32, height: 32, borderRadius: 8, background: '#EFE7F2', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <IconFile size={16} stroke="#7E5FB0" />
                </div>
                <div style={{ flex: 1, fontSize: 12.5, fontWeight: 700, color: '#5C5448', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{doc}</div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#B7AC9B" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M12 3v12M7 10l5 5 5-5M5 21h14" />
                </svg>
              </div>
            ))}
          </div>
        </div>
      </div>
    </DrawerShell>
  );
}

export function Drawers() {
  return (
    <>
      <LeaveDrawer />
      <OvertimeDrawer />
      <FeedbackDrawer />
      <ReimbursementDrawer />
      <EmployeeDrawer />
      <AddUserModal />
    </>
  );
}
