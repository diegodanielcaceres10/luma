describe('Mobile navigation menu', () => {
  beforeEach(() => {
    cy.viewport('iphone-6');
    cy.visit('/');
  });

  const toggle = () => cy.get('button[aria-controls="mobile-menu"]');

  it('opens from the toggle and exposes its expanded state', () => {
    toggle().should('have.attr', 'aria-expanded', 'false').click();

    toggle().should('have.attr', 'aria-expanded', 'true');
    cy.get('#mobile-menu').should('be.visible');
  });

  it('closes after choosing a section link', () => {
    toggle().click();

    cy.get('#mobile-menu').contains('a', 'Funcionalidades').click();

    cy.get('#mobile-menu').should('not.exist');
    cy.location('hash').should('eq', '#funcionalidades');
  });

  it('closes with Escape and returns focus to the toggle', () => {
    toggle().click();

    cy.get('body').type('{esc}');

    cy.get('#mobile-menu').should('not.exist');
    toggle().should('have.focus');
  });
});
