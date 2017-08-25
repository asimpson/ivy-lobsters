;;; ivy-lobsters.el --- Browse lobste.rs stories with ivy.

;; Copyright (C) 2017 by Julien Blanchard
;; Author: Julien Blanchard <https://github.com/julienXX>
;; Package: ivy-lobsters
;; Package-Requires: ((ivy "0.8.0") (cl-lib "0.5"))
;; Version: 0.1

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; Makes it easier to browse lobste.rs from Emacs.

;;; Code:

(require 'cl-lib)
(require 'ivy)
(require 'browse-url)

(defgroup  ivy-lobsters nil
  "Customs for `ivy-lobsters'"
  :group 'applications)

(defcustom ivy-lobsters-url "https://lobste.rs/newest.json"
  "Variable to define lobste.rs newest articles url."
  :type 'string :group 'ivy-lobsters)

(defvar ivy-lobsters-stories '())

(defun ivy-lobsters-get-posts ()
  "Get newest posts json and store parsed stories."
  (with-temp-buffer
    (unless (zerop (call-process "curl" nil t nil "-s" ivy-lobsters-url))
      (error "Failed: 'curl -s %s'" ivy-lobsters-url))
    (let* ((json nil)
           (ret (ignore-errors
                  (setq json (json-read-from-string
                              (buffer-substring-no-properties
                               (point-min) (point-max))))
                  t)))
      (unless ret
        (error "Error: Can't get JSON response"))
      (setq ivy-lobsters-stories (ivy-lobsters-parse json)))))

(defun ivy-lobsters-parse (stories)
  "Parse the json provided by STORIES."
  (cl-loop for story being the elements of stories
           for score = (cdr (ivy-lobsters-tree-assoc 'score story))
           for title = (decode-coding-string
                        (string-make-multibyte
                         (cdr (ivy-lobsters-tree-assoc 'title story)))
                        'utf-8)
           for url = (cdr (ivy-lobsters-tree-assoc 'url story))
           for comments = (cdr (ivy-lobsters-tree-assoc 'comment_count story))
           for comments-url = (cdr (ivy-lobsters-tree-assoc 'comments_url story))
           for cand = (format "%s %s (%d comments)"
                              (format "[%d]" score)
                              title
                              comments)
           collect (cons cand (list :url url :score score :comments-url comments-url))))

(defun ivy-lobsters-tree-assoc (key tree)
  "Build the tree-assoc from KEY TREE."
  (when (consp tree)
    (cl-destructuring-bind (x . y)  tree
      (if (eql x key) tree
        (or (ivy-lobsters-tree-assoc key x) (ivy-lobsters-tree-assoc key y))))))

(defun ivy-lobsters ()
  "Bring Ivy frontend to choose and open a story."
  (interactive)
  (ivy-lobsters-get-posts)
  (ivy-read (concat "Lobste.rs latest stories: ") ivy-lobsters-stories
            :action (lambda (story)
                      (browse-url (plist-get (cdr story) :url)))))

(ivy-set-actions
 t
 '(("c" (lambda (story)
          (browse-url (plist-get (cdr story) :comments-url))) "Browse Comments")))


(provide 'ivy-lobsters)
;;; ivy-lobsters.el ends here
