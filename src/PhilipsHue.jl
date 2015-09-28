VERSION >= v"0.4.0-dev+6641" && __precompile__()

module PhilipsHue

using JSON, Requests, Colors

import Requests: get, post, put, delete, options, bytes, text, json

export  PhilipsHueBridge, getIP, getbridgeconfig, isinitialized,
        getlights, getlight, setlight, setlights,
        testlights, register, initialize

type PhilipsHueBridge
    ip::String
    username:: String
    function PhilipsHueBridge(ip, username)
        fields = split(ip,'.')
        if length(fields) != 4
            throw(ArgumentError("IP address must have exactly four components."))
        end
        for f in fields
            fint = parse(Int, f)
            if fint < 0 || fint > 255
                throw(ArgumentError("IP address components must be between 0 and 255."))
            end
        end
        new(ip, username)
    end
end

"""
Initialize a bridge, supplying devicetype and username. Registering this script with the bridge
may require you to run to the bridge and press the button.

Returns true or false.

For example:

    B = PhilipsHueBridge("192.168.1.90", "yourusername")
    initialize(bridge::PhilipsHueBridge; devicetype="juliascript", username="juliauser1")
"""

function initialize(bridge::PhilipsHueBridge; devicetype="juliascript", username="juliauser1")
    println("initialize(): Trying to get the IP address of the Philips bridge.")
    ipaddress = getIP()
    bridge.ip = ipaddress
    println("initialize(): Found bridge at $(bridge.ip).")
    println("initialize(): Trying to register $devicetype with the bridge at $(bridge.ip)...")
    username = register(bridge.ip, devicetype=devicetype, username=username)
    if ! isempty(username)
        println("initialize(): Registration successful")
        bridge.username = username
        return true
    else
        warn("initialize(): Registration failed")
        return false
    end
end

"""
Return true if the bridge has been initialized, and there is a connection to the portal.

    isinitialized(bridge::PhilipsHueBridge)
"""

function isinitialized(bridge::PhilipsHueBridge)
    if get(getbridgeconfig(bridge), "portalconnection", "not connected") == "connected"
        return true
    else
        return false
    end
end

"""
Read the bridge's IP settings from the [meethue.com]("https://www.meethue.com/api/nupnp") website.

    getIP()
"""

function getIP()
    response = get("https://www.meethue.com/api/nupnp")
    # this url sometimes redirects, we should follow...
    if response.status == 302
        println("trying curl instead, in case of redirects")
        bridgeinfo = JSON.parse(readall(`curl -sL http://www.meethue.com/api/nupnp`))
    else
        bridgeinfo = JSON.parse(Requests.text(response))
    end
    return bridgeinfo[1]["internalipaddress"]
end

"""
Read the current bridge configuration. For example:

    B = PhilipsHueBridge("192.168.1.90", "yourusername")
    getbridgeconfig(B)
"""

function getbridgeconfig(bridge::PhilipsHueBridge)
    response = get("http://$(bridge.ip)/api/$(bridge.username)/config")
	return JSON.parse(Requests.text(response))
end


"""
Return the current setting of all lights connected to the bridge.

    getlights(bridge::PhilipsHueBridge)
"""

function getlights(bridge::PhilipsHueBridge)
    response = get("http://$(bridge.ip)/api/$(bridge.username)/lights")
 	return JSON.parse(Requests.text(response))
end

"""
Return the settings of the specified light.

    getlight(bridge::PhilipsHueBridge, light=1)
"""

function getlight(bridge::PhilipsHueBridge, light=1)
    response = get("http://$(bridge.ip)/api/$(bridge.username)/lights/$(string(light))")
    responsedata = JSON.parse(Requests.text(response))

    println("data for light $light: $responsedata")

    # not all Hue lights have sat/hue, some are the uncolored version

    if responsedata["type"] == "Dimmable light"
        return (
        responsedata["state"]["on"],
        responsedata["state"]["bri"])
    elseif responsedata["type"] == "Extended color light"
        return (
        responsedata["state"]["on"],
        responsedata["state"]["sat"],
        responsedata["state"]["bri"],
        responsedata["state"]["hue"])
    end
end

"""
Set a light by passing a dictionary of settings.

eg Dict{Any,Any}("on" => true, "sat" => 123, "bri" => 123, "hue" => 123),
"hue" is from 0 to 65280 (?), "sat" and "bri" are saturation and brightness from 0 to 255,
0 is red, yellow is 12750, green is 25500, blue is 46920, etc.

If keys are omitted, that aspect of the light won't be changed.

Keys are strings, values can be numeric and will get converted to strings

    setlight(B, 1, Dict("on" => true))
    setlight(B, 3, Dict("on" => false))
    setlight(B, 2, Dict("on" => true, "sat" => 123, "bri" => 243, "hue" => 123)

"""

function setlight(bridge::PhilipsHueBridge, light::Int, settings::Dict)
    state = AbstractString[]
    for (k, v) in settings
        push!(state, ("\"$k\": $(string(v))"))
    end
    state = "{" * join(state, ",") * "}"
    response = put("http://$(bridge.ip)/api/$(bridge.username)/lights/$(string(light))/state", data="$(state)")
    return JSON.parse(Requests.text(response))
end

"""
Set color of a light using Colors.jl style colors.

setlight(bridge::PhilipsHueBridge, light::Int, col::ColorTypes.Colorant)

   setlight(B, 1, Colors.RGB(0.75, 0.25, 0.75))
   setlight(B, 1, colorant"Pink")

"""

function setlight(bridge::PhilipsHueBridge, light::Int, col::Color)
    c = convert(Colors.HSV, col)
    h, s, v = round(Int, (c.h / 360) * 65535), round(Int, c.s * 255), round(Int, c.v * 255)
    setlight(bridge, light, Dict("on" => true, "sat" => s, "bri" => v, "hue" => h))
end

"""

Set all lights in a group by passing a dictionary of settings.

eg Dict{Any,Any}("on" => true, "sat" => 123, "bri" => 123, "hue" => 123),
"hue" is from 0 to 65280 (?), "sat" and "bri" are saturation and brightness from 0 to 255,
0 is red, yellow is 12750, green is 25500, blue is 46920, etc.

If keys are omitted, that aspect of the light won't be changed.

Keys are strings, values can be numeric and will get converted to strings

    setlights(B, Dict("on" => true))
    setlights(B, Dict("on" => false))
    setlights(B, Dict("on" => true, "sat" => 123, "bri" => 243, "hue" => 123)

"""

function setlights(bridge::PhilipsHueBridge, settings::Dict)
    state = AbstractString[]
    for (k, v) in settings
        push!(state,("\"$k\": $(string(v))"))
    end
    state = "{" * join(state, ",") * "}"
    response = put("http://$(bridge.ip)/api/$(bridge.username)/groups/0/action", data="$(state)")
    return JSON.parse(Requests.text(response))
end

"""

Register the devicetype and username with the bridge.

    Quoth Philips: If the username is not provided, a random key will be
        generated and returned in the response. Important! The
        username will soon be deprecated in the bridge. It is
        strongly recommended not to use this and use the randomly
        generated bridge username.

    So we'll return the randomly generated key, or "" on failure

"""

function register(bridge_ip; devicetype="juliascript", username="juliauser1")
    response     = post("http://$(bridge_ip)/api/"; data="{\"devicetype\":\"$(devicetype)#$(username)\"}")
    responsedata = JSON.parse(Requests.text(response))
    # responsedata is probably:
    # 1-element Array{Any,1}:
    # ["error"=>["type"=>101,"description"=>"link button not pressed","address"=>"/"]]
    if responsedata[1][first(keys(responsedata[1]))]["description"] == "link button not pressed"
        println("register(): Quick, you have ten seconds to press the button on the bridge!")
        sleep(10)
        response = post("http://$(bridge_ip)/api/"; data="{\"devicetype\":\"$(devicetype)#$(username)\"}")
        responsedata = JSON.parse(Requests.text(response))
        if first(keys(responsedata[1])) == "success"
            println("register(): Successfully registered $devicetype and $username with the bridge at $bridge_ip")
            # returns username which is randomly generated key
            username = responsedata[1]["success"]["username"]
            return username
        else
            warn("register(): Failed to register $devicetype#$username with the bridge at $bridge_ip")
            return ""
        end
    end
end


"""
Test all lights.

    testlights(bridge::PhilipsHueBridge, total=5)
"""

function testlights(bridge::PhilipsHueBridge, total=5)
    for i in 1:total
        setlights(bridge, Dict("on" => false))
        sleep(1)
        setlights(bridge, Dict("on" => true))
        sleep(1)
    end
    setlights(bridge, Dict("hue" => 10000, "sat" => 64, "bri" => 255))
end

end # module
