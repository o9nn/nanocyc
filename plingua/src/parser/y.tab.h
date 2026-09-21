/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_YY_SRC_PARSER_Y_TAB_H_INCLUDED
# define YY_YY_SRC_PARSER_Y_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    MODEL = 258,                   /* MODEL  */
    ASIG = 259,                    /* ASIG  */
    SEPARATOR = 260,               /* SEPARATOR  */
    ID = 261,                      /* ID  */
    LESS_THAN = 262,               /* LESS_THAN  */
    GREATER_THAN = 263,            /* GREATER_THAN  */
    DEF = 264,                     /* DEF  */
    LPAR = 265,                    /* LPAR  */
    RPAR = 266,                    /* RPAR  */
    LBRACE = 267,                  /* LBRACE  */
    RBRACE = 268,                  /* RBRACE  */
    LET = 269,                     /* LET  */
    SYMBOL = 270,                  /* SYMBOL  */
    COMMA = 271,                   /* COMMA  */
    NON_NEGATIVE_LONG = 272,       /* NON_NEGATIVE_LONG  */
    NON_NEGATIVE_DOUBLE = 273,     /* NON_NEGATIVE_DOUBLE  */
    DIFF = 274,                    /* DIFF  */
    SYSTEM = 275,                  /* SYSTEM  */
    PLUS = 276,                    /* PLUS  */
    MINUS = 277,                   /* MINUS  */
    MUL = 278,                     /* MUL  */
    DIV = 279,                     /* DIV  */
    MOD = 280,                     /* MOD  */
    COLON = 281,                   /* COLON  */
    LESS_OR_EQUAL_THAN = 282,      /* LESS_OR_EQUAL_THAN  */
    GREATER_OR_EQUAL_THAN = 283,   /* GREATER_OR_EQUAL_THAN  */
    CALL = 284,                    /* CALL  */
    LSQUARE = 285,                 /* LSQUARE  */
    RSQUARE = 286,                 /* RSQUARE  */
    QUOTE = 287,                   /* QUOTE  */
    MU = 288,                      /* MU  */
    EMPTY = 289,                   /* EMPTY  */
    MS = 290,                      /* MS  */
    LONG_RIGHT_ARROW = 291,        /* LONG_RIGHT_ARROW  */
    SHORT_RIGHT_ARROW = 292,       /* SHORT_RIGHT_ARROW  */
    DOUBLE_COLON = 293,            /* DOUBLE_COLON  */
    DISSOLUTION_SYMBOL = 294,      /* DISSOLUTION_SYMBOL  */
    LONG_DOUBLE_ARROW = 295,       /* LONG_DOUBLE_ARROW  */
    SHORT_DOUBLE_ARROW = 296,      /* SHORT_DOUBLE_ARROW  */
    EQUAL = 297,                   /* EQUAL  */
    AND = 298,                     /* AND  */
    OR = 299,                      /* OR  */
    NOT = 300,                     /* NOT  */
    LABELS = 301,                  /* LABELS  */
    FEATURE = 302,                 /* FEATURE  */
    EMU = 303,                     /* EMU  */
    PROB_TYPE = 304,               /* PROB_TYPE  */
    IF = 305,                      /* IF  */
    ELSE = 306,                    /* ELSE  */
    WHILE = 307,                   /* WHILE  */
    DO = 308,                      /* DO  */
    FOR = 309,                     /* FOR  */
    INC = 310,                     /* INC  */
    DEC = 311,                     /* DEC  */
    INC_BY = 312,                  /* INC_BY  */
    DEC_BY = 313,                  /* DEC_BY  */
    MUL_BY = 314,                  /* MUL_BY  */
    DIV_BY = 315,                  /* DIV_BY  */
    MOD_BY = 316,                  /* MOD_BY  */
    BITWISE_OR = 317,              /* BITWISE_OR  */
    BITWISE_AND = 318,             /* BITWISE_AND  */
    BITWISE_NOT = 319,             /* BITWISE_NOT  */
    BITWISE_LEFT = 320,            /* BITWISE_LEFT  */
    BITWISE_RIGHT = 321,           /* BITWISE_RIGHT  */
    BITWISE_XOR = 322,             /* BITWISE_XOR  */
    QUESTION_MARK = 323,           /* QUESTION_MARK  */
    BITWISE_LEFT_BY = 324,         /* BITWISE_LEFT_BY  */
    BITWISE_RIGHT_BY = 325,        /* BITWISE_RIGHT_BY  */
    STRING = 326,                  /* STRING  */
    AT_SYMBOL = 327,               /* AT_SYMBOL  */
    BITWISE_AND_BY = 328,          /* BITWISE_AND_BY  */
    BITWISE_OR_BY = 329,           /* BITWISE_OR_BY  */
    BITWISE_XOR_BY = 330,          /* BITWISE_XOR_BY  */
    RETURN = 331,                  /* RETURN  */
    INTEGER_LITERAL = 332,         /* INTEGER_LITERAL  */
    DOUBLE_LITERAL = 333,          /* DOUBLE_LITERAL  */
    STRING_LITERAL = 334,          /* STRING_LITERAL  */
    POST_INC = 335,                /* POST_INC  */
    POST_DEC = 336,                /* POST_DEC  */
    ADD = 337,                     /* ADD  */
    SUB = 338,                     /* SUB  */
    DEFINITIONS = 339,             /* DEFINITIONS  */
    ERROR = 340,                   /* ERROR  */
    MODULE = 341,                  /* MODULE  */
    VARIABLE = 342,                /* VARIABLE  */
    ARGUMENTS = 343,               /* ARGUMENTS  */
    PARAMETERS = 344,              /* PARAMETERS  */
    SENTENCES = 345,               /* SENTENCES  */
    INCLUDE = 346,                 /* INCLUDE  */
    RANGES = 347,                  /* RANGES  */
    RANGE = 348,                   /* RANGE  */
    RULE = 349,                    /* RULE  */
    INDEXES = 350,                 /* INDEXES  */
    MEMBRANES = 351,               /* MEMBRANES  */
    MEMBRANE = 352,                /* MEMBRANE  */
    CHARGE = 353,                  /* CHARGE  */
    LABEL = 354,                   /* LABEL  */
    MULTISET = 355,                /* MULTISET  */
    PATTERN = 356,                 /* PATTERN  */
    RULES = 357,                   /* RULES  */
    REXP_TYPE = 358,               /* REXP_TYPE  */
    PROBABILITY = 359,             /* PROBABILITY  */
    PRIORITY = 360,                /* PRIORITY  */
    PLINGUA = 361,                 /* PLINGUA  */
    ANONYMOUS_VARIABLE = 362,      /* ANONYMOUS_VARIABLE  */
    INT_TYPE = 363,                /* INT_TYPE  */
    LONG_TYPE = 364,               /* LONG_TYPE  */
    DOUBLE_TYPE = 365,             /* DOUBLE_TYPE  */
    STRING_TYPE = 366,             /* STRING_TYPE  */
    SYSTEM_CONSTANT = 367,         /* SYSTEM_CONSTANT  */
    MODEL_DEFINITION = 368,        /* MODEL_DEFINITION  */
    MODEL_BODY = 369,              /* MODEL_BODY  */
    MODEL_ELEMENT = 370,           /* MODEL_ELEMENT  */
    SYSTEM_CALL = 371,             /* SYSTEM_CALL  */
    INNER_MEMBRANE = 372,          /* INNER_MEMBRANE  */
    INNER_MEMBRANES = 373,         /* INNER_MEMBRANES  */
    OUTER_MEMBRANE = 374,          /* OUTER_MEMBRANE  */
    OUTER_MEMBRANES = 375,         /* OUTER_MEMBRANES  */
    RIGHT_HAND_RULE = 376,         /* RIGHT_HAND_RULE  */
    LEFT_HAND_RULE = 377           /* LEFT_HAND_RULE  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif
/* Token kinds.  */
#define YYEMPTY -2
#define YYEOF 0
#define YYerror 256
#define YYUNDEF 257
#define MODEL 258
#define ASIG 259
#define SEPARATOR 260
#define ID 261
#define LESS_THAN 262
#define GREATER_THAN 263
#define DEF 264
#define LPAR 265
#define RPAR 266
#define LBRACE 267
#define RBRACE 268
#define LET 269
#define SYMBOL 270
#define COMMA 271
#define NON_NEGATIVE_LONG 272
#define NON_NEGATIVE_DOUBLE 273
#define DIFF 274
#define SYSTEM 275
#define PLUS 276
#define MINUS 277
#define MUL 278
#define DIV 279
#define MOD 280
#define COLON 281
#define LESS_OR_EQUAL_THAN 282
#define GREATER_OR_EQUAL_THAN 283
#define CALL 284
#define LSQUARE 285
#define RSQUARE 286
#define QUOTE 287
#define MU 288
#define EMPTY 289
#define MS 290
#define LONG_RIGHT_ARROW 291
#define SHORT_RIGHT_ARROW 292
#define DOUBLE_COLON 293
#define DISSOLUTION_SYMBOL 294
#define LONG_DOUBLE_ARROW 295
#define SHORT_DOUBLE_ARROW 296
#define EQUAL 297
#define AND 298
#define OR 299
#define NOT 300
#define LABELS 301
#define FEATURE 302
#define EMU 303
#define PROB_TYPE 304
#define IF 305
#define ELSE 306
#define WHILE 307
#define DO 308
#define FOR 309
#define INC 310
#define DEC 311
#define INC_BY 312
#define DEC_BY 313
#define MUL_BY 314
#define DIV_BY 315
#define MOD_BY 316
#define BITWISE_OR 317
#define BITWISE_AND 318
#define BITWISE_NOT 319
#define BITWISE_LEFT 320
#define BITWISE_RIGHT 321
#define BITWISE_XOR 322
#define QUESTION_MARK 323
#define BITWISE_LEFT_BY 324
#define BITWISE_RIGHT_BY 325
#define STRING 326
#define AT_SYMBOL 327
#define BITWISE_AND_BY 328
#define BITWISE_OR_BY 329
#define BITWISE_XOR_BY 330
#define RETURN 331
#define INTEGER_LITERAL 332
#define DOUBLE_LITERAL 333
#define STRING_LITERAL 334
#define POST_INC 335
#define POST_DEC 336
#define ADD 337
#define SUB 338
#define DEFINITIONS 339
#define ERROR 340
#define MODULE 341
#define VARIABLE 342
#define ARGUMENTS 343
#define PARAMETERS 344
#define SENTENCES 345
#define INCLUDE 346
#define RANGES 347
#define RANGE 348
#define RULE 349
#define INDEXES 350
#define MEMBRANES 351
#define MEMBRANE 352
#define CHARGE 353
#define LABEL 354
#define MULTISET 355
#define PATTERN 356
#define RULES 357
#define REXP_TYPE 358
#define PROBABILITY 359
#define PRIORITY 360
#define PLINGUA 361
#define ANONYMOUS_VARIABLE 362
#define INT_TYPE 363
#define LONG_TYPE 364
#define DOUBLE_TYPE 365
#define STRING_TYPE 366
#define SYSTEM_CONSTANT 367
#define MODEL_DEFINITION 368
#define MODEL_BODY 369
#define MODEL_ELEMENT 370
#define SYSTEM_CALL 371
#define INNER_MEMBRANE 372
#define INNER_MEMBRANES 373
#define OUTER_MEMBRANE 374
#define OUTER_MEMBRANES 375
#define RIGHT_HAND_RULE 376
#define LEFT_HAND_RULE 377

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 69 "src/parser/plingua.y"

	long   longValue;
	double doubleValue;
	char*  stringValue;
	plingua::parser::Node* node;

#line 318 "src/parser/y.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif

/* Location type.  */
#if ! defined YYLTYPE && ! defined YYLTYPE_IS_DECLARED
typedef struct YYLTYPE YYLTYPE;
struct YYLTYPE
{
  int first_line;
  int first_column;
  int last_line;
  int last_column;
};
# define YYLTYPE_IS_DECLARED 1
# define YYLTYPE_IS_TRIVIAL 1
#endif


extern YYSTYPE yylval;
extern YYLTYPE yylloc;

int yyparse (void);


#endif /* !YY_YY_SRC_PARSER_Y_TAB_H_INCLUDED  */
