;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
(setq doom-font (font-spec :family "Maple Mono NF" :size 18 :weight 'semi-light)
      doom-variable-pitch-font (font-spec :family "Maple Mono NF" :size 13))
;;
(setq doom-theme 'doom-monokai-classic)
;;
;; nil or relative
(setq display-line-numbers-type 'relative)
;;
(setq org-directory "~/org/")
;;
(use-package! quickrun
  :bind ("C-c r" . quickrun-shell))
