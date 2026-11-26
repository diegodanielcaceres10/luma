import { ChangeDetectionStrategy, Component, inject } from '@angular/core';

import { APP_VERSION } from '@core/config/app-version';

/** Product version label. It has no styles of its own: each host element sets them through classes. */
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-version',
  template: 'v {{ version }}',
})
export class AppVersionComponent {
  protected readonly version = inject(APP_VERSION);
}
