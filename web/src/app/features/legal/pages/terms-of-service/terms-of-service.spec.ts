import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { TERMS_OF_SERVICE_LAST_UPDATED } from '../../legal-dates';
import { TermsOfService } from './terms-of-service';

describe('TermsOfService', () => {
  let root: HTMLElement;

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [provideRouter([])] });
    const fixture = TestBed.createComponent(TermsOfService);
    fixture.detectChanges();
    root = fixture.nativeElement;
  });

  it('has a single main heading', () => {
    expect(root.querySelectorAll('h1')).toHaveLength(1);
  });

  it('shows the last update date defined in legal-dates', () => {
    expect(root.textContent).toContain(TERMS_OF_SERVICE_LAST_UPDATED);
  });

  it('numbers its sections consecutively', () => {
    const titles = Array.from(root.querySelectorAll('h2')).map((h2) => h2.textContent?.trim() ?? '');

    expect(titles.length).toBeGreaterThan(0);
    expect(titles.map((title, index) => title.startsWith(`${index + 1}.`))).not.toContain(false);
  });

  it('exposes the main landmark as the skip link target', () => {
    const main = root.querySelector('main');

    expect(main?.id).toBe('main-content');
    expect(main?.getAttribute('tabindex')).toBe('-1');
  });

  it('offers a way back to the home page', () => {
    expect(root.querySelector('a[href="/"]')).not.toBeNull();
  });
});
