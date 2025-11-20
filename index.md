# checkpdf: Check, validate, and report PDF accessibility

  

> \[!WARNING\]  
> work in progress

[checkpdf](https://rfortherestofus.github.io/checkpdf/) is an R package
that aims to make checking the accessibility of PDF files as easy as
possible. It relies on
[verapdf](https://github.com/veraPDF/veraPDF-library) (which does all
the hard work in the background) and uses it to provide detailed reports
on issues found in your PDF files.

  

## Installation

``` r
# install.packages("pak")
pak::pkg_install("rfortherestofus/checkpdf")
```

  

## Usage

- Make sure to install verapdf\*:

``` r
checkpdf::install_verapdf()
```

> \*Should only do once and is **not** necessary if you already have the
> verapdf cli on PATH

  

- Check that a PDF is PDF/UA-1 compliant:

``` r
checkpdf::is_pdf_compliant("report.pdf")
#> TRUE

# check for PDF/UA-2
checkpdf::is_pdf_compliant("report.pdf", profile = "ua2")
#> FALSE
```

It works with many standards: `profile` can be any of `ua1`, `ua2`,
`1a`, `1b`, `2a`, `2b`, `2u`, `3a`, `3b`, `3u`, `4`, `4f`, `4e`. Default
is `ua1`. You can find their meaning
[here](https://docs.verapdf.org/cli/validation/#list-profiles).

  

- Generate an HTML accessibility report:

``` r
# Basic usage: this opens your browser
checkpdf::accessibility_report("report.pdf")

# Explicit output file
checkpdf::accessibility_report(
   "report.pdf",
   output_file = "report.html"
)

# Do not open browser
checkpdf::accessibility_report(
   "report.pdf",
   output_file = "report.html",
   open = FALSE
)

# Specify a different accessibility standard
checkpdf::accessibility_report(
   "report.pdf",
   output_file = "report.html",
   open = FALSE,
   profile = "ua2"
)
```

  

- Print an accessibility summary

``` r
checkpdf::accessibility_summary("report.pdf")
#> PDF Accessibility Summary
#> =========================
#> Verapdf version:  1.28.2
#> Compliant:  No
#> Profile:  ua1
#>
#> Passed Rules:   95
#> Passed Checks:  591
#> Failed Rules:   11
#> Failed Checks:  195
```

  

## Licenses

This packages is licensed under the MIT license but this package also
bundles the verapdf installer, which is licensed under MPL-2.0. Your use
of verapdf is subject to the MPL-2.0 license. See
`inst/LICENSE.verapdf`.
