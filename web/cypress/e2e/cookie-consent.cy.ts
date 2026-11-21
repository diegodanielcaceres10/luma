import { CONSENT_STORAGE_KEY } from '../support/constants';

const GOOGLE_TAG_SCRIPT = 'script[src*="googletagmanager.com"]';

describe('Cookie consent', () => {
  const banner = () => cy.get('section[aria-labelledby="cookie-banner-title"]');

  it('asks first-time visitors and loads nothing from Google while undecided', () => {
    cy.visit('/');

    banner().should('be.visible');
    cy.get(GOOGLE_TAG_SCRIPT).should('not.exist');
  });

  it('remembers an accepted choice after a reload', () => {
    cy.visit('/');

    banner().contains('button', 'Aceptar').click();
    banner().should('not.exist');
    cy.window().its('localStorage').invoke('getItem', CONSENT_STORAGE_KEY).should('eq', 'granted');

    cy.reload();
    cy.get('h1').should('be.visible');
    banner().should('not.exist');
  });

  it('remembers a rejected choice and keeps Google out', () => {
    cy.visit('/');

    banner().contains('button', 'Rechazar').click();
    banner().should('not.exist');
    cy.window().its('localStorage').invoke('getItem', CONSENT_STORAGE_KEY).should('eq', 'denied');

    cy.reload();
    cy.get('h1').should('be.visible');
    banner().should('not.exist');
    cy.get(GOOGLE_TAG_SCRIPT).should('not.exist');
  });

  it('lets the visitor change the decision from the footer', () => {
    cy.visit('/');
    banner().contains('button', 'Rechazar').click();
    banner().should('not.exist');

    cy.get('footer').contains('button', 'Preferencias de cookies').click();

    banner().should('be.visible');
  });

  it('links the banner to the privacy policy', () => {
    cy.visit('/');

    banner().find('a[href="/privacidad"]').click();

    cy.location('pathname').should('eq', '/privacidad');
    cy.get('h1').should('contain.text', 'Política de Privacidad');
  });
});
