const fs = require('fs');

let source = fs.readFileSync('Aimbot_Pronto_Final.lua', 'utf8');
source = source.replace(/--\[\[[\s\S]*?\]\]/g, '');
source = source.replace(/--[^\n]*\n/g, '\n');

let key1 = "LYAN_V6_" + Math.random().toString(36).substring(2);
let enc1 = [];
for(let i=0; i<source.length; i++) {
    enc1.push((source.charCodeAt(i) ^ key1.charCodeAt(i % key1.length)) + 15);
}

function R(len) {
    let chars = "O0Il";
    let s = "";
    for(let i=0;i<len;i++) s+= chars[Math.floor(Math.random()*chars.length)];
    return s;
}

let v_ls = R(12), v_env = R(14), v_res = R(10), v_enc = R(15), v_key = R(13), v_idx = R(11), v_xor = R(16), v_chr = R(10);

let layer1 = "";
layer1 += "local " + v_env + " = getfenv or function() return _ENV end\n";
layer1 += "local " + v_ls + " = " + v_env + "().loadstring or " + v_env + "().load\n";
layer1 += "local function prevent_spy()\n";
layer1 += "    local safe = true\n";
layer1 += "    if iscclosure and not iscclosure(" + v_ls + ") then safe = false end\n";
layer1 += "    if ishooked and ishooked(" + v_ls + ") then safe = false end\n";
layer1 += "    if debug and debug.getinfo then\n";
layer1 += "        local i = debug.getinfo(" + v_ls + ")\n";
layer1 += "        if i and i.what ~= 'C' then safe = false end\n";
layer1 += "    end\n";
layer1 += "    if not safe then\n";
layer1 += "        local crash = {}\n";
layer1 += "        while true do table.insert(crash, string.rep('DUMP_DETECTED_LYAN_MENU_SECURITY_', 100000)) end\n";
layer1 += "    end\n";
layer1 += "end\n";
layer1 += "pcall(prevent_spy)\n";

layer1 += "local " + v_key + " = '" + key1 + "'\n";
layer1 += "local " + v_enc + " = {" + enc1.join(",") + "}\n";
layer1 += "local " + v_res + " = {}\n";
layer1 += "local " + v_chr + " = string.char\n";
layer1 += "local " + v_xor + " = bit32 and bit32.bxor or bit and bit.bxor\n";
layer1 += "if not " + v_xor + " then\n";
layer1 += "    " + v_xor + " = function(a,b)\n";
layer1 += "        local p,c=1,0\n";
layer1 += "        while a>0 or b>0 do\n";
layer1 += "            local ra,rb=a%2,b%2\n";
layer1 += "            if ra~=rb then c=c+p end\n";
layer1 += "            a,b,p=(a-ra)/2,(b-rb)/2,p*2\n";
layer1 += "        end\n";
layer1 += "        return c\n";
layer1 += "    end\n";
layer1 += "end\n";

layer1 += "for " + v_idx + " = 1, #" + v_enc + " do\n";
layer1 += "    local b = " + v_enc + "[" + v_idx + "] - 15\n";
layer1 += "    local k = string.byte(" + v_key + ", ((" + v_idx + " - 1) % #" + v_key + ") + 1)\n";
layer1 += "    " + v_res + "[" + v_idx + "] = " + v_chr + "(" + v_xor + "(b, k))\n";
layer1 += "end\n";

layer1 += "(function(...)\n";
layer1 += "    local orig_print = print\n";
layer1 += "    print = function() end\n";
layer1 += "    local exe = " + v_ls + "(table.concat(...))\n";
layer1 += "    for i=1, #... do (...)[i] = '' end\n";
layer1 += "    print = orig_print\n";
layer1 += "    if type(exe) == 'function' then exe() end\n";
layer1 += "end)(" + v_res + ")\n";

let enc2 = [];
for(let i=0; i<layer1.length; i++) {
    enc2.push(layer1.charCodeAt(i) + 7);
}

let v_t2 = R(14), v_i2 = R(11), v_r2 = R(12);
let final_code = "-- LyanMenu v6.0 | Protected by LyanCipher V2 (Anti-Dump/Anti-Spy)\n";
final_code += "local " + v_t2 + " = {" + enc2.join(",") + "}\n";
final_code += "local " + v_r2 + " = {}\n";
final_code += "for " + v_i2 + " = 1, #" + v_t2 + " do " + v_r2 + "[" + v_i2 + "] = string.char(" + v_t2 + "[" + v_i2 + "] - 7) end\n";
final_code += "local _e = loadstring or load\n";
final_code += "_e(table.concat(" + v_r2 + "))()\n";

fs.writeFileSync('LyanMenu.lua', final_code);
