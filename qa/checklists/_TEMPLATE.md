# Checklist : <NomModule>

> Fichier : `modules/<NomModule>.qml`
> Taille : <XX> KB
> Type de fenêtre : [Fenêtre standalone | Tab dans BeeConfig | Overlay | QtObject backend]
> Inspecté par : ____________
> Date : ____________

## Rendu de base

- [ ] La fenêtre s'affiche sans erreur console Qt
- [ ] Le fond est correct (couleur theme, pas de zone vide)
- [ ] Les bordures ne sont pas coupées par le contenu

## Texte

- [ ] Aucun texte ne déborde de son conteneur parent
- [ ] Aucun texte ne chevauche la bordure de la fenêtre
- [ ] Le texte long est tronqué (elide) ou wrap correctement
- [ ] Le line-height / line-spacing est cohérent
- [ ] Le contraste est lisible (mode nuit + mode jour)

## Icônes

- [ ] Toutes les icônes affichées servent à quelque chose (pas d'icône contextuelle orpheline)
- [ ] Aucune icône ne déborde de son conteneur
- [ ] Les icônes sont alignées avec le texte adjacent
- [ ] Taille cohérente entre les icônes de la même fenêtre

## Scrollbar

- [ ] Si présence de ListView/GridView → scrollbar visible
- [ ] La scrollbar a un style cohérent avec le theme
- [ ] Le ratio scrollbar/contenu est correct (pas une mini-barre pour 1000 items)
- [ ] Le scroll au trackpad/molette fonctionne

## Layout & ancrage

- [ ] Marges intérieures cohérentes (pas 0px partout)
- [ ] Espacement entre éléments cohérent
- [ ] Pas de chevauchement entre enfants
- [ ] Comportement au resize : pas de casse

## Comportement interactif

- [ ] Hover states visibles (changement de couleur/bordure)
- [ ] Click targets assez grands (min 32x32 idéalement)
- [ ] Pas de zone morte où on clique sans effet

## Mode nuit / jour

- [ ] Bascule night/day fonctionne
- [ ] Couleurs adaptées automatiquement

## BUGS identifiés

| ID        | Sévérité | Description courte                                 | Statut |
|-----------|----------|----------------------------------------------------|--------|
| BUG-XXX   | 🔴🟠🟡🟢 | description                                        | open   |

## Notes

(observations libres, TODO, questions)
