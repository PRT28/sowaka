import { createContext, useCallback, useContext, useState } from 'react';
import type { ReactNode } from 'react';
import { getStoredUser, logout as logoutApi } from '../../services/auth';
import type { AuthUser } from '../../services/auth';

type AuthState = {
  user: AuthUser | null;
  setUser: (u: AuthUser) => void;
  signOut: () => Promise<void>;
};

const Ctx = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUserState] = useState<AuthUser | null>(() => getStoredUser());

  const setUser = useCallback((u: AuthUser) => setUserState(u), []);
  const signOut = useCallback(async () => {
    await logoutApi();
    setUserState(null);
  }, []);

  return <Ctx.Provider value={{ user, setUser, signOut }}>{children}</Ctx.Provider>;
}

export function useAuth(): AuthState {
  const s = useContext(Ctx);
  if (!s) throw new Error('useAuth must be used within AuthProvider');
  return s;
}
