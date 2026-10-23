# Essential type model (used by Rules 10.x, 14.x, 16.7, 20.8 and others)

8.10 The essential type model
8.10.1 Rationale
The rules in this section collec tively define the essential type model and restrict the C type system so as to:
1.	Support a stronger system of type-checking;
2.	Provide a rational basis for defining rules to control the use of implicit and explicit type conversions;
3.	Promote portable coding practices;
4.	Address some of the type conversion anomalies found within ISO C.
The essential type model does this by allocating an essential type to those objects and expressions which ISO C considers to be of arithmetic type. For example, adding an int to a char gives a result having essentially character type rather than the int type that is actually produced by integer promotion.
The full rationale behind the essential type model is given in Appendix C with Appendix D providing a comprehensive definition of the essential type of any arithmetic expression.
8.10.2 Essential type
The essential type of an object or expression is defined by its essential type category and size.
The essential type category of an expression reflects its underlying behaviour and may be:
•	Essentially Boolean;
•	Essentially character;
•	Essentially enum;
•	Essentially signed;
•	Essentially unsigned;
•	Essentially floating.
Note: each enumerated type is a unique essentially enum type identified as enum<i>. This allows different enumerated types to be handled as distinct types, which supports a stronger system of type-checking. One exception is the use of an enumerated type to define a Boolean value in C90. Such types are considered to have essentially Boolean type. Another exception is the use of anonymous enumerations as defined in Appendix D. Anonymous enumerations are a way of defining a set of related constant integers and are considered to have an essentially signed type.
When comparing two types of the same type category, the terms wider and narrower are used to describe their relative sizes as measured in bytes. Two different types are sometimes implemented with the same size.
The following table shows how the standard integer types map on to essential type categories.
		Essential type category
Boolean	character	signed	unsigned	enum<i>	floating
_Bool	char	signed char signed short signed int signed long signed long long	unsigned char unsigned short unsigned int unsigned long unsigned long long	named enum	float
double long double
Note: C99 implementations may provide extended integer types each of which would be allocated a location appropriate to its rank and signedness (see C99 Section 6.3.1.1).
The restrictions enforced by the rules in this section also apply to the compound assignment operators (e.g. ^=) as these are equivalent to assigning the result obtained from the use of one of the arithmetic, bitwise or shift operators. For example: u8a += u8b + 1U;
is equivalent to:
u8a = u8a + ( u8b + 1U );


8.10.3 Composite operators and expressions
Some of the concerns mentioned in Appendix C can be avoided by restricting the implicit and explicit conversions that may be applied to non-trivial expressions. These include:
•	The confusion about the type in which integer expressions are evaluated, as this depends on the type of the operands after any integer promotion. The type of the result of an arithmetic operation depends on the implemented size of int;
•	The common misconception among programmers that the type in which a calculation is conducted is influenced by the type to which the result is assigned or cast. This false expectation may lead to unintended results.
In addition to the previous rules, the essential type model places further restrictions on expressions whose operands are composite expressions, as defined below.
The following are defined as composite operators in this document:
•	Multiplicative (*, /, %)
•	Additive (binary +, binary -)
•	Bitwise (&, |, ^)
•	Shift (<<, >>)
•	Conditional (?:) if either the second or third operand is a composite expression
A compound assignment is equivalent to an assignment of the result of its corresponding composite operator.
A composite expression is defined in this document as a non-constant expression which is the direct result of a composite operator.
Note:
•	The result of a compound assignment operator is not a composite expression; • 	A parenthesized composite expression is also a composite expression;
•	A constant expression is not a composite expression.



