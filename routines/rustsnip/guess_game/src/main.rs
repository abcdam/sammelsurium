use std::io;
use std::cmp::Ordering;
use rand::Rng;

fn main() {
    println!("Guess the number: ");
    let randn = rand::thread_rng().gen_range(1..=100);
    

    loop {
        let mut guess = String::new();
        //println!("input: {}", randn);
        io::stdin()
            .read_line(&mut guess)
            .expect("Failed to read input.");
        

        //let guess: u32 = guess.trim().parse().expect("Please type a number.");
        let guess: u32 = match guess.trim().parse() {
            Ok(num) => num,
            Err(_) => {
                println!("not a number bro..");
                continue;
            },
        };
        println!("You guessed: {}", guess);
        match guess.cmp(&randn) {
            Ordering::Less => println!("<"),
            Ordering::Greater => println!(">"),
            Ordering::Equal => {
                println!("nice."); 
                break;
            }
        }
    }
}