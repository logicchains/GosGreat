package main

import(
	"fmt"
	"runtime"
	"os"
	"strconv"
)

func sendSidewards(from chan int, to chan int){
	for{
		n := <-from
		to <-n
	}
}

func makeTrack(left chan int, numLeft int){
	if numLeft > 0{
		right := make(chan int)
		go makeTrack(right, numLeft-1)
		go sendSidewards(left, right)
		sendSidewards(right, left)
	}else{
		for{
			n := <-left
			left<- n			
		}
	}
}
	
func doRace(start chan int, resultChan chan []int, numRunners int){
	results := make([]int,0,numRunners)
	for i := 0; i < numRunners; i++{
		start <- i
	}
	for i := 0; i < numRunners; i++{
		n := <-start
		results = append(results, n)
	}
	resultChan <- results
}

func main(){
	if len(os.Args) != 3{
		panic("Error: program takes two arguments, runners and threads.")
	}
	inThreads := os.Args[2]
	inRunners := os.Args[1]
	runtime.GOMAXPROCS(4)
	numThreads, err := strconv.Atoi(inThreads)
	if err != nil{
		panic("Error: threads must be a int.")
	}
	numRunners, err := strconv.Atoi(inRunners)
	if err != nil{
		panic("Error: runners must be a int.")
	}
	racerA := make(chan int)
	racerB := make(chan int)
	go makeTrack(racerA, numThreads)
	go makeTrack(racerB, numThreads)
	resultsA := make(chan []int)
	resultsB := make(chan []int)
	go doRace(racerA, resultsA, numRunners)
	go doRace(racerB, resultsB, numRunners)
	select{
	case results := <- resultsA:
		fmt.Printf("A won! With results: \n %v\n", results)
	case results := <- resultsB:
		fmt.Printf("B won! With results: \n %v\n", results)
	}
}
