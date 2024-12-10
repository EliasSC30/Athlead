pub mod encryption
{
    use std::fmt;
    use std::mem::swap;

    pub struct BigInt {
        pub parts: Vec<u32>
    }

    impl Clone for BigInt {
        fn clone(&self) -> Self { BigInt { parts: self.parts.clone() } }
    }

    impl fmt::Display for BigInt {
        fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
            for &num in self.parts.iter() {
                write!(f, "|").expect("TODO: panic message");
                // Extract each byte of the u32 using bit shifting and masking
                write!(f, "{:?}.", (num & 0xFF) as u8).expect("TODO: panic message");          // least significant byte
                write!(f, "{:?}.", ((num >> 8) & 0xFF) as u8).expect("TODO: panic message");  // second byte
                write!(f, "{:?}.", ((num >> 16) & 0xFF) as u8).expect("TODO: panic message"); // third byte
                write!(f, "{:?}", (num >> 24) as u8).expect("TODO: panic message"); // most significant byte
                write!(f, "|").expect("TODO: panic message");
            }

            write!(f, "")
        }
    }

    pub fn add_with_carry(a:u32, b:u32) -> (u32, u32)
    {
        // This is a+b = Max + carry <=> carry = a - (Max - b) to get the carry, if there is any
        if (u32::MAX - b) > a { (a+b,0) } else { (a.wrapping_add(b), 1) }
    }

    impl BigInt {
        pub fn new(parts_to_take_over: Vec<u32>) -> BigInt { BigInt { parts: parts_to_take_over } }

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

        pub fn is_odd(&self) -> bool { (self.parts[0] & 1) == 1 }

        fn shrink_to_highest_power(&mut self) {
            let mut nr_of_parts_to_remove = 0;
            for index in (0..self.parts.len()).rev() {
                if self.parts[index] == 0u32 {nr_of_parts_to_remove +=1;} else {break;};
            }

            self.parts.truncate(self.parts.len() - nr_of_parts_to_remove);
        }

        fn padd_n_zeros(&mut self, n: usize) { for _ in 0..n {self.parts.push(0u32);} }

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


            let mut return_value = vec![0u32; this_highest_power+other_highest_power+1];
            let mut carry = 0u32;

            for outer_index in 0..this_highest_power+1
            {
                let part = self.parts[outer_index];
                for inner_index in 0..other_highest_power+1
                {
                    let cur_index = outer_index + inner_index;
                    let (mul_r, mul_c) = Self::mul_with_carry(part, other.parts[inner_index]);
                    let (add_r, add_c) = Self::add_with_carry(return_value[cur_index], carry);

                    let (add_to_return_value_r, add_to_return_value_c) = Self::add_with_carry(add_r, mul_r);

                    return_value[cur_index] = add_to_return_value_r;
                    let final_add_carry = if add_to_return_value_c != 0 || add_c != 0 { 1 } else { 0 };
                    carry = mul_c + final_add_carry;
                }
            }

            if carry != 0 {
                return_value.push(0u32);
                return_value[other_highest_power+this_highest_power+1] += carry;
            }

            BigInt{parts: return_value}
        }

        // We are computing self/other = (whole_result, remainder)
        pub fn div(&mut self, other: &mut BigInt) -> (BigInt, BigInt)
        {
            self.shrink_to_highest_power();
            other.shrink_to_highest_power();

            // If self is smaller than other the result is simply (0,self)
            if self.compare(&other) < 0 {
                return (BigInt{parts: vec![0u32]}, self.clone());
            };

            let (this_highest_power, other_highest_power) = (Self::find_highest_power(&self.parts), Self::find_highest_power(&other.parts));

            let mut guess = BigInt {
                parts: vec![u32::MAX; this_highest_power - other_highest_power + 1]
            }
                .half()
                .add(&Self::one());
            guess = guess;
            let mut adder = guess.half();

            let mut guess_times_other = other.mul(&guess);

            let a = guess_times_other.parts[0];

            while Self::power_difference(self, &guess_times_other) != 0 ||
                self.parts[this_highest_power] > guess_times_other.parts[other_highest_power]
            {
                if self.compare(&guess_times_other) < 0 {
                    guess = guess.add(&adder);
                } else {
                    guess = guess.sub(&adder).unwrap();
                }

                let was_odd = adder.is_odd();
                adder = adder.half();
                if was_odd { adder.add(&Self::one());};

                guess_times_other = guess.mul(&other);
            }


            (guess, self.clone())
        }

        pub fn add(&self, other: &BigInt) -> BigInt
        {
            let this_highest_power = Self::find_highest_power(&self.parts);
            let other_highest_power = Self::find_highest_power(&other.parts);
            let bigger_size = if other_highest_power > this_highest_power {other_highest_power} else {this_highest_power};
            let smaller_size = if other_highest_power <= this_highest_power {other_highest_power} else {this_highest_power};

            let mut return_value = vec![0u32;bigger_size+1];
            let mut carry = 0u32;

            for index in 0..smaller_size+1
            {
                let a = self.parts[index];
                let b = other.parts[index];

                let (a_plus_b_wrapped, a_plus_b_carry) = Self::add_with_carry(a, b);
                let (a_plus_b_plus_carry_wrapped, final_carry) = Self::add_with_carry(a_plus_b_wrapped, carry);

                return_value[index] = a_plus_b_plus_carry_wrapped;
                carry = if a_plus_b_carry != 0 || final_carry != 0 { 1 } else { 0 };
            }

            for index in smaller_size+1..bigger_size
            {
                let a = self.parts[index];

                let (a_plus_carry, a_plus_carry_carry) = Self::add_with_carry(a, carry);

                return_value[index] = a_plus_carry;
                carry = if a_plus_carry_carry != 0 { 1 } else { 0 };
            }

            if carry != 0u32 { return_value.push(1); };

            BigInt{parts: return_value}
        }

        pub fn sub(&self, other: &BigInt) -> Result<BigInt, &'static str>
        {
            if self.compare(other) < 0 { return Err("Only unsigned integers are supported"); };
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
    pub fn generate_key() -> (u128, u128, u128)
    {
        let p = 1708023547; // GPT...
        let q = 7260931823; // GPT...

        let n = p*q;
        let phi_n = (p-1u128) * (q -1u128);

        let e = 1099511627791;

        let gcd = gcd(e, phi_n);

        (e, gcd.1, n)
    }

    // Solving for gcd(a,b) = s*a + t*b
    fn gcd(a: u128, b: u128) -> (u128,u128,u128)
    {
        let mut r_0 = a;
        let mut r_1 = b;
        let mut s_0 = 1;
        let mut s_1 = 0;
        let mut t_0 = 0;
        let mut t_1 = 1;

        let mut n = 0u32;
        while r_1 > 0u128
        {
            let q = r_0 / r_1;
            r_0 = if r_0 > q*r_1 { r_0-q*r_1 } else { q*r_1-r_0 };
            swap(&mut r_0, &mut r_1);
            s_0 = s_0+q*s_1;
            swap(&mut s_0, &mut s_1);
            t_0 = t_0+q*t_1;
            swap(&mut t_0, &mut t_1);
            n += 1;
        }
        if (n%2) != 0 {s_0 = b-s_0;} else {t_0 = a-t_0;};

        (r_0, s_0, t_0)
    }

    // Solving c = m ^ d mod n
    // and m = c ^ e mod n
    pub fn crypt(m: u128, d:u128, n: u128) -> u128
    {
        let mut intermediate = m % n;
        let mut total_remainder = 1u128;

        let highest_bit_pos_of_d = highest_bit_pos(d);

        for i in 0..=highest_bit_pos_of_d
        {
            total_remainder *= if get_nth_bit(d, i) {intermediate} else {1};
            total_remainder = total_remainder % n;

            intermediate = (intermediate * intermediate) % n;
        }

        total_remainder
    }


    pub fn crypt_many(ms: Vec<u128>, d_or_e : u128, n: u128) -> Vec<u128>
    {
        ms.iter().map(|m| crypt(*m, d_or_e, n)).collect()
    }

    fn array_to_u64(bytes: [u8; 8]) -> u64 {
        let mut result = 0u64;
        for &byte in &bytes {
            result = (result << 8) | u64::from(byte);
        }
        result
    }

    // For now, we only have 128bit and the algorithm needs to be able to square the value.., ie 8 u8-characters
    pub fn crypt_arr(string: &[u8; 8], d_or_e : u128, n: u128) -> [u8;8]
    {
        assert!(string.len() <= 8, "Before we have a bigint lib we are limited to 16 character");

        let cryptable_format = array_to_u64(string.clone()); // 128 bits

        let encrypted = crypt(cryptable_format as u128, d_or_e, n);

        (encrypted as u64).to_be_bytes()
    }

    // For now, we only have 128bit and the algorithm needs to be able to square the value.., ie 8 u8-characters
    pub fn crypt_str(string: &String, d_or_e : u128, n: u128) -> [u8;8]
    {
        assert_eq!(string.len(), 8, "Before we have a bigint lib we are limited to 8 character");

        let converted: [u8;8] = string.clone().as_bytes().try_into().unwrap();

        crypt_arr(&converted, d_or_e, n)
    }

    fn highest_bit_pos(n: u128) -> u32 {
        128 - n.leading_zeros() - 1
    }

    fn get_nth_bit(d: u128, n: u32) -> bool
    {
        (d & (1u128 << n)) == (1u128 << n)
    }

    pub fn hash(to_hash: &[u8;8]) -> u64
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

}