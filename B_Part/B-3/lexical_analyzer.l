/* File name:           simple-flex-code.l
   Description:         Lexical analyzer using Flex tool
   Authors:             Dimitrios Kontoulis(21390095),Aggelos Konstantinos Mentzelos(21390132),
                        Efrsosini Barsou(21390021),Enterisa Gkiozi(21390041),Leonidas Alexopoulos(21390006)
                        Compilers Lab, Department of Informatics and Computer Engineering,
                        University of West Attica
   Comments:            The current program implements (using flex) a simple lexical analyzer
                        recognizing spaces (space and tab), operators, identifiers, comments, strings,
                        integers, floats, octals and hexadecimal numbers for the Uni-C language
                        while handling the special characters of new line '\n' and 'EOF'. The lexical
                        analyzer accepts input and output file arguments.
Execution instructions: Give "make" without quotes in the current directory. Alternatively:
                        flex -o lexical_analyzer.c lexical_analyzer.l
                        gcc -o lexical_analyzer lexical_analyzer.c
                        ./lexical_analyzer input.txt output.txt
*/

/* The lexer can only read from one file and terminates at the first EOF */
%option noyywrap

/* The following C code is for the definition of the required header files and variables.
   Anything between %{ and %} is transferred as is to the C file that Flex will create. */

%{
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    /* Header file containing all the required tokens */
    #include "syntax_analyzer.tab.h"  // Include the Bison header
    void handle_comment(); // definition of function to handle multiline comments

    int line = 1; // Current line counter
    int lex_warn = 0; // Counter for the number of characters ignored
    int cor_words = 0; // Counter for the number of correct words
    int inc_words = 0; // Counter for the number of incorrect words

%}

/* Below are the names and the corresponding regular expression for each token.
   With the use of names we can make it easier to use these regular expressions,
   instead of having to write them all the time, making the program confusing. */
DELIMITER         ;
SYMBOL            ,
INTEGER           ([1-9][0-9]*|0)|(0[xX][0-9A-F]+)|(0[0-7]+)
FLOAT             (([1-9][0-9]*|0)(\.[0-9]+)?([eE][-]?([1-9][0-9]*|0))?)
IDENTIFIERS       [a-zA-Z_]+[a-zA-Z_0-9]*
STRINGS           \"(\\[\\n\"]|[^\n\\\"])*\"
LINE_COMMENT      \/\/.*
OPERATORS         ([\+\-\*\/\=\!\<\>]=)|[\*\/\=\!\<\>%]|&{1,2}|\-{1,2}|\+{1,2}|(\|\|)
KEYWORDS          scan|len|cmp|print|break|case|func|const|continue|do|double|else|float|for|if|int|long|return|short|sizeof|struct|switch|void|while
OPEN_BRACKET      \{
CLOSE_BRACKET     \}
OPEN_PARENTHESIS  \(
CLOSE_PARENTHESIS \)
OPEN_BRACE        \[
CLOSE_BRACE       \]
WHITESPACE        [ \t]+
%x REALLYEND error

/* For each pattern on the left that matches, the corresponding code inside the braces is executed.
   The return command allows the return of a numerical value through the yylex() function,
   allowing us to return numerican values that we have defined in the token.h file. */

%%
"/*"                { handle_comment(); }
{LINE_COMMENT}      { /* ignore line comments */ }
{DELIMITER}         { cor_words++; return DELIMITER; }
{INTEGER}           { cor_words++; return INTEGER;}
{FLOAT}             { cor_words++; return FLOAT;}
{STRINGS}           { cor_words++; return STRINGS;}
{WHITESPACE}        { /* don't return anything */ }
{OPERATORS}         { cor_words++; return OPERATORS;}
{KEYWORDS}          { cor_words++; return KEYWORD;}
{IDENTIFIERS}       { cor_words++; return IDENTIFIERS;}
{OPEN_BRACKET}      { cor_words++; return OPEN_BRACKET; }
{CLOSE_BRACKET}     { cor_words++; return CLOSE_BRACKET; }
{OPEN_PARENTHESIS}  { cor_words++; return OPEN_PARENTHESIS; }
{CLOSE_PARENTHESIS} { cor_words++; return CLOSE_PARENTHESIS; }
{OPEN_BRACE}        { cor_words++; return OPEN_BRACE; }
{CLOSE_BRACE}       { cor_words++; return CLOSE_BRACE; }
{SYMBOL}            { cor_words++; return SYMBOL; }
\n                  { line++; return END; }
.                   { inc_words++ ;printf ("Unrecognized character(s) encountered!\n"); lex_warn++; BEGIN(error); return UNKNOWN_TOKEN;}
<error>[ \t]+       { BEGIN(0); printf("\t\t%d character(s) ignored so far \n",lex_warn); }
<error>.            { lex_warn++;}
<error>\n           { BEGIN(0); printf("\t\t%d character(s) ignored so far \n",lex_warn ); line++;  return END; }

<INITIAL><<EOF>>    { BEGIN(REALLYEND); printf("#END-OF-FILE#\n"); return EOP; }
<REALLYEND><<EOF>>  { yyterminate();}

%%

/* Inside the brackets of the <<INITIAL>> label, we are executing some code */
/*   by giving a specific token to Bison. That way we don't actually end the program, */
/*   instead, we manage to return the EOP token to Bison, that we are later going to use */
/*  in the syntax analyzer to print a report regarding correct/incorrect words and expressions. */
   
/* After the above block of code has been executed, we really end the program */
/* by calling yyterminate() (hence the REALLYEND label). So, after printing the report, */
/* we are completely terminating the program. */

// Implementation of function that handles multi-line comments
void handle_comment()
{
    /* while character read is not '*' (indicating comment end) or EOF
         this loop basically eats up the text inside the comment. */
    register int c;
    for (;;)
    {
        while ((c = input()) != '*' && c != 0)
            if (c == '\n') line++;
        // if there is a '*' found, indicating (possibly) the end of the comment
        if (c == '*')
        {
            /* the loop below detects if there are many
            '*' symbols in a row, basically skipping them
            and not regarding them as the end of the comment. */
            while ((c = input()) == '*'); 
            if (c == '/') break; // found the end of the comment.
        }
        // if there is EOF contained in the multiple line comment
        if (c == 0)
        {
            printf("Error: EOF in comment.\n");
            break;
        }
    }
}