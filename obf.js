const fs = require('fs');

let source = fs.readFileSync('Aimbot_Pronto_Final.lua', 'utf8');

// Minify & Strip Comments
source = source.replace(/--\[\[[\s\S]*?\]\]/g, '');
source = source.replace(/--[^\n]*\n/g, '\n');

// Generator for misleading variable names (e.g. O0IlIlI0)
function R(len) {
    let chars = "O0Il";
    let s = chars[Math.floor(Math.random()*2)+2]; // start with 'I' or 'l' to be valid Lua variables
    for(let i=1;i<len;i++) s+= chars[Math.floor(Math.random()*chars.length)];
    return s;
}

// LAYER 1: Core Encryption (XOR + Arbitrary Byte Shift)
let key1 = "LYAN_PRIME_" + Math.random().toString(36).substring(2);
let enc1 = [];
for(let i=0; i<source.length; i++) {
    let charCode = source.charCodeAt(i);
    let keyChar = key1.charCodeAt(i % key1.length);
    let shifted = (charCode ^ keyChar) + 42; 
    enc1.push(shifted);
}

// Variable Mapping for Layer 1
let v_env = R(14), v_load = R(12), v_key = R(15), v_enc = R(16), v_res = R(11), v_chr = R(10), v_xor = R(13), v_idx = R(10);
let v_pcall = R(12), v_safe = R(10), v_crash = R(14), v_strrep = R(15), v_origp = R(13), v_exe = R(11);

let layer1 = "";
layer1 += "local " + v_env + " = getfenv or function() return _ENV end\n";
layer1 += "local " + v_load + " = " + v_env + "().loadstring or " + v_env + "().load\n";
layer1 += "local " + v_pcall + " = " + v_env + "().pcall\n";
layer1 += "local " + v_chr + " = " + v_env + "().string.char\n";
layer1 += "local " + v_strrep + " = " + v_env + "().string.rep\n";
layer1 += "local " + v_xor + " = " + v_env + "().bit32 and " + v_env + "().bit32.bxor or " + v_env + "().bit and " + v_env + "().bit.bxor\n";

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

layer1 += "local function " + v_safe + "()\n";
layer1 += "    local s = true\n";
layer1 += "    if " + v_env + "().iscclosure and not " + v_env + "().iscclosure(" + v_load + ") then s = false end\n";
layer1 += "    if " + v_env + "().ishooked and " + v_env + "().ishooked(" + v_load + ") then s = false end\n";
layer1 += "    if " + v_env + "().debug and " + v_env + "().debug.getinfo then\n";
layer1 += "        local i = " + v_env + "().debug.getinfo(" + v_load + ")\n";
layer1 += "        if i and i.what ~= 'C' then s = false end\n";
layer1 += "    end\n";
layer1 += "    if not s then\n";
layer1 += "        local " + v_crash + " = {}\n";
layer1 += "        while true do table.insert(" + v_crash + ", " + v_strrep + "('LYAN_CRASH', 99999)) end\n";
layer1 += "    end\n";
layer1 += "end\n";
layer1 += v_pcall + "(" + v_safe + ")\n";

layer1 += "local " + v_key + " = '" + key1 + "'\n";
layer1 += "local " + v_enc + " = {" + enc1.join(",") + "}\n";
layer1 += "local " + v_res + " = {}\n";

layer1 += "for " + v_idx + " = 1, #" + v_enc + " do\n";
layer1 += "    local b = " + v_enc + "[" + v_idx + "] - 42\n";
layer1 += "    local k = " + v_env + "().string.byte(" + v_key + ", ((" + v_idx + " - 1) % #" + v_key + ") + 1)\n";
layer1 += "    " + v_res + "[" + v_idx + "] = " + v_chr + "(" + v_xor + "(b, k))\n";
layer1 += "end\n";

layer1 += "(function(...)\n";
layer1 += "    local " + v_origp + " = " + v_env + "().print\n";
layer1 += "    " + v_env + "().print = function() end\n";
layer1 += "    local " + v_exe + " = " + v_load + "(" + v_env + "().table.concat(...))\n";
layer1 += "    for i=1, #... do (...)[i] = '' end\n";
layer1 += "    " + v_env + "().print = " + v_origp + "\n";
layer1 += "    if type(" + v_exe + ") == 'function' then " + v_exe + "() end\n";
layer1 += "end)(" + v_res + ")\n";

// LAYER 2: Dynamic Byte Shifting Arrays
let enc2 = [];
let shiftMap = [];
for(let i=0; i<layer1.length; i++) {
    let shift = Math.floor(Math.random() * 20) + 1;
    enc2.push(layer1.charCodeAt(i) + shift);
    shiftMap.push(shift);
}

let v_t2 = R(16), v_s2 = R(15), v_r2 = R(14), v_i2 = R(13), v_f2 = R(12);

let layer2 = "";
layer2 += "local " + v_t2 + " = {" + enc2.join(",") + "}\n";
layer2 += "local " + v_s2 + " = {" + shiftMap.join(",") + "}\n";
layer2 += "local " + v_r2 + " = {}\n";
layer2 += "for " + v_i2 + " = 1, #" + v_t2 + " do\n";
layer2 += "    " + v_r2 + "[" + v_i2 + "] = string.char(" + v_t2 + "[" + v_i2 + "] - " + v_s2 + "[" + v_i2 + "])\n";
layer2 += "end\n";
layer2 += "local " + v_f2 + " = loadstring or load\n";
layer2 += v_f2 + "(table.concat(" + v_r2 + "))()\n";

// LAYER 3: Junk Code Injection & Control Flow Confusion
let lines = layer2.split('\n');
let layer3 = "";
for(let i=0; i<lines.length; i++) {
    layer3 += lines[i] + '\n';
    if (lines[i].trim() !== "" && Math.random() > 0.5) {
        let junkVar = R(10);
        let op = Math.floor(Math.random() * 3);
        if (op === 0) layer3 += "local " + junkVar + " = " + Math.floor(Math.random()*1000) + " + " + Math.floor(Math.random()*1000) + "\n";
        else if (op === 1) layer3 += "local " + junkVar + " = '" + R(8) + "'\n";
        else layer3 += "local " + junkVar + " = function() return " + Math.floor(Math.random()*1000) + " end\n";
    }
}

// LAYER 4: Polymorphic Base64 Wrap
let b64 = Buffer.from(layer3, 'utf8').toString('base64');
let v_b64 = R(14), v_dec = R(15), v_d = R(10), v_b = R(10), v_x = R(10);

let final_code = "-- LyanMenu v6.0 | MAXIMUM SECURITY (LyanCipher V3 + Polymorphic Enc)\n";
final_code += "local " + v_b64 + " = '" + b64 + "'\n";
final_code += "local function " + v_dec + "(" + v_d + ")\n";
final_code += "    local " + v_b + "='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'\n";
final_code += "    " + v_d + "=string.gsub(" + v_d + ",'[^'.." + v_b + "..'=]','')\n";
final_code += "    return (" + v_d + ":gsub('.', function(" + v_x + ")\n";
final_code += "        if " + v_x + " == '=' then return '' end\n";
final_code += "        local r,f='',(" + v_b + ":find(" + v_x + ")-1)\n";
final_code += "        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end\n";
final_code += "        return r;\n";
final_code += "    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(" + v_x + ")\n";
final_code += "        if (#" + v_x + " ~= 8) then return '' end\n";
final_code += "        local c=0\n";
final_code += "        for i=1,8 do c=c+(" + v_x + ":sub(i,i)=='1' and 2^(8-i) or 0) end\n";
final_code += "        return string.char(c)\n";
final_code += "    end))\n";
final_code += "end\n";
final_code += "local _e = loadstring or load\n";
final_code += "_e(" + v_dec + "(" + v_b64 + "))()\n";

fs.writeFileSync('LyanMenu.lua', final_code);
