-- colors.lua
local COLOR = {}
function COLOR.color(c)
    if (c=='red') then return ImVec4(0.9, 0.1, 0.1, 1) end
    if (c=='pink') then return ImVec4(0.9, 0.4, 0.4, 0.8) end
    if (c=='orange') then return ImVec4( 0.78, 0.20, 0.05, 0.8) end
    if (c=='yellow') then return ImVec4(1, 1, 0, 1) end
    if (c=='yellow2') then return ImVec4( 0.7, 0.6, 0.1, 0.7) end
    if (c=='white') then return ImVec4(1, 1, 1, 1) end
    if (c=='blue') then return ImVec4(0, 0, 1, 1) end
    if (c=='softblue') then return ImVec4(0, 0, 1, 0.5) end
    if (c=='light blue2') then return ImVec4(0.2, 0.9, 0.9, 0.5) end
    if (c=='light blue') then return ImVec4(0, 1, 1, 1) end
    if (c=='green') then return ImVec4(0, 1, 0, 1) end
    if (c=='green2') then return ImVec4(0.01, 0.56, 0.001, 1) end
    if (c=='grey') then return ImVec4(0.6, 0.6, 0.6, 1) end
    if (c=='purple') then return ImVec4(0.8, 0.0, 1.0, 1.0) end
end
return COLOR