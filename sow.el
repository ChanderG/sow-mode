;; Whether to base on evil. Set to 't' by default. Setting to nil, will make toodoo work with plain emacs.
(defvar sow-evil-base t)
;; variable tracking the last entry
(defvar sow-last-entry nil)

;===============================================================================
;;; Sow Core Functions

(defun sow-add-entry (entry)
  "Add a new entry using current selection or word under cursor as prompt."
  (interactive (list
                (read-string "Add Entry: "
                             (if (use-region-p)
                                 (buffer-substring-no-properties (mark) (point))
                                 (thing-at-point 'word)))))
  (setq sow-last-entry (org-get-heading t t t t))
  (org-insert-heading-after-current)
  (insert entry)
  (highlight-regexp entry 'org-agenda-clocking)
  (org-narrow-to-subtree))

(defun sow-jump-last-entry ()
  "Jump to last editing entry."
  (interactive)
  (let ((entry sow-last-entry))
    ;; update last entry pointer
    (setq sow-last-entry (org-get-heading t t t t))
    ;; need to expand scope
    (widen)
    (org-overview)
    ;; otherwise, this search below fails
    (goto-char (org-find-exact-headline-in-buffer entry))
    (org-narrow-to-subtree)
    (org-show-subtree)))

(defun sow-jump-entry ()
  "Jump to entry under cursor. If nothing found, run wild card jump."
  (interactive)
  ;; update last entry pointer
  (setq sow-last-entry (org-get-heading t t t t))
  (if (eq (car (get-text-property (point) 'face)) 'org-agenda-clocking)
      (let* ((beg (next-property-change (point)))
             (end (previous-property-change (+ (point) 1)))
             (match (buffer-substring-no-properties beg end)))
        (goto-char (org-find-exact-headline-in-buffer match))
        (org-narrow-to-subtree)
        (org-show-subtree))
    (sow-jump-entry-wildcard)))

(defun sow-jump-entry-wildcard ()
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
  (define-key sow-mode-keymap (kbd ";p") 'sow-jump-last-entry)
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
    (progn
      (unhighlight-regexp t)
      )
      ))

(provide 'sow-mode)
(provide 'sow)
