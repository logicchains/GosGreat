import Control.Monad
import Control.Concurrent
import Control.Conditional
import Data.Int
import System.Environment
import System.IO.Unsafe

sendSidewards :: Chan Int -> Chan Int -> IO ()
sendSidewards from to = do
	      n <- readChan from
	      writeChan to n
	      sendSidewards from to

sendLeft :: Chan Int -> IO ()
sendLeft left = do
	 n <- readChan left
	 writeChan left n
	 sendLeft left

makeTrack :: Chan Int -> Int -> IO()
makeTrack left nRemaining =
    if nRemaining > 0 then 
	midTrack left nRemaining
    else
        sendLeft left

midTrack :: Chan Int -> Int -> IO()
midTrack left nRemaining = do
        right <- newChan
        forkIO $ makeTrack right (nRemaining - 1)
        forkIO $ sendSidewards left right
        sendSidewards right left

launchRunner :: Chan Int -> Int -> IO()
launchRunner chan num = do
	writeChan chan num

doRace :: Chan Int -> MVar [Int] -> Int -> IO()
doRace start resultChan numRunners = do
       let runners = [1..numRunners]
       let launchRunnerOnChan = launchRunner start
       forkIO $ mapM_ launchRunnerOnChan runners
       finishLine start numRunners [] resultChan
       
finishLine :: Chan Int -> Int -> [Int] -> MVar [Int] -> IO()
finishLine inChan remaining results resultChan =
        if remaining > 0 then
	   finishLine inChan (remaining - 1) ((receiveResults inChan):results) resultChan
	else doneResults results resultChan 

doneResults :: [Int] -> MVar [Int] -> IO()
doneResults results resultChan  = do
	    putMVar resultChan results

receiveResults :: Chan Int -> Int
receiveResults inChan = do
	       unsafePerformIO (readChan inChan)

main = do
     (numRunners:numThreads:_) <- getArgs
     racerA <- newChan
     racerB <- newChan
     forkIO $ makeTrack racerA $ read numThreads
     forkIO $ makeTrack racerB $ read numThreads
     resultsA <- newEmptyMVar
     resultsB <- newEmptyMVar
     forkIO $ doRace racerA resultsA $ read numRunners
     forkIO $ doRace racerB resultsB $ read numRunners
     awaitWinner resultsA resultsB 


awaitWinner :: MVar [Int] -> MVar [Int] -> IO()
awaitWinner aChan bChan  =
	    if varReady aChan then	    
	       printWinner aChan "a"
	    else if varReady bChan then
	       printWinner bChan "b"
	    else awaitWinner aChan bChan

varReady :: MVar [Int] -> Bool
varReady var = not $ unsafePerformIO $ isEmptyMVar var

printWinner :: MVar [Int] -> [Char] -> IO()
printWinner chan name = do
	    putStrLn (name ++ " won!")
	    nums <- takeMVar chan
	    putStrLn $ show nums