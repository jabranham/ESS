;;; ess-mode.el --- Support for editing ESS source code

;; Copyright (C) 1989-1994 Doug Bates, Ed Kademan, Frank Ritter, David Smith.
;; Copyright (C) 1997--2010 A.J. Rossini, Richard M. Heiberger, Martin
;;      Maechler, Kurt Hornik, Rodney Sparapani, and Stephen Eglen.
;; Copyright (C) 2011--2012 A.J. Rossini, Richard M. Heiberger, Martin Maechler,
;;      Kurt Hornik, Rodney Sparapani, Stephen Eglen and Vitalie Spinu.

;; Author: David Smith <dsmith@stats.adelaide.edu.au>
;; Created: 7 Jan 1994
;; Maintainer: ESS-core <ESS-core@r-project.org>

;; This file is part of ESS

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; A copy of the GNU General Public License is available at
;; http://www.r-project.org/Licenses/

;;; Commentary:

;; Code for editing ESS source code.

;;; Code:

 ; Requires and autoloads

;;; AJR: THIS IS GROSS AND DISGUSTING (but I wrote it).
;;; MM:  and I had to add all other 'ess-eval-*** ...
;;; >>> why not just do the obvious instead of all these ? Namely,
;;; (require 'ess-inf)
;;; ------------------ ?
;;; AJR: The reason is that we ONLY need to load ess-inf for the
;;; functions which are interactive in nature.   We don't want to load
;;; it when we are only editing.

;;; VS: ess-inf is always loaded form ess-toggle-underscore in ess-s-l.el. I am
;;; placing require ess-inf and ess-mode in ess. This cross autoloads are
;;; useless. Compiler is also silent without them. These funcs are used in mode-map
;;; only as symbols.

;; (autoload 'ess-mode-minibuffer-map      "ess-inf" "" nil 'keymap)
;; (autoload 'ess-read-object-name         "ess-inf" "" nil)
;; (autoload 'ess-list-object-completions  "ess-inf" "" nil)

;; (autoload 'ess-eval-buffer              "ess-inf" "" nil)
;; (autoload 'ess-eval-buffer-and-go       "ess-inf" "" nil)
;; (autoload 'ess-eval-function            "ess-inf" "" nil)
;; (autoload 'ess-eval-function-and-go     "ess-inf" "" nil)
;; (autoload 'ess-eval-function-or-paragraph-and-step
;;   "ess-inf" "" nil)
;; (autoload 'ess-eval-line                "ess-inf" "" nil)
;; (autoload 'ess-eval-line-and-go         "ess-inf" "" nil)
;; (autoload 'ess-eval-line-and-step       "ess-inf" "" nil)
;; (autoload 'ess-eval-linewise            "ess-inf" "" nil)
;; (autoload 'ess-eval-paragraph           "ess-inf" "" nil)
;; (autoload 'ess-eval-paragraph-and-go    "ess-inf" "" nil)
;; (autoload 'ess-eval-paragraph-and-step  "ess-inf" "" nil)
;; (autoload 'ess-eval-region              "ess-inf" "" nil)
;; (autoload 'ess-eval-region-and-go       "ess-inf" "" nil)

;; (autoload 'ess-load-file                "ess-inf" "" nil)
;; (autoload 'ess-switch-process           "ess-inf" "" nil)
;; (autoload 'ess-switch-to-ESS            "ess-inf" "" nil)
;; (autoload 'ess-request-a-process        "ess-inf" "" nil)
;; (autoload 'ess-get-process              "ess-inf" "" nil)
;; (autoload 'ess-command                  "ess-inf" "" nil)
;; (autoload 'ess-create-temp-buffer       "ess-inf" "" nil)
;; (autoload 'ess-display-temp-buffer      "ess-inf" "" nil)
;; (autoload 'ess-force-buffer-current     "ess-inf" "" nil)
;; (autoload 'ess-make-buffer-current      "ess-inf" "" nil)
;; (autoload 'ess-modtime-gt               "ess-inf" "" nil)
;; (autoload 'ess-object-modtime           "ess-inf" "" nil)
;; (autoload 'ess-quit                     "ess-inf" "" nil)

(autoload 'ess-turn-on-eldoc            "ess-r-d" "" nil)
;; (autoload 'ess-ddeclient-p              "ess-inf" "(autoload)" nil)
(autoload 'ess-dump-object-ddeclient        "ess-dde" "(autoload)" nil)
(autoload 'SAS                              "ess-sas-d.el" "(autoload)" t)

(require 'ess-utils)

(defun ess-line-end-position (&optional N)
  "return the 'point' at the end of N lines. N defaults to 1, i.e., current line."
  (save-excursion
    (end-of-line N)
    (point)))


 ; ESS mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; In this section:
;;;;
;;;; * The major mode ess-mode
;;;; * Commands for ess-mode
;;;; * Code evaluation commands
;;;; * Indenting code and commands
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;*;; Major mode definition


(defvar ess-mode-map
  (let ((map (make-sparse-keymap)))

    ;; By popular demand:
    (define-key map "\C-m"       'newline-and-indent); = [RETURN]
    (define-key map [remap yank] 'ess-yank)

    (define-key map "\C-c\C-r"   'ess-eval-region)
    (define-key map "\C-c\M-r"   'ess-eval-region-and-go)
    (define-key map "\C-c\C-b"   'ess-eval-buffer)
    (define-key map "\C-c\M-b"   'ess-eval-buffer-and-go)
    (define-key map (kbd "C-c C-<up>")   'ess-eval-buffer-from-beg-to-here)
    (define-key map (kbd "C-c C-<down>") 'ess-eval-buffer-from-here-to-end)
    (define-key map "\C-c\C-f"   'ess-eval-function)
    (define-key map "\C-c\M-f"   'ess-eval-function-and-go)
    (define-key map "\C-c\C-c"   'ess-eval-region-or-function-or-paragraph-and-step)
    (define-key map "\C-c\C-p"   'ess-eval-paragraph-and-step)
    (define-key map "\C-c\M-p"   'ess-eval-paragraph-and-go)
    (define-key map "\C-\M-x"    'ess-eval-region-or-function-or-paragraph)
    (define-key map "\C-c\C-n"   'ess-eval-line-and-step)
    (define-key map "\C-c\C-j"   'ess-eval-line)
    (define-key map [(control return)] 'ess-eval-region-or-line-and-step)
    (define-key map "\C-c\M-j"   'ess-eval-line-and-go)
    ;; the next three can only work in S/R - mode {FIXME}
    (define-key map "\C-\M-a"    'ess-goto-beginning-of-function-or-para)
    (define-key map "\C-\M-e"    'ess-goto-end-of-function-or-para)
    (define-key map "\C-xnd"     'ess-narrow-to-defun)
    (define-key map "\C-c\C-y"   'ess-switch-to-ESS-deprecated)
    (define-key map "\C-c\C-z"   'ess-switch-to-inferior-or-script-buffer)
    (define-key map "\C-c\C-l"   'ess-load-file)
    (define-key map "\C-c\M-l"   'ess-load-file); alias, as in 'iESS' where C-c C-l is comint-list-*
    (define-key map "\C-c\C-v"   'ess-display-help-on-object)
    ;;(define-key map "\C-c5\C-d"'ess-dump-object-into-edit-buffer-other-frame)
    (define-key map "\C-c\C-s"   'ess-switch-process) ; use a
    ;; different process for the buffer.
    ;; (define-key map "\C-c\C-t"   'ess-execute-in-tb)
    (define-key map "\C-c\t"     'ess-complete-object-name-deprecated)
    ;;M  (define-key map "\C-c\t"        'comint-dynamic-complete-filename)
    (unless (and (featurep 'emacs) (>= emacs-major-version 24))
      (define-key map "\M-\t"    'comint-dynamic-complete))
    (define-key map "\M-?"       'ess-list-object-completions)
    ;; wrong here (define-key map "\C-c\C-k" 'ess-request-a-process)
    (define-key map "\C-c\C-k"   'ess-force-buffer-current)
    (define-key map "\C-c`"      'ess-show-traceback)
    (define-key map [(control ?c) ?~] 'ess-show-call-stack)
    (define-key map "\C-c."      (lambda () (interactive) (message "ess-set-style moved to C-c C-e C-s. Sorry for the inconvenience")))
    (define-key map "{"          'ess-electric-brace)
    (define-key map "}"          'ess-electric-brace)
    (define-key map "\C-\M-q"    'ess-indent-exp)
    (define-key map "\C-\M-h"    'ess-mark-function)
    (if (featurep 'xemacs) ;; work around Xemacs bug (\C-\M-h redefines M-BS):
        (define-key map [(meta backspace)] 'backward-kill-word))
    ;;(define-key map [delete]   'backward-delete-char-untabify)
    (define-key map "\t"         'ess-indent-or-complete)
    (define-key map "\C-c\C-q"   'ess-quit)
    (define-key map "\M-\r"      'ess-use-this-dir)

    ;; smart operators; most likely will go in the future into a separate local map
    (define-key map ","          'ess-smart-comma)

    (define-key map "\C-c\C-d"   'ess-doc-map)
    (define-key map "\C-c\C-e"   'ess-extra-map)
    (define-key map "\C-c\C-t"   'ess-dev-map)
    map)
  "Keymap for `ess-mode'.")


(defvar ess-eval-map
  (let ((map (make-sparse-keymap)))
    ;; (define-key map "\C-r"    'ess-eval-region)
    ;; (define-key map "\M-r"    'ess-eval-region-and-go)
    ;; (define-key map "\C-b"    'ess-eval-buffer)
    ;; (define-key map "\M-b"    'ess-eval-buffer-and-go)
    ;; (define-key map "\C-f"    'ess-eval-function)
    ;; (define-key map "\M-f"    'ess-eval-function-and-go)
    ;; (define-key map "\C-x"    'ess-eval-function)
    ;; (define-key map "\C-n"    'ess-eval-line-and-step)
    ;; (define-key map "\C-j"    'ess-eval-line)
    ;; (define-key map "\M-j"    'ess-eval-line-and-go)
    map)
  "Keymap for ess-eval functions.")
(make-obsolete-variable 'ess-eval-map nil "ESS[12.09.1]")

(defvar ess-extra-map
  (let (ess-extra-map)
    (define-prefix-command 'ess-extra-map)
    (define-key ess-extra-map "\C-d" 'ess-dump-object-into-edit-buffer)
    (define-key ess-extra-map "d" 'ess-dump-object-into-edit-buffer)
    (define-key ess-extra-map "\C-e" 'ess-execute)
    (define-key ess-extra-map "e" 'ess-execute)
    (define-key ess-extra-map "\C-i" 'ess-install-library)
    (define-key ess-extra-map "i" 'ess-install-library)
    (define-key ess-extra-map "\C-l" 'ess-load-library)
    (define-key ess-extra-map "l" 'ess-load-library)
    (define-key ess-extra-map "\C-s" 'ess-set-style)
    (define-key ess-extra-map "s" 'ess-set-style)
    (define-key ess-extra-map "\C-t" 'ess-build-tags-for-directory)
    (define-key ess-extra-map "t" 'ess-build-tags-for-directory)
    (define-key ess-extra-map "\C-w" 'ess-execute-screen-options)
    (define-key ess-extra-map "w" 'ess-execute-screen-options)
    (define-key ess-extra-map "/" 'ess-set-working-directory)
    ess-extra-map)
  "ESS extra map")


(require 'ess-noweb-mode)

(easy-menu-define
  ess-mode-menu ess-mode-map
  "Menu for use in `ess-mode'."
  '("ESS" ; ESS-mode
    ["What is this? (beta)"    ess-mouse-me                     t]
    ["Load file"                ess-load-file t]
    ["Eval region | func | para" ess-eval-region-or-function-or-paragraph t]
    ["Eval region | func | para & step" ess-eval-region-or-function-or-paragraph-and-step t]
    ["Eval region | line" ess-eval-region-or-line-and-step t]
    ["Enter expression" ess-execute                 t]
    ;; sub menus
    "------"
    ("Process"
     ["Goto end of process buffer"  ess-switch-to-end-of-ESS        t]
     ["Switch to process buffer"    ess-switch-to-inferior-or-script-buffer t]
     ["Switch Process"   ess-switch-process              t]
     ["Recreate R and S versions known to ESS" (ess-r-s-versions-creation+menu) t]
     ("Start Process"
      ;; SJE - :help not yet recognised in XEmacs.
      ["R"     R   t] ;; :help "Start a new R process" :active t
      ["S"     S   t] ;; :help "Start a new S process" :active t
      ["Sqpe" Sqpe ess-microsoft-p] ;; :help "Start a new Sqpe process" :active t
      ["S+6-exisiting" S+6-existing ess-microsoft-p] ;; :help "Access an existing S process" :active t
      ["SAS"   SAS-menu t] ;;  :help "Start a new SAS process" :active t
      ;; The following menu item "Other" is a place-holder that will
      ;; be replaced with the other versions of R and Sqpe that can be run.
      ;; See `ess-r-versions-create' and ess-site.el
      ("Other"
       ["No other R or Sqpe versions" nil nil])
      ["About"
       (ess-goto-info "Starting up") t]
      ;; :help "Read about starting a new ESS process" :active t]
      )
     ("Eval visibly "
      :filter ess--generate-eval-visibly-submenu))
    "------"
    ("ESS Eval"
     ["Eval region | func | para" ess-eval-region-or-function-or-paragraph t]
     ["Eval region | func | para & step" ess-eval-region-or-function-or-paragraph-and-step t]
     ["Eval region | line" ess-eval-region-or-line-and-step t]
     "-----"
     ["Eval buffer"     ess-eval-buffer                   t]
     ["Eval buffer till here" ess-eval-buffer-from-beg-to-here t]
     ["Eval buffer from here" ess-eval-buffer-from-here-to-end t]
     ["Eval region"     ess-eval-region                   t]
     ["Eval function"   ess-eval-function                 t]
     ["Eval line"       ess-eval-line                     t]
     ["Eval line & step" ess-eval-line-and-step            t]
     ["Eval paragraph"   ess-eval-paragraph                t]
     ["Eval paragraph & step" ess-eval-paragraph-and-step      t]
     ["Eval chunk"      ess-eval-chunk           ess-noweb-mode]
     ["Eval chunk and step"      ess-eval-chunk-and-step  ess-noweb-mode]
     ["Eval thread"     ess-eval-thread          ess-noweb-mode]
     ["About"           (ess-goto-info "Evaluating code") t]
     )
    ("Eval and Go"
     ["Eval buffer"     ess-eval-buffer-and-go            t]
     ["Eval region"     ess-eval-region-and-go            t]
     ["Eval function"   ess-eval-function-and-go          t]
     ["Eval line"       ess-eval-line-and-go              t]
     ["Eval paragraph"   ess-eval-paragraph-and-go         t]
     ["Eval chunk"      ess-eval-chunk-and-go    ess-noweb-mode]
     ["Eval thread"     ess-eval-thread-and-go   ess-noweb-mode]
     ["About"           (ess-goto-info "Evaluating code") t]
     )
    ("Motion"
     ["Beginning of function or para"   ess-goto-beginning-of-function-or-para       t]
     ["End of function or para"         ess-goto-end-of-function-or-para             t]
     "-----"
     ["Backward list"           backward-list                   t]
     ["Forward list"            forward-list                    t]
     ["Next parenthesis"                down-list                       t]
     ["Enclosing parenthesis"   backward-up-list                t]
     ["Backward sexp"           backward-sexp                   t]
     ["Forward sexp"            forward-sexp                    t]
     ["About"                   (Info-goto-node "(Emacs)Lists") t]
     )
    ("ESS Edit"
     ["Edit new object"         ess-dump-object-into-edit-buffer t]
     ["Complete Filename" comint-replace-by-expanded-filename   t]
     ["Complete File or Object"   ess-indent-or-complete        t]
     ["Kill sexp"         kill-sexp                             t]
     ["Mark function"     ess-mark-function                     t]
     ["Indent expression" ess-indent-exp                        t]
     ["Indent line"       ess-indent-command                    t]
     ["Toggle Auto-Fill Mode" auto-fill-mode                    t]
     ["Undo"              undo                                  t]
     ["About"             (ess-goto-info "Edit buffer")         t]
     )
    "------"
    ("start-dev" :visible nil)
    ("end-dev" :visible nil)
    "------"
    ("Font Lock"
     :active ess-font-lock-keywords
     :filter ess--generate-font-lock-submenu)
    "------"
    ["Describe"         describe-mode                   t]
    ["About editing" (ess-goto-info "Editing")  t]
    ["Read ESS info" (ess-goto-info "") t]
    ["Send bug report"  ess-submit-bug-report           t]
    ))



;; (defun test-gen-menu (men)
;;   '(
;;     ["About editing" (ess-goto-info "Editing")  t]
;;     ["Read ESS info" (ess-goto-info "") t]
;;     ["Send bug report"  ess-submit-bug-report           t]))

(defun SAS-menu ()
  "Start SAS from the menu."
  (interactive)
  (if ess-microsoft-p
      ;; replace with other choices for starting SAS under XEmacs?
      (error "SAS cannot be started this way in ESS on Windows.")
    (SAS)))

(defun ess-mode-xemacs-menu ()
  "Hook to install `ess-mode' menu for XEmacs (w/ easymenu)."
  (if 'ess-mode
      (easy-menu-add ess-mode-menu)
    (easy-menu-remove ess-mode-menu)))

(if (featurep 'xemacs)
    (add-hook 'ess-mode-hook 'ess-mode-xemacs-menu))

(defun ess-mode (&optional alist proc-name)
  "Major mode for editing ESS source.
Optional arg ALIST describes how to customize the editing mode.
Optional arg PROC-NAME is name of associated inferior process.

\\{ess-mode-map}

Extra binding to note:  'ESC C-\\' indent-region.

Entry to this mode runs the hooks in ess-mode-hook.

You can send text to the inferior ESS process from other buffers containing
ESS source.
    `ess-eval-region' sends the current region to the ESS process.
    `ess-eval-buffer' sends the current buffer to the ESS process.
    `ess-eval-function' sends the current function to the ESS process.
    `ess-eval-line' sends the current line to the ESS process.
    `ess-beginning-of-function' and `ess-end-of-function' move the point to
        the beginning and end of the current ESS function.
    `ess-switch-to-ESS' switches the current buffer to the ESS process buffer.
    `ess-switch-to-end-of-ESS' switches the current buffer to the ESS process
        buffer and puts point at the end of it.

    `ess-eval-region-and-go', `ess-eval-buffer-and-go',
        `ess-eval-function-and-go', and `ess-eval-line-and-go' switch to the S
        process buffer after sending their text.

    `ess-load-file' sources a file of commands to the ESS process.

\\[ess-indent-command] indents for ESS code.
\\[backward-delete-char-untabify] converts tabs to spaces as it moves back.
Comments are indented in a similar way to Emacs-lisp mode:
       `###'     beginning of line
       `##'      the same level of indentation as the code
       `#'       the same column on the right, or to the right of such a
                 column if that is not possible.(default value 40).
                 \\[indent-for-comment] command automatically inserts such a
                 `#' in the right place, or aligns such a comment if it is
                 already inserted.
\\[ess-indent-exp] command indents each line of the ESS grouping following point.

Variables controlling indentation style:
 `ess-tab-always-indent'
    Non-nil means TAB in ESS mode should always reindent the current line,
    regardless of where in the line point is when the TAB command is used.
 `ess-auto-newline'
    Non-nil means automatically newline before and after braces inserted in S
    code.
 `ess-indent-level'
    Indentation of ESS statements within surrounding block.
    The surrounding block's indentation is the indentation of the line on
    which the open-brace appears.
 `ess-offset-block'
    Indentation of blocks opened with curly braces or anonymous parentheses.
 `ess-offset-arguments'
    Indentation of function arguments or bracket indices.
 `ess-offset-arguments-newline'
    Indentation of function arguments or bracket indices when the opening
    delimiter is immediately followed by a newline.
 `ess-indent-function-declaration'
    Whether arguments of function declarations should always be indented at
    the opening parenthesis.
 `ess-indent-from-outer-parameter'
    Whether function calls given as argument should be indented from the
    parameter name.
 `ess-offset-continued'
    Extra indentation given to a substatement, such as the then-clause of an
    if or body of a while.
 `ess-offset-continued-first'
    Extra indentation given to the first continued statement.
 `ess-offset-else'
    Extra indentation for line if it starts with `else'.
 `ess-fancy-comments'
    Non-nil means distinguish between #, ##, and ### for indentation.

Furthermore, \\[ess-set-style] command enables you to set up predefined ess-mode
indentation style. At present, predefined style are `BSD', `GNU', `K&R', `C++',
`CLB' (quoted from C language style)."
  (setq alist (or alist
		  (buffer-local-value 'ess-local-customize-alist (current-buffer))
		  (error "Customise alist is not specified, nor  ess-local-customize-alist is set.")))
  (kill-all-local-variables) ;; NOTICE THIS! *** NOTICE THIS! *** NOTICE THIS! ***
  (ess-setq-vars-local alist)
  ;; must happen here, since the mode map is set up too early:
  (if ess-r-args-electric-paren (define-key ess-mode-map "(" 'ess-r-args-auto-show))
  (ess-write-to-dribble-buffer
   (format "(ess-mode-1): ess-language=%s, ess-dialect=%s buf=%s \n"
           ess-language
           ess-dialect
           (current-buffer)))
  ;; (ess-write-to-dribble-buffer
  ;;  (format "(ess-mode-1.2): ess-process=%s \n"
  ;;   (ess-local-process-name ess-local-process-name "none")))
  (ess-write-to-dribble-buffer
   (format "(ess-mode-1.5): alist=%s \n" alist))
  (setq major-mode 'ess-mode)
  (setq mode-name (concat "ESS[" ess-language "]")) ; was ess-dialect
  ;; The following line does the next 20 or so :-).
  (ess-write-to-dribble-buffer
   (format "(ess-mode-1.6): editing-alist=%s \n"
           ess-mode-editing-alist))
  (ess-setq-vars-local ess-mode-editing-alist)

  (ess-set-style ess-style t)
  (use-local-map ess-mode-map)
  (set-syntax-table ess-mode-syntax-table)

  ;; Keep <tabs> out of the code.
  (make-local-variable 'indent-tabs-mode)
  (setq indent-tabs-mode nil)

  (put 'ess-local-process-name 'permanent-local t) ; protect from RCS
  (setq mode-line-process
        '(" ["
          (:eval (ess--get-mode-line-indicator))
          ess--local-mode-line-process-indicator
          "]"))
  ;; completion
  (if (and (featurep 'emacs)
           (>= emacs-major-version 24))
      (add-hook 'completion-at-point-functions 'ess-filename-completion nil 'local)
    (add-hook 'comint-dynamic-complete-functions 'ess-complete-filename nil 'local)
    (delq t comint-dynamic-complete-functions)
    )
  (set (make-local-variable 'comint-completion-addsuffix)
       (cons "/" ""))
  ;; timer
  (add-hook 'ess-idle-timer-functions 'ess-synchronize-dirs nil 'local)
  ;;; extras
  (ess-load-extras)
  ;; SJE Tue 28 Dec 2004: do not attempt to load object name db.
  ;; (ess-load-object-name-db-file)
  (if (> emacs-major-version 21)
      (run-mode-hooks 'ess-mode-hook)
    ;; old emacs 21.x
    (run-hooks 'ess-mode-hook))
  (ess-write-to-dribble-buffer "\nFinished setting up ESS-mode.\n"))


(defun ess--get-mode-line-indicator ()
  "Get `ess--mode-line-process-indicator' from process buffer.
Internal function to be used for dynamic mode-line dysplay in
ess-mode."
  (if ess-local-process-name
      (let* ((proc (get-process ess-local-process-name))
             (buff (when proc (process-buffer proc))))
        (if (and proc (buffer-live-p buff))
            (with-current-buffer buff (mapcar 'eval ess--mode-line-process-indicator))
          "none"))
    "none"))


;;*;; User commands in ess-mode

;;;*;;; Handy commands

(defun ess-execute-in-tb ()
  "Like `ess-execute', but always evaluates in temp buffer."
  (interactive)
  (let ((ess-execute-in-process-buffer nil))
    (call-interactively 'ess-execute)))

;;;*;;; Buffer motion/manipulation commands

(defvar ess-set-function-start
  ;; setAs, setGeneric;  setMethod, setReplaceMethod, setGroupMethod
  "^set[MGAR][Ma-z]+\\s-?("
  )

;; common R and S
;; SJE: 2007-07-16 add to quieten byte-compiler.
(defvar ess-function-pattern nil
  "Regexp to match the beginning of a function in S buffers.")

(defvar ess-R-symbol-pattern
  "\\(\\sw\\|\\s_\\)"
  "The regular expression for matching an R symbol")

(defvar ess-R-name-pattern
  (concat "\\(" ess-R-symbol-pattern "+\\|\\(`\\).+`\\)")
  "The regular expression for matching a R name.")

(defvar ess-R-operator-pattern
  "\\(%[^ \t]*%\\)\\|\\([-:+*/><=&|~]\\)"
  "Regular expression for an operator")

(let*
    ((Q     "\\s\"")                    ; quote
     (repl "\\(<-\\)?")                 ; replacement (function)
     (Sym-0 "\\(\\sw\\|\\s_\\)")        ; symbol
     (Symb (concat Sym-0 "+"))
     (xSymb "[^ \t\n\"']+") ;; (concat "\\[?\\[?" Sym-0 "*")); symbol / [ / [[ / [symbol / [[symbol
     ;; FIXME: allow '%foo%' but only when quoted; don't allow [_0-9] at beg.
     (_or_  "\\)\\|\\(")                ; OR
     (space "\\(\\s-\\|\n\\)*")         ; white space

     (part-1 (concat
              "\\(" ;;--------outer Either-------
              "\\(\\("          ; EITHER
              Q xSymb Q         ; any function name between quotes
              _or_
              "\\(^\\|[ ]\\)" Symb ; (beginning of name) + ess-R-symbol-pattern
              "\\)\\)"))        ; END EITHER OR

     (set-S4-exp
      (concat
       "^set\\(As\\|Method\\|Generic\\|GroupMethod\\|ReplaceMethod\\)(" ; S4 ...
       Q xSymb Q "," space
       ;; and now often `` signature(......), : ''
       ".*" ;; <<< FIXME ???
       ))

     (part-2 (concat
              "\\|" ;;--------outer Or ---------
              set-S4-exp
              "\\)" ;;--------end outer Either/Or-------

              "\\(" space "\\s<.*\\s>\\)*"      ; whitespace, comment
              ;; FIXME: in principle we should skip 'definition *= *' here
              space "function\\s-*(" ; whitespace, function keyword, parenthesis
              ))
     )

  (defvar ess-R-function-pattern
    (concat part-1
            "\\s-*\\(<-\\|=\\)" ; whitespace, assign
            part-2)
    "The regular expression for matching the beginning of an R function.")

  (defvar ess-S-function-pattern
    (concat part-1
            "\\s-*\\(<-\\|_\\|=\\)" ; whitespace, assign (incl. "_")
            part-2)
    "The regular expression for matching the beginning of an S function.")

  ); {end let}

(defun ess-beginning-of-function (&optional no-error)
  "Leave (and return) the point at the beginning of the current ESS function.
If the optional argument NO-ERROR is non-nil, the function returns nil when
it cannot find a function beginning."

  ;; FIXME: should not throw error in accordance with beginning-of-defun and
  ;; beginning-of-defun-function specification

  (interactive)
  (let ((init-point (point))
        (in-set-S4 nil)
        beg end done)

    ;; Note that we must be sure that we are past the 'function (' text,
    ;; such that ess-function-pattern is found in BACKwards later.
    ;; In case we're sitting in a function or setMethod() header,
    ;; we need to move further.
    ;; But not too far! {wrongly getting into next function}
    (if (search-forward "("
                        (ess-line-end-position 2) t); at most end of next line
        (forward-char 1))
    ;; TODO: replace the above by hopefully more sucessful logic:
    ;; 1. If we have 'function *(' in the same line, move to end of that line
    ;; 2. if *not*, skip all comment lines (concat space comment-char .* "\n")
    ;;    and only* then do something like the
    ;;    (search-forward '(' .. (..line-end.. 2) )  above

    (setq end (point)); = init-point when nothing found

    (ess-write-to-dribble-buffer
     (format "ess-BEG-of-fun after 'search-FWD (': Ini-pt %d, (p)-Ini-pt = %d\n"
             init-point (- end init-point)))
    (if (and (> end 1)
             (re-search-backward ;; in case of setMethod() etc ..
              ess-set-function-start
              ;; at most 1 line earlier {2 is too much: finds previous sometimes}
              (+ 1 (ess-line-end-position -1)) t))

        (progn ;; yes we *have* an S4  setMethod(..)-like
          (setq in-set-S4 t
                beg (point))
          (ess-write-to-dribble-buffer
           (format " set*() function start at position %d" beg))
          ;; often need to move even further to have 'function(' to our left
          ;;        (if (search-forward "function" end t)
          ;;            (ess-write-to-dribble-buffer
          ;;             (format " -> 'function' already at pos %d\n" (point)))
          ;;          ;; else need to move further
          (goto-char end)
          ;; search 4 lines, we are pretty sure now:
          (search-forward
           "function" (ess-line-end-position 4) t)
          ;;        )
          (search-forward "(" (ess-line-end-position) t)
          )
      ;; else: regular function; no set*Method(..)
      (ess-write-to-dribble-buffer "ELSE  not in setMethod() header ...\n")
      )

    (while (not done)
      ;; Need this while loop to skip over local function definitions

      ;; In the case of non-success, it is inefficiently
      ;; going back in the buffer through all function definitions...
      (unless
          (and (re-search-backward ess-function-pattern (point-min) t)
               (not (ess-inside-string-or-comment-p (point))))
        (goto-char init-point)
        (if no-error
            (setq  done t  beg nil)
          ;; else [default]:
          (error "Point is not in a function according to 'ess-function-pattern'.")
          ))
      (unless done
        (setq beg (point))
        (ess-write-to-dribble-buffer
         (format "\tMatch,Pt:(%d,%d),%d\n"
                 (match-beginning 0) (match-end 0) beg))
        (setq in-set-S4 (looking-at ess-set-function-start))
        (forward-list 1)                ; get over arguments

        ;; The following used to bomb  "Unbalanced parentheses", n1, n2
        ;; when the above (search-forward "(" ..) wasn't delimited :
        (unless in-set-S4 (forward-sexp 1)) ; move over braces
        ;;DBG (ess-write-to-dribble-buffer "|")
        (setq end (point))
        (goto-char beg)
        ;; current function must begin and end around point
        (setq done (and (>= end init-point) (<= beg init-point)))))
    beg))

(defun ess-end-of-function (&optional beginning no-error)
  "Leave the point at the end of the current ESS function.
Optional argument for location of beginning.  Return '(beg end)."
  (interactive)
  (if beginning
      (goto-char beginning)
    (setq beginning (ess-beginning-of-function no-error)))
  (if beginning
      ;; *hack* only for S (R || S+): are we in setMethod(..) etc?
      (let ((in-set-S4 (looking-at ess-set-function-start))
            (end-pos) (npos))
        (ess-write-to-dribble-buffer
         (format "ess-END-of-fun: S4=%s, beginning = %d\n" in-set-S4 beginning))
        (forward-list 1)        ; get over arguments || whole set*(..)
        (unless in-set-S4 (forward-sexp 1)) ; move over braces
        (ess-write-to-dribble-buffer
         (format "ess-END-of-fun: found #1 : %d\n" (point)))

        ;; For one-line functions withOUT '{ .. }' body  -- added 2008-07-23 --
        ;; particularly helpful for C-c C-c (ess-eval-function-or-paragraph-and-step):
        (setq end-pos (ess-line-end-position))
        (while (< (point) end-pos) ; if not at end of line, move further forward
          (goto-char ;; careful not to move too far; e.g. *not* over empty lines:
           (min (save-excursion (forward-sexp 1) (point))
                (save-excursion (forward-paragraph 1) (point)))))
        (list beginning (point))
        )
    ;; else: 'no-error': we are not in a function
    nil))


(defun ess-goto-beginning-of-function-or-para ()
  "If inside a function go to the beginning of it, otherwise go to the beginning
  of paragraph."
  (interactive)
  (unless (ess-beginning-of-function 'no-error)
    (backward-paragraph)))

(defun ess-goto-end-of-function-or-para ()
  "If inside a function go to end of it, otherwise go to the end
  of paragraph."
  (interactive)
  (unless (ess-end-of-function nil 'no-error)
    (forward-paragraph)))

;;; Kurt's version, suggested 1997-03-06.
(defun ess-mark-function ()
  "Put mark at end of ESS function, point at beginning."
  (interactive)
  (let ((beg (ess-beginning-of-function)))
    (push-mark (point))
    (ess-end-of-function beg)
    (exchange-point-and-mark)))

;; Donated by Stephen Eglen, 2001-08-29:
;; This command is analogous to `narrow-to-defun' (elisp)
;; and `py-narrow-to-defun' (python)."
(defun ess-narrow-to-defun ()
  "Make text outside current function invisible.
If text is already narrowed, this is removed before narrowing to the
current function."
  (interactive)
  ;; if point is not in a function, ess-end-of-function catches the error.
  (save-excursion
    (widen)
    (let* ((beg-end (ess-end-of-function)))
      (narrow-to-region (nth 0 beg-end) (nth 1 beg-end)))))

;;*;; Loading files

(defun ess-check-modifications nil
  "Check whether loading this file would overwrite some ESS objects
which have been modified more recently than this file, and confirm
if this is the case."
  ;; FIXME: this should really cycle through all top-level assignments in
  ;; the buffer
  ;;VS[02-04-2012|ESS 12.03]: this is sooo ugly
  (when (> (length ess-change-sp-regexp) 0)
    (and (buffer-file-name) ess-filenames-map
	 (let ((sourcemod (nth 5 (file-attributes (buffer-file-name))))
	       (objname))
	   (save-excursion
	     (goto-char (point-min))
	     ;; Get name of assigned object, if we can find it
	     (setq objname
		   (and
		    (re-search-forward
		     "^\\s *\"?\\(\\(\\sw\\|\\s_\\)+\\)\"?\\s *[<_]"
		     nil
		     t)
		    (buffer-substring (match-beginning 1)
				      (match-end 1)))))
	   (and
	    sourcemod			; the file may have been deleted
	    objname			; may not have been able to
					; find name
	    (ess-modtime-gt (ess-object-modtime objname) sourcemod)
	    (not (y-or-n-p

		  (format
		   "The ESS object %s is newer than this file. Continue?"
		   objname)))
	    (error "Aborted"))))))

(defun ess-check-source (fname)
  "If file FNAME has an unsaved buffer, offer to save it.
Returns t if the buffer existed and was modified, but was not saved."
  (let ((buff (get-file-buffer fname)))
    ;; RMH: Corrections noted below are needed for C-c C-l to work
    ;; correctly when issued from *S* buffer.
    ;; The following barfs since
    ;; 1. `if' does not accept a buffer argument, `not' does.
    ;; 2. (buffer-file-name) is not necessarily defined for *S*
    ;;(if buff
    ;; (let ((deleted (not (file-exists-p (buffer-file-name)))))
    ;; Next 2 lines are RMH's solution:
    (if (not(not buff))
        (let ((deleted (not (file-exists-p fname))))
          (if (and deleted (not (buffer-modified-p buff)))
              ;; Buffer has been silently deleted, so silently save
              (with-current-buffer buff
                (set-buffer-modified-p t)
                (save-buffer))
            (if (and (buffer-modified-p buff)
                     (or ess-mode-silently-save
                         (y-or-n-p
                          (format "Save buffer %s first? "
                                  (buffer-name buff)))))
                (with-current-buffer buff
                  (save-buffer))))
          (buffer-modified-p buff)))))

(defvar ess-error-regexp   "^\\(Syntax error: .*\\) at line \\([0-9]*\\), file \\(.*\\)$"
  "Regexp to search for errors.")

(defun ess-parse-errors (&optional showerr reset)
  "Jump to error in last loaded ESS source file.
With prefix argument, only shows the errors ESS reported."
  ;; reset argument is for compatibility with emacs next-error (tracebug
  ;; rebinds ess-parse-errors to next-error), This silences the compiler.
  (interactive "P")
  (ess-make-buffer-current)
  (let ((errbuff (get-buffer ess-error-buffer-name)))
    (if (not errbuff)
        (error "You need to do a load first!")
      (set-buffer errbuff)
      (goto-char (point-max))
      (if
	  (re-search-backward
	   ;; FIXME: R does not give "useful" error messages -
	   ;; -----  by default: We (ESS) could try to use a more useful one, via
	   ;;   options(error=essErrorHandler)
	   ess-error-regexp
	   nil
	   t)
	  (let* ((filename (buffer-substring (match-beginning 3) (match-end 3)))
		 (fbuffer (get-file-buffer filename))
		 (linenum
		  (string-to-number
		   (buffer-substring (match-beginning 2) (match-end 2))))
		 (errmess (buffer-substring (match-beginning 1) (match-end 1))))
	    (if showerr
                (ess-display-temp-buffer errbuff)
	      (if fbuffer nil
		(setq fbuffer (find-file-noselect filename))
		(with-current-buffer fbuffer
		  (ess-mode)))
	      (pop-to-buffer fbuffer)
	      ;;(goto-line linenum) gives warning: is said to be replaced by
	      (goto-char (point-min)) (forward-line (1- linenum)))
	    (princ errmess t))
	(message "Not a syntax error.")
	(ess-display-temp-buffer errbuff)))))

;;*;; ESS code formatting/indentation

;;;*;;; User commands

(defun ess-electric-brace (arg)
  "Insert character and correct line's indentation."
  (interactive "P")
  ;; skeleton-pair takes precedence
  (if (and (boundp 'skeleton-pair) skeleton-pair (featurep 'skeleton))
      (skeleton-pair-insert-maybe "{")
    ;; else
    (let (insertpos)
      (if (and (not arg)
               (eolp)
               (or (save-excursion
                     (skip-chars-backward " \t")
                     (bolp))
                   (if ess-auto-newline (progn (ess-indent-line) (newline) t) nil)))
          (progn
            (insert (if (featurep 'xemacs) (event-to-character last-command-event) last-command-event))
            (ess-indent-line)
            (if ess-auto-newline
                (progn
                  (newline)
                  ;; (newline) may have done auto-fill
                  (setq insertpos (- (point) 2))
                  (ess-indent-line)))
            (save-excursion
              (if insertpos (goto-char (1+ insertpos)))
              (delete-char -1))))
      (if insertpos
          (save-excursion
            (goto-char insertpos)
            (self-insert-command (prefix-numeric-value arg)))
        (self-insert-command (prefix-numeric-value arg))))))

;; fixeme: move into ess-indent-or-complete, indentation functions are overly
;; scattered around
(defun ess-indent-command (&optional whole-exp)
  "Indent current line as ESS code, or in some cases insert a tab character.
If `ess-tab-always-indent' is non-nil (the default), always indent
current line.  Otherwise, indent the current line only if point is at
the left margin or in the line's indentation; otherwise insert a tab.
A numeric argument, regardless of its value, means indent rigidly all
the lines of the expression starting after point so that this line
becomes properly indented.  The relative indentation among the lines
of the expression are preserved."
  (interactive "P")
  (if whole-exp
      ;; If arg, always indent this line as S
      ;; and shift remaining lines of expression the same amount.
      (let ((shift-amt (ess-indent-line))
            beg end)
        (save-excursion
          (if ess-tab-always-indent
              (beginning-of-line))
          (setq beg (point))
          (backward-up-list 1)
          (forward-list 1)
          (setq end (point))
          (goto-char beg)
          (forward-line 1)
          (setq beg (point)))
        (if (> end beg)
            (indent-code-rigidly beg end shift-amt)))
    (if (and (not ess-tab-always-indent)
             (save-excursion
               (skip-chars-backward " \t")
               (not (bolp))))
        (insert-tab)
      ;; call ess-indent-line
      (funcall indent-line-function))))


(defun ess-indent-or-complete ()
  "When region is selected indent the region, otherwise, if
`ess-tab-complete-in-script' is non-nil, try to indent, if code
is already indented, complete instead.

The default of `ess-tab-complete-in-script' is nil.  Also see
`ess-first-tab-never-complete'."
  (interactive)
  (if (use-region-p)
      (indent-region (region-beginning) (region-end))
    (let ((shift (ess-indent-command)))
      (when (and ess-tab-complete-in-script
                 (numberp shift) ;; can be nil if ess-tab-always-indent is nil
                 (equal shift 0)
                 (or (eq last-command 'ess-indent-or-complete)
                     (null ess-first-tab-never-complete)
                     (and (eq ess-first-tab-never-complete 'unless-eol)
                          (looking-at "\\s-*$"))
                     (and (eq ess-first-tab-never-complete 'symbol)
                          (not (looking-at "\\w\\|\\s_")))
                     (and (eq ess-first-tab-never-complete 'symbol-or-paren)
                          (not (looking-at "\\w\\|\\s_\\|\\s)")))
                     (and (eq ess-first-tab-never-complete 'symbol-or-paren-or-punct)
                          (not (looking-at "\\w\\|\\s_\\|\\s)\\|\\s.")))
                     ))
        (if (and (featurep 'emacs) (>= emacs-major-version 24))
            (completion-at-point)
          (comint-dynamic-complete)
          )))))

(defun ess-indent-exp ()
  "Indent each line of the ESS grouping following point."
  (interactive)
  (save-excursion
    (let ((start (point))
          (end (ignore-errors (forward-sexp 1) (point))))
      (when end
        (indent-region start end)))))

;;;*;;; Support functions for indentation

(defun ess-comment-indent ()
  (if (or (looking-at "###")
          (and (looking-at "#!") (= 1 (line-number-at-pos))))
      (current-column)
    (if (looking-at "##")
        (let ((tem (ess-calculate-indent)))
          (if (listp tem) (car tem) tem))
      (skip-chars-backward " \t")
      (max (if (bolp) 0 (1+ (current-column)))
           comment-column))))

(defun ess-indent-line ()
  "Indent current line as ESS code.
Return the amount the indentation changed by."
  ;; fixme: make this work with standard indent-line-function
  (if (fboundp ess-indent-line-function)
      (funcall ess-indent-line-function)
    ;; else S and R default behavior
    (let ((indent (ess-calculate-indent nil))
          beg shift-amt
          (case-fold-search nil)
          (pos (- (point-max) (point))))
      (beginning-of-line)
      (setq beg (point))
      (if (eq indent nil)
          (setq indent (current-indentation))
        (skip-chars-forward " \t")
        (cond
         ((and ess-fancy-comments ;; ### or #!
               (or (looking-at "###")
                   (and (looking-at "#!") (= 1 (line-number-at-pos)))))
          (setq indent 0))
         ;; Single # comment
         ((and ess-fancy-comments
               (looking-at "#") (not (looking-at "##")) (not (looking-at "#'")))
          (setq indent comment-column))
         (t
          (if (eq indent t) (setq indent 0))
          (if (listp indent) (setq indent (car indent)))
          (cond
           ((and (looking-at "else\\b")
                 (not (looking-at "else\\s_")))
            (setq indent (save-excursion
                           (ess-backward-to-start-of-if)
                           (+ (ess-offset 'else) (current-column)))))))))
      (skip-chars-forward " \t")
      (setq shift-amt (- indent (current-column)))
      (if (zerop shift-amt)
          (if (> (- (point-max) pos) (point))
              (goto-char (- (point-max) pos)))
        (delete-region beg (point))
        (indent-to indent)
        ;; If initial point was within line's indentation,
        ;; position after the indentation.
        ;; Else stay at same point in text.
        (when (> (- (point-max) pos) (point))
          (goto-char (- (point-max) pos))))
      shift-amt)))

(defun ess-offset (symbol)
  (let* ((name (concat "ess-offset-" (symbol-name symbol)))
         (offset (eval (intern name))))
    (if (eq offset t)
        ess-indent-level
      offset)))

(defun ess-extract-offset (offset &optional use-default)
  (let ((res (cond
              ((null offset)
               (if use-default ess-indent-level 0))
              ((listp offset)
               (car offset))
              ((or (numberp offset) (eq t offset))
               offset)
              (t (error "Malformed offset")))))
    (if (eq res t)
        ess-indent-level
      res)))

(defun ess-looking-at-last-open-delim-p ()
  (looking-at "[[:blank:]]*[([][[:blank:]]*\\($\\|#\\)"))

(defun ess-block-opening-p ()
  (save-excursion
    (cond
     ((looking-at "{"))
     ;; Opening parenthesis not attached to a function opens up a
     ;; block too
     ((looking-at "(")
      (not (ess-looking-back-attached-name-p))))))

(defun ess-block-closing-p ()
  (save-excursion
    (cond
     ((looking-at "}"))
     ((looking-at ")")
      (forward-char)
      (backward-sexp)
      (not (looking-back
            (concat ess-R-name-pattern "[[:blank:]]*")
            (line-beginning-position)))))))

(defun ess-block-p ()
  (save-excursion
    (goto-char containing-sexp)
    (ess-block-opening-p)))

;; Should be called just before the opening brace
(defun ess-looking-back-attached-name-p ()
  (looking-back
   (concat ess-R-symbol-pattern "[[:blank:]]*")
   (line-beginning-position)))

(defun ess-climb-block ()
  (let ((saved-pos (point)))
    (unless (and (ignore-errors
                   (backward-sexp)
                   (cond ((looking-at "else")
                          (re-search-backward
                           "}[[:blank:]]\\=" ; fixme: not robust to comments
                           (line-beginning-position) t)
                          t)
                         (t
                          (backward-sexp)
                          (looking-at "function\\|if\\|for")))))
      (goto-char saved-pos))))

(defun ess-climb-parameter ()
  (when (looking-back "=[[:blank:]]*" (line-beginning-position))
    (ignore-errors (backward-sexp))))

(defun ess-climb-to-args-opening ()
  (let ((saved-pos (point)))
    (when prev-containing-sexp
      (goto-char prev-containing-sexp))
    (if (save-excursion
          (ignore-errors
            (backward-sexp)
            (looking-at (concat ess-R-name-pattern "[[:blank:]]*[[(]"))))
        t (progn (goto-char saved-pos) nil))))

(defun ess-calculate-indent (&optional parse-start)
  "Return appropriate indentation for current line as ESS code.
In usual case returns an integer: the column to indent to.
Returns nil if line starts inside a string, t if in a comment."
  (save-excursion
    (beginning-of-line)
    (let* ((indent-point (point))
           (state (syntax-ppss))
           (containing-sexp (cadr state))
           (prev-containing-sexp (car (last (butlast (nth 9 state)))))
           ind)
      (back-to-indentation)
      (cond
       ;; return nil (in string) or t (in comment)
       ((or (nth 3 state) (nth 4 state))
        (nth 4 state))
       ;; Indentation of commas
       ((looking-at ",")
        (ess-calculate-indent--comma))
       ;; Block: Opening
       ((ess-block-opening-p)
        (ess-calculate-indent--block-opening))
       ;; Block: Continuations
       ((setq ind (ess-calculate-indent--continued-block containing-sexp))
        (+ ind ess-indent-level))
       ((setq ind (ess-calculate-indent--continued containing-sexp))
        (+ ind (ess-offset 'continued)))
       ((null containing-sexp)
        0)
       ;; Block: Closing
       ((ess-block-closing-p)
        (ess-calculate-indent--block 0))
       ;; Block: Contents
       ((ess-block-p)
        (ess-calculate-indent--block))
       ;; Arguments: Closing
       ((looking-at "[])]")
        (ess-calculate-indent--args 0))
       ;; Arguments: Contents
       (t
        (ess-calculate-indent--args))))))

(defun ess-calculate-indent--block (&optional offset)
  (when containing-sexp
    (goto-char containing-sexp))
  (let ((offset (or offset (ess-extract-offset ess-offset-block t)))
        (indent
         (if (save-excursion
               (and prev-containing-sexp
                    (goto-char prev-containing-sexp)
                    (looking-at "[[(]")
                    (ess-looking-back-attached-name-p)))
             (cond
              ;; Indent from opening delimiter
              ((null ess-offset-block)
               (unless (null (ess-offset 'block))
                 (ess-climb-block)
                 (when ess-indent-from-outer-parameter
                   (ess-climb-parameter)))
               (current-column))

              ;; Indent from previous line indentation
              ((listp ess-offset-block)
               (goto-char prev-containing-sexp)
               (current-indentation))

              ;; Indent from function call
              (t
               (ess-climb-to-args-opening)
               (ess-calculate-indent--args nil (point) indent-point)))

           ;; Block is not part of an arguments list
           (ess-climb-block)
           (current-indentation))))

    (+ indent offset)))

(defun ess-calculate-indent--block-opening ()
  (cond ((save-excursion
           (ess-climb-block)
           (when (looking-at "function[[:blank:]\n(]+")
             (when (and containing-sexp
                        (listp ess-offset-block))
               (ignore-errors (backward-sexp)))
             (current-column))))
        ((null containing-sexp) 0)
        (t (ess-calculate-indent--args))))

(defun ess-calculate-indent--comma ()
  (let ((indent (save-excursion
                  (ess-calculate-indent--args)))
        (unindent (progn (skip-chars-forward " \t")
                         ;; return number of skiped chars
                         (skip-chars-forward ", \t"))))
    (- indent unindent)))

(defun ess-calculate-indent--args (&optional offset from to)
  (let* ((min-col (ess-minimum-args-indent from to))
         (from (or from containing-sexp))
         (type (progn
                 (goto-char from)
                 (cond
                  ((and (save-excursion
                          (ignore-errors (backward-sexp))
                          (looking-at
                           "function[([:blank:]]+"))
                        ess-indent-function-declaration)
                   nil)
                  ((ess-looking-at-last-open-delim-p)
                   ess-offset-arguments-newline)
                  (t ess-offset-arguments))))
         (offset (or offset (ess-extract-offset type)))
         (indent
          (cond
           ;; Indent from opening delimiter
           ((null type)
            (re-search-forward "[[(]" (line-end-position) t)
            (current-column))

           ;; Indent from previous line indentation
           ((listp type)
            (goto-char from)
            (current-indentation))

           ;; Indent from attached name
           (t
            ;; Handle brackets chains (cf data.table)
            (while (equal (char-before) ?\])
              (ignore-errors (backward-sexp)))
            (ignore-errors (backward-sexp))
            (when ess-indent-from-outer-parameter
              (ess-climb-parameter))
            (current-column)))))

    (+ (ess-adjust-argument-indent (+ indent offset)
        min-col))))

;; Indentation of arguments needs to keep track of how previous
;; arguments are indented. If one of those has a smaller indentation,
;; we push off the current line from its natural indentation.
(defun ess-adjust-argument-indent (offset min-col)
  (min offset (or min-col offset)))

;; When previous arguments are shifted to the left (can happen in
;; several situations) compared to their natural indentation, the
;; following lines should not get indented past them. The following
;; function checks the minimum indentation for all arguments of the
;; current function call or bracket indexing.
(defun ess-minimum-args-indent (&optional from to)
  (let* ((to (or to (point)))
         (to-line (line-number-at-pos to))
         (from-line (progn
                       (goto-char (1+ (or from containing-sexp)))
                       (line-number-at-pos)))
         (prev-pos (1- (point)))
         min-col)
    (while (< prev-pos (min (point) to) )
      (setq prev-pos (point))
      (ignore-errors (forward-sexp))
      ;; Ignore the line with the function call and the line to be
      ;; indented.
      (unless (or (= (line-number-at-pos) from-line)
                  (>= (line-number-at-pos) to-line))
        ;; Handle lines starting with a comma
        (let ((indent (if (save-excursion
                            (back-to-indentation)
                            (looking-at ","))
                          (+ (current-indentation) 2)
                        (current-indentation))))
          (setq min-col (min indent (or min-col indent))))))
    min-col))

(defun ess-calculate-indent--continued-block (&optional containing-sexp)
  "If a continuation line of a block, return and indent of this line, otherwise nil."
  (save-excursion
    (beginning-of-line)
    (ess-backward-to-noncomment containing-sexp)
    (cond ((memq (preceding-char) '(nil ?\, ?\; ?\} ?\{ ?\] ?\())
           nil)
          ;; treat <- to avoid creating another check function
          ((looking-back "<-" (- (point) 2))
           (current-indentation))
          ((= (preceding-char) ?\)) ;; if, for, while, function
           (ignore-errors
             ;; if throws an error clearly not a continuation
             ;; can happen if the parenthetical statement starts a new line
             ;; (foo)  ## or
             ;; !(foo)
             (backward-sexp 2)
             (cond ((looking-at "\\(for\\|while\\)\\b[ \t]*(")
                    (current-column))
                   ((looking-at "if\\b[ \t]*(")
                    (when (looking-back
                           "\\belse[ \t]*"
                           (line-beginning-position))
                      (backward-sexp))
                    (current-column))
                   ((looking-at "function\\b[ \t]*(")
                    (if t
                        (current-indentation))))))
          ((progn (ignore-errors (forward-sexp -1))
                  (looking-at "else\\b\\|repeat\\b\\([:blank:]*\|\\&\\)"))
           (let ((col (current-column)))
             (skip-chars-backward " \t")
             (if (or (bolp)
                     (eq (preceding-char) ?\;))
                 (- col (current-column))
               (when (eq ?} (preceding-char))
                 (- (current-column) 1))))))))


(defun ess-calculate-indent--continued (&optional containing-sexp)
  "If a continuation line, return an indent of this line, otherwise nil."
  (save-excursion
    (beginning-of-line)
    (ess-backward-to-noncomment containing-sexp)
    (let ((start (point)))
      (cond ((memq (preceding-char) '(nil ?\, ?\; ?\} ?\{ ?\] ?\())
             nil)
            ;; Ignore continuation rules for "if" statements
            ((ignore-errors
               (up-list -1)
               (looking-back "if[ \t]*" (line-beginning-position)))
             nil)
            ((progn (goto-char start)
                    (or (and (> (current-column) 1)
                             (or (looking-back "<-" (- (point) 2))
                                 (looking-back "[-:+*/><=&|~]" (- (point) 1))))
                        (and (> (current-column) 3)
                             (looking-back "%[^ \t]*%" (line-beginning-position)))))
             (goto-char (match-beginning 0))
             (skip-chars-backward " \t")
             ;; If natural indentation was pushed off, go to smallest column
             (let ((prev-point (point))
                   (prev-col (current-column)))
               (ess-climb-continued-statements)
               (if (> (current-column) prev-col)
                   (goto-char prev-point)))
             (let ((first-indent
                    (or (and (/= (ess-offset 'continued-first) 0)
                             (null (ess-calculate-indent--continued containing-sexp))
                             (ess-offset 'continued-first))
                        0)))
               (+ first-indent (current-column))))
            (t nil)))))

(defun ess-climb-continued-statements ()
  (ignore-errors
    (backward-sexp)
    (cond ((looking-at "[[(]")
           (if (ess-looking-back-attached-name-p)
               (backward-sexp)
             (forward-sexp)
             (backward-char)))
          ((looking-at "{")
           (ess-climb-block)))
    (when (save-excursion
            (ignore-errors
              (let ((line-start (line-number-at-pos)))
                (backward-sexp)
                (forward-sexp)
                (when (equal line-start (line-number-at-pos))
                  (looking-at
                   (concat "[[:blank:]]*\\("
                           "<-\\|[-:+*/><=&|~]"
                           "\\|%[^ \t]*%\\)"))))))
      (ess-climb-continued-statements))))

(defun ess-backward-to-noncomment (limit)
  ;; this one is bad. Use
  (let ((limit (or limit (point-min)))
        opoint stop)
    (while (not stop)
      (skip-chars-backward " \t\n\f" limit)
      (setq opoint (point))
      (beginning-of-line)
      (search-forward "#" opoint 'move)
      (while (eq 'string (syntax-ppss-context (syntax-ppss)))
        (search-forward "#" opoint 'move))
      (skip-chars-backward " \t#")
      (setq stop (or (/= (preceding-char) ?\n) (<= (point) limit)))
      (if stop (point)
        (beginning-of-line)))))

(defun ess-backward-to-start-of-continued-exp (limit)
  (let ((limit (or limit (point-min))))
    (if (= (preceding-char) ?\))
        (forward-sexp -1))
    (beginning-of-line)
    (if (<= (point) limit)
        (goto-char (1+ limit)))
    (skip-chars-forward " \t")))

(defun ess-backward-to-start-of-if (&optional limit)
  "Move to the start of the last ``unbalanced'' 'if' or 'else if'
expression."
  (let ((beginning-of-defun-function nil))
    (or limit (setq limit (save-excursion (beginning-of-defun) (point))))
    (let ((if-level 1)
          (case-fold-search nil))
      (while (not (zerop if-level))
        (backward-sexp 1)
        (cond ((looking-at "else\\b")
               (setq if-level (1+ if-level)))
              ((looking-at "if\\b")
               (when (looking-back "\\belse[[:blank:]]*")
                 (backward-sexp 1))
               (setq if-level (1- if-level)))
              ((< (point) limit)
               (setq if-level 0)
               (goto-char limit)))))))

;;;*;;; Predefined indentation styles

(defun ess-set-style (&optional style quiet)
  "Set up the `ess-mode' style variables from the `ess-style' variable
or if STYLE argument is given, use that.  It makes the ESS indentation
style variables buffer local."

  (interactive)
  (let ((ess-styles (mapcar 'symbol-name (mapcar 'car ess-style-alist))))
    (unless style
      (setq style
            (intern (ess-completing-read "Set ESS mode indentation style"
                                         ess-styles nil t nil nil ess-default-style))))
    (setq style (or style ess-style))
    (make-local-variable 'ess-style)
    (if (memq (symbol-name style) ess-styles)
        (setq ess-style style)
      (error (format "Bad ESS style: %s" style)))
    (if (not quiet)
        (message "ESS-style: %s" ess-style))
    ;; finally, set the indentation style variables making each one local
    (mapc (lambda (ess-style-pair)
            (make-local-variable (car ess-style-pair))
            (set (car ess-style-pair)
                 (eval (cdr ess-style-pair))))
          (cdr (assq ess-style ess-style-alist)))
    ess-style))

;;*;; Creating and manipulating dump buffers

;;;*;;; The user command

(defun ess-dump-object-into-edit-buffer (object)
  "Edit an ESS object in its own buffer.

Without a prefix argument, this simply finds the file pointed to by
`ess-source-directory'. If this file does not exist, or if a
prefix argument is given, a dump() command is sent to the ESS process to
generate the source buffer."
  (interactive
   (progn
     (ess-force-buffer-current "Process to dump from: ")
     (if (ess-ddeclient-p)
         (list (read-string "Object to edit: "))
       (ess-read-object-name "Object to edit"))))

  (let* ((dirname (file-name-as-directory
                   (if (stringp ess-source-directory)
                       ess-source-directory
                     (with-current-buffer (process-buffer (ess-get-process
                                                           ess-local-process-name))
                       (ess-setq-vars-local ess-customize-alist)
                       (apply ess-source-directory nil)))))
         (filename (concat dirname (format ess-dump-filename-template object)))
         (old-buff (get-file-buffer filename)))

    ;; If the directory doesn't exist, offer to create it
    (if (file-exists-p (directory-file-name dirname)) nil
      (if (y-or-n-p                     ; Approved
           (format "Directory %s does not exist. Create it? " dirname))
          (make-directory (directory-file-name dirname))
        (error "Directory %s does not exist." dirname)))

    ;; Three options:
    ;;  (1) Pop to an existing buffer containing the file in question
    ;;  (2) Find an existing file
    ;;  (3) Create a new file by issuing a dump() command to S
    ;; Force option (3) if there is a prefix arg

    (if current-prefix-arg
        (ess-dump-object object filename)
      (if old-buff
          (progn
            (pop-to-buffer old-buff)
            (message "Popped to edit buffer."))
        ;; No current buffer containing desired file
        (if (file-exists-p filename)
            (progn
              (ess-find-dump-file-other-window filename)
              (message "Read %s" filename))
          ;; No buffer and no file
          (ess-dump-object object filename))))))

(defun ess-dump-object (object filename)
  "Dump the ESS object OBJECT into file FILENAME."
  (let ((complete-dump-command (format inferior-ess-dump-command
                                       object filename)))
    (if (file-writable-p filename) nil
      (error "Can't dump %s as %f is not writeable." object filename))

    (if (ess-ddeclient-p)
        ;; ddeclient version
        (ess-dump-object-ddeclient object filename)

      ;; else: "normal", non-DDE behavior:

      ;; Make sure we start fresh
      (if (get-file-buffer filename)
          (kill-buffer (get-file-buffer filename)))

      (ess-command complete-dump-command)
      (message "Dumped in %s" filename)

      (ess-find-dump-file-other-window filename)

      ;; PD, 1Apr97
      ;;This ensures that the object gets indented according to ess-mode,
      ;;not as the R/S deparser does it. At the same time, it gets rid
      ;;of the mess generated by sending TAB characters to the readline
      ;;functions in R when you eval-buffer-*.
      (indent-region (point-min-marker) (point-max-marker) nil)
      (set-buffer-modified-p nil) ; no need to safe just because of indenting

      ;; Don't make backups for temporary files; it only causes clutter.
      ;; The ESS object itself is a kind of backup, anyway.
      (unless ess-keep-dump-files
        (make-local-variable 'make-backup-files)
        (setq make-backup-files nil))

      ;; Don't get confirmation to delete dumped files when loading
      (if (eq ess-keep-dump-files 'check)
          (setq ess-keep-dump-files nil))

      ;; Delete the file if necessary
      (if ess-delete-dump-files
          (delete-file (buffer-file-name))))))

(defun ess-find-dump-file-other-window (filename)
  "Find ESS source file FILENAME in another window."

  (if (file-exists-p filename) nil
    (ess-write-to-dribble-buffer
     (format "%s does not exist. Bad dump, starting fresh." filename)))

  ;; Generate a buffer with the dumped data
  (find-file-other-window filename)
  (ess-mode ess-customize-alist)

  (auto-save-mode 1)            ; Auto save in this buffer
  (setq ess-local-process-name ess-current-process-name)

  (if ess-function-template
      (progn
        (goto-char (point-max))
        (if (re-search-backward ess-dumped-missing-re nil t)
            (progn
              (replace-match ess-function-template t t)
              (set-buffer-modified-p nil) ; Don't offer to save if killed now
              (goto-char (point-min))
              (condition-case nil
                  ;; This may fail if there are no opens
                  (down-list 1)
                (error nil)))))))

;; AJR: XEmacs, makes sense to dump into "other frame".
(defun ess-dump-object-into-edit-buffer-other-frame (object)
  "Edit an ESS object in its own frame."
  (switch-to-buffer-other-frame (ess-dump-object-into-edit-buffer object)))

(provide 'ess-mode)

 ; Local variables section

;;; This file is automatically placed in Outline minor mode.
;;; The file is structured as follows:
;;; Chapters:     ^L ;
;;; Sections:    ;;*;;
;;; Subsections: ;;;*;;;
;;; Components:  defuns, defvars, defconsts
;;;              Random code beginning with a ;;;;* comment

;;; Local variables:
;;; mode: emacs-lisp
;;; outline-minor-mode: nil
;;; mode: outline-minor
;;; outline-regexp: "\^L\\|\\`;\\|;;\\*\\|;;;\\*\\|(def[cvu]\\|(setq\\|;;;;\\*"
;;; End:

;;; ess-mode.el ends here
