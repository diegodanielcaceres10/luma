import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { PRIVACY_POLICY_LAST_UPDATED } from '../../legal-dates';
import { PrivacyPolicy } from './privacy-policy';

describe('PrivacyPolicy', () => {
  let root: HTMLElement;

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [provideRouter([])] });
    const fixture = TestBed.createComponent(PrivacyPolicy);
    fixture.detectChanges();
    root = fixture.nativeElement;
  });

  it('has a single main heading', () => {
    expect(root.querySelectorAll('h1')).toHaveLength(1);
  });

  it('shows the last update date defined in legal-dates', () => {
    expect(root.textContent).toContain(PRIVACY_POLICY_LAST_UPDATED);
  });

  it('numbers its sections consecutively', () => {
    const titles = Array.from(root.querySelectorAll('h2')).map((h2) => h2.textContent?.trim() ?? '');

    expect(titles.length).toBeGreaterThan(0);
    expect(titles.map((title, index) => title.startsWith(`${index + 1}.`))).not.toContain(false);
  });

  it('offers a way back to the home page', () => {
    expect(root.querySelector('a[href="/"]')).not.toBeNull();
  });
});
