extern crate green;
extern crate rustuv;

use std::comm;

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
	   	let (toRight, fromRight) = channel::<int>();
		let toRight2 = toRight.clone();	
		let fromRight2 = fromRight.clone();	
		spawn(proc(){makeTrack(fromRight, toRight, numLeft-1)});
		spawn(proc(){sendSidewards(fromLeft, toRight2)});
		sendSidewards(fromRight, toLeft);
	}else {
	      loop{
			let n = fromLeft.recv();
			toLeft.send(n);			
		}
	}
}

fn main() {
   
}