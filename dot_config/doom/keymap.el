;;; keymap.el -*- lexical-binding: t; -*-

(map! :leader
      (:prefix-map ("r" . "run")
       :desc "Quickrun"        "r"  #'quickrun
       :desc "Quickrun shell"  "s"  #'quickrun-shell
       :desc "Venv activate"   "v"  #'pyvenv-activate))

;(global-set-key (kbd "M-u") #'fix-word-upcase)
; (global-set-key (kbd "M-l") #'fix-word-downcase)
; (global-set-key (kbd "M-c") #'fix-word-capitalize)

;; (with-eval-after-load 'writeroom-mode
;;   (define-key writeroom-mode-map (kbd "C-M-<") #'writeroom-decrease-width)
;;   (define-key writeroom-mode-map (kbd "C-M->") #'writeroom-increase-width)
;;   (define-key writeroom-mode-map (kbd "C-M-=") #'writeroom-adjust-width))
