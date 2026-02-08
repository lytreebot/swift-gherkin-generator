# language: fr

@authentification @securite
Fonctionnalité: Gestion des comptes utilisateurs
  En tant qu'administrateur système
  Je veux gérer les comptes utilisateurs
  Afin de contrôler l'accès à la plateforme

  Contexte:
    Soit un administrateur connecté
    Et le module de gestion des utilisateurs est actif

  Scénario: Créer un nouveau compte utilisateur
    Soit les informations suivantes :
      | champ   | valeur              |
      | nom     | Jean Dupont         |
      | email   | jean@exemple.fr     |
      | rôle    | éditeur             |
    Quand je crée le compte utilisateur
    Alors le compte est créé avec succès
    Et un email de bienvenue est envoyé à "jean@exemple.fr"

  Scénario: Désactiver un compte utilisateur
    Soit un utilisateur actif "marie@exemple.fr"
    Quand je désactive le compte
    Alors le compte est marqué comme inactif
    Mais les données de l'utilisateur sont conservées

  @critique
  Scénario: Réinitialiser le mot de passe
    Soit un utilisateur "pierre@exemple.fr" ayant oublié son mot de passe
    Quand je lance la procédure de réinitialisation
    Alors un lien de réinitialisation est envoyé par email
    Et le lien expire après 24 heures

  Plan du Scénario: Validation des rôles utilisateurs
    Soit un utilisateur avec le rôle "<role>"
    Quand il accède à la section "<section>"
    Alors l'accès est "<resultat>"

    Exemples:
      | role          | section        | resultat |
      | administrateur | administration | autorisé |
      | éditeur       | contenu        | autorisé |
      | éditeur       | administration | refusé   |
      | lecteur       | contenu        | autorisé |
      | lecteur       | administration | refusé   |
