/** Every test starts as a first-time visitor: no stored cookie choice. */
beforeEach(() => {
  cy.clearAllLocalStorage();
});
