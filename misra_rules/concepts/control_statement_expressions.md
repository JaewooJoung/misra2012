# Control statement expressions and loop counters (background for Rules 14.x)

8.14 Control statement expressions
The term loop counter is used by some of the rules in this section. A loop counter is defined as an object, array element or member of a structure or union which satisfies the following:
1.	It has a scalar type;
2.	Its value varies monotonically on each iteration of a given instance of a loop; and
3.	It is involved in a decision to exit the loop.
Note: the second condition means that the value of the loop counter must change on each iteration of the loop and it must always change in the same direction for a given instance of the loop. It may, however, change in different directions on different instances, for example sometimes reading the elements of an array backwards and sometimes reading them forwards.
According to this definition, a loop need not have just one loop counter: it is possible for a loop to have no loop counter or to have more than one. See Rule 14.2 for further restrictions on loop counters in for loops.
The following code fragments show examples of loops and their corresponding loop counters.
In this loop, i is a loop counter because it has a scalar type, varies monotonically (increasing) and is involved in the loop termination condition.
for ( uint16_t i = 0; a[ i ] < 10; ++i ) {
}
The following loop has no loop counter. The object count has scalar type and varies monotonically but is not involved in the termination condition.
extern volatile bool_t b; uint16_t  count = 0;
while ( b ) {   count = count + 1U; }
In the following code, both i and sum are scalar and monotonically varying (decreasing and increasing respectively). However sum is not a loop counter because it is not involved in the decision to exit the loop.
uint16_t sum = 0;
for ( uint16_t i = 10U; i != 0U; --i ) {   sum += i; }
In the following loop, p is a loop counter. It is not involved in the loop control expression but it is involved in a decision to exit the loop by means of the break statement.
extern volatile bool_t b; extern char *p;
do {   if ( *p == '\0' )   {     break;   }
  ++p;
} while ( b );
The loop counter in the following example is p->count.
struct s {   uint16_t count;   uint16_t a[ 10 ]; }; extern struct s *p;
for ( p->count = 0U; p->count < 10U; ++( p->count ) ) {   p->a[ p->count ] = 0U;
}
