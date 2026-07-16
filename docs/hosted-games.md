# Hosted game integration

Games may be built with Vanilla JavaScript or React and hosted on any HTTPS URL, including GitHub Pages. Sowaka loads the URL inside its authenticated mobile WebView.

When a run ends, submit the player's numeric score with:

```js
window.Sowaka?.submitScore(score);
```

The bridge is injected after the page loads and emits a `sowaka-ready` event. Games that initialize before it is available can listen for that event:

```js
window.addEventListener('sowaka-ready', () => {
  // The score bridge is ready.
});
```

Only non-negative finite scores are accepted. The leaderboard keeps each employee's best score. Authentication stays in the mobile app and is never passed to the hosted game.
