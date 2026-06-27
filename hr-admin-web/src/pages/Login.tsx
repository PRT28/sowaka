export function Login() {
  return (
    <main className="auth-page">
      <section className="auth-panel">
        <h1>HR Admin Login</h1>
        <form>
          <label>
            Email
            <input type="email" name="email" placeholder="admin@example.com" />
          </label>
          <label>
            Password
            <input type="password" name="password" placeholder="Password" />
          </label>
          <button type="submit">Sign in</button>
        </form>
      </section>
    </main>
  );
}
