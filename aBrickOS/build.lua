local path = os.getenv("_")
path = path:sub(1,path:find("/[^/]*$"))

--os.execute("lua "..path.."minify.lua minify "..path.."boot.lua > "..path.."boot_minified.lua")
os.execute("lua "..path.."compress_lzss.lua "..path.."boot_minified.lua > "..path.."boot_compressed.lua")