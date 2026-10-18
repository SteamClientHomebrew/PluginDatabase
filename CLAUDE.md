# Millennium Plugin Database

This repository contains community plugins for [Millennium](https://steambrew.app/), a Steam client modding platform. Each subdirectory under `plugins/` is an independent plugin. Plugins are added as git submodules.

## Cloning Plugin Source for Review

Plugins in this repo are git submodules pointing to external repositories. The submodule files may not be checked out in CI. To review plugin code:

1. Look at the PR diff to find the submodule entry being added or updated (check `.gitmodules` and the submodule path under `plugins/`).
2. Use `git` or `gh` to determine the plugin's source repository URL and commit SHA from the PR diff.
3. Clone the plugin repository yourself and check out the correct commit:
   ```bash
   git clone <repo-url> /tmp/plugin-review
   cd /tmp/plugin-review
   git checkout <commit-sha>
   ```
4. Review the plugin source code from there.

Do NOT skip the review because submodule files aren't available locally. Always clone and inspect the actual plugin code.

## PR Review Instructions

When reviewing pull requests that add or update plugins, perform the following checks thoroughly. Be direct and specific in your feedback.

### Security Review

- Audit all network requests (fetch, XMLHttpRequest, WebSocket) for data exfiltration, SSRF, or connections to suspicious/hardcoded external endpoints.
- Check for unsafe use of `eval()`, `Function()`, `innerHTML`, `dangerouslySetInnerHTML`, or any other code injection vectors.
- Look for credential/token leakage -- secrets hardcoded in source, logged to console, or sent to third parties.
- Inspect `callable` RPC declarations and their backend counterparts for input validation issues.
- Flag any use of `document.cookie`, `localStorage`/`sessionStorage` access that reads data unrelated to the plugin's own scope.
- Check for prototype pollution, unsafe deserialization, or any DOM-based injection risks.
- Review file system access patterns in Lua backends for path traversal or arbitrary file read/write.

### Bug Review (Priority)

This is the most important part of the review. Drill deep into logic and correctness:

- Trace every code path -- look for unhandled edge cases, off-by-one errors, null/undefined dereferences, race conditions, and incorrect async/await usage.
- Check for missing cleanup: event listeners not removed, intervals/timeouts not cleared, subscriptions not unsubscribed. These cause memory leaks and ghost behavior in a long-running Steam client.
- Verify state management correctness: stale closures, missing dependency arrays in `useEffect`/`useMemo`/`useCallback`, state updates on unmounted components.
- Check error handling: uncaught promise rejections, missing try/catch around `callable` RPC calls, network requests without error handling.
- Look for incorrect type coercion, string/number confusion, and comparisons that should use strict equality.
- Verify that `plugin.json` schema is correct: required fields present (`name`, `common_name`, `description`, `version`), version format is valid, `backendType` matches actual backend usage.
- Check for hardcoded Steam AppIDs, user IDs, or other magic values that should be dynamic.
- Look for infinite loops, infinite re-renders, or expensive operations inside render cycles.

### Breaking Changes

Always flag the following as breaking changes when they occur in plugin updates:

- Changes to `plugin.json` fields: `name`, `backendType`, `data` schema changes (renamed/removed keys).
- Removed or renamed `callable` backend function signatures.
- Changed settings storage keys (causes users to lose their settings on update).
- Bumped minimum Millennium version requirements.
- Removed features or changed default behavior.

Clearly label these as **Breaking Change** in your review.

### UI/Component Standards

Plugins must use the component library from `@steambrew/client` and Steam's built-in components. Review settings panels and UI for compliance:

**Settings panels** are defined in `definePlugin()`'s return object via the `content` prop (in the plugin's `index.tsx`):

```tsx
export default definePlugin(() => {
	return {
		title: "Plugin Name",
		icon: <IconsModule.Something />,
		content: <SettingsPanel />,
	};
});
```

**Required component usage:**

- Use `Field` for settings rows (with `label`, `description`, and `bottomSeparator` props).
- Use `Toggle`, `TextField`, `Dropdown`, `Slider` for input controls inside `Field`.
- Use `DialogButton` or `Button` for actions.
- Use `showModal`/`ModalRoot`/`ConfirmModal` for dialogs.
- Use `showContextMenu`/`Menu`/`MenuItem` for context menus.
- Use `Focusable` for keyboard/controller navigation support.
- Use `Spinner` for loading states.

**Flag these anti-patterns:**

- Raw HTML elements (`<input>`, `<select>`, `<button>`, `<table>`) used where a `@steambrew/client` or Steam component exists.
- Direct DOM manipulation (`document.createElement`, `element.innerHTML`, `element.appendChild`) for UI that could be React components.
- Inline `style` attributes or `<style>` tags for layout/styling that Steam's existing CSS classes handle. Custom styles are acceptable only when Steam provides no equivalent.
- Using `window.SP_REACT.createElement` directly instead of JSX.
- Building settings UI outside of the `definePlugin` `content` pattern without good reason.

**Acceptable exceptions:**

- DOM manipulation for injecting into parts of Steam's UI that aren't exposed via React (e.g., patching existing Steam pages via `Millennium.findElement`).
- Custom CSS for genuinely novel UI that has no Steam equivalent.
- Plugins that don't have user-facing settings don't need a settings panel.

### General Quality

- Check that the plugin does what its description claims.
- Flag dead code, unused imports, and unreachable branches.
- Note overly complex code that could be simplified.
- Verify consistent error messaging (user-facing errors should be helpful, not raw stack traces).
