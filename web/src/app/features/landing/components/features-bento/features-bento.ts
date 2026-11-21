import { ChangeDetectionStrategy, Component } from '@angular/core';

import { BentoAccountsCardComponent } from './cards/bento-accounts-card/bento-accounts-card';
import { BentoBudgetCardComponent } from './cards/bento-budget-card/bento-budget-card';
import { BentoIncomeCardComponent } from './cards/bento-income-card/bento-income-card';
import { BentoInsightsCardComponent } from './cards/bento-insights-card/bento-insights-card';
import { BentoPdfExportCardComponent } from './cards/bento-pdf-export-card/bento-pdf-export-card';
import { BentoRecurringCardComponent } from './cards/bento-recurring-card/bento-recurring-card';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-features-bento',
  imports: [
    BentoIncomeCardComponent,
    BentoBudgetCardComponent,
    BentoInsightsCardComponent,
    BentoAccountsCardComponent,
    BentoRecurringCardComponent,
    BentoPdfExportCardComponent,
  ],
  templateUrl: './features-bento.html',
})
export class FeaturesBentoComponent {}
