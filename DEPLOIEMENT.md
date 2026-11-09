# REPART — GitHub → Vercel

## Dépôt canonique

- GitHub : https://github.com/IA-optimist/Repart
- Branche : `main`
- Vercel (site existant) : `repart-marketplace-demo`
- URL publique existante : https://repart-auto-demo.vercel.app/

## Premier push

Ce dépôt a été créé sur GitHub, mais il faut accorder à l'intégration GitHub ChatGPT l'accès en écriture à **IA-optimist/Repart** avant le premier push. Si elle n'est pas installée sur le compte ou n'a pas accès à ce dépôt, installer/réautoriser l'intégration GitHub puis sélectionner le nouveau dépôt parmi les dépôts autorisés. Ne jamais partager de token personnel dans la conversation.

Pour pousser manuellement, depuis la racine de ce projet :

```bash
git remote add origin https://github.com/IA-optimist/Repart.git
git push -u origin main
```

L'authentification doit être assurée par Git Credential Manager, GitHub CLI ou votre configuration Git locale. **Ne pas intégrer de mot de passe ou de jeton dans l'URL distante.**

## Relier le projet Vercel existant

1. Ouvrir Vercel → projet **repart-marketplace-demo** → Settings → Git → Connect Git Repository.
2. Choisir **IA-optimist/Repart**. Ne pas créer un nouveau projet Vercel.
3. Framework Preset : Other ; Root Directory : `./` ; Output Directory : `public` via `vercel.json`.
4. Vérifier Preview, puis production et les deux pages publiques depuis l'Europe et le Maroc.

Une fois la connexion active, les pushes sur `main` pourront déclencher les déploiements Vercel. Les secrets futurs doivent être enregistrés comme variables d'environnement Vercel, jamais dans le dépôt.

## Sécurité

La version V0.6 reste une **démonstration**. Les schémas SQL ne sont pas déployés. Les règlements, commandes, publications d'annonces et comptes vendeurs ne sont pas réels.
