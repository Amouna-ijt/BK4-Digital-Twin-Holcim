function [cmd_marche, cmd_defaut, cmd_vib, gain_charge] = recevoir_commandes()

persistent u1 u3 u4 u5 init val1 val3 val4 val5

if isempty(init)
    u1 = udpport("datagram","IPV4","LocalPort",30001,"Timeout",0.001);
    u3 = udpport("datagram","IPV4","LocalPort",30003,"Timeout",0.001);
    u4 = udpport("datagram","IPV4","LocalPort",30004,"Timeout",0.001);
    u5 = udpport("datagram","IPV4","LocalPort",30005,"Timeout",0.001);
    val1 = 1.0;
    val3 = 0.0;
    val4 = 0.0;
    val5 = 40.0;
    init = true;
end

if u1.NumDatagramsAvailable > 0
    data = read(u1, u1.NumDatagramsAvailable, "string");
    v = str2double(strtrim(data(end).Data));
    if ~isnan(v); val1 = v; end
end

if u3.NumDatagramsAvailable > 0
    data = read(u3, u3.NumDatagramsAvailable, "string");
    v = str2double(strtrim(data(end).Data));
    if ~isnan(v); val3 = v; end
end

if u4.NumDatagramsAvailable > 0
    data = read(u4, u4.NumDatagramsAvailable, "string");
    v = str2double(strtrim(data(end).Data));
    if ~isnan(v); val4 = v; end
end

if u5.NumDatagramsAvailable > 0
    data = read(u5, u5.NumDatagramsAvailable, "string");
    v = str2double(strtrim(data(end).Data));
    if ~isnan(v); val5 = v; end
end

cmd_marche  = val1;
cmd_defaut  = val3;
cmd_vib     = val4;
gain_charge = val5;
end
