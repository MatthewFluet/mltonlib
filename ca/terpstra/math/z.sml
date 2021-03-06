structure Z    = EuclideanDomainOfInteger(LargeInt)
structure Zint = EuclideanDomainOfInteger(Int)

(* these are vulnerable to overflow *)
structure Z64 = EuclideanDomainOfInteger(Int64)
structure Z32 = EuclideanDomainOfInteger(Int32)
structure Z16 = EuclideanDomainOfInteger(Int16)
structure Z8  = EuclideanDomainOfInteger(Int8)

(* these type all wrap around modulo 2^b *)
structure Zword = EuclideanDomainOfWord(Word)
structure Z64 = EuclideanDomainOfWord(Word64)
structure Z32 = EuclideanDomainOfWord(Word32)
structure Z16 = EuclideanDomainOfWord(Word6)
structure Z8  = EuclideanDomainOfWord(Word8)
