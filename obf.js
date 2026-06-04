const fs = require('fs');

let source = fs.readFileSync('Aimbot_Pronto_Final.lua', 'utf8');
source = source.replace(/^\uFEFF/, ''); // STRIP BOM!

source = source.replace(/--\[\[[\s\S]*?\]\]/g, '');
source = source.replace(/--[^\n]*\n/g, '\n');

function R(len) {
    let chars = "O0Il";
    let s = chars[Math.floor(Math.random()*2)+2]; 
    for(let i=1;i<len;i++) s+= chars[Math.floor(Math.random()*chars.length)];
    return s;
}

let key = "LYAN_PRIME_" + Math.random().toString(36).substring(2);
let enc = [];
for(let i=0; i<source.length; i++) {
    enc.push((source.charCodeAt(i) ^ key.charCodeAt(i % key.length)));
}

let b64 = Buffer.from(enc).toString('base64');

let v_b64 = R(14), v_dec = R(15), v_d = R(10), v_b = R(10), v_x = R(10);
let v_key = R(12), v_idx = R(11), v_xor = R(13), v_res = R(14), v_char = R(10), v_load = R(10);

let final_code = "-- LyanMenu v6.0 | LyanCipher V4 (Optimized for Solara/Mobile)\n";

for(let i=0;i<5;i++) {
    final_code += "local " + R(10) + " = " + Math.floor(Math.random() * 1000) + "\n";
}

final_code += "local " + v_b64 + " = '" + b64 + "'\n";
final_code += "local " + v_key + " = '" + key + "'\n";

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

final_code += "local " + v_xor + " = bit32 and bit32.bxor or bit and bit.bxor\n";
final_code += "if not " + v_xor + " then\n";
final_code += "    " + v_xor + " = function(a,b)\n";
final_code += "        local p,c=1,0\n";
final_code += "        while a>0 or b>0 do\n";
final_code += "            local ra,rb=a%2,b%2\n";
final_code += "            if ra~=rb then c=c+p end\n";
final_code += "            a,b,p=(a-ra)/2,(b-rb)/2,p*2\n";
final_code += "        end\n";
final_code += "        return c\n";
final_code += "    end\n";
final_code += "end\n";

final_code += "local " + v_res + " = {}\n";
final_code += "local " + v_char + " = string.char\n";
final_code += "local decoded_str = " + v_dec + "(" + v_b64 + ")\n";
final_code += "for " + v_idx + " = 1, #decoded_str do\n";
final_code += "    local b = string.byte(decoded_str, " + v_idx + ")\n";
final_code += "    local k = string.byte(" + v_key + ", ((" + v_idx + " - 1) % #" + v_key + ") + 1)\n";
final_code += "    " + v_res + "[" + v_idx + "] = " + v_char + "(" + v_xor + "(b, k))\n";
final_code += "end\n";

final_code += "local " + v_load + " = loadstring or load\n";
final_code += "local exec = " + v_load + "(table.concat(" + v_res + "))\n";

final_code += "for i=1, #" + v_res + " do " + v_res + "[i] = '' end\n";
final_code += "decoded_str = ''\n"; 

final_code += "if type(exec) == 'function' then exec() end\n";

fs.writeFileSync('LyanMenu.lua', final_code);
