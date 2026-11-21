describe('Navigation across routes', () => {
  it('renders the landing page at the root route', () => {
    cy.visit('/');

    cy.title().should('eq', 'Luma — Finanzas personales simples');
    cy.get('h1').should('contain.text', 'El arte de tus finanzas');
    cy.get('link[rel="canonical"]').should('have.attr', 'href').and('match', /\/$/);
  });

  it('renders the privacy policy with its own title and canonical URL', () => {
    cy.visit('/privacidad');

    cy.get('h1').should('contain.text', 'Política de Privacidad');
    cy.title().should('eq', 'Política de privacidad — Luma');
    cy.get('link[rel="canonical"]').should('have.attr', 'href').and('match', /privacidad\/$/);
  });

  it('renders the terms of service with its own title and canonical URL', () => {
    cy.visit('/condiciones');

    cy.get('h1').should('contain.text', 'Condiciones del Servicio');
    cy.title().should('eq', 'Condiciones del servicio — Luma');
    cy.get('link[rel="canonical"]').should('have.attr', 'href').and('match', /condiciones\/$/);
  });

  it('moves between pages from the footer and restores the home title on return', () => {
    cy.visit('/');

    cy.get('footer a[href="/privacidad"]').click();
    cy.location('pathname').should('eq', '/privacidad');
    cy.title().should('eq', 'Política de privacidad — Luma');

    cy.contains('a', 'Volver').click();
    cy.location('pathname').should('eq', '/');
    cy.title().should('eq', 'Luma — Finanzas personales simples');
  });

  it('redirects unknown URLs to the home page', () => {
    cy.visit('/ruta-que-no-existe');

    cy.location('pathname').should('eq', '/');
    cy.get('h1').should('contain.text', 'El arte de tus finanzas');
  });
});
