;;; guix.scm --- Additional functions for Guix Misc

;; Copyright © 2018 Oleg Pykhalov <go.wigust@gmail.com>

;; Guix-Misc is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Guix-Misc is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Guix-Misc.
;; If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file contains Guix package for development version of
;; Guix-Misc.  To build or install, run:
;;
;;   guix build --file=guix.scm
;;   guix package --install-from-file=guix.scm

;;; Code:

(use-modules ((guix licenses) #:prefix license:)
             (guix build utils)
             (guix build-system trivial)
             (guix gexp)
             (guix git-download)
             (guix packages)
             (ice-9 popen)
             (ice-9 rdelim)
             (gnu packages base)
             (gnu packages bash)
             (gnu packages guile)
             (gnu packages parallel))

(define %source-dir (dirname (current-filename)))

(define (git-output . args)
  "Execute 'git ARGS ...' command and return its output without trailing
newspace."
  (with-directory-excursion %source-dir
    (let* ((port   (apply open-pipe* OPEN_READ "git" args))
           (output (read-string port)))
      (close-port port)
      (string-trim-right output #\newline))))

(define (current-commit)
  (git-output "log" "-n" "1" "--pretty=format:%H"))

(let ((commit (current-commit)))
  (package
    (name "guix-misc")
    (version (string-append "0.0.1" "-" (string-take commit 7)))
    (source (local-file %source-dir
                        #:recursive? #t
                        #:select? (git-predicate %source-dir)))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin 
         (use-modules (guix build utils))
         (copy-recursively (assoc-ref %build-inputs "source") ".")
         (setenv "PATH" (string-append
                         (assoc-ref %build-inputs "bash") "/bin" ":"
                         (assoc-ref %build-inputs "parallel") "/bin" ":"
                         (assoc-ref %build-inputs "findutils") "/bin" ":"
                         (assoc-ref %build-inputs "coreutils") "/bin" ":"
                         (assoc-ref %build-inputs "guile") "/bin" ":"))
         (with-directory-excursion "scripts"
           (let ((file "guix-compile-package-path"))
             (substitute* file
               (("/bin/sh") (which "bash"))
               (("@FIND_BIN@") (which "find"))
               (("@GUILD_BIN@") (which "guild"))
               (("@PARALLEL_BIN@") (which "parallel"))
               (("@PRINTENV_BIN@") (which "printenv"))
               (("@TR_BIN@") (which "tr")))
             (chmod file #o555)
             (install-file file (string-append %output "/bin"))))
         #t)))
    (inputs
     `(("bash" ,bash)
       ("coreutils" ,coreutils)
       ("findutils" ,findutils)
       ("guile" ,guile-2.2)
       ("parallel" ,parallel)))
    (home-page "https://gitlab.com/wigust/guix-misc")
    (synopsis "Additional programs to control Guix")
    (description
     "This package provides an additional programs to control Guix.")
    (license license:gpl3+)))

;;; guix.scm ends here
