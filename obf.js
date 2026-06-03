const fs = require('fs');
let source = fs.readFileSync('Aimbot_Pronto_Final.lua', 'utf8');

source = source.replace(/--\[\[[\s\S]*?\]\]/g, '');
source = source.replace(/--[^\n]*\n/g, '\n');

let key = "LYAN_MENU_V6_SECURE_KEY_2026_" + Math.random().toString(36).substring(2);
let enc = [];
for(let i=0; i<source.length; i++) {
    enc.push((source.charCodeAt(i) ^ key.charCodeAt(i % key.length)) + 5);
}

function R() {
    let chars = "Il";
    let len = Math.floor(Math.random() * 10) + 10;
    let s = "";
    for(let i=0;i<len;i++) s+= chars[Math.floor(Math.random()*2)];
    return s;
}

let v_key = R(), v_enc = R(), v_res = R(), v_idx = R(), v_chr = R(), v_bxor = R(), v_load = R(), v_env = R();

let loader = "-- LyanMenu v6.0 Premium | Protected by Custom LyanCipher\n";
loader += "local " + v_env + " = getfenv or function() return _ENV end\n";
loader += "local " + v_load + " = " + v_env + "().loadstring or " + v_env + "().load\n";
loader += "if not " + v_load + " then return end\n\n";

loader += "local " + v_key + " = '" + key + "'\n";
loader += "local " + v_enc + " = {" + enc.join(",") + "}\n";
loader += "local " + v_res + " = {}\n";
loader += "local " + v_chr + " = string.char\n";
loader += "local " + v_bxor + " = bit32 and bit32.bxor or bit and bit.bxor\n\n";

loader += "if not " + v_bxor + " then\n";
loader += "    " + v_bxor + " = function(a,b)\n";
loader += "        local p,c=1,0\n";
loader += "        while a>0 or b>0 do\n";
loader += "            local ra,rb=a%2,b%2\n";
loader += "            if ra~=rb then c=c+p end\n";
loader += "            a,b,p=(a-ra)/2,(b-rb)/2,p*2\n";
loader += "        end\n";
loader += "        return c\n";
loader += "    end\n";
loader += "end\n\n";

loader += "for " + v_idx + " = 1, #" + v_enc + " do\n";
loader += "    local b = " + v_enc + "[" + v_idx + "] - 5\n";
loader += "    local k = string.byte(" + v_key + ", ((" + v_idx + " - 1) % #" + v_key + ") + 1)\n";
loader += "    " + v_res + "[" + v_idx + "] = " + v_chr + "(" + v_bxor + "(b, k))\n";
loader += "end\n\n";

loader += "local _x = table.concat(" + v_res + ")\n";
loader += "for i=1, #" + v_res + " do " + v_res + "[i] = '' end\n";
loader += v_res + " = nil\n";
loader += v_enc + " = nil\n";
loader += v_key + " = nil\n\n";

let f_var = R();
loader += "local " + f_var + " = " + v_load + "(_x)\n";
loader += "if " + f_var + " then " + f_var + "() end\n";
loader += "_x = ''\n";

fs.writeFileSync('LyanMenu.lua', loader);
