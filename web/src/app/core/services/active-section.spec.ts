import { PLATFORM_ID } from '@angular/core';
import { TestBed } from '@angular/core/testing';

import { ActiveSectionService } from './active-section';

type Callback = (entries: Partial<IntersectionObserverEntry>[]) => void;

describe('ActiveSectionService', () => {
  const observed: Element[] = [];
  let disconnects = 0;
  let created = 0;
  let options: IntersectionObserverInit | undefined;
  let notify: Callback;

  const addSection = (id: string) => {
    const section = document.createElement('section');
    section.id = id;
    document.body.appendChild(section);
    return section;
  };

  const intersect = (id: string, isIntersecting: boolean) =>
    notify([{ target: document.getElementById(id) as Element, isIntersecting }]);

  const create = (platform = 'browser') => {
    TestBed.configureTestingModule({ providers: [{ provide: PLATFORM_ID, useValue: platform }] });
    return TestBed.inject(ActiveSectionService);
  };

  beforeEach(() => {
    observed.length = 0;
    disconnects = 0;
    created = 0;
    options = undefined;
    vi.stubGlobal(
      'IntersectionObserver',
      class {
        constructor(callback: Callback, init?: IntersectionObserverInit) {
          created++;
          notify = callback;
          options = init;
        }
        observe(target: Element) {
          observed.push(target);
        }
        disconnect() {
          disconnects++;
        }
      },
    );
    ['uno', 'dos', 'tres'].forEach(addSection);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    document.body.innerHTML = '';
  });

  it('starts without an active section', () => {
    expect(create().active()).toBeNull();
  });

  it('observes only the sections that exist in the page', () => {
    create().watch(['uno', 'missing', 'dos']);

    expect(observed.map((el) => el.id)).toEqual(['uno', 'dos']);
  });

  it('watches a thin band across the middle of the viewport', () => {
    create().watch(['uno']);

    expect(options?.rootMargin).toBe('-45% 0px -54% 0px');
  });

  it('marks the section that crosses the reading band as active', () => {
    const service = create();
    service.watch(['uno', 'dos', 'tres']);

    intersect('dos', true);

    expect(service.active()).toBe('dos');
  });

  it('clears the active section when none crosses the band', () => {
    const service = create();
    service.watch(['uno', 'dos']);
    intersect('uno', true);

    intersect('uno', false);

    expect(service.active()).toBeNull();
  });

  it('prefers the section listed first when several cross the band', () => {
    const service = create();
    service.watch(['uno', 'dos', 'tres']);

    intersect('tres', true);
    intersect('dos', true);

    expect(service.active()).toBe('dos');
  });

  it('disconnects and resets when it stops', () => {
    const service = create();
    service.watch(['uno']);
    intersect('uno', true);

    service.stop();

    expect(disconnects).toBe(1);
    expect(service.active()).toBeNull();
  });

  it('replaces the previous observer when watching again', () => {
    const service = create();
    service.watch(['uno']);

    service.watch(['dos']);

    expect(disconnects).toBe(1);
    expect(created).toBe(2);
  });

  it('does nothing while rendering on the server', () => {
    const service = create('server');

    service.watch(['uno']);

    expect(created).toBe(0);
    expect(service.active()).toBeNull();
  });

  it('does nothing when the browser has no IntersectionObserver', () => {
    vi.stubGlobal('IntersectionObserver', undefined);
    const service = create();

    expect(() => service.watch(['uno'])).not.toThrow();
    expect(service.active()).toBeNull();
  });
});
