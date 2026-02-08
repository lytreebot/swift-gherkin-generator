# language: it

@catalogo @prodotti
Funzionalità: Gestione catalogo prodotti
  Come responsabile del catalogo
  Voglio gestire i prodotti in vendita
  Per mantenere il catalogo aggiornato

  Contesto:
    Dato che il sistema di gestione è attivo
    E il catalogo contiene almeno un prodotto

  Scenario: Aggiungere un nuovo prodotto
    Dato le seguenti informazioni del prodotto:
      | campo       | valore               |
      | nome        | Scarpe da corsa      |
      | prezzo      | 89,90€               |
      | categoria   | Sport                |
      | disponibile | sì                   |
    Quando aggiungo il prodotto al catalogo
    Allora il prodotto è visibile nel catalogo
    E il numero totale di prodotti aumenta di 1

  Scenario: Modificare il prezzo di un prodotto
    Dato un prodotto "Zaino da viaggio" con prezzo 45,00€
    Quando modifico il prezzo a 39,90€
    Allora il nuovo prezzo è 39,90€
    Ma il prezzo originale viene conservato nello storico

  Scenario: Rimuovere un prodotto esaurito
    Dato un prodotto "Cuffie wireless" con disponibilità 0
    Quando rimuovo il prodotto dal catalogo
    Allora il prodotto non è più visibile
