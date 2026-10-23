# Glossary (Appendix J)

Assigned
An expression is assigned if it is the subject  of an assignment.
Assignment
It is sometimes convenient to use the term  assignment to denote any operation which takes place as if it were by assignment. The operations covered by this term are:
•	Assignment by means of one of the assignment operators;
•	Passing an argument to a function, in which case the argument is copied as if by assignment to the corresponding parameter;
•	Returning an expression from a function, in which case the result is copied as if by assignment to an object with the function’s return type;
•	Using an expression to initialize all or part of an object, including a compound literal in C99, in which case the expression is copied as if by assignment to the destination.
Code
Code consists of everything within a translation unit that is not excluded by conditional compilation.
Dead code
Any operation whose result does not affect the program’s behaviour is dead code.
Note: initialization is not the same as an assignment operation and is therefore not a candidate for dead code.
Examples of dead code include:
•	Storing values into non-volatile objects that are never subsequently used;
•	An expression statement that does not assign a value to an object.
The following are never dead code:
•	Accessing a volatile object;
•	Using a language extension.
Since the time at which actions occur is often an important aspect of the behaviour of an embedded program, it follows that code whose effect is to insert a delay is not dead code. However, any such code is very likely to be written with reference to timer hardware and will therefore involve volatile object accesses in any event. For example:
extern const volatile uint16_t MILLISEC_TIMER;
void delay_ms ( uint16_t n ) {   uint16_t  start_time = MILLISEC_TIMER;
  while ( ( MILLISEC_TIMER - start_time ) < n )   {
    /* wait */
  }
}
External identifier
An external identifier is an identifier with external linkage and must therefore denote either an object or a function.
Header file
A header file is any file that is the subject of a #include directive.
Note: the filename extension is not significant.
Inline function
An inline function is one that is declared with the inline function specifier.
Loop counter
A loop  counter is defined in Section 8.14 .
Macro identifier
A macro identifier is an identifier that is either a macro name or a macro parameter.
Opaque type
A type whose implementation detail is not made available to its users.
Persistent side effect
A side effect is said to be persistent at a particular point in execution if it might have an effect on the execution state at that point. All of the following side effects are persistent at a given point in the program:
•	Modifying a file;
•	Modifying an object;
•	Accessing a volatile object.
When a function is called, it may have side effects. Modifying a file or accessing a volatile object are persistent as viewed by the calling function. However any objects modified by the called function, whose lifetimes have ended by the time it returns, do not affect the caller’s execution state. Any side effects arising from modifying such objects are not persistent as viewed by the caller.
For example:
uint16_t f ( void ) {   uint16_t  temp = 1;           /* Side effect of modifying temp is not                                  * persistent to the caller */
  return ( temp ); } x = f ( );
Project
A project consists of the code from the set of translation units used to build a single executable. A typical embedded controller might consist of several logically distinct projects, for example:
•	Primary bootloader; • 	Secondary bootloader;
•	Main application.
Prototype form
A function type is said to be in prototype form if it includes a prototype, i.e. it specifies a list of parameter types and, optionally, names. For example, the following are all in prototype form:
void  f ( void );            /* Prototype specifying no parameters      */ void  g ( int16_t, char );   /* Prototype specifying types but no names */ void  h ( uint32_t n );      /* Prototype specifying type and name      */
The following are not in prototype form:
void      f ( );                /* No information about parameters      */
void g ( x, y )                 /* Function definition "K&R"-style      */ int16_t x; char y; {
}
Standard type
The standard type of an expression is its type as determined according to The Standard.
Unreachable code
Code is unreachable if, in the absence of hardware failures and ignoring the effects of undefined behaviour, there is no combination of program inputs that can cause it to be executed.
Unreachable code may result from the structure of the program’s control flow graph. For example, any code following a return statement is unreachable and some operands of logical or conditional operators may be unreachable:
uint16_t  y;
uint16_t f ( void ) {   uint16_t  x;
  return true ? y : ( y + 1U );    /* y + 1 is never executed     */   x = 10U;                         /* statement is never executed */
}
Unreachable code may also result when there is a control flow path to a statement but that path can never be followed, for example:
uint16_t  x, y;
switch ( 2u * x ) { case 0:   y = 10u;   break; case 1:   y = 0u;   /* unreachable: 2 * x can never be odd */   break;
case 2:   y = x;   break; default:   break; }
Used
An expression is said to be used if it appears in one of the following contexts:
•	The operand of an operator, including a parameter of a function call operator;
•	The controlling expression of an if, while, for, do … while, or switch statement;
•	The value  returned by a return statement;
•	An initializer.
This term should not be confused with reading the value of an object, for example:
uint16_t  x = 3; uint16_t *p = &x;               /* x is used but not read */ return *p;                      /* x is read but not used */
