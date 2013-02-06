grammar OSQL;

options {
    language = Java;
}

//-----------------------------------------------------------------//
// LEXER
//-----------------------------------------------------------------//


// KEYWORDS -------------------------------------------
SELECT : S E L E C T ;
INSERT : I N S E R T ;
UPDATE : U P D A T E ;
DELETE : D E L E T E ;
FROM : F R O M ;
WHERE : W H E R E ;
INTO : I N T O ;
VALUES : V A L U E S ;
SET : S E T ;
ADD : A D D ;
REMOVE : R E M O V E ;
AND : A N D ;
OR : O R ;
ORDER : O R D E R ;
BY : B Y ;
LIMIT : L I M I T ;
RANGE : R A N G E ;
ASC : A S C ;
AS : A S;
DESC : D E S C ;
OTHIS : '@' T H I S ;
ORID_ATTR: '@' R I D ;
OCLASS_ATTR: '@' C L A S S ;
OVERSION_ATTR: '@' V E R S I O N ;
OSIZE_ATTR: '@' S I Z E ;
OTYPE_ATTR: '@' T Y P E ;
CLUSTER : C L U S T E R ;
INDEX : I N D E X ;
DICTIONARY : D I C T I O N A R Y ;
ALTER : A L T E R ;
CLASS : C L A S S ;
SKIP : S K I P;
IN : I N ;
IS : I S ;
NOT : N O T ;
GROUP : G R O U P ;


// GLOBAL STUFF ---------------------------------------
COMMA 	: ',';
DOUBLEDOT 	: ':';
DOT 	: '.';
WS  :   ( ' ' | '\t' | '\r'| '\n' ) -> skip ;
UNARY : '+' | '-' ;
MULT : '*' | '/' ;
EQUALS : '=' ;
fragment DIGIT : '0'..'9' ;
    
// case insensitive
fragment A: ('a'|'A');
fragment B: ('b'|'B');
fragment C: ('c'|'C');
fragment D: ('d'|'D');
fragment E: ('e'|'E');
fragment F: ('f'|'F');
fragment G: ('g'|'G');
fragment H: ('h'|'H');
fragment I: ('i'|'I');
fragment J: ('j'|'J');
fragment K: ('k'|'K');
fragment L: ('l'|'L');
fragment M: ('m'|'M');
fragment N: ('n'|'N');
fragment O: ('o'|'O');
fragment P: ('p'|'P');
fragment Q: ('q'|'Q');
fragment R: ('r'|'R');
fragment S: ('s'|'S');
fragment T: ('t'|'T');
fragment U: ('u'|'U');
fragment V: ('v'|'V');
fragment W: ('w'|'W');
fragment X: ('x'|'X');
fragment Y: ('y'|'Y');
fragment Z: ('z'|'Z');
fragment LETTER : ~('0'..'9' | ' ' | '\t' | '\r'| '\n' | ',' | '-' | '+' | '*' | '/' | '(' | ')' | '{' | '}' | '[' | ']'| '=' | '.'| ':' | '#');

LPAREN : '(';
RPAREN : ')';
LBRACKET : '[';
RBRACKET : ']';
LACCOLADE : '{';
RACCOLADE : '}';
    

//LITERALS  ----------------------------------------------

UNSET : '?';
NULL : N U L L ;
IDENTIFIER : '#';

TEXT : ('\'' ( ESC_SEQ | '\'\'' | ~('\\'|'\'') )* '\'') 
     | ('"'  ( ESC_SEQ | ~('\\'|'"' ) )* '"' );

INT : DIGIT+ ;
FLOAT
    :   ('0'..'9')+ '.' ('0'..'9')* EXPONENT? ('d'|'f')?
    |   '.' ('0'..'9')+ EXPONENT? ('d'|'f')?
    |   ('0'..'9')+ EXPONENT ('d'|'f')?
    | INT ('d'|'f')
    ;

WORD : LETTER (DIGIT|LETTER)* ;




// FRAGMENT -------------------------------------------

fragment EXPONENT : ('e'|'E') ('+'|'-')? ('0'..'9')+ ;
fragment HEX_DIGIT : ('0'..'9'|'a'..'f'|'A'..'F') ;

fragment
ESC_SEQ
    :   '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\')
    |   UNICODE_ESC
    |   OCTAL_ESC
    ;

fragment
OCTAL_ESC
    :   '\\' ('0'..'3') ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7')
    ;

fragment
UNICODE_ESC
    :   '\\' 'u' HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT
    ;
    
 
    
    
//-----------------------------------------------------------------//
// PARSER
//-----------------------------------------------------------------//
    
word        : WORD ;
identifier  : IDENTIFIER INT ':' INT;
unset       : UNSET;
number    	: (UNARY^)? (INT|FLOAT)	;
map         : LACCOLADE (literal DOUBLEDOT expression (COMMA literal DOUBLEDOT expression)*)? RACCOLADE ;
collection  : LBRACKET (expression (COMMA expression)*)? RBRACKET ;
literal	
  : NULL
  | TEXT
	| number
	;

arguments   : LPAREN (expression (COMMA expression)*)? RPAREN ;
functionCall: word arguments ;
methodCall  : DOT word arguments* ;

expression
  : literal
  | map
  | collection
  | identifier
  | unset
  | word
  | LPAREN expression RPAREN
  | functionCall
  | expression methodCall
  ;

filterAnd : AND filter ;
filterOr : OR filter ;
filter
  : expression
  | LPAREN filter RPAREN
  | filter filterAnd
  | filter filterOr
  | NOT filter
  | filter EQUALS filter
  | filter IS NULL
  | filter IS NOT NULL
  ;

// COMMANDS

commandUnknowned : expression (expression)* ;

commandInsertIntoByValues
  : INSERT INTO ((CLUSTER|INDEX) DOUBLEDOT)? word insertCluster? insertFields VALUES insertEntry (COMMA insertEntry)*
  ;
commandInsertIntoBySet
  : INSERT INTO ((CLUSTER|INDEX) DOUBLEDOT)? word insertCluster? SET insertSet (COMMA insertSet)*
  ;
insertCluster : CLUSTER word ;
insertEntry   : LPAREN expression (COMMA expression)* RPAREN ;
insertSet     : word EQUALS expression ;
insertFields  : LPAREN word(COMMA word)* RPAREN ;

commandAlterClass : ALTER CLASS word word (cword|NULL) ;
cword             : (word|literal|COMMA) (word|literal|COMMA)* ;

commandSelect
  : SELECT (projection)* from (WHERE filter)? groupBy? orderBy? skip? limit?
  ;
projection
  : ( word
    | ORID_ATTR
    | OCLASS_ATTR
    | OVERSION_ATTR
    | OSIZE_ATTR
    | OTYPE_ATTR ) 
    (alias)?
  ;
alias          : AS word ;
from           
  : FROM 
    ( ((CLUSTER|INDEX|DICTIONARY) DOUBLEDOT)? word
    | identifier
    | collection ) 
  ;
groupBy        : GROUP BY word ;
orderBy        : ORDER BY orderByElement (COMMA orderByElement)* ;
orderByElement : word (ASC|DESC)? ;
skip           : SKIP INT ;
limit          : LIMIT INT ;

command
	: commandUnknowned
  | commandAlterClass
  | commandInsertIntoByValues
  | commandInsertIntoBySet
  | commandSelect
  ;