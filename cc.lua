
--Copyright (c) 2019 Mirko Kunze
--
--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:
--
--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--SOFTWARE.

local argparse = require "argparse"

local parser = argparse("lua cc.lua", "lua cc.lua -o program -I inc -L libs -l lib1 -l lib2 -c gcc main.cpp utils.cpp")
parser:argument("input", "input file"):args("+")
parser:option("-c --compiler", "choose compiler (clang/gcc/msvc)")
parser:option("-s --standard", "C++ standard (98/11/14/17/2a)", "17")
parser:option("-o --output", "output file", "program")
parser:option("-O --optimize", "optimization level (0/1/2/3/s)")
parser:flag("-g --debug", "create debug information")
parser:option("-I --include", "include locations"):count("*")
parser:option("-L --libdir", "search library in directory"):count("*")
parser:option("-l --library", "include library"):count("*")
parser:option("-D --define", "define macro"):count("*")

local args = parser:parse()

-- helpers

function getOS()
	local libext = package.cpath:match("%p[\\|/]?%p(%a+)")
	if libext == "dll" then
		return "Windows"
	elseif libext == "so" then
		return "Linux"
	elseif libext == "dylib" then
		return "MacOS"
	end
	return nil
end
local system = getOS()

function exec(cmd)
	local h = assert(io.popen(cmd, 'r'))
	local output = h:read('*all')
	h:close()
	return output
end

-- get compiler

compiler = args.compiler
if compiler == nil then
	if system == "Linux" then
		if exec("g++ --version") ~= "" then
			compiler = "gcc"
		elseif exec("clang++ --version") ~= "" then
			compiler = "clang"
		else
			io.stderr:write("detected neither gcc nor clang, terminating\n")
			os.exit(1)
		end
	elseif system == "Windows" then
		if exec("CL") ~= "" then
			compiler = "msvc"
		elseif exec("g++ --version") ~= "" then
			compiler = "gcc"
		elseif exec("clang++ --version") ~= "" then
			compiler = "clang"
		else
			io.stderr:write("detected neither msvc nor gcc nor clang, terminating\n")
			os.exit(1)
		end
	elseif system == "MacOS" then
		if exec("clang++ --version") ~= "" then
			compiler = "clang"
		elseif exec("g++ --version") ~= "" then
			compiler = "gcc"
		else
			io.stderr:write("detected neither gcc nor clang, terminating\n")
			os.exit(1)
		end
	end
end

if compiler ~= "clang" and compiler ~= "gcc" and compiler ~= "msvc" then
	io.stderr:write("unknown compiler: " .. compiler .. " (options are clang/gcc/msvc)")
	os.exit(1)
end

print("using " .. compiler .. " on " .. system)

-- construct invocation command

ccargs = {}

-- c++ standard

if compiler == "msvc" then
	if args.standard == "14" or args.standard == "17" then
		table.insert(ccargs, "/std:c++" .. args.standard)
	elseif args.standard == "2a" then
		table.insert(ccargs, "/std:c++latest")
	else
		io.stderr:write("msvc only supports C++ 14/17/2a, terminating\n")
		os.exit(1)
	end
else
	table.insert(ccargs, "-std=c++" .. args.standard)
end

-- output

if compiler == "msvc" then
	table.insert(ccargs, "/link /out:" .. args.output)
else
	table.insert(ccargs, "-o " .. args.output)
end

-- optimization

if compiler == "msvc" then
	if args.optimize == "0" or args.optimize == nil and args.debug then
		table.insert(ccargs, "/Od")
	elseif args.optimize == nil and not args.debug then
		table.insert(ccargs, "/O2")
	else
		table.insert(ccargs, "/O" .. args.optimize)
	end
else
	if args.optimize == nil then
		if args.debug then
			table.insert(ccargs, "-O0")
		else
			table.insert(ccargs, "-O2")
		end
	else
		table.insert(ccargs, "-O" .. args.optimize)
	end
end

-- debug

if args.debug then
	if compiler == "msvc" then
		table.insert(ccargs, "/Zi")
	else
		table.insert(ccargs, "-g")
	end
end

-- include directories

for i = 1, #args.include do
	if compiler == "msvc" then
		table.insert(ccargs, "/I" .. args.include[i]:gsub("/", "\\"))
	else
		table.insert(ccargs, "-I" .. args.include[i])
	end
end

-- library directories

for i = 1, #args.libdir do
	if compiler == "msvc" then
		io.stderr:write("todo\n")
		os.exit(1)
	else
		table.insert(ccargs, "-L" .. args.libdir[i])
	end
end

-- static libraries

for i = 1, #args.library do
	if compiler == "msvc" then
		io.stderr:write("todo\n")
		os.exit(1)
	else
		table.insert(ccargs, "-l" .. args.library[i])
	end
end

-- defines

for i = 1, #args.define do
	if compiler == "msvc" then
		table.insert(ccargs, "/D" .. args.define[i])
	else
		table.insert(ccargs, "-D" .. args.define[i])
	end
end

-- misc

if compiler == "msvc" then
	table.insert(ccargs, "/EHsc /Wall")
else
	table.insert(ccargs, "-pthread -Wall -Wextra -Wpedantic")
end

-- input

for i = 1, #args.input do
	table.insert(ccargs, args.input[i])
end

-- invoke compiler

local cmd
if compiler == "clang" then
	cmd = "clang++ " .. table.concat(ccargs, " ")
elseif compiler == "gcc" then
	cmd = "g++ " .. table.concat(ccargs, " ")
elseif compiler == "msvc" then
	cmd = "CL " .. table.concat(ccargs, " ")
end

print(cmd)
result = exec(cmd)
print(result)
