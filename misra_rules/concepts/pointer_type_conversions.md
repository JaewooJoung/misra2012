# Pointer type conversions (background for Rules 11.x)

8.11 Pointer type conversions
Pointer types can be classified as follows:
•	Pointer to object;
•	Pointer to function;
•	Pointer to incomplete;
•	Pointer to void;
•	A null pointer constant, i.e. the value 0, optionally cast to void *.
The only conversions involving pointers that are permitted by The Standard are:
•	A conversion from a pointer type into void;
•	A conversion from a pointer type into an arithmetic type;
•	A conversion from an arithmetic type into a pointer type;
•	A conversion from one pointer type into another pointer type.
Although permitted by the language constraints, conversion between pointers and any arithmetic types other than integer types is undefined.
The following permitted pointer conversions do not require an explicit cast:
•	A conversion from a pointer type into _Bool (C99 only);
•	A conversion from a null pointer constant into a pointer type;
•	A conversion from a pointer type into a compatible pointer type provided that the destination type has all the type qualifiers of the source type;
•	A conversion between a pointer to an object or incomplete type and void *, or qualified version thereof, provided that the destination type has all the type qualifiers of the source type.
In C99, any implicit conversion that does not fall into this subset of pointer conversions violates a constraint (C99 Sections 6.5.4 and 6.5.16.1).
In C90, any implicit conversion that does not fall into this subset of pointer conversions leads to undefined behaviour (C90 Sections 6.3.4 and 6.3.16.1).
The conversion between pointer types and integer types is implementation-defined.
