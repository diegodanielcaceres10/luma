import { Component, afterNextRender, ElementRef, inject, PLATFORM_ID } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { NavbarComponent } from '../../components/navbar/navbar';
import { HeroComponent } from '../../components/hero/hero';
import { AppShowcaseComponent } from '../../components/app-showcase/app-showcase';
import { FeaturesBentoComponent } from '../../components/features-bento/features-bento';
import { ExperienceTabsComponent } from '../../components/experience-tabs/experience-tabs';
import { GeminiSectionComponent } from '../../components/gemini-section/gemini-section';
import { SecuritySectionComponent } from '../../components/security-section/security-section';
import { StackSectionComponent } from '../../components/stack-section/stack-section';
import { CtaBannerComponent } from '../../components/cta-banner/cta-banner';
import { FooterComponent } from '../../components/footer/footer';
import { EditorialBackgroundComponent } from '../../components/editorial-background/editorial-background';

@Component({
  selector: 'app-home',
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
export class Home {
  private readonly platformId = inject(PLATFORM_ID);
  private readonly el = inject(ElementRef);

  constructor() {
    afterNextRender(() => {
      this.initScrollReveal();
    });
  }

  private initScrollReveal(): void {
    if (!isPlatformBrowser(this.platformId)) return;

    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const elementsToReveal = this.el.nativeElement.querySelectorAll(
      '.editorial-reveal, .editorial-reveal-scale, .editorial-stat-reveal, .editorial-progress-fill'
    );

    if (prefersReducedMotion) {
      elementsToReveal.forEach((el: Element) => el.classList.add('is-revealed'));
      return;
    }

    const observer = new IntersectionObserver(
      (entries, obs) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-revealed');
            obs.unobserve(entry.target);
          }
        });
      },
      {
        root: null,
        threshold: 0.1,
        rootMargin: '0px 0px -40px 0px',
      }
    );

    elementsToReveal.forEach((el: Element) => observer.observe(el));
  }
}
