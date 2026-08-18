;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "54L1M"
      user-mail-address "themhsalimi@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:

(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 16 :weight 'medium)
      doom-variable-pitch-font (font-spec :family "JetBrainsMono Nerd Font" :size 16))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'catppuccin)
(setq catppuccin-flavor 'macchiato) ; or 'frappe 'latte, 'macchiato, or 'mocha
(load-theme 'catppuccin t)
;; set transparency... I don't think this works so TODO
(set-frame-parameter (selected-frame) 'alpha '(85 85))
(add-to-list 'default-frame-alist '(alpha 85 85))

;; Open every frame maximized. Swap 'maximized for 'fullboth if you want
;; native macOS fullscreen (its own Space) instead.
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")
;; you can customize your rss feed at ~/org/elfeed.org. This works because I'm
;; using +org with my rss plugin. Check out
;; https://github.com/remyhonig/elfeed-org to see an example.
;; (moved here from custom.el; only takes effect if :app (rss +org) is enabled)
(after! elfeed
  (setq elfeed-search-filter "@12-month-ago"))


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; pyright setup, ported from nvim (nvim/lsp/pyright.lua):
;; pyright does completion/hover/navigation only — type checking off and
;; all pyright diagnostics ignored; linting comes from ruff, which
;; lsp-mode runs alongside pyright as an add-on server (needs `ruff' on
;; PATH, which nix provides).
(after! lsp-pyright
  (setq lsp-pyright-type-checking-mode "off"
        ;; "openFilesOnly" (pyright default): workspace-wide analysis is
        ;; pointless here since all pyright diagnostics are ignored anyway
        ;; (ruff lints); also stops the "analyzing N files" modeline churn.
        lsp-pyright-diagnostic-mode "openFilesOnly"
        lsp-pyright-auto-search-paths t
        lsp-pyright-extra-paths [])
  ;; settings lsp-pyright doesn't expose as variables
  (lsp-register-custom-settings
   '(("python.analysis.ignore" ["*"])
     ("python.analysis.useLibraryCodeForTypes" t t))))

;; ruff: explicitly load the client so it registers before any python
;; buffer starts lsp — it attaches alongside pyright (:add-on? t) and
;; provides lint diagnostics + organize-imports, like ruff did in nvim.
(after! lsp-mode
  (require 'lsp-ruff)
  (setq lsp-disabled-clients (delq 'ruff lsp-disabled-clients)))

;; golang formatting set up
;; use gofumpt
(after! lsp-mode
  (setq  lsp-go-use-gofumpt t)
  )
;; automatically organize imports
(add-hook 'go-mode-hook #'lsp-deferred)
;; Make sure you don't have other goimports hooks enabled.
(defun lsp-go-install-save-hooks ()
  (add-hook 'before-save-hook #'lsp-organize-imports t t))
(add-hook 'go-mode-hook #'lsp-go-install-save-hooks)

;; enable all analyzers; not done by default
(after! lsp-mode
  (setq  lsp-go-analyses '((fieldalignment . t)
                           (nilness . t)
                           (shadow . t)
                           (unusedparams . t)
                           (unusedwrite . t)
                           (useany . t)
                           (unusedvariable . t)))
  )

;; use system clipboard
;; macos
(require 'pbcopy)
(turn-on-pbcopy)

;; use fish shell by default

;; use wayland copy (I found this online, hopefully it works :D)
;; (when (string-equal (getenv "XDG_SESSION_TYPE") "wayland")
;;   (executable-find "wl-copy")
;;   (executable-find "wl-paste")
;;   (defun my-wl-copy (text)
;;     "Copy with wl-copy if in terminal, otherwise use the original value of `interprogram-cut-function'."
;;     (if (display-graphic-p)
;;         (gui-select-text text)
;;       (let ((wl-copy-process
;;              (make-process :name "wl-copy"
;;                            :buffer nil
;;                            :command '("wl-copy")
;;                            :connection-type 'pipe)))
;;         (process-send-string wl-copy-process text)
;;         (process-send-eof wl-copy-process))))
;;   (defun my-wl-paste ()
;;     "Paste with wl-paste if in terminal. otherwise use the original value of `interprogram-paste-function'"
;;     (if (display-graphic-p)
;;         (gui-selection-value)
;;       (shell-command-to-string "wl-paste --no-newline")))
;;   (setq interprogram-cut-function #'my-wl-copy)
;;   (setq interprogram-paste-function #'my-wl-paste))

;; macOS caps file descriptors at 256 and file watching burns one per
;; watched file — without this, lsp servers die with "no file descriptor
;; left" on any real project (same bug we hit with eglot).
(after! lsp-mode
  (setq lsp-enable-file-watchers nil))

;; remove LSP delays
(after! flycheck (setq flycheck-idle-change-delay 0.1))
(after! lsp-mode
  (setq lsp-idle-delay 0.1)
  :custom
  (setq lsp-completion-enable-additional-text-edit t)
  (setq lsp-modeline-code-actions-enable t)
  )   

;; load go-specific dap package
;; (after! dap-mode
;;   (require 'dap-dlv-go)
;;   (dap-ui-mode 1)
;;   (dap-tooltip-mode 1))   

;; Better debugging
(use-package! dape)   

;; jk to escape insert mode (evil-escape ships with Doom's evil module)
(after! evil-escape
  (setq evil-escape-key-sequence "jk"
        evil-escape-delay 0.15))
