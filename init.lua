sda, scl = 3, 4
i2c.setup(0, sda, scl, i2c.SLOW)
bme280.setup()

local mySsid="universe"
local myKey="::konskykokot::"

wifi.setmode(wifi.STATION)
wifi.setphymode(wifi.PHYMODE_G)
wifi.sta.config{ssid=mySsid,pwd=myKey}
wifi.sta.connect()
tmr.alarm(1, 1000, 1, function() 
    if wifi.sta.getip() == nil then 
        print("IP unavaiable, Waiting...") 
    else 
        tmr.stop(1)
        print("Config done, IP is "..wifi.sta.getip())
    end 
end)

function print_temp()
    alt=320 -- altitude of the measurement place
   
    P, T = bme280.baro()
    print(string.format("QFE=%d.%03d", P/1000, P%1000))

    -- convert measure air pressure to sea level pressure
    QNH = bme280.qfe2qnh(P, alt)
    print(string.format("QNH=%d.%03d", QNH/1000, QNH%1000))

    H, T = bme280.humi()

    local Tsgn = (T < 0 and -1 or 1); T = Tsgn*T
    print(string.format("T=%s%d.%02d", Tsgn<0 and "-" or "", T/100, T%100))
    print(string.format("humidity=%d.%03d%%", H/1000, H%1000))

    D = bme280.dewpoint(H, T)
    local Dsgn = (D < 0 and -1 or 1); D = Dsgn*D
    print(string.format("dew_point=%s%d.%02d", Dsgn<0 and "-" or "", D/100, D%100))

    -- altimeter function - calculate altitude based on current sea level pressure (QNH) and measure pressure
    P = bme280.baro()
    curAlt = bme280.altitude(P, QNH)
    local curAltsgn = (curAlt < 0 and -1 or 1); curAlt = curAltsgn*curAlt
    print(string.format("altitude=%s%d.%02d", curAltsgn<0 and "-" or "", curAlt/100, curAlt%100))
    
end

function post_things_speak(level)
    http.get("http://api.thingspeak.com/update?api_key=CL1D98IXKW6XBLO2" 
    .. "&field1=" .. (T/100) .. "." .. (T%100) 
    .. "&field2=" .. (H/1000) .. "." .. (H%1000) 
    .. "&field3=" .. (P/1000) .. "." .. (P%1000) , nil, function(code, data)
        if (code < 0) then
            print("HTTP request failed")
        else  
            print(code, data)
        end
    end)
end
  
interval=150000
mytimer = tmr.create()
mytimer:register(interval, tmr.ALARM_AUTO, function()
    print_temp()
    post_things_speak(0)
end)

tmr.start(mytimer)
