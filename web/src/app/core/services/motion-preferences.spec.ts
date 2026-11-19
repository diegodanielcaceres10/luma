import { DOCUMENT } from '@angular/common';
import { TestBed } from '@angular/core/testing';

import { MotionPreferencesService } from './motion-preferences';

describe('MotionPreferencesService', () => {
  const create = (defaultView: unknown) => {
    TestBed.configureTestingModule({
      providers: [{ provide: DOCUMENT, useValue: { defaultView } }],
    });
    return TestBed.inject(MotionPreferencesService);
  };

  it('reports reduced motion when the media query matches', () => {
    const matchMedia = vi.fn().mockReturnValue({ matches: true });
    const service = create({ matchMedia });

    expect(service.prefersReducedMotion()).toBe(true);
    expect(matchMedia).toHaveBeenCalledWith('(prefers-reduced-motion: reduce)');
  });

  it('reports full motion when the media query does not match', () => {
    const service = create({ matchMedia: () => ({ matches: false }) });

    expect(service.prefersReducedMotion()).toBe(false);
  });

  it('falls back to full motion when there is no window', () => {
    expect(create(null).prefersReducedMotion()).toBe(false);
  });

  it('falls back to full motion when matchMedia is not available', () => {
    expect(create({}).prefersReducedMotion()).toBe(false);
  });
});
