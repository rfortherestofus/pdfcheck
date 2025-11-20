<br>

> [!WARNING]  
> work in progress

# checkpdf: Check, validate, and report PDF accessibility

`{checkpdf}` is an R package that aims to make checking the accessibility of PDF files as easy as possible. It relies on [verapdf](https://github.com/veraPDF/veraPDF-library) (which does all the hard work in the background) and uses it to provide detailed reports on issues found in your PDF files.

<br>

## Installation

```r
# install.packages("pak")
pak::pkg_install("rfortherestofus/checkpdf")
```

<br>

## Usage

- Make sure to install verapdf (should only do once):

```r
checkpdf::install_verapdf()
```

- Check that a PDF is PDF/UA-1 compliant:

```r
checkpdf::is_pdf_compliant("report.pdf")
#> TRUE
```

- Generate an HTML accessibility report:

```r
checkpdf::accessibility_report("report.pdf") # will open your browser
```

- Summary

```r
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

<br>

## Licenses

This packages is licensed under the MIT license but this package also bundles the verapdf installer, which is licensed under MPL-2.0. Your use of verapdf is subject to the MPL-2.0 license. See `inst/LICENSE.verapdf`.
