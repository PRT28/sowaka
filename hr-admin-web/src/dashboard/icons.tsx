// SVG icons from the design handoff, as React components.
import type { CSSProperties, ReactElement } from 'react';
import type { View } from './theme';

type IconProps = { size?: number; stroke?: string; style?: CSSProperties };

const base = (size: number, stroke: string, style?: CSSProperties) => ({
  width: size,
  height: size,
  viewBox: '0 0 24 24',
  fill: 'none' as const,
  stroke,
  strokeWidth: 1.7,
  strokeLinecap: 'round' as const,
  strokeLinejoin: 'round' as const,
  style,
});

export const Logo = () => (
  <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">
    <path d="M5 16c2.5-1 4-3 4-6" />
    <path d="M19 8c-2.5 1-4 3-4 6" />
    <path d="M5 16c3 1.6 11 1.6 14-8" />
  </svg>
);

// ---- Nav / section icons (18px, currentColor) ----
export const navIcon: Record<View, ReactElement> = {
  games: (
    <svg {...base(18, 'currentColor')}>
      <path d="M7 8h10a4 4 0 0 1 3.7 5.5l-1.2 3a2 2 0 0 1-3.2.8L14.8 16H9.2l-1.5 1.3a2 2 0 0 1-3.2-.8l-1.2-3A4 4 0 0 1 7 8z" />
      <path d="M8 11v4M6 13h4M16 12h.01M18 14h.01" />
    </svg>
  ),
  overview: (
    <svg {...base(18, 'currentColor')}>
      <rect x="3" y="3" width="7" height="9" rx="1.5" />
      <rect x="14" y="3" width="7" height="5" rx="1.5" />
      <rect x="14" y="12" width="7" height="9" rx="1.5" />
      <rect x="3" y="16" width="7" height="5" rx="1.5" />
    </svg>
  ),
  leave: (
    <svg {...base(18, 'currentColor')}>
      <rect x="3" y="4.5" width="18" height="16.5" rx="2.5" />
      <path d="M3 9h18M8 2.5v4M16 2.5v4" />
    </svg>
  ),
  overtime: (
    <svg {...base(18, 'currentColor')}>
      <circle cx="12" cy="13" r="8" />
      <path d="M12 9.5V13l2.5 2M9 2.5h6M12 2.5v3" />
    </svg>
  ),
  attendance: (
    <svg {...base(18, 'currentColor')}>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7.5V12l3 2" />
    </svg>
  ),
  feedback: (
    <svg {...base(18, 'currentColor')}>
      <path d="M21 11.5a8.38 8.38 0 0 1-9 8.3 8.5 8.5 0 0 1-3.8-.9L3 20.5l1.6-4.2A8.4 8.4 0 0 1 12 3.2a8.38 8.38 0 0 1 9 8.3z" />
    </svg>
  ),
  reimbursements: (
    <svg {...base(18, 'currentColor')}>
      <path d="M5 3h14v18l-2.5-1.5L14 21l-2-1.5L10 21l-2.5-1.5L5 21z" />
      <path d="M9 8h6M9 12h6" />
    </svg>
  ),
  onboarding: (
    <svg {...base(18, 'currentColor')}>
      <path d="M16 19v-1.5A3.5 3.5 0 0 0 12.5 14h-5A3.5 3.5 0 0 0 4 17.5V19" />
      <circle cx="10" cy="7.5" r="3.5" />
      <path d="M19 8v6M22 11h-6" />
    </svg>
  ),
  exit: (
    <svg {...base(18, 'currentColor')}>
      <path d="M14 21H6a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h8" />
      <path d="M17 16l4-4-4-4M21 12H9" />
    </svg>
  ),
  payroll: (
    <svg {...base(18, 'currentColor')}>
      <rect x="2.5" y="6" width="19" height="13" rx="2.5" />
      <path d="M2.5 10.5h19" />
      <circle cx="17.5" cy="14.5" r="1.3" />
    </svg>
  ),
  employees: (
    <svg {...base(18, 'currentColor')}>
      <circle cx="9" cy="8" r="3.2" />
      <path d="M3.5 19v-1A3.5 3.5 0 0 1 7 14.5h4A3.5 3.5 0 0 1 14.5 18v1" />
      <path d="M16.5 5.2a3.2 3.2 0 0 1 0 6M18.5 14.7a3.5 3.5 0 0 1 2 3.1V19" />
    </svg>
  ),
  orgchart: (
    <svg {...base(18, 'currentColor')}>
      <rect x="9" y="3" width="6" height="5" rx="1.3" />
      <rect x="2.5" y="16" width="6" height="5" rx="1.3" />
      <rect x="15.5" y="16" width="6" height="5" rx="1.3" />
      <path d="M12 8v4M5.5 16v-2.5h13V16" />
    </svg>
  ),
};

// Large placeholder icons (34px, currentColor)
export const phIcon: Partial<Record<View, ReactElement>> = {
  attendance: (
    <svg {...base(34, 'currentColor')} strokeWidth={1.6}>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7.5V12l3 2" />
    </svg>
  ),
  onboarding: (
    <svg {...base(34, 'currentColor')} strokeWidth={1.6}>
      <path d="M16 19v-1.5A3.5 3.5 0 0 0 12.5 14h-5A3.5 3.5 0 0 0 4 17.5V19" />
      <circle cx="10" cy="7.5" r="3.5" />
      <path d="M19 8v6M22 11h-6" />
    </svg>
  ),
  exit: (
    <svg {...base(34, 'currentColor')} strokeWidth={1.6}>
      <path d="M14 21H6a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h8" />
      <path d="M17 16l4-4-4-4M21 12H9" />
    </svg>
  ),
  payroll: (
    <svg {...base(34, 'currentColor')} strokeWidth={1.6}>
      <rect x="2.5" y="6" width="19" height="13" rx="2.5" />
      <path d="M2.5 10.5h19" />
      <circle cx="17.5" cy="14.5" r="1.3" />
    </svg>
  ),
  orgchart: (
    <svg {...base(34, 'currentColor')} strokeWidth={1.6}>
      <rect x="9" y="3" width="6" height="5" rx="1.3" />
      <rect x="2.5" y="16" width="6" height="5" rx="1.3" />
      <rect x="15.5" y="16" width="6" height="5" rx="1.3" />
      <path d="M12 8v4M5.5 16v-2.5h13V16" />
    </svg>
  ),
};

// ---- Standalone icons ----
export const IconSearch = ({ size = 16, stroke = '#B7AC9B' }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.9" strokeLinecap="round">
    <circle cx="11" cy="11" r="7" />
    <path d="M21 21l-4-4" />
  </svg>
);

export const IconChevronRight = ({ size = 17, stroke = '#CDC2B1' }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M9 6l6 6-6 6" />
  </svg>
);

export const IconChevronDown = ({ size = 14, stroke = '#B7AC9B', style }: IconProps) => (
  <svg style={style} width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M6 9l6 6 6-6" />
  </svg>
);

export const IconSort = ({ size = 16, stroke = '#B7AC9B' }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.8" strokeLinecap="round">
    <path d="M8 9l4-4 4 4M8 15l4 4 4-4" />
  </svg>
);

export const IconDownload = ({ size = 15, stroke = '#fff' }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 3v12M7 10l5 5 5-5M5 21h14" />
  </svg>
);

export const IconClose = ({ size = 16, stroke = '#6E6457' }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="2" strokeLinecap="round">
    <path d="M6 6l12 12M18 6L6 18" />
  </svg>
);

export const IconEye = ({ size = 16, stroke = '#9B9082' }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="12" r="3" />
    <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7z" />
  </svg>
);

export const IconCheck = ({ size = 15, stroke = '#4F7A52' }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
    <path d="M5 12.5l4.5 4.5L19 6.5" />
  </svg>
);

export const IconX = ({ size = 15, stroke = '#A8475F' }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="2.2" strokeLinecap="round">
    <path d="M6 6l12 12M18 6L6 18" />
  </svg>
);

export const IconBell = ({ size = 18, stroke = '#6E6457' }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
    <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
    <path d="M13.7 21a2 2 0 0 1-3.4 0" />
  </svg>
);

export const IconPlus = ({ size = 16, stroke = '#fff' }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 5v14M5 12h14" />
  </svg>
);

export const IconStar = ({ size = 15 }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="#BE5A36" stroke="none">
    <path d="M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 18.4 6.1 21l1.2-6.5L2.5 9.9 9.1 9z" />
  </svg>
);

export const IconFile = ({ size = 18, stroke = '#BE5A36' }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
    <path d="M14 2v6h6" />
  </svg>
);

export const IconExternal = ({ size = 17, stroke = '#B7AC9B' }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M7 17L17 7M17 7H8M17 7v9" />
  </svg>
);

export const IconInfo = ({ size = 16, stroke = '#B7AC9B' }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="12" r="9" />
    <path d="M12 11v5M12 7.5v.5" />
  </svg>
);

export const IconOverride = ({ size = 17, stroke = '#BE5A36' }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 2.5a9.5 9.5 0 1 0 9.5 9.5" />
    <path d="M21.5 4.5l-9 9-3-3" />
  </svg>
);

export const IconChevronUpDown = ({ size = 16, stroke = '#B7AC9B' }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.8" strokeLinecap="round">
    <path d="M8 9l4-4 4 4M8 15l4 4 4-4" />
  </svg>
);

export const IconLogout = ({ size = 16, stroke = '#B7AC9B' }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M14 21H6a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h8" />
    <path d="M17 16l4-4-4-4M21 12H9" />
  </svg>
);
