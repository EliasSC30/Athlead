use rand::Rng;
use num_bigint::{ToBigInt};


pub mod encryption
{
    use std::fmt;
    use std::mem::swap;
    use std::ops::{Add, Mul};
    use rand::Rng;

    pub struct BigInt {
        pub parts: Vec<u32>
    }

    impl Clone for BigInt {
        fn clone(&self) -> Self { BigInt { parts: self.parts.clone() } }
    }

    impl fmt::Display for BigInt {
        fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
            let mut power = 0 as usize;
            let length = self.parts.len();
            for i in 0..length {
                write!(f, "{}", self.parts[i]).expect("Ace");
                if i != 0 { write!(f,"*2^{}", power).expect("T"); };
                if i != length -1 { write!(f,"+").expect("T"); };
                power += 32usize;
            }

            write!(f, "\n")
        }
    }

    pub fn add_with_carry(a:u32, b:u32) -> (u32, u32)
    {
        // This is a+b = Max + carry <=> carry = a - (Max - b) to get the carry, if there is any
        if (u32::MAX - b) > a { (a+b,0) } else { (a.wrapping_add(b), 1) }
    }

    impl BigInt {
        pub fn new(parts_to_take_over: Vec<u32>) -> BigInt { BigInt { parts: parts_to_take_over } }

        pub fn from(a: u64) -> BigInt
        {
            let mut return_value = vec![0u32,0u32];
            return_value[0] = (a & (u32::MAX as u64)) as u32;
            return_value[1] = ((a & ((u32::MAX as u64) << 32)) >> 32) as u32;

            let mut return_value = BigInt { parts: return_value };
            return_value.shrink_to_highest_power();
            return_value
        }

        pub fn from_128(a: u128) -> BigInt
        {
            let mut return_value = vec![0u32,0u32,0u32,0u32];
            return_value[0] = (a & (u32::MAX as u128)) as u32;
            return_value[1] = ((a & ((u32::MAX as u128) << 32)) >> 32) as u32;
            return_value[2] = ((a & ((u32::MAX as u128) << 64)) >> 64) as u32;
            return_value[3] = (a >> 96) as u32;

            let mut return_value = BigInt { parts: return_value };
            return_value.shrink_to_highest_power();
            return_value
        }

        pub fn parse(s: &String) -> BigInt
        {
            let mut parts =
                s.chars().into_iter().map(|c| c.to_digit(10).unwrap()).collect::<Vec<u32>>();



            BigInt { parts }
        }

        pub fn a7_u32_vec_to_string(vec: &Vec<u32>) -> String
        {
            let mut ret = String::with_capacity(vec.len()*4);

            for part in vec
            {
                let fst_char = (*part & 0xFF) as u8;
                let snd_char = ((*part & (0xFF<<8)) >> 8) as u8;
                let thd_char = ((*part & (0xFF<<16)) >> 16) as u8;
                let fth_char = ((*part & (0xFF<<24)) >> 24) as u8;

                ret.push(fst_char as char);
                ret.push(snd_char as char);
                ret.push(thd_char as char);
                ret.push(fth_char as char);

            }

            while ret.chars().last().unwrap() == '\0' {ret.pop();};
            ret
        }

        pub fn non_a7_u32_vec_to_exp_string(vec: &Vec<u32>) -> String {
            let nr_of_characters = vec.len()*8;
            let mut ret = String::with_capacity(nr_of_characters);

            for part in vec
            {
                let val = *part;

                let fst_char = (( val & (0xF)) + 97) as u8;
                let snd_char = (((val & (0xF<<4) ) >> 4 ) + 97) as u8;
                let thd_char = (((val & (0xF<<8) ) >> 8 ) + 97) as u8;
                let fth_char = (((val & (0xF<<12)) >> 12) + 97) as u8;
                let ffh_char = (((val & (0xF<<16)) >> 16) + 97) as u8;
                let sth_char = (((val & (0xF<<20)) >> 20) + 97) as u8;
                let svh_char = (((val & (0xF<<24)) >> 24) + 97) as u8;
                let eth_char = (((val & (0xF<<28)) >> 28) + 97) as u8;

                ret.push(fst_char as char); println!("{}", fst_char);
                ret.push(snd_char as char); println!("{}", snd_char);
                ret.push(thd_char as char); println!("{}", thd_char);
                ret.push(fth_char as char); println!("{}", fth_char);
                ret.push(ffh_char as char); println!("{}", ffh_char);
                ret.push(sth_char as char); println!("{}", sth_char);
                ret.push(svh_char as char); println!("{}", svh_char);
                ret.push(eth_char as char); println!("{}", eth_char);
            }

            while ret.chars().last().unwrap() == '\0' { ret.pop(); }
            ret
        }

        pub fn exp_str_to_u32_vec(s: &String) -> Vec<u32> {
            let mut ret = Vec::<u32>::with_capacity(s.chars().count()/8);
            let nr_of_characters = s.len();
            for index in (0..nr_of_characters).step_by(8) {
                let val1 = (s.chars().nth(index).unwrap() as u8 -97) as u32;
                let val2 = (s.chars().nth(index + 1).unwrap() as u8 -97) as u32;
                let val3 = (s.chars().nth(index + 2).unwrap() as u8 -97) as u32;
                let val4 = (s.chars().nth(index + 3).unwrap() as u8 -97) as u32;
                let val5 = (s.chars().nth(index + 4).unwrap() as u8 -97) as u32;
                let val6 = (s.chars().nth(index + 5).unwrap() as u8 -97) as u32;
                let val7 = (s.chars().nth(index + 6).unwrap() as u8 -97) as u32;
                let val8 = (s.chars().nth(index + 7).unwrap() as u8 -97) as u32;

                let fst_val = val1;
                let snd_val = val2 <<4;
                let thd_val = val3 <<8;
                let fth_val = val4 <<12;
                let ffh_val = val5 <<16;
                let sth_val = val6 <<20;
                let svh_val = val7 <<24;
                let eth_val = val8 <<28;

                ret.push(fst_val|snd_val|thd_val|fth_val|ffh_val|sth_val|svh_val|eth_val);
            }

            ret
        }
        pub fn a7_string_to_u32_vec(s: &String) -> Vec<u32> {
            let mut s = s.clone();
            let mut ret = Vec::<u32>::with_capacity(s.len());
            let nr_of_characters = s.chars().count();
            let zeros_to_push = (4 - nr_of_characters % 4) %4;
            for _ in 0..zeros_to_push { s.push('\0'); };


            for index in (0..s.chars().count()).step_by(4)
            {
                let fst_char = s.chars().nth(index).unwrap() as u32;
                let snd_char = s.chars().nth(index+1).unwrap() as u32;
                let thd_char = s.chars().nth(index+2).unwrap() as u32;
                let frth_char = s.chars().nth(index+3).unwrap() as u32;

                let to_push = fst_char +
                    (snd_char<<8) +
                    (thd_char<<16) +
                    (frth_char<<24);

                ret.push(to_push);
            }

            ret
        }


        pub fn half(&self) -> BigInt {
            let mut return_value = vec![0u32; self.parts.len()];

            return_value.iter_mut().zip(self.parts.iter()).for_each(
                |(a, b)| *a = b >> 1
            );

            for i in 0..self.parts.len()-1
            {
                return_value[i] |= (1u32 & self.parts[i+1]) << 31u32;
            }

            BigInt { parts: return_value }
        }

        pub fn half_ceil(&self) -> BigInt {
            let mut return_value = vec![0u32; self.parts.len()];
            let round_up_add = if self.is_odd() {BigInt::one()} else {BigInt::zero()};

            return_value.iter_mut().zip(self.parts.iter()).for_each(
                |(a, b)| *a = b >> 1
            );

            for i in 0..self.parts.len()-1
            {
                return_value[i] |= (1u32 & self.parts[i+1]) << 31u32;
            }

            BigInt { parts: return_value }.add(&round_up_add)
        }

        pub fn square(&self) -> BigInt { self.mul(&self) }

        pub fn highest_bit_pos(self: &BigInt) -> u32
        {
            let highest_power = BigInt::find_highest_power(&self.parts);
            let highest_bit_in_highest_power =
                match self.parts[highest_power] {
                    0 => 0,
                    unequal_zero => unequal_zero.ilog2()
                };

            (highest_power as u32) * 32u32 + highest_bit_in_highest_power
        }

        pub fn get_nth_bit(self: &BigInt, n: u32) -> bool
        {
            let inner_index = n % 32;
            let part = self.parts[(n / 32) as usize];
            (part & (1u32 << inner_index)) != 0
        }

        pub fn is_odd(&self) -> bool { (self.parts[0] & 1) == 1 }

        pub fn shrink_to_highest_power(&mut self)
        {
            let mut nr_of_parts_to_remove = 0;
            let mut current_power_to_check = self.parts.len() - 1;
            loop
            {
                if current_power_to_check == 0 {break;};
                if self.parts[current_power_to_check] == 0u32 {
                    nr_of_parts_to_remove +=1;
                } else {
                    break;
                };
                current_power_to_check -= 1;
            }

            self.parts.truncate(self.parts.len() - nr_of_parts_to_remove);
        }

        pub fn shrink_to_highest_power_copy(&self) -> BigInt
        {
            let mut copy = BigInt{ parts: self.parts.clone() };
            copy.shrink_to_highest_power();
            copy
        }

        fn padd_n_zeros(&mut self, n: usize) { for _ in 0..n {self.parts.push(0u32);} }

        pub(crate) fn zero() -> BigInt {BigInt{parts:vec![0u32]}}
        pub(crate) fn one() -> BigInt {BigInt{parts:vec![1u32]}}

        pub fn is_zero(&self) -> bool { self.parts.iter().all(|&x| x == 0u32) }

        fn find_highest_power(parts_to_check: &Vec<u32>) -> usize
        {
            let mut non_zero_index = parts_to_check.len() - 1;
            while non_zero_index > 0 {
                if parts_to_check[non_zero_index] != 0u32 { return non_zero_index; }
                non_zero_index -= 1;
            }

            0
        }

        fn power_difference(a: &BigInt, b: &BigInt) -> i32
        {
            let this_highest_power = Self::find_highest_power(&a.parts);
            let other_highest_power = Self::find_highest_power(&b.parts);

            this_highest_power as i32 - other_highest_power as i32
        }

        pub fn compare(&self, other: &BigInt) -> i32 {
            let power_difference = Self::power_difference(&self, &other);
            let a = self.parts[0];
            let b = other.parts[0];

            if power_difference == 0 {
                let mut power_index_to_compare = Self::find_highest_power(&self.parts);
                while self.parts[power_index_to_compare] == other.parts[power_index_to_compare] {
                    if power_index_to_compare == 0usize {break;};
                    power_index_to_compare -= 1usize;
                }

                if self.parts[power_index_to_compare] > other.parts[power_index_to_compare] {1}
                else if self.parts[power_index_to_compare] < other.parts[power_index_to_compare] {-1}
                else {0}
            } else {
                power_difference
            }
        }

        fn add_with_carry(a:u32, b:u32) -> (u32, u32)
        {
            // This is a+b = Max + carry <=> carry = a - (Max - b) to get the carry, if there is any
            //if (u32::MAX - b) > a { (a+b,0) } else { (a.wrapping_add(b), 1) }
            let a_as_64 = a as u64;
            let b_as_64 = b as u64;

            let res = a_as_64 + b_as_64;

            ((res & (0xFFFFFFFF)) as u32, ((res & (0xFFFFFFFF << 32)) >> 32) as u32)
        }

        fn mul_with_carry(a:u32, b:u32) -> (u32, u32)
        {
            let a_as_64 = a as u64;
            let b_as_64 = b as u64;

            let res = a_as_64 * b_as_64;

            ((res & (0xFFFFFFFF)) as u32, ((res & (0xFFFFFFFF << 32)) >> 32) as u32)
        }

        fn div_with_remainder(a:u32, b:u32) -> (u32, u32)
        {
            let without_remainder = a / b;

            (without_remainder, a - b * without_remainder)
        }

        pub fn mul(&self, other: &BigInt) -> BigInt
        {
            let this_highest_power = Self::find_highest_power(&self.parts);
            let other_highest_power = Self::find_highest_power(&other.parts);


            let mut return_value = vec![0u32; this_highest_power+other_highest_power+1 +1];
            let mut carry = 0u32;

            for outer_index in 0..this_highest_power+1
            {
                let part = self.parts[outer_index];
                for inner_index in 0..other_highest_power+1
                {
                    let cur_index = outer_index + inner_index;
                    //println!("cur_index: {}", cur_index);
                    let (mul_r, mul_c) = Self::mul_with_carry(part, other.parts[inner_index]);
                    // println!("mul_r: {}, mul_c: {}", mul_r, mul_c);
                    let (add_r, add_c) = Self::add_with_carry(return_value[cur_index], carry);
                    //println!("add_r: {}, add_c: {}", add_r, add_c);

                    let (add_to_return_value_r, add_to_return_value_c) = Self::add_with_carry(add_r, mul_r);
                    // println!("add_to_return_value_r: {}", add_to_return_value_r);

                    // a_n*b_m -> ret[i] = [prev]_(n+m)+carry+mul_res, carry =

                    return_value[cur_index] = add_to_return_value_r;
                    carry = mul_c + add_to_return_value_c + add_c;
                }
                let mut index_of_last_carry = outer_index+other_highest_power+1;
                while carry != 0 {
                    let (add_res, add_c) = Self::add_with_carry(return_value[index_of_last_carry], carry);
                    return_value[index_of_last_carry] = add_res;
                    carry = add_c;
                    index_of_last_carry += 1;
                }
            }

            let mut ret = BigInt{parts: return_value};
            ret.shrink_to_highest_power();
            ret
        }

        fn calculate_remainder(last_guess: &BigInt, denominator: &BigInt, nominator: &BigInt) -> BigInt {
            let to_sub = last_guess.mul(denominator);
            let mut remainder = if to_sub.compare(&nominator) < 0 {
                nominator.sub(&to_sub).unwrap()
            } else {to_sub.sub(&nominator).unwrap() };

            remainder.shrink_to_highest_power();
            remainder
        }

        // We are computing self/other = (whole_result, remainder)
        pub fn div(&self, other: &BigInt) -> (BigInt, BigInt)
        {
            let mut other = other.clone();
            let mut this = self.clone();
            this.shrink_to_highest_power();
            other.shrink_to_highest_power();

            // If self is smaller than other the result is simply (0,self)
            if self.compare(&other) < 0 {
                return (BigInt{parts: vec![0u32]}, this);
            };

            let (this_highest_power, other_highest_power) =
                (Self::find_highest_power(&this.parts), Self::find_highest_power(&other.parts));
            let highest_power_of_first_guess = this_highest_power - other_highest_power + 2;

            let mut high_guess = BigInt { parts: vec![u32::MAX; highest_power_of_first_guess] };
            let mut low_guess = BigInt { parts: vec![0u32; highest_power_of_first_guess] };

            let mut next_guess = BigInt::one();

            loop
            {
                next_guess = low_guess.add(&high_guess).half_ceil();
                let guess_times_other = next_guess.mul(&other);// println!("x*b ={}",guess_times_other);

                let comparison = this.compare(&guess_times_other);// println!("a {} x*b", if comparison > 0 { '>' } else { '<' });
                match comparison {
                    1.. => low_guess = next_guess,
                    0   => break,
                    _   => high_guess = next_guess.sub(&BigInt::one()).unwrap()
                };// println!("low_guess: {}\nhigh_guess: {}", low_guess, high_guess);

                if low_guess.compare(&high_guess) >= 0 {
                    next_guess = low_guess;
                    break;
                };
            }

            if next_guess.mul(&other).compare(&this) > 0 { next_guess = next_guess.sub(&BigInt::one()).unwrap() };
            //println!("before calculating remainder: {}", next_guess);
            let remainder = Self::calculate_remainder(&next_guess, &other, &this);
            let y = remainder.parts[0];
            (next_guess, remainder)
        }

        pub fn add(&self, other: &BigInt) -> BigInt
        {

            let smaller: &Self = if self.compare(&other) < 0 { self } else { other };
            let bigger: &Self = if self.compare(&other) >= 0 { self } else { other };
            let bigger_highest_power = Self::find_highest_power(&bigger.parts);
            let smaller_highest_power = Self::find_highest_power(&smaller.parts);

            let mut return_value = vec![0u32;bigger_highest_power+1];
            let mut carry = 0u32;

            for index in 0..smaller_highest_power+1
            {
                let a = self.parts[index];
                let b = other.parts[index];

                let (a_plus_b_wrapped, a_plus_b_carry) = Self::add_with_carry(a, b);
                let (a_plus_b_plus_carry_wrapped, final_carry) = Self::add_with_carry(a_plus_b_wrapped, carry);

                return_value[index] = a_plus_b_plus_carry_wrapped;
                carry = if a_plus_b_carry != 0 || final_carry != 0 { 1 } else { 0 };
            }

            for index in smaller_highest_power+1..bigger_highest_power+1
            {
                let a = bigger.parts[index];

                let (a_plus_carry, a_plus_carry_carry) = Self::add_with_carry(a, carry);

                return_value[index] = a_plus_carry;
                carry = if a_plus_carry_carry != 0 { 1 } else { 0 };
            }

            if carry != 0u32 { return_value.push(1); };

            BigInt{parts: return_value}
        }

        pub fn sub(&self, other: &BigInt) -> Result<BigInt, String>
        {
            if self.compare(other) < 0 {
                let mut output = String::from("Tried to sub ");
                output += &*other.to_string();
                output += " from ";
                output += &*self.to_string();
                return Err(output);
            };

            let mut return_value = vec![0u32;self.parts.len()];
            let mut this = self.clone();
            let mut other = other.clone();

            let this_highest_power = Self::find_highest_power(&this.parts);
            let other_highest_power = Self::find_highest_power(&other.parts);
            let power_diff = this_highest_power - other_highest_power;

            other.padd_n_zeros(power_diff);

            for index in 0..this_highest_power+1
            {
                let a_n = this.parts[index];
                let b_n = other.parts[index];

                if a_n >= b_n {
                    return_value[index] += a_n - b_n;
                } else {
                    // Since we checked that we are bigger this branch will never be out of bounds
                    let mut index_offset_to_subtract = 1;
                    while this.parts[index + index_offset_to_subtract] == 0u32 {
                        this.parts[index + index_offset_to_subtract] = u32::MAX;
                        index_offset_to_subtract += 1;
                    }

                    this.parts[index + index_offset_to_subtract] -= 1u32;

                    let tmp = (a_n as u64) + (1u64 << 32);
                    return_value[index] = (tmp - b_n as u64) as u32;
                };
            }

            Ok(BigInt{parts: return_value})
        }
    }
    pub fn generate_key() -> (BigInt, BigInt, BigInt)
    {
        let my_p = BigInt {parts: vec![1150773219, 3236988108, 2228614866, 458142249, 1378787120, 120964419, 1280341924, 995117329, 514]};
        let my_q = BigInt {parts: vec![756627691, 856635683, 1445467880, 60618053, 3098661805, 4047942669, 3076960666, 3766133036, 329]};
        let my_n = my_p.mul(&my_q);

        let my_phi_n = my_p.sub(&BigInt::one()).unwrap().mul(&my_q.sub(&BigInt::one()).unwrap());

        let my_e = BigInt {parts: vec![1819729999, 2373032901, 331272633, 1462885573, 464677505, 3058999981, 2070505180, 26939296]};

        let gcd = gcd(&my_e, &my_phi_n);

        (my_e, gcd.1, my_n)
    }

    // Solving for gcd(a,b) = s*a + t*b
    fn gcd(a: &BigInt, b: &BigInt) -> (BigInt,BigInt,BigInt)
    {
        let mut r_0 = a.clone();
        let mut r_1 = b.clone();
        let mut s_0 = BigInt::one();
        let mut s_1 = BigInt::zero();
        let mut t_0 = BigInt::zero();
        let mut t_1 = BigInt::one();

        let mut n = 0u32;
        while r_1.compare(&BigInt::zero()) > 0
        {
            let q = r_0.div(&r_1).0;
            r_0 = if r_0.compare(&q.mul(&r_1)) > 0 { r_0.sub(&q.mul(&r_1)).unwrap() } else { q.mul(&r_1).sub(&r_0).unwrap() };
            swap(&mut r_0, &mut r_1);
            s_0 = s_0.add(&q.mul(&s_1));
            swap(&mut s_0, &mut s_1);
            t_0 = t_0.add(&q.mul(&t_1));
            swap(&mut t_0, &mut t_1);
            n += 1;
        }
        if (n%2) != 0 {s_0 = b.sub(&s_0).unwrap();} else {t_0 = a.sub(&t_0).unwrap();};

        (r_0, s_0, t_0)
    }

    pub fn crypt(m: &BigInt, d:&BigInt, n: &BigInt) -> BigInt
    {
        let mut intermediate = m.div(n).1;
        let mut total_remainder = BigInt::one();

        let highest_bit_pos_of_d = d.highest_bit_pos();

        for i in 0..=highest_bit_pos_of_d
        {
            let to_multiply = if d.get_nth_bit(i) {&intermediate} else {&BigInt::one()};
            total_remainder = total_remainder.mul(to_multiply);
            total_remainder = total_remainder.div(n).1;


            let result = intermediate.square();
            intermediate = result.div(n).1;
        }

        total_remainder
    }

    pub fn crypt_str(to_crypt: &String, d_or_e : &BigInt, n: &BigInt) -> BigInt
    {
        let converted = BigInt { parts: BigInt::a7_string_to_u32_vec(&to_crypt.clone()) };

        crypt(&converted, d_or_e, n)
    }

    pub fn hash(to_hash: &Vec<u32>) -> u64
    {
        let prime = 67108859u64; // Smaller than 2^32 so prime * expanded_byte doesn't overflow

        let mut hash_value = 0u64;

        for byte in to_hash
        {
            let expanded_byte = *byte as u64;
            hash_value ^= expanded_byte * prime;
        }

        hash_value
    }

    fn fuzzy_tests() {
        let one = BigInt{parts:vec![1u32]};
        let two = BigInt{parts:vec![2u32]};
        let mut add_total = BigInt::zero();
        let mut mul_total = BigInt::one();
        let mut remainder_total = BigInt::zero();
        let nr_of_test_runs = 10000;

        for _ in 0..nr_of_test_runs {
            add_total = add_total.add(&one);
            mul_total = mul_total.mul(&two);
            remainder_total = one.div(&mul_total).1;
        }
        mul_total.shrink_to_highest_power();
        remainder_total.shrink_to_highest_power();

        assert_eq!(1, add_total.parts.len());
        assert_eq!(nr_of_test_runs, add_total.parts[0]);

        let expected_mul_parts_length = nr_of_test_runs as usize / 32usize + 1;
        assert_eq!(expected_mul_parts_length, mul_total.parts.len());
        for i in 0..expected_mul_parts_length-1 { assert_eq!(0u32, mul_total.parts[i]); }
        assert_eq!(1<<(nr_of_test_runs % 32), mul_total.parts[expected_mul_parts_length-1]);

        assert_eq!(1, remainder_total.parts.len());
        assert_eq!(1, remainder_total.parts[0]);

        let mut rng = rand::rng();
        let random_part_len = rng.random::<u32>() % 2 + 1;
        let mut random = BigInt{parts:vec![0u32;random_part_len as usize]};
        random.parts.iter_mut().for_each(|part|{*part = rng.random()});
        let large_n = BigInt{parts:vec![rand::random::<u32>().saturating_add(1); 3]};
        let mut random_before_div = random.clone();

        for _ in 0..nr_of_test_runs {
            random_before_div = random.clone();
            random = random.square();
            let (result, remainder) = random.div(&large_n);
            assert_eq!(0, result.mul(&large_n).add(&remainder).compare(&random), "Remainder wrong\nrandom_before_square:{}\nrandom:{}\nlarge_n: {}", random_before_div, random, large_n);
            random = remainder.clone();
        }
    }

    pub fn run_tests() {
        let mut zero = BigInt{parts:vec![0u32]};
        let mut one = BigInt{parts:vec![1u32]};
        let mut two = BigInt{parts:vec![2u32]};
        assert_eq!(1, zero.parts.len());
        assert_eq!(0, zero.parts[0]);
        assert_eq!(1, one.parts.len());
        assert_eq!(1, one.parts[0]);
        assert_eq!(1, two.parts.len());
        assert_eq!(2, two.parts[0]);

        assert_eq!(0, one.compare(&BigInt::one()));

        assert_eq!(0, one.add(&zero).compare(&one));

        let highest_bit_of_zero = zero.highest_bit_pos();
        let highest_bit_of_one = one.highest_bit_pos();
        let highest_bit_of_two = two.highest_bit_pos();
        let highest_bit_of_two_to_128 = BigInt{parts: vec![0,0,0,0,1]}.highest_bit_pos();
        assert_eq!(0, highest_bit_of_zero);
        assert_eq!(0, highest_bit_of_one);
        assert_eq!(1, highest_bit_of_two);
        assert_eq!(128, highest_bit_of_two_to_128);

        let zero_from_u64 = BigInt::from(0u64);
        let one_from_u64 = BigInt::from(1u64);
        let two_from_u64 = BigInt::from(2u64);
        let two_to_32_from_u64 = BigInt::from(1u64 << 32);
        let u32_max_from_u64 = BigInt::from(u32::MAX as u64);

        assert_eq!(1, zero_from_u64.parts.len());
        assert_eq!(0, zero_from_u64.parts[0]);
        assert_eq!(1, one_from_u64.parts.len());
        assert_eq!(1, one_from_u64.parts[0]);
        assert_eq!(1, two_from_u64.parts.len());
        assert_eq!(2, two_from_u64.parts[0]);
        assert_eq!(2, two_to_32_from_u64.parts.len());
        assert_eq!(0, two_to_32_from_u64.parts[0]);
        assert_eq!(1, two_to_32_from_u64.parts[1]);
        assert_eq!(1, u32_max_from_u64.parts.len());
        assert_eq!(u32::MAX, u32_max_from_u64.parts[0]);


        let zero_plus_zero = zero.add(&zero);
        assert_eq!(1, zero_plus_zero.parts.len());
        assert_eq!(0, zero_plus_zero.parts[0]);
        assert_eq!(0, zero_plus_zero.compare(&zero));

        let one_plus_zero = one.add(&zero);
        let zero_plus_one = zero.add(&one);
        assert_eq!(1, one_plus_zero.parts.len());
        assert_eq!(1, zero_plus_one.parts.len());
        assert_eq!(1, one_plus_zero.parts[0]);
        assert_eq!(1, zero_plus_one.parts[0]);


        let one_plus_one = one.add(&one);
        assert_eq!(1, one_plus_one.parts.len());
        assert_eq!(2, one_plus_one.parts[0]);
        assert_eq!(0, one_plus_one.compare(&two));

        let u32_max = BigInt{parts:vec![u32::MAX]};
        assert_eq!(1, u32_max.parts.len());
        assert_eq!(u32::MAX, u32_max.parts[0]);

        let add_single_overflow = one.add(&u32_max);
        assert_eq!(2, add_single_overflow.parts.len());
        assert_eq!(0, add_single_overflow.parts[0]);
        assert_eq!(1, add_single_overflow.parts[1]);

        let two_parts_max = BigInt{parts:vec![u32::MAX, u32::MAX]};
        let add_double_overflow = one.add(&two_parts_max);
        assert_eq!(3, add_double_overflow.parts.len());
        assert_eq!(0, add_double_overflow.parts[0]);
        assert_eq!(0, add_double_overflow.parts[1]);
        assert_eq!(1, add_double_overflow.parts[2]);

        let add_rnd_overflow = two_parts_max.add(&two_parts_max);
        assert_eq!(3, add_rnd_overflow.parts.len());
        assert_eq!(u32::MAX-1, add_rnd_overflow.parts[0]);
        assert_eq!(u32::MAX, add_rnd_overflow.parts[1]);
        assert_eq!(1, add_rnd_overflow.parts[2]);

        let bigger_plus_smaller =
            BigInt{parts:vec![8,8,u32::MAX,u32::MAX,u32::MAX,u32::MAX,u32::MAX,u32::MAX]}.add(&BigInt{parts: vec![2,1,1]});
        assert_eq!(9, bigger_plus_smaller.parts.len());
        assert_eq!(10, bigger_plus_smaller.parts[0]);
        assert_eq!(9, bigger_plus_smaller.parts[1]);
        assert_eq!(0, bigger_plus_smaller.parts[2]);
        assert_eq!(0, bigger_plus_smaller.parts[3]);
        assert_eq!(0, bigger_plus_smaller.parts[4]);
        assert_eq!(0, bigger_plus_smaller.parts[5]);
        assert_eq!(0, bigger_plus_smaller.parts[6]);
        assert_eq!(0, bigger_plus_smaller.parts[7]);
        assert_eq!(1, bigger_plus_smaller.parts[8]);

        let smaller_plus_bigger =
            BigInt{parts: vec![2,1,1]}.add(&BigInt{parts:vec![8,8,u32::MAX,u32::MAX,u32::MAX,u32::MAX,u32::MAX,u32::MAX]});
        assert_eq!(9, smaller_plus_bigger.parts.len());
        assert_eq!(10, smaller_plus_bigger.parts[0]);
        assert_eq!(9, smaller_plus_bigger.parts[1]);
        assert_eq!(0, smaller_plus_bigger.parts[2]);
        assert_eq!(0, smaller_plus_bigger.parts[3]);
        assert_eq!(0, smaller_plus_bigger.parts[4]);
        assert_eq!(0, smaller_plus_bigger.parts[5]);
        assert_eq!(0, smaller_plus_bigger.parts[6]);
        assert_eq!(0, smaller_plus_bigger.parts[7]);
        assert_eq!(1, smaller_plus_bigger.parts[8]);

        let one_times_zero = one.mul(&zero);
        assert_eq!(1, one_times_zero.parts.len());
        assert_eq!(0, one_times_zero.parts[0]);

        let zero_times_one = zero.mul(&one);
        assert_eq!(1, zero_times_one.parts.len());
        assert_eq!(0, zero_times_one.parts[0]);

        let one_times_one = one.mul(&one);
        assert_eq!(1, one_times_one.parts.len());
        assert_eq!(1, one_times_one.parts[0]);

        let zero_times_zero = zero.mul(&zero);
        assert_eq!(1, zero_times_zero.parts.len());
        assert_eq!(0, zero_times_zero.parts[0]);

        let one_times_two = one.mul(&two);
        assert_eq!(1, one_times_two.parts.len());
        assert_eq!(2, one_times_two.parts[0]);

        let one_times_u32_max = one.mul(&u32_max);
        assert_eq!(1, one_times_u32_max.parts.len());
        assert_eq!(u32::MAX, one_times_u32_max.parts[0]);

        let u32_max_times_one = u32_max.mul(&one);
        assert_eq!(1, u32_max_times_one.parts.len());
        assert_eq!(u32::MAX, u32_max_times_one.parts[0]);

        let two_times_u32_max = two.mul(&u32_max);
        assert_eq!(2, two_times_u32_max.parts.len());
        assert_eq!(u32::MAX-1, two_times_u32_max.parts[0]);
        assert_eq!(1, two_times_u32_max.parts[1]);

        let u32_max_times_two = u32_max.mul(&two);
        assert_eq!(2, u32_max_times_two.parts.len());
        assert_eq!(u32::MAX-1, u32_max_times_two.parts[0]);
        assert_eq!(1, u32_max_times_two.parts[1]);

        let u32_max_times_u32_max = u32_max.mul(&u32_max);
        assert_eq!(2, u32_max_times_u32_max.parts.len());
        assert_eq!(1, u32_max_times_u32_max.parts[0]);
        assert_eq!(u32::MAX-1, u32_max_times_u32_max.parts[1]);

        let big_multiplication =
            BigInt{parts:vec![3,3,3,3]}.mul(&BigInt{parts:vec![4,4,4,4]});
        assert_eq!(7, big_multiplication.parts.len());
        assert_eq!(12, big_multiplication.parts[0]);
        assert_eq!(24, big_multiplication.parts[1]);
        assert_eq!(36, big_multiplication.parts[2]);
        assert_eq!(48, big_multiplication.parts[3]);
        assert_eq!(36, big_multiplication.parts[4]);
        assert_eq!(24, big_multiplication.parts[5]);
        assert_eq!(12, big_multiplication.parts[6]);

        let mult_with_inner_carry =
            BigInt{parts:vec![2,u32::MAX,u32::MAX,u32::MAX]}.mul(&BigInt{parts:vec![u32::MAX/2 + 1,1]});
        assert_eq!(6, mult_with_inner_carry.parts.len());
        assert_eq!(0, mult_with_inner_carry.parts[0]);
        assert_eq!(2147483651, mult_with_inner_carry.parts[1]);
        assert_eq!(4294967294, mult_with_inner_carry.parts[2]);
        assert_eq!(4294967295, mult_with_inner_carry.parts[3]);
        assert_eq!(2147483647, mult_with_inner_carry.parts[4]);
        assert_eq!(1, mult_with_inner_carry.parts[5]);

        let zero_minus_zero = zero.sub(&zero).unwrap();
        assert_eq!(1, zero_minus_zero.parts.len());
        assert_eq!(0, zero_minus_zero.parts[0]);

        let one_minus_zero = one.sub(&zero).unwrap();
        assert_eq!(1, one_minus_zero.parts.len());
        assert_eq!(1, one_minus_zero.parts[0]);

        let one_minus_one = one.sub(&one).unwrap();
        assert_eq!(1, one_minus_one.parts.len());
        assert_eq!(0, one_minus_one.parts[0]);

        let two_minus_one = two.sub(&one).unwrap();
        assert_eq!(1, two_minus_one.parts.len());
        assert_eq!(1, two_minus_one.parts[0]);
        assert_eq!(0, two_minus_one.compare(&BigInt::one()));

        let sub_with_carries = BigInt{parts:vec![1,0,0,0,1]}.sub(&BigInt{parts:vec![1,0,1,0,0]}).unwrap();
        assert_eq!(5, sub_with_carries.parts.len());
        assert_eq!(3, BigInt::find_highest_power(&sub_with_carries.parts));
        assert_eq!(0, sub_with_carries.parts[0]);
        assert_eq!(0, sub_with_carries.parts[1]);
        assert_eq!(u32::MAX, sub_with_carries.parts[2]);
        assert_eq!(u32::MAX, sub_with_carries.parts[3]);
        assert_eq!(0, sub_with_carries.parts[4]);

        let bigger_minus_smaller_with_higher_parts =
            BigInt{parts: vec![8,8,8,8,8,8,8,8,8]}.sub(&BigInt{parts:vec![11,0,13,0,24]}).unwrap();
        assert_eq!(9, bigger_minus_smaller_with_higher_parts.parts.len());
        assert_eq!(u32::MAX - 3 + 1, bigger_minus_smaller_with_higher_parts.parts[0]);
        assert_eq!(7, bigger_minus_smaller_with_higher_parts.parts[1]);
        assert_eq!(u32::MAX - 4, bigger_minus_smaller_with_higher_parts.parts[2]);
        assert_eq!(7, bigger_minus_smaller_with_higher_parts.parts[3]);
        assert_eq!(u32::MAX - 15, bigger_minus_smaller_with_higher_parts.parts[4]);
        assert_eq!(7, bigger_minus_smaller_with_higher_parts.parts[5]);
        assert_eq!(8, bigger_minus_smaller_with_higher_parts.parts[6]);
        assert_eq!(8, bigger_minus_smaller_with_higher_parts.parts[7]);
        assert_eq!(8, bigger_minus_smaller_with_higher_parts.parts[8]);

        let not_implemented = zero.sub(&one);
        assert!(not_implemented.is_err());

        let (one_div_one, one_div_one_remainder) = one.div(&one);
        assert_eq!(1, one_div_one.parts.len());
        assert_eq!(1, one_div_one.parts[0]);
        assert_eq!(0, one_div_one.compare(&one));
        assert_eq!(1, one_div_one_remainder.parts.len());
        assert_eq!(0, one_div_one_remainder.parts[0]);
        assert_eq!(0, one_div_one_remainder.compare(&zero));

        let (zero_div_one, zero_div_one_remainder) = zero.div(&one);
        let (zero_div_u32_max, zero_div_u32_max_remainder) = zero.div(&u32_max);
        let (zero_div_many_parts, zero_div_many_parts_remainder) = zero.div(&BigInt{parts:vec![1,0,0,0,1]});
        assert_eq!(1, zero_div_one.parts.len());
        assert_eq!(1, zero_div_u32_max.parts.len());
        assert_eq!(1, zero_div_u32_max.parts.len());
        assert_eq!(0, zero_div_one.parts[0]);
        assert_eq!(0, zero_div_u32_max.parts[0]);
        assert_eq!(0, zero_div_many_parts.parts[0]);
        assert_eq!(1, zero_div_one_remainder.parts.len());
        assert_eq!(1, zero_div_u32_max_remainder.parts.len());
        assert_eq!(1, zero_div_u32_max_remainder.parts.len());
        assert_eq!(0, zero_div_one_remainder.parts[0]);
        assert_eq!(0, zero_div_u32_max_remainder.parts[0]);
        assert_eq!(0, zero_div_many_parts_remainder.parts[0]);

        let (one_div_one, one_div_one_remainder) = one.div(&one);
        assert_eq!(1, one_div_one.parts.len());
        assert_eq!(1, one_div_one.parts[0]);
        assert_eq!(1, one_div_one_remainder.parts.len());
        assert_eq!(0, one_div_one_remainder.parts[0]);

        let (two_div_one, two_div_one_remainder) = two.div(&one);
        assert_eq!(1, two_div_one.parts.len());
        assert_eq!(2, two_div_one.parts[0]);
        assert_eq!(1, two_div_one_remainder.parts.len());
        assert_eq!(0, two_div_one_remainder.parts[0]);

        let (u32_max_div_one, u32_max_div_one_remainder) = u32_max.div(&one);
        assert_eq!(1, u32_max_div_one.parts.len());
        assert_eq!(u32::MAX, u32_max_div_one.parts[0]);
        assert_eq!(1, u32_max_div_one_remainder.parts.len());
        assert_eq!(0, u32_max_div_one_remainder.parts[0]);

        let (u32_max_div_two, u32_max_div_two_remainder) = u32_max.div(&two);
        assert_eq!(1, u32_max_div_two.parts.len());
        assert_eq!(u32::MAX / 2, u32_max_div_two.parts[0]);
        assert_eq!(1, u32_max_div_two_remainder.parts.len());
        assert_eq!(1, u32_max_div_two_remainder.parts[0]);

        let (two_to_the_32_div_two, two_to_the_32_div_two_remainder) = BigInt{parts: vec![0,1]}.div(&two);
        assert_eq!(1, two_to_the_32_div_two.parts.len());
        assert_eq!(u32::MAX - u32::MAX/2, two_to_the_32_div_two.parts[0]);
        assert_eq!(1, two_to_the_32_div_two_remainder.parts.len());
        assert_eq!(0, two_to_the_32_div_two_remainder.parts[0]);

        let (two_to_128_plus_one_div_two_to_32, two_to_128_plus_one_div_two_to_32_remainder) =
            BigInt{parts: vec![1,0,0,0,1]}.div(&BigInt{parts: vec![0,1]});
        assert_eq!(4, two_to_128_plus_one_div_two_to_32.parts.len());
        assert_eq!(0, two_to_128_plus_one_div_two_to_32.parts[0]);
        assert_eq!(0, two_to_128_plus_one_div_two_to_32.parts[1]);
        assert_eq!(0, two_to_128_plus_one_div_two_to_32.parts[2]);
        assert_eq!(1, two_to_128_plus_one_div_two_to_32.parts[3]);
        assert_eq!(1, two_to_128_plus_one_div_two_to_32_remainder.parts.len());
        assert_eq!(1, two_to_128_plus_one_div_two_to_32_remainder.parts[0]);

        let (rnd_div_res, rnd_div_rem) =
            BigInt{parts: vec![1,2,3]}.div(&BigInt{parts: vec![32, (1<<12) + (1<<30) + (1<<19)]});
        assert_eq!(1, rnd_div_res.parts.len());
        assert_eq!(11, rnd_div_res.parts[0]);
        assert_eq!(2, rnd_div_rem.parts.len());
        assert_eq!(4294966945, rnd_div_rem.parts[0]);
        assert_eq!(1067929601, rnd_div_rem.parts[1]);

        fuzzy_tests();

        let str = String::from("Elias");

        let (e,d,n) = generate_key();
        let encrypted = crypt_str(&str,&e,&n);
        let decrypted = crypt(&encrypted,&d,&n);
        let decrypted = BigInt::a7_u32_vec_to_string(&decrypted.parts);
        assert_eq!(decrypted, str);
    }

}