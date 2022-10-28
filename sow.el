;; Whether to base on evil. Set to 't' by default. Setting to nil, will make toodoo work with plain emacs.
(defvar sow-evil-base t)

;===============================================================================
;;; Sow Core Functions

(defun sow-add-entry (entry)
  "Add a new entry using current selection or word under cursor as prompt."
  (interactive (list
                (read-string "Add Entry: "
                             (if (use-region-p)
                                 (buffer-substring-no-properties (mark) (point))
                                 (thing-at-point 'word)))))
  (org-insert-heading-after-current)
  (insert entry)
  (org-narrow-to-subtree))

(defun sow-jump-entry ()
  "Jump to an entry."
  (interactive)
  ;; this widening is required for org-goto to work correctly
  (widen)
  (org-overview)
  ;; can be replaced with imenu, imenu-anywhere, helm-imenu, etc
  (call-interactively #'org-goto)
  (org-narrow-to-subtree)
  (org-show-subtree))

(defun sow-setup-highlights ()
  "Highlight all current entries."
  (widen)
  (outline-hide-sublevels 1)
  (org-map-entries (lambda () (highlight-regexp (org-get-heading t t t t) 'org-agenda-clocking)) "LEVEL=1"))

;===============================================================================
;;; Operating Transient Menus

;===============================================================================
;;; Sow Keymap setup

(defvar sow-mode-keymap (make-sparse-keymap))
(progn
  (define-key sow-mode-keymap (kbd ";h") 'sow-transient-main)
  (define-key sow-mode-keymap (kbd ";a") 'sow-add-entry)
  (define-key sow-mode-keymap (kbd ";e") 'sow-jump-entry))

(if sow-evil-base
  (progn
    ;; overrides all maps, not just normal
    ;; this is bad - since we can't use single key shortcuts anymore: such as a in normal mode since keys now impact even insert mode
    ;; but, this is needed since we need a specific command in visual mode
    ;; manually overriding normal and visual didn't seem to work - needs some investigation
    (evil-make-overriding-map sow-mode-keymap nil)
    (add-hook 'sow-mode-hook #'evil-normalize-keymaps)))

;===============================================================================
;;; Sow Minor Mode setup

;;;###autoload
(define-minor-mode sow-mode
  "Simple Wiki built on Org."
  :lighter " sow"
  :keymap sow-mode-keymap
  (if sow-mode
      (progn
        (setq org-goto-interface (quote outline-path-completion))
        (sow-setup-highlights))
      ))

(provide 'sow-mode)
(provide 'sow)
