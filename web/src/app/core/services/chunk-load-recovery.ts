import { DOCUMENT, Location } from '@angular/common';
import { Injectable, inject } from '@angular/core';
import { withNavigationErrorHandler } from '@angular/router';

const RELOAD_STORAGE_KEY = 'luma-chunk-reload-at';
/** A second chunk failure inside this window is treated as a real outage, not a stale deployment. */
const RELOAD_WINDOW_MS = 30_000;

// Chromium, Firefox and Safari word the same dynamic import failure differently.
const CHUNK_FAILURE_MESSAGE =
  /Failed to fetch dynamically imported module|error loading dynamically imported module|Importing a module script failed|Loading chunk .+ failed/i;

/**
 * Recovers from lazy chunks that no longer exist after a deployment while a tab was left open:
 * a full load of the target URL fetches the new index and its current chunk names.
 */
@Injectable({ providedIn: 'root' })
export class ChunkLoadRecovery {
  private readonly view = inject(DOCUMENT).defaultView;
  private readonly location = inject(Location);

  /** Reloads the target page for a chunk failure; rethrows anything it cannot safely recover from. */
  recover(error: unknown, url: string): void {
    if (!this.isChunkFailure(error) || !this.claimReload()) {
      throw error;
    }
    // The router reports app-relative URLs; a full page load needs the base href (e.g. /luma/) in front.
    this.view?.location.assign(this.location.prepareExternalUrl(url));
  }

  private isChunkFailure(error: unknown): boolean {
    return error instanceof Error && (error.name === 'ChunkLoadError' || CHUNK_FAILURE_MESSAGE.test(error.message));
  }

  /** Records the reload attempt; returns false when it would repeat a recent one or cannot be recorded. */
  private claimReload(): boolean {
    if (!this.view) {
      return false;
    }
    try {
      const last = Number(this.view.sessionStorage.getItem(RELOAD_STORAGE_KEY));
      if (Date.now() - last < RELOAD_WINDOW_MS) {
        return false;
      }
      this.view.sessionStorage.setItem(RELOAD_STORAGE_KEY, String(Date.now()));
      return true;
    } catch {
      // Without storage a reload loop cannot be ruled out, so the error is surfaced instead.
      return false;
    }
  }
}

/** Router feature that applies {@link ChunkLoadRecovery} to failed navigations. */
export const withChunkLoadRecovery = () =>
  withNavigationErrorHandler((navigationError) =>
    inject(ChunkLoadRecovery).recover(navigationError.error, navigationError.url),
  );
