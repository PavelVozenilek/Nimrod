#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Implementation of some runtime checks.

proc raiseRangeError(val: BiggestInt) {.compilerproc, noreturn, noinline.} =
  when hostOS == "standalone":
    sysFatal(EOutOfRange, "value out of range")
  else:
    sysFatal(EOutOfRange, "value out of range: ", $val)

proc raiseIndexError() {.compilerproc, noreturn, noinline.} =
  sysFatal(EInvalidIndex, "index out of bounds")

proc raiseFieldError(f: string) {.compilerproc, noreturn, noinline.} =
  sysFatal(EInvalidField, f, " is not accessible")

proc chckIndx(i, a, b: int): int =
  if i >= a and i <= b:
    return i
  else:
    raiseIndexError()

proc chckRange(i, a, b: int): int =
  if i >= a and i <= b:
    return i
  else:
    raiseRangeError(i)

proc chckRange64(i, a, b: int64): int64 {.compilerproc.} =
  if i >= a and i <= b:
    return i
  else:
    raiseRangeError(i)

proc chckRangeF(x, a, b: float): float =
  if x >= a and x <= b:
    return x
  else:
    when hostOS == "standalone":
      sysFatal(EOutOfRange, "value out of range")
    else:
      sysFatal(EOutOfRange, "value out of range: ", $x)

proc chckNil(p: pointer) =
  if p == nil:
    sysFatal(EInvalidValue, "attempt to write to a nil address")
    #c_raise(SIGSEGV)

proc chckObj(obj, subclass: PNimType) {.compilerproc.} =
  # checks if obj is of type subclass:
  var x = obj
  if x == subclass: return # optimized fast path
  while x != subclass:
    if x == nil:
      sysFatal(EInvalidObjectConversion, "invalid object conversion")
      break
    x = x.base

proc chckObjAsgn(a, b: PNimType) {.compilerproc, inline.} =
  if a != b:
    sysFatal(EInvalidObjectAssignment, "invalid object assignment")

type ObjCheckCache = array[0..1, PNimType]

proc isObjSlowPath(obj, subclass: PNimType;
                   cache: var ObjCheckCache): bool {.noinline.} =
  # checks if obj is of type subclass:
  var x = obj.base
  while x != subclass:
    if x == nil:
      cache[0] = obj
      return false
    x = x.base
  cache[1] = obj
  return true

proc isObjWithCache(obj, subclass: PNimType;
                    cache: var ObjCheckCache): bool {.compilerProc, inline.} =
  if obj == subclass: return true
  if obj.base == subclass: return true
  if cache[0] == obj: return false
  if cache[1] == obj: return true
  return isObjSlowPath(obj, subclass, cache)

proc isObj(obj, subclass: PNimType): bool {.compilerproc.} =
  # checks if obj is of type subclass:
  var x = obj
  if x == subclass: return true # optimized fast path
  while x != subclass:
    if x == nil: return false
    x = x.base
  return true
