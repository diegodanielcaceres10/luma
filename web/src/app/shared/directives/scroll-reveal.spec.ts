import { ChangeDetectionStrategy, Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';

import { MotionPreferencesService } from '@core/services/motion-preferences';
import { ScrollRevealDirective } from './scroll-reveal';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-scroll-reveal-host',
  imports: [ScrollRevealDirective],
  template: `
    <section appScrollReveal>
      <p class="editorial-reveal">one</p>
      <p class="editorial-reveal-scale">two</p>
      <p class="editorial-stat-reveal">three</p>
      <p class="editorial-progress-fill">four</p>
      <p class="not-animated">five</p>
    </section>
  `,
})
class HostComponent {}

type ObserverCallback = (entries: Partial<IntersectionObserverEntry>[], observer: IntersectionObserver) => void;

describe('ScrollRevealDirective', () => {
  const observed: Element[] = [];
  const unobserved: Element[] = [];
  let disconnects = 0;
  let options: IntersectionObserverInit | undefined;
  let notify: ObserverCallback;

  const renderFixture = async (reducedMotion: boolean) => {
    TestBed.configureTestingModule({
      providers: [{ provide: MotionPreferencesService, useValue: { prefersReducedMotion: () => reducedMotion } }],
    });
    const fixture = TestBed.createComponent(HostComponent);
    await fixture.whenStable();
    fixture.detectChanges();
    return fixture;
  };

  const render = async (reducedMotion: boolean) => (await renderFixture(reducedMotion)).nativeElement as HTMLElement;

  /** The directive stops observing through the observer the browser hands to the callback. */
  const observerStub = { unobserve: (el: Element) => unobserved.push(el) } as unknown as IntersectionObserver;

  const paragraph = (root: HTMLElement, label: string) =>
    Array.from(root.querySelectorAll('p')).find((p) => p.textContent === label) as HTMLElement;

  beforeEach(() => {
    observed.length = 0;
    unobserved.length = 0;
    disconnects = 0;
    options = undefined;
    vi.stubGlobal(
      'IntersectionObserver',
      class {
        constructor(callback: ObserverCallback, init?: IntersectionObserverInit) {
          notify = callback;
          options = init;
        }
        observe = (el: Element) => observed.push(el);
        unobserve = (el: Element) => unobserved.push(el);
        disconnect = () => disconnects++;
      },
    );
  });

  afterEach(() => vi.unstubAllGlobals());

  it('reveals every animated element at once when the user prefers reduced motion', async () => {
    const root = await render(true);

    expect(root.querySelectorAll('.is-revealed').length).toBe(4);
    expect(paragraph(root, 'five').classList.contains('is-revealed')).toBe(false);
    expect(observed).toEqual([]);
  });

  it('observes only the animated elements when motion is allowed', async () => {
    const root = await render(false);

    expect(observed.length).toBe(4);
    expect(observed).not.toContain(paragraph(root, 'five'));
    expect(root.querySelectorAll('.is-revealed').length).toBe(0);
    expect(options).toMatchObject({ threshold: 0.1 });
  });

  it('reveals an element once it enters the viewport and stops observing it', async () => {
    const root = await render(false);
    const first = paragraph(root, 'one');
    const second = paragraph(root, 'two');

    notify([{ isIntersecting: true, target: first }], observerStub);

    expect(first.classList.contains('is-revealed')).toBe(true);
    expect(unobserved).toEqual([first]);
    expect(second.classList.contains('is-revealed')).toBe(false);
  });

  it('keeps an element hidden while it is outside the viewport', async () => {
    const root = await render(false);
    const first = paragraph(root, 'one');

    notify([{ isIntersecting: false, target: first }], observerStub);

    expect(first.classList.contains('is-revealed')).toBe(false);
    expect(unobserved).toEqual([]);
  });

  it('disconnects the observer when the host is destroyed', async () => {
    const fixture = await renderFixture(false);

    expect(disconnects).toBe(0);
    fixture.destroy();

    expect(disconnects).toBe(1);
  });

  it('has nothing to disconnect when motion is reduced', async () => {
    const fixture = await renderFixture(true);

    fixture.destroy();

    expect(disconnects).toBe(0);
  });
});
