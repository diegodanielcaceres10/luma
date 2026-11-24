import { DestroyRef } from '@angular/core';
import { NavigationEnd, NavigationStart, Router } from '@angular/router';
import { Subject } from 'rxjs';

import { onNavigationEnd } from './navigation-end';

describe('onNavigationEnd', () => {
  let events: Subject<unknown>;
  let router: Router;
  let destroyCallbacks: (() => void)[];
  let destroyRef: DestroyRef;

  beforeEach(() => {
    events = new Subject<unknown>();
    router = { events } as unknown as Router;
    destroyCallbacks = [];
    destroyRef = {
      onDestroy: (callback: () => void) => {
        destroyCallbacks.push(callback);
        return () => undefined;
      },
    } as DestroyRef;
  });

  afterEach(() => vi.restoreAllMocks());

  it('calls the handler only for completed navigations', () => {
    const handler = vi.fn();
    onNavigationEnd(router, destroyRef, handler);
    const end = new NavigationEnd(1, '/a', '/b');

    events.next(new NavigationStart(1, '/a'));
    events.next(end);

    expect(handler).toHaveBeenCalledExactlyOnceWith(end);
  });

  it('stops listening when the owner is destroyed', () => {
    const handler = vi.fn();
    onNavigationEnd(router, destroyRef, handler);

    destroyCallbacks.forEach((callback) => callback());
    events.next(new NavigationEnd(1, '/a', '/b'));

    expect(handler).not.toHaveBeenCalled();
  });

  it('reports a failure of the event stream instead of losing it', () => {
    const error = new Error('stream failed');
    const report = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    onNavigationEnd(router, destroyRef, vi.fn());

    events.error(error);

    expect(report).toHaveBeenCalledExactlyOnceWith(expect.stringContaining('Navigation'), error);
  });
});
