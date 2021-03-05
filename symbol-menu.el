;;; -*- lexical-binding: t -*-

(require 'tabulated-list)

(defcustom symbol-menu-should-sort-p t
  "To sort function/variable entries or not.

This will make entry initialization much slower, especially for `list-functions',
which generally has more than 15k entries.")

(defun symbol-menu--collect-entries (kind)
  (let ((filter (cond ((eq kind 'function) #'functionp)
                      ((eq kind 'variable) (lambda (x)
                                             (and (boundp x) (not (keywordp x)))))
                      (t (error (format "Unrecognized symbol query ~s" (symbol-name kind))))))
        (entries nil))
    (mapatoms (lambda (x)
                (when (funcall filter x)
                  (add-to-list
                   'entries
                   `(,x [,(symbol-name x) ,(short-doc x kind)])))))
    entries))

(defun short-doc (sym kind)
  (let* ((doc (or (cond ((eq kind 'function) (documentation sym))
                        ((eq kind 'variable) (documentation-property
                                             sym
                                             'variable-documentation))
                        (t (error (format "No ~s kind document for ~s"
                                          (symbol-name kind)
                                          (symbol-name sym)))))
                  "no documentation."))
         (start (string-match "." doc))
         (end (string-match "[\\.\\?!\n]" doc start)))
    (substring doc start end)))

(defun symbol-menu-find-definitions ()
  (interactive)
  (let ((xref-backend-functions '(elisp--xref-backend t)))
    (xref-find-definitions (tabulated-list-get-id))))

(defun function-menu-describe ()
  (interactive)
  (describe-function (tabulated-list-get-id)))

(defvar function-menu-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map (kbd "C-m") #'function-menu-describe)
    (define-key map (kbd ".") #'symbol-menu-find-definitions)
    map))

(defvar function-menu-format [("function" 40 t)
                              ("documentation" 0 nil)])

(define-derived-mode function-menu-mode tabulated-list-mode "Function Menu"
  "Major mode to display list of functions and documentation."
  (setq tabulated-list-format function-menu-format)
  (setq tabulated-list-entries (symbol-menu--collect-entries 'function))
  (when symbol-menu-should-sort-p
    (setq tabulated-list-sort-key (cons "function" nil)))
  (setq tabulated-list-padding 2)
  (tabulated-list-init-header)
  (tabulated-list-print))

;;;###autoload
(defun list-functions ()
  "List all functions and related documentation."
  (interactive)
  (let ((buf (get-buffer-create "*functions*")))
    (with-current-buffer buf
      (function-menu-mode))
    (switch-to-buffer buf)))

(defun variable-menu-describe ()
  (interactive)
  (describe-variable (tabulated-list-get-id)))

(defvar variable-menu-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map (kbd "C-m") #'variable-menu-describe)
    (define-key map (kbd ".") #'symbol-menu-find-definitions)
    map))

(defvar variable-menu-format [("variable" 40 t)
                              ("documentation" 0 nil)])

(define-derived-mode variable-menu-mode tabulated-list-mode "Variable Menu"
  "Major mode to display list of variables and documentation."
  (setq tabulated-list-format variable-menu-format)
  (setq tabulated-list-entries (symbol-menu--collect-entries 'variable))
  (when symbol-menu-should-sort-p
    (setq tabulated-list-sort-key (cons "variable" nil)))
  (setq tabulated-list-padding 2)
  (tabulated-list-init-header)
  (tabulated-list-print))

;;;###autoload
(defun list-variables ()
  "List all variables and related documentation."
  (interactive)
  (let ((buf (get-buffer-create "*variables*")))
    (with-current-buffer buf
      (variable-menu-mode))
    (switch-to-buffer buf)))

(provide 'symbol-menu)
