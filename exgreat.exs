defmodule Great do

def sendSidewards(left, right) do
    receive do
        {:left, num} -> 
		send left, {:left, num}
       		IO.puts "sent value ${num} left"
		sendSidewards left, right
        {:right, num} -> 
		send right, {:right, num}
       		IO.puts "sent value ${num} right"
		sendSidewards left, right	
    end
end

def sendSidewards(left) do
    IO.puts "Registering with left process"
    send left, {:rightId, self()}
    IO.puts "Awaiting connection from right process"
    receive do
        {:rightId, id} ->
		   sendSidewards(left, id)
    end
end

def sendAllLeft(left, first) do
    if first do send left, {:rightId, self()} end
    receive do
    	{_, num} ->
		send left, {:left, num}
		IO.puts "sending left"
		sendAllLeft left, :false
    end
end

def makeTrack(left, remaining) do
    if remaining > 0 do
       IO.puts "making track #{remaining}"
       nextLeft = spawn_link(sendSidewards(left))
       IO.puts "made it"
       makeTrack(nextLeft, remaining - 1)	
    else
       IO.puts "making left sender"
       spawn_link sendAllLeft(left, :true)
    end
end

def finishLine(remaining, results, resultChan, name) do
    if remaining > 0 do
       receive do
       	       {_, num} ->
	       	   finishLine(remaining-1, [num|results], resultChan, name)
       end
    else
	send resultChan, {name, results}
    end
end

def doRace(resultChan, numRunners, numThreads, name) do
    IO.puts "Making tracks"
    start = spawn_link makeTrack(self(), numThreads)
    IO.puts "Made track"
    for n <- 1..numRunners, do: send(start, n)
    IO.puts "SentRunners"
    finishLine(numRunners, [], resultChan, name)
end

def main() do
    numThreads = 3
    numRunners = 1
    spawn_link doRace(self(), numRunners, numThreads, :A)
    spawn_link doRace(self(), numRunners, numThreads, :B)
    receive do
    	    {:A, res} ->
	    	 IO.puts res
    	    {:B, res} ->
	    	 IO.puts res
    end
end

end

Great.main()