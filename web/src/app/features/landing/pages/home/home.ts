import { ChangeDetectionStrategy, Component } from '@angular/core';
import { NavbarComponent } from '@shared/components/navbar/navbar';
import { ScrollRevealDirective } from '@shared/directives/scroll-reveal';
import { HeroComponent } from '../../components/hero/hero';
import { AppShowcaseComponent } from '../../components/app-showcase/app-showcase';
import { FeaturesBentoComponent } from '../../components/features-bento/features-bento';
import { ExperienceTabsComponent } from '../../components/experience-tabs/experience-tabs';
import { GeminiSectionComponent } from '../../components/gemini-section/gemini-section';
import { SecuritySectionComponent } from '../../components/security-section/security-section';
import { StackSectionComponent } from '../../components/stack-section/stack-section';
import { CtaBannerComponent } from '../../components/cta-banner/cta-banner';
import { FooterComponent } from '@shared/components/footer/footer';
import { EditorialBackgroundComponent } from '../../components/editorial-background/editorial-background';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-home',
  hostDirectives: [ScrollRevealDirective],
  imports: [
    NavbarComponent,
    HeroComponent,
    AppShowcaseComponent,
    FeaturesBentoComponent,
    ExperienceTabsComponent,
    GeminiSectionComponent,
    SecuritySectionComponent,
    StackSectionComponent,
    CtaBannerComponent,
    FooterComponent,
    EditorialBackgroundComponent,
  ],
  templateUrl: './home.html',
  styleUrl: './home.css'
})
export class Home {}
