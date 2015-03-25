module PhilipsHue

export  PhilipsHueBridge, getIP, get_bridge_config, isinitialized,
        get_all_lights, get_light, set_light, set_light_group, test_all_lights,
        register, initialize

using JSON, Requests

type PhilipsHueBridge
  ip::String
  username:: String
  function PhilipsHueBridge(ip, username)
    new(ip, username)
  end
end

#@doc doc"""
#    Read the bridge's settings from the [meethue.com]("https://www.meethue.com/api/nupnp")
#  """ ->
function getIP()
	response = get("https://www.meethue.com/api/nupnp")
    # this url sometimes redirects, we should follow...
	if response.status == 302
	    println("trying curl instead, in case of redirects")
        bridgeinfo = JSON.parse(readall(`curl -sL http://www.meethue.com/api/nupnp`))
	else
	    bridgeinfo = JSON.parse(response.data)
	end
	return bridgeinfo[1]["internalipaddress"]
end

function get_bridge_config(bridge::PhilipsHueBridge)
  response = get("http://$(bridge.ip)/api/$(bridge.username)/config")
	return JSON.parse(response.data)
end

function isinitialized(bridge::PhilipsHueBridge)
	if get(get_bridge_config(bridge), "portalconnection", "not connected") == "connected"
	  return true
	else
	  return false
	end
end

function get_all_lights(bridge::PhilipsHueBridge)
    response = get("http://$(bridge.ip)/api/$(bridge.username)/lights")
 	return JSON.parse(response.data)
end

function get_light(bridge::PhilipsHueBridge, light=1)
    response = get("http://$(bridge.ip)/api/$(bridge.username)/lights/$(string(light))")
 	responsedata = JSON.parse(response.data)
 	# return tuple of some information
    return (
     responsedata["state"]["on"],
     responsedata["state"]["sat"],
     responsedata["state"]["bri"],
     responsedata["state"]["hue"]
  )
end

#=

Set a light by passing a dict of settings. 
Typically this dict is eg {"on" => true, "sat" => 123, "bri" => 123, "hue" => 123}, 
and "hue" is from 0 to 65280 (?) where 
where "sat" and "bri" are saturation and brightness from 0 to 255, 
0 is red, yellow is 12750, green is 25500, blue is 46920, etc.

If keys are omitted, that aspect of the light won't be changed.

Keys are strings, values can be numeric and will get converted to strings

=#

function set_light(bridge::PhilipsHueBridge, light::Int, settings::Dict)
  state = {}
  for (k, v) in settings
     push!(state,("\"$k\": $(string(v))"))
  end
  state = "{" * join(state, ",") * "}"
  response = put("http://$(bridge.ip)/api/$(bridge.username)/lights/$(string(light))/state", data="$(state)") 
  return JSON.parse(response.data)
end

#=

set all lights, the same as sending the same set_light settings to each light 

=# 

function set_light_group(bridge::PhilipsHueBridge, settings::Dict)
    state = {}
    for (k, v) in settings
        push!(state,("\"$k\": $(string(v))"))
    end
    state = "{" * join(state, ",") * "}"
    response = put("http://$(bridge.ip)/api/$(bridge.username)/groups/0/action", data="$(state)") 
    return JSON.parse(response.data)
end

function register(bridge_ip; devicetype="juliascript", username="juliauser1")
  response   = post("http://$(bridge_ip)/api/"; data="{\"devicetype\":\"$(devicetype)\",\"username\":\"$(username)\"}")
  responsedata = JSON.parse(response.data)
  # responsedata is probably:
  # 1-element Array{Any,1}:
  #   ["error"=>["type"=>101,"description"=>"link button not pressed","address"=>"/"]]
  if responsedata[1][first(keys(responsedata[1]))]["description"] == "link button not pressed"
    println("register(): Quick, you have ten seconds to press the button on the bridge!")
    sleep(10)
    response = post("http://$(bridge_ip)/api/"; data="{\"devicetype\":\"$(devicetype)\",\"username\":\"$(username)\"}")
    responsedata = JSON.parse(response.data)
    if first(keys(responsedata[1])) == "success"
        println("register(): Successfully registered $devicetype and $username in the bridge at $bridge_ip")
        return true
    else
        println("register(): Failed to register $devicetype and $username in the bridge at $bridge_ip")
        return false
    end
  end
end 

function test_all_lights(bridge::PhilipsHueBridge, total=5)
    for i in 1:total
        set_light_group(bridge, {"on" => false})
        sleep(1)
        set_light_group(bridge, {"on" => true})
        sleep(1)
    end
    set_light_group(bridge, {"hue" => 10000, "sat" => 64, "bri" => 255})
end

function initialize(bridge::PhilipsHueBridge; devicetype="juliascript", username="juliauser1") 
    println("initialize(): Trying to get the IP address of the Philips bridge.")
    ipaddress = getIP()
    bridge.ip = ipaddress
    println("initialize(): Found bridge at $(bridge.ip).") 
    println("initialize(): Trying to register $devicetype and $username to the bridge at $(bridge.ip)...")
    status = register(bridge.ip, devicetype=devicetype, username=username)
    if status
        println("initialize(): Registration successful")
        bridge.username = username
        return true
    else
        println("initialize(): Registration failed")
        return false
    end
end

end # module
