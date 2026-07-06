import { useStore } from '../store';
import { PH } from '../theme';
import { phIcon } from '../icons';

export function Placeholder() {
  const s = useStore();
  const ph = PH[s.view];
  if (!ph) return null;
  return (
    <div style={{ animation: 'fade .3s ease both', display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 520 }}>
      <div style={{ maxWidth: 480, textAlign: 'center' }}>
        <div style={{ width: 76, height: 76, borderRadius: 22, background: '#fff', border: '1px solid #EFE6D8', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 22px' }}>
          <div style={{ color: '#BE5A36' }}>{phIcon[s.view]}</div>
        </div>
        {ph.soon && (
          <span style={{ display: 'inline-block', fontSize: 11, fontWeight: 700, letterSpacing: '.6px', color: '#9A6B25', background: '#F6E9D5', borderRadius: 20, padding: '4px 12px', marginBottom: 14 }}>
            COMING SOON
          </span>
        )}
        <div style={{ fontSize: 23, fontWeight: 800, letterSpacing: '-.5px', marginBottom: 9 }}>{ph.title}</div>
        <div style={{ fontSize: 14, color: '#8B8378', fontWeight: 500, lineHeight: 1.55, marginBottom: 22 }}>{ph.desc}</div>
        {ph.fields.length > 0 && (
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, justifyContent: 'center' }}>
            {ph.fields.map((f) => (
              <span key={f} style={{ fontSize: 12, fontWeight: 600, color: '#6E6457', background: '#fff', border: '1px solid #EFE6D8', borderRadius: 9, padding: '6px 12px' }}>{f}</span>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
