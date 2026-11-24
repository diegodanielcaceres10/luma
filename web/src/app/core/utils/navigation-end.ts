import { DestroyRef } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { NavigationEnd, Router } from '@angular/router';
import { filter } from 'rxjs';

/** Runs `handler` after every completed navigation until the owner is destroyed. */
export function onNavigationEnd(router: Router, destroyRef: DestroyRef, handler: (event: NavigationEnd) => void): void {
  router.events
    .pipe(
      filter((event): event is NavigationEnd => event instanceof NavigationEnd),
      takeUntilDestroyed(destroyRef),
    )
    .subscribe({
      next: handler,
      // The router does not emit errors today; this keeps a future failure from ending the sync silently.
      error: (error: unknown) => console.error('Navigation event stream failed.', error),
    });
}
