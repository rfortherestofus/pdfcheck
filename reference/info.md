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
pdf_file <- system.file("pdf", "not-compliant-1.pdf", package = "checkpdf")

verapdf(pdf_file) |>
  get_total_failed_checks()
#> [1] 195

verapdf(pdf_file) |>
  get_total_failed_rules()
#> [1] 11

verapdf(pdf_file) |>
  get_verapdf_version()
#> [1] "1.28.2"
```
