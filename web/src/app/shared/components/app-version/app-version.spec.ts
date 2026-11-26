import { TestBed } from '@angular/core/testing';

import { APP_VERSION } from '@core/config/app-version';
import { AppVersionComponent } from './app-version';

describe('AppVersionComponent', () => {
  const render = (version?: string): HTMLElement => {
    if (version) TestBed.configureTestingModule({ providers: [{ provide: APP_VERSION, useValue: version }] });
    const fixture = TestBed.createComponent(AppVersionComponent);
    fixture.detectChanges();
    return fixture.nativeElement;
  };

  it('shows the injected version with a leading "v"', () => {
    expect(render('9.8.7').textContent?.trim()).toBe('v 9.8.7');
  });

  it('shows the real product version by default', () => {
    expect(render().textContent?.trim()).toBe(`v ${TestBed.inject(APP_VERSION)}`);
  });
});
