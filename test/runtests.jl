using PhilipsHue

println("loaded PhilipsHue")

# these will have to be set to valid values before you run the test

B = PhilipsHueBridge("192.168.1.86"    , "juliauser1")
println("Bridge config: \t"             , getbridgeconfig(B))

println("Bridge IP: \t"                 , getIP())
println("Bridge initialized?: \t"       , isinitialized(B))
println("Light config: \t"              , getlights(B))
println("Get light config: \t"          , getlight(B))
println("Get light config: \t"          , getlight(B, 4))
println("Set light 1 on: \t"            , setlight(B, 1, Dict("on" => true)))
println("Set light 1 off: \t"           , setlight(B, 1, Dict("on" => false)))
println("Set light 1 \t"                , setlight(B, 1, Dict("on" => true, "sat" => 123, "bri" => 243, "hue" => 123)))

# random all lights
for i in 0:20
    setlights(B, Dict("bri" => rand(0:255), "hue" => rand(1:65000), "sat" => rand(1:255)))
    sleep(0.5)
end

# one light, set RGB color

for r in 0:0.25:1
    for g in 0:0.25:1
        for b in 0:0.25:1
           setlight(B, 1, Colors.RGB(r, g, g))
           sleep(1)
       end
    end
end

setlights(B, Dict("bri" => 255))
