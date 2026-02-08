# language: de

@bestellung @lieferung
Funktionalität: Bestellverwaltung
  Als Online-Shop-Betreiber
  möchte ich Bestellungen effizient verwalten
  damit Kunden ihre Produkte rechtzeitig erhalten

  Grundlage:
    Angenommen das Bestellsystem ist verfügbar
    Und der Lagerbestand ist aktualisiert

  Szenario: Neue Bestellung aufgeben
    Angenommen ein Kunde mit der Adresse "Berliner Straße 42, 10115 Berlin"
    Und der Warenkorb enthält folgende Artikel:
      | Artikel           | Menge | Preis  |
      | Bluetooth-Lautsprecher | 1     | 49,99€ |
      | USB-Ladekabel     | 2     | 9,99€  |
    Wenn der Kunde die Bestellung aufgibt
    Dann wird eine Bestellbestätigung per E-Mail gesendet
    Und der Gesamtbetrag beträgt 69,97€

  Szenario: Bestellung stornieren
    Angenommen eine Bestellung mit der Nummer "ORD-2025-1842"
    Und der Status ist "in Bearbeitung"
    Wenn der Kunde die Stornierung beantragt
    Dann wird die Bestellung storniert
    Aber die Rückerstattung dauert 3-5 Werktage

  Szenario: Lieferstatus verfolgen
    Angenommen eine versandte Bestellung "ORD-2025-1700"
    Wenn der Kunde den Lieferstatus abfragt
    Dann wird der aktuelle Standort des Pakets angezeigt
    Und die voraussichtliche Lieferzeit wird berechnet
