// Small reusable presentational pieces used across views.
import type { CSSProperties, ReactNode } from 'react';
import type { Pill as PillT } from './theme';
import { avColor, initials } from './theme';
import { IconChevronDown, IconSearch } from './icons';

export function Avatar({
  name,
  size = 36,
  font = 13,
}: {
  name: string;
  size?: number;
  font?: number;
}) {
  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: '50%',
        color: '#fff',
        fontWeight: 700,
        fontSize: font,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0,
        background: avColor(name),
      }}
    >
      {initials(name)}
    </div>
  );
}

export function Pill({
  label,
  tone,
  fontSize = 11.5,
  padding = '4px 11px',
  fontWeight = 700,
}: {
  label: ReactNode;
  tone: PillT;
  fontSize?: number;
  padding?: string;
  fontWeight?: number;
}) {
  return (
    <span
      style={{
        fontSize,
        fontWeight,
        padding,
        borderRadius: 20,
        background: tone.bg,
        color: tone.fg,
      }}
    >
      {label}
    </span>
  );
}

export function SummaryCard({
  label,
  value,
  color = '#2A2420',
}: {
  label: string;
  value: ReactNode;
  color?: string;
}) {
  return (
    <div style={{ background: '#fff', border: '1px solid #EFE6D8', borderRadius: 15, padding: '15px 17px' }}>
      <div style={{ fontSize: 12, color: '#9B9082', fontWeight: 600 }}>{label}</div>
      <div style={{ fontSize: 24, fontWeight: 800, letterSpacing: '-.6px', marginTop: 3, color }}>{value}</div>
    </div>
  );
}

export function SearchInput({
  value,
  onChange,
  placeholder,
  width = 262,
}: {
  value: string;
  onChange: (v: string) => void;
  placeholder: string;
  width?: number;
}) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', background: '#fff', border: '1px solid #EBE1D2', borderRadius: 11, padding: '9px 13px', gap: 9, width }}>
      <IconSearch />
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        style={{ border: 'none', outline: 'none', background: 'none', fontSize: 13, width: '100%', color: '#2A2420' }}
      />
    </div>
  );
}

export function StatusTabs<T extends string>({
  options,
  active,
  onSelect,
  labels,
}: {
  options: T[];
  active: T;
  onSelect: (v: T) => void;
  labels?: Partial<Record<T, string>>;
}) {
  return (
    <div style={{ display: 'flex', background: '#fff', border: '1px solid #EBE1D2', borderRadius: 11, padding: 3, gap: 2 }}>
      {options.map((opt) => {
        const on = active === opt;
        return (
          <button
            key={opt}
            onClick={() => onSelect(opt)}
            style={{
              border: 'none',
              cursor: 'pointer',
              fontSize: 12.5,
              fontWeight: 700,
              padding: '6px 13px',
              borderRadius: 8,
              background: on ? '#2A2420' : 'transparent',
              color: on ? '#fff' : '#8B8378',
            }}
          >
            {labels?.[opt] ?? (opt === ('all' as T) ? 'All' : opt)}
          </button>
        );
      })}
    </div>
  );
}

export function SelectBox({
  value,
  onChange,
  children,
}: {
  value: string;
  onChange: (v: string) => void;
  children: ReactNode;
}) {
  return (
    <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        style={{
          appearance: 'none',
          WebkitAppearance: 'none',
          background: '#fff',
          border: '1px solid #EBE1D2',
          borderRadius: 11,
          padding: '9px 32px 9px 13px',
          fontSize: 12.5,
          fontWeight: 700,
          color: '#6E6457',
          cursor: 'pointer',
        }}
      >
        {children}
      </select>
      <IconChevronDown style={{ position: 'absolute', right: 11, pointerEvents: 'none' }} />
    </div>
  );
}

export function Card({ children, style }: { children: ReactNode; style?: CSSProperties }) {
  return (
    <div style={{ background: '#fff', border: '1px solid #EFE6D8', borderRadius: 18, overflow: 'hidden', ...style }}>
      {children}
    </div>
  );
}

export function EmptyRow({ text }: { text: string }) {
  return (
    <div style={{ padding: 48, textAlign: 'center', color: '#A89C8B', fontSize: 13.5, fontWeight: 600 }}>
      {text}
    </div>
  );
}
