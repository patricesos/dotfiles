;;; c4d.el --- Cinéma 4D depuis Emacs (via le bridge Python)
;;; Commentary:
;;;
;;; Pourquoi ce fichier ?
;;;     On veut pouvoir appuyer sur une touche dans Emacs et voir le
;;;     résultat dans C4D immédiatement.  Le pont ("bridge") entre
;;;     les deux est un programme Python (c4dbridge) qui tourne en
;;;     permanence et translate entre Emacs et C4D.
;;;
;;; Topologie WSL2 (important, lis avant de modifier ce fichier) :
;;;     Le bridge (c4dbridge) tourne CÔTÉ WINDOWS, avec C4D.  Cet
;;;     Emacs tourne dans WSL2.  Conséquence directe sur ce fichier :
;;;
;;;     1. On ne peut PLUS tenter de démarrer le bridge depuis Emacs
;;;        (start-process lancerait un process Linux qui ne pourrait
;;;        jamais joindre C4D — qui n'existe que côté Windows).  Le
;;;        bridge doit être démarré manuellement côté Windows.  Ce
;;;        fichier se contente de VÉRIFIER qu'il répond, et d'avertir
;;;        clairement sinon.
;;;
;;;     2. On ne teste plus la connexion réseau nous-mêmes en Elisp
;;;        (l'ancienne version ouvrait une socket vers "127.0.0.1",
;;;        ce qui est faux depuis WSL2 : il faudrait l'IP de la
;;;        passerelle Windows). On délègue ce calcul à
;;;        `c4dbridge status`, qui connaît déjà cette logique côté
;;;        Python (détection auto de l'IP, overridable via
;;;        C4DBRIDGE_HOST). Pas de duplication de la logique réseau
;;;        entre deux langages.
;;;
;;;     3. (getenv "TEMP") n'existe pas sous Linux/WSL — on utilise
;;;        `temporary-file-directory`, la variable Emacs portable
;;;        (équivalent natif de tempfile.gettempdir() en Python).
;;;
;;; Comment ça marche (haut niveau) :
;;;     1. L'utilisateur appuie sur C-c C-c dans un buffer Python
;;;     2. Emacs sauvegarde le fichier, puis lance :
;;;        c4dbridge execute <chemin_du_fichier>
;;;     3. c4dbridge envoie le code à C4D via WebSocket (port 7788)
;;;     4. C4D exécute le script, le résultat s'affiche dans C4D
;;;     5. Le message de confirmation du bridge s'affiche dans
;;;        le minibuffer Emacs (pas de fenêtre parasite)
;;;
;;; Ce fichier ne contient QUE du code Emacs Lisp ("Elisp") —
;;; le langage de programmation d'Emacs.  Si tu ne connais pas,
;;; voici les bases pour lire ce qui suit :
;;;
;;;   (nom-fonction arg1 arg2)    — tout est entre parenthèses, le
;;;                                 premier mot est le nom de la
;;;                                 fonction, le reste ses arguments
;;;   'symbole                    — l'apostrophe = "ne pas évaluer"
;;;                                 (comme "ne pas exécuter, c'est
;;;                                 juste un nom")
;;;   :clef                       — les deux-points = un mot-clé
;;;                                 (utilisé comme étiquette)
;;;   "chaîne"                    — entre guillemets, comme en Python
;;;   #'fonction                  — dièse-apostrophe = "référence à
;;;                                 une fonction" (on peut la passer
;;;                                 en argument)
;;;   ;; commentaire              — deux points-virgules = commentaire
;;;   `(,variable . normale)      — backquote + virgule = template
;;;                                 (comme une f-string ${variable})
;;;
;;; Noms de fonctions :
;;;   c4d--quelque-chose  — fonction "privée" (interne, pas pour
;;;                         l'utilisateur)
;;;   c4d-quelque-chose   — fonction "publique" (appelable par
;;;                         l'utilisateur directement)
;;;
;;; -*- lexical-binding: t; -*-  — active la portée lexicale des
;;;                                variables (concept avancé, dis
;;;                                juste que c'est le comportement
;;;                                moderne et prévisible)


;;; Code:
;; ── Gestion du bridge ──────────────────────────────────────────────────
;;
;; Le bridge (c4dbridge) est un serveur Python qui doit tourner en
;; arrière-plan, côté Windows.  Cette fonction vérifie qu'il est en
;; vie ; elle NE le démarre PLUS automatiquement (voir note de tête
;; de fichier sur la topologie WSL2).

;; -----------------------------------------------------------------------
;; c4d--bridge-running-p  (interne)
;; -----------------------------------------------------------------------
;; Vérifie si le bridge répond, en délégant à `c4dbridge status`.
;;
;; Pourquoi déléguer plutôt que tester la socket nous-mêmes ?
;;   Parce que l'adresse à joindre dépend de la topologie (127.0.0.1
;;   en local, IP de la passerelle Windows depuis WSL2).  Cette
;;   logique existe déjà côté Python (constants.py,
;;   _detect_windows_host_ip).  La dupliquer en Elisp serait une
;;   deuxième source de vérité à maintenir en synchro — un piège
;;   classique.  `call-process' est l'équivalent Elisp de
;;   subprocess.run : on lance "c4dbridge status" et on regarde son
;;   code de sortie (0 = bridge joignable, non-zéro = pas joignable).
;;
;; Retourne : t (vrai) si le bridge répond, nil (faux) sinon.

(defun c4d--bridge-running-p ()
  "Return t si le bridge C4D répond (délègue à `c4dbridge status')."
  (condition-case nil
      (= 0 (call-process "c4dbridge" nil nil nil "status"))
    (error nil)))

;; -----------------------------------------------------------------------
;; c4d--ensure-bridge  (interne)
;; -----------------------------------------------------------------------
;; S'assure que le bridge répond. Si ce n'est pas le cas, on NE
;; tente PAS de le démarrer ici (contrairement à l'ancienne version) :
;; le bridge tourne côté Windows, cet Emacs tourne dans WSL2 —
;; `start-process' lancerait un bridge Linux qui ne pourrait jamais
;; joindre C4D (qui n'existe que côté Windows). On prévient
;; clairement l'utilisateur à la place.

(defun c4d--ensure-bridge ()
  "Vérifie que le bridge C4D répond ; signale une erreur claire sinon.

    Ne tente jamais de démarrer le bridge localement : sous WSL2, le
    bridge doit tourner côté Windows (avec C4D), pas dans Emacs/WSL."
  (unless (c4d--bridge-running-p)
    (error
     "Bridge non joignable. Démarrez-le côté Windows (c4dbridge), puis réessayez")))


;; ── Fonctions utilisateur ──────────────────────────────────────────────
;;
;; Quatre actions possibles :
;;
;;   1. Exécuter tout le buffer Python   (le cas le plus fréquent)
;;   2. Exécuter seulement une sélection  (pour tester un extrait)
;;   3. Charger dans le Script Manager    (ouvre le script dans C4D
;;      sans l'exécuter)
;;   4. Ré-exécuter le dernier script     (pratique pour itérer : on
;;      modifie le code, on rappelle la même commande)
;;
;; Chacune :
;;   a. Vérifie que le bridge répond (erreur claire sinon, pas
;;      d'auto-démarrage — voir c4d--ensure-bridge)
;;   b. Sauvegarde le fichier ou écrit le fichier temporaire
;;   c. Appelle « c4dbridge <action> <fichier> » via
;;      shell-command-to-string (pas shell-command — ne crée pas
;;      de buffer/fenêtre parasite)
;;   d. Affiche le résultat dans le minibuffer via message
;;
;; Technique Lisp :
;;   "interactive"  = déclare la fonction comme commande Emacs
;;                     (appelable par M-x ou par un raccourci clavier)
;;   "let"          = crée des variables locales (comme "let" en Rust
;;                     ou "const" en JS)
;;   "unless"       = si la condition est fausse, exécute le bloc
;;   "save-buffer"  = sauvegarde le fichier courant sur le disque
;;   "shell-command-to-string" = exécute une commande et retourne
;;                     sa sortie stdout sans fenêtre parasite
;;   "message"      = affiche un message dans le minibuffer
;;   "string-trim"  = enlève les sauts de ligne en trop
;;   "temporary-file-directory" = dossier temporaire portable
;;                     (équivalent de tempfile.gettempdir() en Python ;
;;                     contrairement à (getenv "TEMP"), fonctionne
;;                     aussi bien sous Windows que sous WSL/Linux)

;; -----------------------------------------------------------------------
;; c4d-execute-buffer  (publique)
;; -----------------------------------------------------------------------
;; Raccourci :
;;   Doom :  SPC m c  ou  C-c C-c
;;
;; Envoie le fichier Python actuellement ouvert à C4D et l'exécute.
;;
;; Déroulement :
;;   1. Vérifie que le fichier est sauvegardé sur le disque
;;   2. Sauvegarde (au cas où l'utilisateur a oublié)
;;   3. Lance : c4dbridge execute /chemin/du/fichier.py
;;   4. Affiche le résultat du bridge dans le minibuffer
;;
;; Pourquoi sauvegarder avant d'exécuter ?
;;   Le bridge lit le contenu du fichier depuis le disque.  Si le
;;   buffer n'est pas sauvegardé, le fichier sur le disque est
;;   périmé — C4D exécuterait l'ancienne version.
;;
;; Pourquoi passer par le shell plutôt que directement par le
;;   réseau comme la version WebSocket ?  Le bridge simplifie tout.
;;   Plus besoin de normaliser les chemins, gérer le sous-protocole,
;;   reconnecter, etc.  On utilise l'infra déjà écrite.

;;;###autoload
;; ← le « ;;;###autoload » est un marqueur Doom : ça dit à Doom
;;   de charger cette fonction « paresseusement » (seulement quand
;;   on en a besoin, pas au démarrage d'Emacs).  Gain de temps.
(defun c4d-execute-buffer ()
  "Envoie le buffer courant à C4D via le bridge et l'exécute."
  (interactive)
  (c4d--ensure-bridge)
  (let ((filepath (buffer-file-name)))
    (unless filepath
      (error "Buffer non sauvegardé. Sauvegardez d'abord"))
    (save-buffer)
    ;; « shell-command-to-string » exécute la commande et retourne
    ;; sa sortie sous forme de chaîne sans ouvrir de fenêtre.
    ;; Contrairement à shell-command, pas de buffer, pas de popup.
    (message "%s"
             (ansi-color-apply
              (string-trim
               (shell-command-to-string
                (format "c4dbridge execute %s" (shell-quote-argument filepath))))))))

;; -----------------------------------------------------------------------
;; c4d-execute-region  (publique)
;; -----------------------------------------------------------------------
;; Raccourci :
;;   Doom :  SPC m r  ou  C-c C-r
;;
;; Envoie seulement le texte sélectionné (la région) à C4D.
;;
;; Pourquoi un fichier temporaire plutôt qu'envoyer le texte brut ?
;;   Le bridge s'attend à recevoir un chemin de fichier.  Pour
;;   exécuter une région, on écrit le texte dans un fichier
;;   temporaire (c4d_region.py dans temporary-file-directory), puis
;;   on appelle execute sur ce fichier comme si c'était un fichier
;;   normal.
;;
;; Limitation : le fichier temporaire s'appelle toujours pareil.
;;   Si on exécute deux régions à la suite, la deuxième écrase
;;   la première.  C'est voulu — on ne veut pas accumuler des
;;   fichiers temporaires.

;;;###autoload
(defun c4d-execute-region (start end)
  "Envoie la région sélectionnée à C4D via le bridge et l'exécute.
Écrit la région dans un fichier temporaire d'abord."
  ;; « interactive "r" » = la fonction reçoit deux arguments :
  ;;   « start » et « end », les positions de début et fin de
  ;;   la sélection.  Emacs les passe automatiquement.
  (interactive "r")
  (c4d--ensure-bridge)
  ;; « let* » (avec astérisque) = comme « let » mais les variables
  ;; peuvent se référer les unes aux autres (ordre séquentiel)
  (let* ((tmpfile (expand-file-name "c4d_region.py" temporary-file-directory))
         ;; « buffer-substring-no-properties » = récupère le texte
         ;; entre deux positions, sans les infos de coloration
         (content (buffer-substring-no-properties start end)))
    ;; Si le début et la fin sont au même endroit, pas de sélection
    (when (= start end)
      (error "Sélectionnez une région valide"))
    ;; « with-temp-file » = crée un fichier temporaire, écrit
    ;; le contenu dedans, le sauvegarde sur le disque
    (with-temp-file tmpfile
      (insert content))
    (message "%s"
             (ansi-color-apply
              (string-trim
               (shell-command-to-string
                (format "c4dbridge execute %s" (shell-quote-argument tmpfile))))))))

;; -----------------------------------------------------------------------
;; c4d-load-in-manager  (publique)
;; -----------------------------------------------------------------------
;; Raccourci :
;;   Doom :  SPC m l  ou  C-c C-l
;;
;; Ouvre le script dans le Script Manager de C4D sans l'exécuter.
;; Utile pour : inspecter le code dans C4D, le modifier depuis C4D,
;; le lier à un tag ou un objet.
;;
;; Différence avec execute :
;;   load = envoie le code à C4D, l'affiche dans le Script Manager,
;;          mais ne le lance pas.
;;   execute = envoie le code à C4D et le lance immédiatement.

;;;###autoload
(defun c4d-load-in-manager ()
  "Charge le buffer courant dans le Script Manager de C4D sans l'exécuter."
  (interactive)
  (c4d--ensure-bridge)
  (let ((filepath (buffer-file-name)))
    (unless filepath
      (error "Buffer non sauvegardé. Sauvegardez d'abord"))
    (save-buffer)
    (message "%s"
             (ansi-color-apply
              (string-trim
               (shell-command-to-string
                (format "c4dbridge load %s" (shell-quote-argument filepath))))))))

;; -----------------------------------------------------------------------
;; c4d-reexecute-last  (publique)
;; -----------------------------------------------------------------------
;; Raccourci :
;;   Doom :  SPC m e  ou  C-c C-e
;;
;; Ré-exécute le dernier script qu'on a lancé.  Utile pour le
;; cycle "modifier → lancer → modifier → lancer".
;;
;; Comment le bridge se souvient du dernier script ?
;;   c4dbridge écrit le chemin dans un fichier marqueur (dossier
;;   temporaire système) à chaque execute / load.  La commande
;;   reexecute lit ce fichier et renvoie le même code à C4D.
;;
;; Pourquoi ne pas utiliser une variable Emacs c4d-last-file ?
;;   Parce que le marqueur est partagé : si tu passes de Zed à
;;   Emacs (ou l'inverse), le "dernier script" est le même.
;;   C'est cohérent entre les deux éditeurs.

;;;###autoload
(defun c4d-reexecute-last ()
  "Ré-exécute le dernier script via le bridge (marqueur disque)."
  (interactive)
  (c4d--ensure-bridge)
  (message "%s"
           (ansi-color-apply
            (string-trim
             (shell-command-to-string "c4dbridge reexecute")))))


;; ── Keybindings (raccourcis clavier) ───────────────────────────────────
;;
;; On attache les quatre fonctions ci-dessus à des touches, mais
;; SEULEMENT dans les buffers Python.  Pas envie que C-c C-c fasse
;; une exécution C4D dans un buffer Markdown ou Org.
;;
;; Deux styles de raccourcis sont définis :
;;
;;   1. Localleader (SPC m) — le style Doom
;;      SPC m c = execute  |  SPC m l = load
;;      SPC m r = region   |  SPC m e = reexecute
;;
;;   2. Classique (C-c) — le style Emacs historique
;;      C-c C-c = execute  |  C-c C-l = load
;;      C-c C-r = region   |  C-c C-e = reexecute
;;
;; Pourquoi deux fois les mêmes bindings (python-mode ET
;; python-ts-mode) ?
;;   Emacs 29 a introduit python-ts-mode (avec arbre syntaxique
;;   « tree-sitter »).  On ne sait pas si l'utilisateur utilise
;;   l'ancien ou le nouveau mode.  On définit les deux au cas où.

;; « after! python » = attend que le mode Python soit chargé avant
;; d'ajouter les raccourcis (évite les erreurs si Python n'est pas
;; encore actif au démarrage d'Emacs)
(after! python
  ;; ── Localleader (SPC m) ─────────────────────────────────
  ;; « map! » = macro Doom pour créer des raccourcis simplement
  ;; « :localleader » = les touches sont sous SPC m (leader local
  ;;   au mode)
  ;; « :mode python-mode » = ces bindings ne s'activent que dans
  ;;   les buffers python-mode
  ;;
  ;; Syntaxe : une lettre + la fonction à appeler
  ;;   "c" → SPC m c  appelle  c4d-execute-buffer
  ;;   "l" → SPC m l  appelle  c4d-load-in-manager
  ;;   ...etc.
  (map! :localleader :mode python-mode
        "c" #'c4d-execute-buffer
        "l" #'c4d-load-in-manager
        "e" #'c4d-reexecute-last
        "r" #'c4d-execute-region
        "R" #'c4d-repl)
  (map! :localleader :mode python-ts-mode
        "c" #'c4d-execute-buffer
        "l" #'c4d-load-in-manager
        "e" #'c4d-reexecute-last
        "r" #'c4d-execute-region
        "R" #'c4d-repl)

  (map! :map python-mode-map
        "C-c C-c" #'c4d-execute-buffer
        "C-c C-l" #'c4d-load-in-manager
        "C-c C-e" #'c4d-reexecute-last
        "C-c C-r" #'c4d-execute-region
        "C-c C-z" #'c4d-repl)
  (map! :map python-ts-mode-map
        "C-c C-c" #'c4d-execute-buffer
        "C-c C-l" #'c4d-load-in-manager
        "C-c C-e" #'c4d-reexecute-last
        "C-c C-r" #'c4d-execute-region
        "C-c C-z" #'c4d-repl))


;; -----------------------------------------------------------------------
;; c4d-repl  (publique)
;; -----------------------------------------------------------------------
;; Raccourci :
;;   Doom :  SPC m R  ou  C-c C-z   (convention Emacs pour "switch
;;           to inferior process", comme run-python)
;;
;; Ouvre (ou bascule vers) un buffer REPL connecté à C4D.
;;
;; Comment ça marche :
;;   On ne réinvente pas de protocole socket en Elisp.
;;   `c4dbridge repl' est un sous-process Python normal qui lit
;;   des lignes sur stdin et écrit les résultats sur stdout — donc
;;   on le branche sur `make-comint', exactement comme `run-python'
;;   branche un `python -i'.  Comint gère gratuitement :
;;   l'historique des commandes (flèches haut/bas), l'édition de
;;   ligne, le scroll, l'envoi de Ctrl-C au sous-process.
;;
;; Pourquoi `comint-mode' directement plutôt qu'un mode dérivé
;; custom (genre inferior-python-mode) ?
;;   Pour cette première version, comint-mode suffit : pas besoin
;;   de coloration syntaxique Python avancée dans le REPL, juste
;;   une boucle prompt/réponse fiable.  On pourra dériver un mode
;;   plus riche plus tard si besoin (complétion, docstring au
;;   survol, etc.) sans casser ce qui existe déjà.
;;
;; État persistant :
;;   Le namespace Python (les variables définies) vit côté C4D
;;   (voir protocol.py, build_repl_eval_script) — pas dans ce
;;   buffer Emacs ni dans le sous-process c4dbridge repl.  Fermer
;;   et rouvrir ce buffer ne perd donc pas l'état tant que C4D ne
;;   redémarre pas.

;;;###autoload
(defun c4d-repl ()
  "Ouvre un buffer REPL connecté à C4D (via `c4dbridge repl')."
  (interactive)
  (c4d--ensure-bridge)
  (let ((buf (make-comint "c4d-repl" "c4dbridge" nil "repl")))
    (with-current-buffer buf
      (comint-mode)
      (ansi-color-for-comint-mode-on))
    (pop-to-buffer buf)))


;; ── Fin du module ──────────────────────────────────────────────────────
;;
;; « provide » enregistre le module « c4d » auprès d'Emacs.
;; Permet à d'autres fichiers de faire (require 'c4d) pour
;; charger ce module.  C'est une convention standard.
(provide 'c4d)

;;; c4d.el ends here
