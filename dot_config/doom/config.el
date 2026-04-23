;;; $Doomdir/config.el -*- lexical-binding: t; -*-

;; User
(setq user-full-name "Patrice Gnimdou"
      user-mail-address "patricesos7@gmail.com")

;; Load custom lisp files
(load! "keymap.el")

;; Font settings
(setq doom-font (font-spec :family "Maple Mono NF" :size 16)
      doom-variable-pitch-font (font-spec :family "Maple Mono NF" :size 13)
      doom-big-font (font-spec :family "Maple Mono NF" :size 20)
      ;; doom-symbol-font(font-spec :family "")
      ;; doom-serif-font (font-spec :family "" :size 18)
      )

;; Disable paren highlight
(show-paren-mode t)
(menu-bar-mode 1)
(tab-bar-mode 1)

;; Highlight tabulations
(setq-default highlight-tabs t)

;; Show trailing white spaces
(setq-default show-trailing-whitespace t)

;; Remove useless whitespace before saving a file
(add-hook 'before-save-hook 'whitespace-cleanup)
(add-hook 'before-save-hook (lambda() (delete-trailing-whitespace)))

;; Enable wraping
(setq-default word-wrap t)
(global-visual-line-mode t)
(visual-line-mode t)

;; Line display
(setq display-line-numbers-type 'visual)
(setq-default display-line-numbers-width 3)
(setq-default display-line-numbers-widen t)
(setq highlight-nonselected-windows nil)

;; Minibuffer settings
(setq max-mini-window-height 2.0)
(setq resize-mini-windows nil)

;; Emacs frame settings
(add-to-list 'default-frame-alist '(fullscreen . maximized))
;; (add-hook 'window-setup-hook 'toggle-frame-maximized t)

;; Theme settings and look
(setq doom-theme 'doom-molokai) ;; doom-molokai doom-material doom-peacock
(setq fancy-splash-image (file-name-concat doom-user-dir "assets/hole.png"))
;; (setq +dashboard-functions '(+dashboard-widget-banner))
(setq custom-safe-themes t)
;; (add-to-list 'custom-theme-load-path "~/.config/doom/themes/")
;; (load-theme 'zenburn)

;; Org-mode
(setq org-directory "~/org/")
(add-hook 'org-mode-hook #'org-modern-mode)
;; (add-hook 'org-agenda-finalize-hook #'org-modern-agenda)
;; (with-eval-after-load 'org (global-org-modern-mode))

;; projectile
(setq projectile-project-search-path '("~/code"))
(setq projectile-cleanup-known-projects nil)

;; https://www.alcarney.me/blog/2024/local-llms-with-ollama-and-gptel/
;;
;; (setq gptel-model 'qwen3.5:4b
;;       gptel-backend (gptel-make-ollama "Ollama"
;;                       :host "192.168.1.66:11434"
;;                       :stream t
;;                       :models '(qwen3.5:4b)))

(use-package eglot
  :hook ((sh-mode . eglot-ensure)        ; For standard shell mode
         (bash-ts-mode . eglot-ensure))) ; For tree-sitter bash mode

(use-package elpy
  :ensure t
  :defer t
  :init
  (elpy-enable))

;; (add-hook 'python-mode-hook 'elpy-mode)


;; (add-to-list 'load-path (expand-file-name "/path/to/origami.el/"))
;; (require 'origami)
(load! "packages/siege-mode.el")
;; (require 'siege-mode )


;; (use-package pdf-view-restore
;;   :after pdf-tools
;;   :config
;;   (add-hook 'pdf-view-mode-hook 'pdf-view-restore-mode))
;; (setq pdf-view-restore-filename "~/.pdf-view-restore")
;;


(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 18)))

(use-package python-mode
  :ensure t
  :hook (python-mode . elpy-mode))
