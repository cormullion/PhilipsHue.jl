# PhilipsHue

A few simple functions to control Philips Hue light bulbs from Julia.

## Usage

If you know your Philips Hue bridge's IP address and existing username:
 
     using PhilipsHue
     B = PhilipsHueBridge("192.168.1.111", "yourusername")

But if you don't, try initializing it:

    using PhilipsHue
    B = PhilipsHueBridge("", "")
    initialize(B, devicetype="test developer", username="yourusername")

where "yourusername" must be at least 10 characters long. You'll have to run to the bridge and hit the button (or perhaps you can hit the button then try to initialize within 10 seconds, I haven't tried that):

    Trying to get the IP address of the Philips bridge...
    Trying to register test developer and yourusername to the bridge at 192.168.1.111...
    Quick, you have ten seconds to press the button on the bridge!
    successfully added test developer and yourusername to the bridge at 192.168.1.111
    Registration successful
    true

B now represents your bridge, and most of the functions require this as the first argument.

## Setting light parameters
    
To set the parameters of a light, pass a dictionary with one or more key/value pairs to one of the `set_` functions. Typically this dict is something like this: 

	{"on" => true, "sat" => 123, "bri" => 123, "hue" => 123}
	
where "sat" and "bri" are saturation and brightness from 0 to 255, and "hue" is from 0 to 65280 (?), where 0 is red, yellow is 12750, green is 25500, blue is 46920, etc. If keys are omitted, that aspect of the light won't be changed. Keys are strings, values can be numeric and will get converted to strings.

    set_light(B, 1, {"on" => false}
    set_light(B, 1, {"on" => true, "hue" => 10000}
    set_light_group(B, {"sat" => 255, "bri" => 255, "hue" => 20000, "on" => true})
    set_light_group(B, {"sat" => 25,  "on" => true})

### Other functions

    test_all_lights(B)
    
does a few quick flashes.

Get the bridge's IP address:

    getIP()

Get the main bridge configuration:

    get_bridge_config(B)

For example:

    julia> get_bridge_config(B)["apiversion"]
    
    returns "1.3.0"
    
Get information for all lights:

    get_all_lights(B)
    
For example:

    julia> get_all_lights(B)
    Dict{String,Any} with 3 entries:
      "1" => ["name"=>"Hue Lamp","swversion"=>"66010820","pointsymbol"=>["8"=>"none","4"=>"none","1"=>"none","5"=>"none",…
      "2" => ["name"=>"Hue Lamp 1","swversion"=>"66010820","pointsymbol"=>["8"=>"none","4"=>"none","1"=>"none","5"=>"none…
      "3" => ["name"=>"Hue Lamp 2","swversion"=>"66010820","pointsymbol"=>["8"=>"none","4"=>"none","1"=>"none","5"=>"none…


Get information for one light:

    get_light(B, 2)

For example:
    
    julia> get_light(B, 2)
    
    returns (true,25,254,15000) - O, Saturation, Brightness, Hue

## Problems, issues

In practice, the only problem at the moment is that Julia (version 0.3) takes a few seconds to load Requests.jl and JSON.jl... :)