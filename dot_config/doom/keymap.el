;;; keymap.el -*- lexical-binding: t; -*-

(map! :leader
      (:prefix-map ("r" . "run")
       :desc "Quickrun"        "r"  #'quickrun
       :desc "Quickrun shell"  "s"  #'quickrun-shell
       :desc "Venv activate"   "v"  #'pyvenv-activate))
