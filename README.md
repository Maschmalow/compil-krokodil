# README #

Repository pour le projet S7 compilation : compil-krokodil.

Pour lancer le projet : executer le script runTests.sh, il compile via bison et flex notre grammaire contenue dans grammar.y.

On obtient en sortie le parseur nommé "krokodil", il est utilisé dans les tests pour vérifier et générer le code LLVM de chaque fichier de test contenu dans le dossier tst/.

On peut voir ce code LLVM généré dans le fichier analysis.out. 
