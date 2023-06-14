import std/strformat
import model
#import macros

proc genCode*(m: FMU): string =
  result = &"""
  echo "{m.guid}"
  """

