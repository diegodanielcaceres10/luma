import { APP_BASE_HREF, DOCUMENT } from '@angular/common';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';

import { ChunkLoadRecovery, withChunkLoadRecovery } from './chunk-load-recovery';

describe('ChunkLoadRecovery', () => {
  const assign = vi.fn();
  let storage: Pick<Storage, 'getItem' | 'setItem'>;
  let view: { location: { assign: typeof assign }; sessionStorage: typeof storage } | null;

  const chunkError = () => new TypeError('Failed to fetch dynamically imported module: /chunk-ABC.js');

  const setup = (): ChunkLoadRecovery => {
    TestBed.configureTestingModule({
      providers: [
        { provide: DOCUMENT, useValue: { defaultView: view } },
        { provide: APP_BASE_HREF, useValue: '/luma/' },
      ],
    });
    return TestBed.inject(ChunkLoadRecovery);
  };

  beforeEach(() => {
    sessionStorage.clear();
    assign.mockReset();
    storage = sessionStorage;
    view = { location: { assign }, sessionStorage: storage };
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it.each([
    new TypeError('Failed to fetch dynamically imported module: /chunk-ABC.js'),
    new TypeError('error loading dynamically imported module: /chunk-ABC.js'),
    new TypeError('Importing a module script failed.'),
    Object.assign(new Error('Loading chunk 7 failed.'), { name: 'ChunkLoadError' }),
  ])('reloads the target page when a lazy chunk fails to load: %s', (error) => {
    const recovery = setup();

    expect(() => recovery.recover(error, '/privacidad')).not.toThrow();
    expect(assign).toHaveBeenCalledExactlyOnceWith('/luma/privacidad');
  });

  it('rethrows errors that are not chunk loading failures', () => {
    const recovery = setup();
    const error = new Error('Something else broke');

    expect(() => recovery.recover(error, '/privacidad')).toThrow(error);
    expect(assign).not.toHaveBeenCalled();
  });

  it('rethrows values that are not Error instances', () => {
    const recovery = setup();

    expect(() => recovery.recover('boom', '/')).toThrow('boom');
    expect(assign).not.toHaveBeenCalled();
  });

  it('does not reload twice in a row so a missing chunk cannot cause a reload loop', () => {
    const recovery = setup();
    const error = chunkError();

    recovery.recover(error, '/privacidad');

    expect(() => recovery.recover(error, '/privacidad')).toThrow(error);
    expect(assign).toHaveBeenCalledTimes(1);
  });

  it('reloads again once the loop-protection window has passed', () => {
    vi.useFakeTimers();
    const recovery = setup();

    recovery.recover(chunkError(), '/privacidad');
    vi.advanceTimersByTime(60_000);
    recovery.recover(chunkError(), '/privacidad');

    expect(assign).toHaveBeenCalledTimes(2);
  });

  it('rethrows when session storage is blocked because a loop could not be prevented', () => {
    vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
      throw new Error('blocked');
    });
    const recovery = setup();
    const error = chunkError();

    expect(() => recovery.recover(error, '/')).toThrow(error);
    expect(assign).not.toHaveBeenCalled();
  });

  it('rethrows when there is no browser window (prerender)', () => {
    view = null;
    const recovery = setup();
    const error = chunkError();

    expect(() => recovery.recover(error, '/')).toThrow(error);
  });

  it('recovers from a lazy route that fails to load when wired into the router', async () => {
    TestBed.configureTestingModule({
      providers: [
        { provide: DOCUMENT, useValue: { defaultView: view } },
        { provide: APP_BASE_HREF, useValue: '/luma/' },
        provideRouter(
          [{ path: 'privacidad', loadComponent: () => Promise.reject(chunkError()) }],
          withChunkLoadRecovery(),
        ),
      ],
    });

    // The router always rejects after the handler runs, so the failure still reaches the global error listeners.
    await expect(TestBed.inject(Router).navigateByUrl('/privacidad')).rejects.toThrow(
      'Failed to fetch dynamically imported module',
    );

    expect(assign).toHaveBeenCalledExactlyOnceWith('/luma/privacidad');
  });
});
