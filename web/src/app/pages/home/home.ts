import { Component } from '@angular/core';
import { NavbarComponent } from '../../components/navbar/navbar';
import { HeroComponent } from '../../components/hero/hero';
import { AppShowcaseComponent } from '../../components/app-showcase/app-showcase';
import { FeaturesBentoComponent } from '../../components/features-bento/features-bento';
import { ExperienceTabsComponent } from '../../components/experience-tabs/experience-tabs';
import { SecuritySectionComponent } from '../../components/security-section/security-section';
import { StackSectionComponent } from '../../components/stack-section/stack-section';
import { CtaBannerComponent } from '../../components/cta-banner/cta-banner';
import { FooterComponent } from '../../components/footer/footer';

@Component({
  selector: 'app-home',
  imports: [
    NavbarComponent,
    HeroComponent,
    AppShowcaseComponent,
    FeaturesBentoComponent,
    ExperienceTabsComponent,
    SecuritySectionComponent,
    StackSectionComponent,
    CtaBannerComponent,
    FooterComponent,
  ],
  templateUrl: './home.html',
  styleUrl: './home.css'
})
export class Home {}
