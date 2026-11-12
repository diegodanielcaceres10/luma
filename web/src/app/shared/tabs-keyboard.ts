/**
 * Resolves the next tab index for the WAI-ARIA tabs keyboard pattern.
 * Returns null when the key does not navigate between tabs.
 */
export function nextTabIndex(key: string, current: number, count: number): number | null {
  const last = count - 1;

  switch (key) {
    case 'ArrowRight':
      return current >= last ? 0 : current + 1;
    case 'ArrowLeft':
      return current <= 0 ? last : current - 1;
    case 'Home':
      return 0;
    case 'End':
      return last;
    default:
      return null;
  }
}
