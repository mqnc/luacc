# luacc
C++ compiler wrapper for Clang, GCC and MSVC written in Lua

## Status
in development, untested

## Usage
```
Usage: lua cc.lua [-c <compiler>] [-s <standard>] [-o <output>]
       [-O <optimize>] [-g] [-I <include>] [-L <libdir>]
       [-l <library>] [-D <define>] [-h] <input> [<input>] ...

lua cc.lua -o program -I inc -L libs -l lib1 -l lib2 -c gcc main.cpp utils.cpp

Arguments:
   input                 input file

Options:
           -c <compiler>,
   --compiler <compiler>
                         choose compiler (clang/gcc/msvc)
           -s <standard>,
   --standard <standard>
                         C++ standard (98/11/14/17/2a) (default: 17)
         -o <output>,    output file (default: program)
   --output <output>
           -O <optimize>,
   --optimize <optimize>
                         optimization level (0/1/2/3/s)
   -g, --debug           create debug information
          -I <include>,  include locations
   --include <include>
         -L <libdir>,    search library in directory
   --libdir <libdir>
          -l <library>,  include library
   --library <library>
         -D <define>,    define macro
   --define <define>
   -h, --help            Show this help message and exit.
```
