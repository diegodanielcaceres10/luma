import { DOCUMENT } from '@angular/common';
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SKIP_LINK_TARGET_ID, SkipLinkComponent } from './skip-link';

describe('SkipLinkComponent', () => {
  let fixture: ComponentFixture<SkipLinkComponent>;
  let doc: Document;
  let link: HTMLAnchorElement;
  let main: HTMLElement;

  beforeEach(() => {
    fixture = TestBed.createComponent(SkipLinkComponent);
    fixture.detectChanges();
    doc = TestBed.inject(DOCUMENT);
    link = fixture.nativeElement.querySelector('a');

    main = doc.createElement('main');
    main.id = SKIP_LINK_TARGET_ID;
    main.tabIndex = -1;
    doc.body.appendChild(main);
  });

  afterEach(() => main.remove());

  it('offers a link that points to the main content anchor', () => {
    expect(link.textContent?.trim()).toBe('Saltar al contenido');
    expect(link.getAttribute('href')).toBe(`#${SKIP_LINK_TARGET_ID}`);
  });

  it('is hidden visually until it receives keyboard focus', () => {
    expect(link.classList).toContain('sr-only');
    expect(link.className).toContain('focus:not-sr-only');
  });

  it('moves focus to the main content when activated', () => {
    link.click();

    expect(doc.activeElement).toBe(main);
  });

  it('does not follow the hash, which would resolve against the base href', () => {
    const event = new MouseEvent('click', { bubbles: true, cancelable: true });

    link.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(true);
  });

  it('does nothing when the page has no main content element', () => {
    main.remove();
    const before = doc.activeElement;

    expect(() => link.click()).not.toThrow();
    expect(doc.activeElement).toBe(before);
  });
});
