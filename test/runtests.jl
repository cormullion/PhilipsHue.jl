using PhilipsHue

println("loaded PhilipsHue")

# these will have to be set to valid values before you run the test

B = PhilipsHueBridge("192.168.1.3"      , "KbZxj8G5nBDsDYgqOmHicytLC-aTALLSEaJNruVB")

lightnumbers = getlightnumbers(B)

firstlight = first(lightnumbers)

println("Bridge config: \n\t"             , getbridgeconfig(B))
println("Bridge IP: \n\t"                 , getIP())
println("Bridge initialized?: \n\t"       , isinitialized(B))
println("Light config: \n\t"              , getlights(B))
println("Get light config: \n\t"          , getlight(B, firstlight))
println("Get light config: \n\t"          , getlight(B, 4))


println("Set first light on: \n\t"        , setlight(B, firstlight, Dict("on" => true)))
println("Set first light off: \n\t"       , setlight(B, firstlight, Dict("on" => false)))
println("Set first light  \n\t"          , setlight(B, firstlight, Dict("on" => true, "sat" => 123, "bri" => 243, "hue" => 123)))

# random all lights
for i in 0:20
    setlights(B, Dict("bri" => rand(0:255), "hue" => rand(1:65000), "sat" => rand(1:255)))
    sleep(0.5)
end

# for a random light, set RGB color

# THanks, @ScottPJones!
for r in 0:0.25:1, g in 0:0.25:1, b in 0:0.25:1
    setlight(B, lightnumbers[rand(1:end)], Colors.RGB(r, g, b))
    sleep(.25)
end

setlights(B, Dict("bri" => 255))
