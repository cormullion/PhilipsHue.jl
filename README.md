# PhilipsHue

A few simple functions to control Philips Hue light bulbs from Julia.

Uses JSON and Requests packages, and Compat for compatibility between version 0.3 and 0.4.

## Current status

Updated to work with Julia versions 0.4.

## Summary

    B = PhilipsHueBridge("192.168.1.xx", "existingusername")
    getIP()
    getbridgeconfig(B)
    initialize(B; devicetype="juliascript", username="juliauser1")
    isinitialized(B)
    register("192.168.1.xx"; devicetype="juliascript", username="juliauser1")
    getlight(B, 1)
    getlights(B)
    setlight(B, 1, Dict("sat" => 128, "on" => true, "hue" => 20000, "bri" => 200))
    setlights(B, Dict("sat" => 128, "on" => true, "hue" => 20000, "bri" => 200))
    testlights(B, 20)

## Usage

If you already know your Philips Hue bridge's IP address and existing username:

    using PhilipsHue
    B = PhilipsHueBridge("192.168.1.111", "username")

If you don't know the current IP address, try:

	 getIP()

which accesses your current configuration as registered at http://meethue.com.

If you haven't added your username to the bridge, try initializing it:

    using PhilipsHue
    B = PhilipsHueBridge("", "")
    initialize(B, devicetype="test developer", username="username")

You'll have to run to the bridge and hit the button:

    Trying to get the IP address of the Philips bridge...
    Trying to register test developer and yourusername to the bridge at 192.168.1.111...
    Quick, you have ten seconds to press the button on the bridge!
    successfully added test developer and yourusername to the bridge at 192.168.1.111
    Registration successful
    true

``B`` now represents your bridge, and most of the functions require this as the first argument.

Philips are in the process of deprecating usernames, by the way.

To test:

    testlights(B)

does a few quick flashes.

## Setting light parameters

To set the parameters of a light, pass a dictionary with one or more key/value pairs to one of the `set` functions. Typically this dict is something like this:

    Dict{Any,Any}("bri" => rand(0:255), "hue" => rand(1:65000), "sat" => rand(1:255))

where "sat" and "bri" are saturation and brightness from 0 to 255, and "hue" is from 0 to 65280 (?), where 0 is red, yellow is 12750, green is 25500, blue is 46920, etc. If keys are omitted, that aspect of the light won't be changed. Keys are strings, values can be numeric and will get converted to strings.

    setlight(B, 1, Dict("on" => false)
    setlight(B, 1, Dict("on" => true, "hue" => 10000)
    setlights(B, Dict("sat" => 255, "bri" => 255, "hue" => 20000, "on" => true))
    setlights(B, Dict("sat" => 25,  "on" => true))

Note that this syntax is specific to Julia version 0.4. (For version 3, you used the simpler dictionary syntax:

    {"bri" => rand(0:255), "hue" => rand(1:65000), "sat" => rand(1:255)}

### Other functions

Get the bridge's current registered IP address (which can usually be read from `http://meethue.com` using `get("https://www.meethue.com/api/nupnp")`):

    getIP()

Get the current bridge configuration:

    getbridgeconfig(B)

which returns a dictionary with keys such as "timezone", "apiversion", "paddles", "whitelist", and so on. You can obtain specific values:

    getbridgeconfig(B)["apiversion"]

returns

    "1.3.0"

A list of current approved apps and users is stored in the whitelist:

    getbridgeconfig(B)["whitelist"]
    Dict{AbstractString,Any} with 25 entries:
      "lSsXQfrm7rC32SQ0"                 => Dict{AbstractString,Any}("name"=>"fred’s iPhone","last use date"=>"2015-08-27T10:32:24","create date"=>"2013-12-31T14:05:05")
      "352f5a4637d93da7121471aa39dc2db"  => Dict{AbstractString,Any}("name"=>"Harmony","last use date"=>"2014-10-13T04:56:30","create date"=>"2014-09-06T12:15:28")
      "5F062ECE840DB0FE8D468855570D2EB9" => Dict{AbstractString,Any}("name"=>"QuickHue","last use date"=>"2014-01-09T14:47:13","create date"=>"2014-01-01T12:24:36")
      "0f607264fc6318a92b9e13c65db7cd3c" => Dict{AbstractString,Any}("name"=>"fred’s iPad","last use date"=>"2014-01-03T00:13:28","create date"=>"2013-12-31T13:10:36")
      "hue-js-JkRkZIa8Lasd"              => Dict{AbstractString,Any}("name"=>"Philips hue JavaScript","last use date"=>"2015-06-12T13:34:00","create date"=>"2015-06-12T13:26:00")
      "newjuliauser2"                    => Dict{AbstractString,Any}("name"=>"test developer","last use date"=>"2014-09-21T14:30:18","create date"=>"2014-09-21T13:40:11")
      "q3a619KRfwoS6suF"                 => Dict{AbstractString,Any}("name"=>"HueForAppleWatch#fred’s iPhone 6","last use date"=>"2015-08-20T22:47:41","create date"=>"2015-08-20T16:50:32")
      "juliauser1"                       => Dict{AbstractString,Any}("name"=>"juliascript","last use date"=>"2015-08-27T15:06:43","create date"=>"2014-09-21T10:30:53")
	  ...

Get information for all lights:

	   getlights(B)

For example:

    getlights(B)

    Dict{String,Any} with 3 entries:
      "1" => ["name"=>"Hue Lamp","swversion"=>"66010820","pointsymbol"=>["8"=>"none","4"=>"none","1"=>"none","5"=>"none",…
      "2" => ["name"=>"Hue Lamp 1","swversion"=>"66010820","pointsymbol"=>["8"=>"none","4"=>"none","1"=>"none","5"=>"none…
      "3" => ["name"=>"Hue Lamp 2","swversion"=>"66010820","pointsymbol"=>["8"=>"none","4"=>"none","1"=>"none","5"=>"none…

Get information for a specific light:

    getlight(B, 2)

For example:

    getlight(B, 2)

returns (true,25,254,15000) - On, Saturation, Brightness, Hue

## Problems, issues

In practice, the only problem at the moment is that Julia takes a few seconds to load Requests.jl and JSON.jl... :)
