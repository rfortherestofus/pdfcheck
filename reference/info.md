# Retrieve specific accessibility info

Utility functions to retrieve specific informations about PDF
accessibility.

## Usage

``` r
get_total_failed_checks(x)

get_total_failed_rules(x)

get_verapdf_version(x)
```

## Arguments

- x:

  Output from
  [`verapdf()`](https://rfortherestofus.github.io/checkpdf/reference/verapdf.md)

## Examples

``` r
if (FALSE) { # \dontrun{
verapdf("inst/pdf/not-compliant-1.pdf") |>
  get_total_failed_checks()

verapdf("inst/pdf/not-compliant-1.pdf") |>
  get_total_failed_rules()

verapdf("inst/pdf/not-compliant-1.pdf") |>
  get_verapdf_version()
} # }
```
