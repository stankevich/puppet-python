# @summary Match all valid versions for python
#
type Python::Version = Pattern[
  /\A(python)?[0-9](\.?[0-9])*/,
  /\Apypy\Z/,
  /\Asystem\Z/,
  /\Arh-python[0-9]{2}(?:-python)?\Z/
]
