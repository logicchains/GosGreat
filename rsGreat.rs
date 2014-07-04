extern crate green;
extern crate rustuv;

use std::os; 

#[start]
fn start(argc: int, argv: **u8) -> int {
    green::start(argc, argv, rustuv::event_loop, main)
}

fn sendSidewards(from : Receiver<int>, to : Sender<int>){
   loop {
	let n = from.recv();
	to.send(n);
   }
}

fn makeTrack(fromLeft : Receiver<int>, toLeft : Sender<int>, numLeft: int){
	if numLeft > 0{
	   	let (senderToRight, receiverForRight) = channel::<int>();
	   	let (senderForRight, receiverFromRight) = channel::<int>();
		spawn(proc(){makeTrack(receiverForRight, senderForRight, numLeft-1)});
		spawn(proc(){sendSidewards(fromLeft, senderToRight)});
		sendSidewards(receiverFromRight, toLeft);
	}else {
	      loop{
			let n = fromLeft.recv();
			toLeft.send(n);			
		}
	}
}

fn doRace(fromStart : Receiver<int>, toStart : Sender<int>,  resultChan : Sender<Vec<int>>, numRunners : uint){
        let mut results = Vec::with_capacity(numRunners);
	for i in range(0, numRunners){
	      	toStart.send(i.to_int().unwrap());
	}
	for _ in range(0, numRunners){	
		let n = fromStart.recv();
		results.push(n);
	}
	resultChan.send(results);
}	

fn main() {
  let args = os::args();
  if args.len() != 3{
        print!("Error: input should be in the form of <numRunners> <numThreads>\n");
        return;
  }
  let numRunners = from_str(args.get(1).as_slice()).expect("numRunners must be an int");
  let numThreads = from_str(args.get(1).as_slice()).expect("numThreads must be an int");
  let (senderToRightA, receiverForRightA) = channel::<int>();
  let (senderForRightA, receiverFromRightA) = channel::<int>();
  let (senderToRightB, receiverForRightB) = channel::<int>();
  let (senderForRightB, receiverFromRightB) = channel::<int>();
  spawn(proc(){ makeTrack(receiverForRightA, senderForRightA, numThreads)});
  spawn(proc(){ makeTrack(receiverForRightB, senderForRightB, numThreads)});
  let (toResultsA, fromResultsA) = channel::<Vec<int>>();
  let (toResultsB, fromResultsB) = channel::<Vec<int>>();
  spawn(proc(){doRace(receiverFromRightA, senderToRightA, toResultsA, numRunners)});
  spawn(proc(){doRace(receiverFromRightB, senderToRightB, toResultsB, numRunners)});
  loop{
    select! (
        aResults = fromResultsA.recv() => {
		 println!("A won! With results: {}", aResults); 
		 break;
	},
	bResults = fromResultsB.recv() => {
		 println!("B won! With results: {}", bResults);
		 break;
	}
    );
  }  
}