# Exemple d'entrée BUG (à déplacer dans visual-bugs.md)

## BUG-001-bee-bar-text-overflow

- **Sévérité** : 🟠 MAJEUR
- **Module** : `modules/BeeBar.qml`
- **Détecté par** : audit statique 10 juin 2026
- **Description** : 18 éléments Text dans BeeBar n'ont ni `elide` ni `wrapMode`. Combiné avec 8 anchors.fill sans anchors.margins, le texte des workspaces/notifs peut déborder ou chevaucher la bordure droite de la barre.
- **Reproduction** : Ouvrir BeeBar, avoir > 5 workspaces actifs, observer le texte tronqué bizarrement ou qui sort du cadre.
- **Fix proposé** : Ajouter `elide: Text.ElideRight` sur les Text de label, et `anchors.margins: 4` sur les containers principaux.
- **Statut** : open
- **Commit fix** : (à remplir)

---

Pour ajouter un nouveau bug, copier ce format dans `qa/visual-bugs.md` sous la bonne sévérité, et incrémenter le numéro.
