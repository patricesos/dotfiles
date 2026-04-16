;;; $DOOMDIR/config.rl -*- lexical-binding: t; -*-

;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face

;; (global-visual-line-mode t)
;; (visual-line-mode t)

;; (setq default-frame-alist '((width . 0) (height . 0) (menu-bar-lines . 1)))
;; (add-hook 'window-setup-hook 'toggle-frame-maximized t)
(setq-default word-wrap t)
(add-to-list 'default-frame-alist '(fullscreen . maximized))


;; (toggle-word-wrap 1)
;; (setq toggle-truncate-lines 1)

(load! "keymap.el")

(setq doom-font (font-spec :family "Maple Mono NF" :size 16 :weight 'semi-light)
      doom-variable-pitch-font (font-spec :family "Maple Mono NF" :size 13))

(setq doom-theme 'doom-monokai-classic)
(setq display-line-numbers-type 'relative)

(setq org-directory "~/org/")
(setq projectile-project-search-path "~/code/")

;; https://www.alcarney.me/blog/2024/local-llms-with-ollama-and-gptel/
;;
;; (setq gptel-model 'qwen3.5:4b
;;       gptel-backend (gptel-make-ollama "Ollama"
;;                       :host "192.168.1.66:11434"
;;                       :stream t
;;                       :models '(qwen3.5:4b)))
