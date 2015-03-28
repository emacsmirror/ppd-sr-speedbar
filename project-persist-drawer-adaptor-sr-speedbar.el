(require 'sr-speedbar)

(defun project-persist-drawer-get-window ()
  (when (boundp 'sr-speedbar-window) sr-speedbar-window))

(defun project-persist-drawer-open (dir)
  (sr-speedbar-open)
  (speedbar-update-contents)
  (ppd/sr-speedbar-pin dir))

(defun project-persist-drawer-before-open (dir)
  (ppd/sr-speedbar-undedicate)
  (ppd/sr-speedbar-unpin))

(defun project-persist-drawer-after-open (dir)
    (ppd/sr-speedbar-pin dir)
    (ppd/sr-speedbar-rededicate)))

;;; Internal

(defun ppd/sr-speedbar-undedicate ()
  (ppd/try-set-window-dedication nil))

(defun ppd/sr-speedbar-rededicate ()
  (ppd/try-set-window-dedication t))

(defun ppd/try-set-window-dedication (p)
  (let ((window (project-persist-drawer-get-window)))
    (when window
      (set-window-dedicated-p window p))))

(defun ppd/sr-speedbar-pin (dir)
  "Prevent the speedbar from changing the displayed root directory."
  (setq ppd/sr-speedbar-pinned-directory dir)
  (mapc (lambda (ls) (apply 'ad-enable-advice ls)) ppd/sr-speedbar-pin-advice)
  (ppd/sr-speedbar-pin-advice-activate))

(defun ppd/sr-speedbar-unpin ()
  ((mapc (lambda (ls) (apply 'ad-disable-advice ls)) ppd/sr-speedbar-pin-advice)
   (ppd/sr-speedbar-pin-advice-activate)))

(defun ppd/sr-speedbar-pin-advice-activate ()
  "Activate the advice applied to speedbar functions in order to pin it to a directory."
  (mapc 'ad-activate (mapcar 'car ppd/sr-speedbar-pin-advice)))

(defun ppd/sr-speedbar-setup-pinning ()
  (defadvice speedbar-update-directory-contents
      (around ppd/sr-speedbar-pin-directory activate disable)
    "Pin the speedbar to the directory set in ppd/sr-speedbar-pinned-directory."
    (let ((default-directory ppd/sr-speedbar-pinned-directory))
      ad-do-it))
  (defadvice speedbar-dir-follow
      (around ppd/sr-speedbar-prevent-follow activate disable)
    "Prevent speedbar changing directory on button clicks."
    (speedbar-toggle-line-expansion))
  (defadvice speedbar-directory-buttons-follow
      (around ppd/sr-speedbar-prevent-root-follow activate disable)
    "Prevent speedbar changing root directory on button clicks.")
  (defvar ppd/sr-speedbar-pin-advice
    '((speedbar-update-directory-contents around ppd/sr-speedbar-pin-directory)
      (speedbar-dir-follow around ppd/sr-speedbar-prevent-follow)
      (speedbar-directory-buttons-follow around ppd/sr-speedbar-prevent-root-follow))))

(defun ppd/sr-speedbar-load-settings ()
  (setq speedbar-hide-button-brackets-flag t
        speedbar-show-unknown-files t
        speedbar-smart-directory-expand-flag t
        speedbar-directory-button-trim-method 'trim
        speedbar-use-images nil
        speedbar-indentation-width 2
        speedbar-use-imenu-flag t
        sr-speedbar-width 40
        sr-speedbar-width-x 40
        sr-speedbar-auto-refresh nil
        sr-speedbar-skip-other-window-p t
        sr-speedbar-right-side nil))

(defvar ppd/sr-speedbar-refresh-hooks '(after-save-hook))
(defvar ppd/sr-speedbar-refresh-hooks-added nil)

(defun ppd/sr-speedbar-add-refresh-hooks ()
  (when (not ppd/sr-speedbar-refresh-hooks-added)
    (lambda ()
      (mapc (lambda (hook)
              (add-hook hook 'speedbar-refresh))
            ppd/sr-speedbar-refresh-hooks)
      (setq ppd/sr-speedbar-refresh-hooks-added t))))

(defun ppd/sr-speedbar-setup-speedbar ()
  (add-hook 'speedbar-mode-hook
            '(lambda ()
               (hl-line-mode 1)
               (visual-line-mode -1)
               (setq automatic-hscrolling nil)
               (let ((speedbar-display-table (make-display-table)))
                 (set-display-table-slot speedbar-display-table 0 8230)
                 (setq buffer-display-table speedbar-display-table)))))

(defun ppd/sr-speedbar-setup-keymap ()
  (add-hook 'speedbar-reconfigure-keymaps-hook
            '(lambda ()
               (define-key speedbar-mode-map [right] 'speedbar-flush-expand-line)
               (define-key speedbar-mode-map [left] 'speedbar-contract-line))))

(defvar ppd/sr-speedbar-target-window
  (if (not (eq (selected-window) sr-speedbar-window))
      (selected-window)
    (other-window 1)))

(defun ppd/sr-speedbar-setup-target-window ()
  (defadvice select-window (after remember-selected-window activate)
    (unless (or (eq (selected-window) sr-speedbar-window)
                (not (window-live-p (selected-window))))
      (setq ppd/sr-speedbar-target-window (selected-window))))
  (add-hook 'sr-speedbar-before-visiting-file-hook 'ppd/sr-speedbar-select-target-window)
  (add-hook 'sr-speedbar-before-visiting-tag-hook 'ppd/sr-speedbar-select-target-window)
  (add-hook 'sr-speedbar-visiting-file-hook 'ppd/sr-speedbar-select-target-window)
  (add-hook 'sr-speedbar-visiting-tag-hook 'ppd/sr-speedbar-select-target-window))

(defun ppd/sr-speedbar-select-target-window ()
  (select-window ppd/sr-speedbar-target-window))

(eval-after-load 'sr-speedbar
  '(progn
     (ppd/sr-speedbar-load-settings)
     (ppd/sr-speedbar-add-refresh-hooks)
     (ppd/sr-speedbar-setup-speedbar)
     (ppd/sr-speedbar-setup-keymap)
     (ppd/sr-speedbar-setup-target-window)
     (ppd/sr-speedbar-setup-pinning)))

(provide 'project-persist-drawer-adaptor-sr-speedbar)
