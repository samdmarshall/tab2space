import os
import strutils
import asyncfile
import asyncdispatch
import parseopt2


var files: seq[string] = @[]
var tab_length = 2
var echo_out: bool = false

proc versionInfo(): void = 
  echo("v0.1.0")
  quit(QuitSuccess)

proc usage(): void =
  echo()
  quit(QuitSuccess)

for kind, key, value in getopt():
  case kind
  of cmdArgument:
    files.add(key)
  of cmdLongOption, cmdShortOption:
    case key
    of "version":
      versionInfo()
    of "help":
      usage()
    of "length", "l":
      tab_length = parseInt(value)
    of "echo", "e":
      echo_out = true
    else:
      discard
  else:
    discard

if len(files) == 0:
  echo("Please supply files!")
  quit(QuitFailure)

for file in files:
  var path = file.expandTilde()
  let mode = if not echo_out: fmReadWrite
             else: fmRead
  var fd = openAsync(path, mode)
  let output_fd = if not echo_out: fd
                  else: stdout
  let size = fd.getFileSize()
  var index = 0
  while index < size:
    fd.setFilePos(index)
    let future_ch = fd.read(1)
    let ch = waitFor(future_ch)
    if ch.cstring[0] == '\t':
      output_fd.write(" ".repeat(tab_length))
    else:
      output_fd.write(ch.cstring[0])
    index += 1
  fd.close()
