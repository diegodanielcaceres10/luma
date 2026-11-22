import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { App } from './app';

describe('App', () => {
  it('hosts the router outlet and the cookie banner', () => {
    TestBed.configureTestingModule({ providers: [provideRouter([])] });
    const fixture = TestBed.createComponent(App);
    fixture.detectChanges();
    const root: HTMLElement = fixture.nativeElement;

    expect(root.querySelector('router-outlet')).not.toBeNull();
    expect(root.querySelector('app-cookie-banner')).not.toBeNull();
  });

  it('places the skip link before any other content', () => {
    TestBed.configureTestingModule({ providers: [provideRouter([])] });
    const fixture = TestBed.createComponent(App);
    fixture.detectChanges();
    const first = (fixture.nativeElement as HTMLElement).firstElementChild;

    expect(first?.tagName.toLowerCase()).toBe('app-skip-link');
  });
});
