# shuffle_latex_exam
Perl script to shuffle test written in LaTeX
by documentclass exam.

To exec:
    ./shuffle.pl

## LaTeX Info
The text to be shuffle is between questions environment like:
```Latex
\begin{questions}

\question
    ...
\question
    ...

\end{questions}
```

## software requirements

### Perl software requirements

```Perl
use List::Util qw/shuffle/;
use POSIX qw(ceil);
```

### system software requirements
```console
$ cp
$ rm
$ pdflatex
$ pdftk
```

cp and rm are system commands,
pdflatex to build pdf, pdftk to join pdf in single pdf.
