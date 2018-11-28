sensor_pin = 0;
local ssid="universe"
local key="::konskykokot::"

wifi.setmode(wifi.STATION)
wifi.setphymode(wifi.PHYMODE_G)
wifi.sta.config{ssid=ssid,pwd=key}
wifi.sta.connect()
tmr.alarm(1, 1000, 1, function() 
    if wifi.sta.getip() == nil then 
        print("IP unavaiable, Waiting...") 
    else 
        tmr.stop(1)
        print("Config done, IP is "..wifi.sta.getip())
    end 
end)

function read_soil_humidity()
  moisture_percentage = ( 100.00 - ( (adc.read(sensor_pin)/1023.00)) )
  print(string.format("Soil Moisture(in Percentage) = %0.4g",moisture_percentage),"%")
end

function post_things_speak(level)
    http.get("http://api.thingspeak.com/update?api_key=Y7FRLRDMC7NZKW03" 
    .. "&field1=" .. moisture_percentage, nil, function(code, data)
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
    read_soil_humidity()
    post_things_speak(0)
end)

tmr.start(mytimer)
