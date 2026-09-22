/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison implementation for Yacc-like parsers in C

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

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output, and Bison version.  */
#define YYBISON 30802

/* Bison version string.  */
#define YYBISON_VERSION "3.8.2"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 0

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1




/* First part of user prologue.  */
#line 26 "src/parser/plingua.y"

#include <stdio.h> 
#include <parser/syntax_tree.hpp>
#include <parser/parser.hpp>

#define YYERROR_VERBOSE

#define yyerror(s) plingua::parser::PARSER.error(s,yylloc)


extern int yylex();

using namespace plingua::parser;


#line 87 "src/parser/y.tab.c"

# ifndef YY_CAST
#  ifdef __cplusplus
#   define YY_CAST(Type, Val) static_cast<Type> (Val)
#   define YY_REINTERPRET_CAST(Type, Val) reinterpret_cast<Type> (Val)
#  else
#   define YY_CAST(Type, Val) ((Type) (Val))
#   define YY_REINTERPRET_CAST(Type, Val) ((Type) (Val))
#  endif
# endif
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif

#include "y.tab.h"
/* Symbol kind.  */
enum yysymbol_kind_t
{
  YYSYMBOL_YYEMPTY = -2,
  YYSYMBOL_YYEOF = 0,                      /* "end of file"  */
  YYSYMBOL_YYerror = 1,                    /* error  */
  YYSYMBOL_YYUNDEF = 2,                    /* "invalid token"  */
  YYSYMBOL_MODEL = 3,                      /* MODEL  */
  YYSYMBOL_ASIG = 4,                       /* ASIG  */
  YYSYMBOL_SEPARATOR = 5,                  /* SEPARATOR  */
  YYSYMBOL_ID = 6,                         /* ID  */
  YYSYMBOL_LESS_THAN = 7,                  /* LESS_THAN  */
  YYSYMBOL_GREATER_THAN = 8,               /* GREATER_THAN  */
  YYSYMBOL_DEF = 9,                        /* DEF  */
  YYSYMBOL_LPAR = 10,                      /* LPAR  */
  YYSYMBOL_RPAR = 11,                      /* RPAR  */
  YYSYMBOL_LBRACE = 12,                    /* LBRACE  */
  YYSYMBOL_RBRACE = 13,                    /* RBRACE  */
  YYSYMBOL_LET = 14,                       /* LET  */
  YYSYMBOL_SYMBOL = 15,                    /* SYMBOL  */
  YYSYMBOL_COMMA = 16,                     /* COMMA  */
  YYSYMBOL_NON_NEGATIVE_LONG = 17,         /* NON_NEGATIVE_LONG  */
  YYSYMBOL_NON_NEGATIVE_DOUBLE = 18,       /* NON_NEGATIVE_DOUBLE  */
  YYSYMBOL_DIFF = 19,                      /* DIFF  */
  YYSYMBOL_SYSTEM = 20,                    /* SYSTEM  */
  YYSYMBOL_PLUS = 21,                      /* PLUS  */
  YYSYMBOL_MINUS = 22,                     /* MINUS  */
  YYSYMBOL_MUL = 23,                       /* MUL  */
  YYSYMBOL_DIV = 24,                       /* DIV  */
  YYSYMBOL_MOD = 25,                       /* MOD  */
  YYSYMBOL_COLON = 26,                     /* COLON  */
  YYSYMBOL_LESS_OR_EQUAL_THAN = 27,        /* LESS_OR_EQUAL_THAN  */
  YYSYMBOL_GREATER_OR_EQUAL_THAN = 28,     /* GREATER_OR_EQUAL_THAN  */
  YYSYMBOL_CALL = 29,                      /* CALL  */
  YYSYMBOL_LSQUARE = 30,                   /* LSQUARE  */
  YYSYMBOL_RSQUARE = 31,                   /* RSQUARE  */
  YYSYMBOL_QUOTE = 32,                     /* QUOTE  */
  YYSYMBOL_MU = 33,                        /* MU  */
  YYSYMBOL_EMPTY = 34,                     /* EMPTY  */
  YYSYMBOL_MS = 35,                        /* MS  */
  YYSYMBOL_LONG_RIGHT_ARROW = 36,          /* LONG_RIGHT_ARROW  */
  YYSYMBOL_SHORT_RIGHT_ARROW = 37,         /* SHORT_RIGHT_ARROW  */
  YYSYMBOL_DOUBLE_COLON = 38,              /* DOUBLE_COLON  */
  YYSYMBOL_DISSOLUTION_SYMBOL = 39,        /* DISSOLUTION_SYMBOL  */
  YYSYMBOL_LONG_DOUBLE_ARROW = 40,         /* LONG_DOUBLE_ARROW  */
  YYSYMBOL_SHORT_DOUBLE_ARROW = 41,        /* SHORT_DOUBLE_ARROW  */
  YYSYMBOL_EQUAL = 42,                     /* EQUAL  */
  YYSYMBOL_AND = 43,                       /* AND  */
  YYSYMBOL_OR = 44,                        /* OR  */
  YYSYMBOL_NOT = 45,                       /* NOT  */
  YYSYMBOL_LABELS = 46,                    /* LABELS  */
  YYSYMBOL_FEATURE = 47,                   /* FEATURE  */
  YYSYMBOL_EMU = 48,                       /* EMU  */
  YYSYMBOL_PROB_TYPE = 49,                 /* PROB_TYPE  */
  YYSYMBOL_IF = 50,                        /* IF  */
  YYSYMBOL_ELSE = 51,                      /* ELSE  */
  YYSYMBOL_WHILE = 52,                     /* WHILE  */
  YYSYMBOL_DO = 53,                        /* DO  */
  YYSYMBOL_FOR = 54,                       /* FOR  */
  YYSYMBOL_INC = 55,                       /* INC  */
  YYSYMBOL_DEC = 56,                       /* DEC  */
  YYSYMBOL_INC_BY = 57,                    /* INC_BY  */
  YYSYMBOL_DEC_BY = 58,                    /* DEC_BY  */
  YYSYMBOL_MUL_BY = 59,                    /* MUL_BY  */
  YYSYMBOL_DIV_BY = 60,                    /* DIV_BY  */
  YYSYMBOL_MOD_BY = 61,                    /* MOD_BY  */
  YYSYMBOL_BITWISE_OR = 62,                /* BITWISE_OR  */
  YYSYMBOL_BITWISE_AND = 63,               /* BITWISE_AND  */
  YYSYMBOL_BITWISE_NOT = 64,               /* BITWISE_NOT  */
  YYSYMBOL_BITWISE_LEFT = 65,              /* BITWISE_LEFT  */
  YYSYMBOL_BITWISE_RIGHT = 66,             /* BITWISE_RIGHT  */
  YYSYMBOL_BITWISE_XOR = 67,               /* BITWISE_XOR  */
  YYSYMBOL_QUESTION_MARK = 68,             /* QUESTION_MARK  */
  YYSYMBOL_BITWISE_LEFT_BY = 69,           /* BITWISE_LEFT_BY  */
  YYSYMBOL_BITWISE_RIGHT_BY = 70,          /* BITWISE_RIGHT_BY  */
  YYSYMBOL_STRING = 71,                    /* STRING  */
  YYSYMBOL_AT_SYMBOL = 72,                 /* AT_SYMBOL  */
  YYSYMBOL_BITWISE_AND_BY = 73,            /* BITWISE_AND_BY  */
  YYSYMBOL_BITWISE_OR_BY = 74,             /* BITWISE_OR_BY  */
  YYSYMBOL_BITWISE_XOR_BY = 75,            /* BITWISE_XOR_BY  */
  YYSYMBOL_RETURN = 76,                    /* RETURN  */
  YYSYMBOL_INTEGER_LITERAL = 77,           /* INTEGER_LITERAL  */
  YYSYMBOL_DOUBLE_LITERAL = 78,            /* DOUBLE_LITERAL  */
  YYSYMBOL_STRING_LITERAL = 79,            /* STRING_LITERAL  */
  YYSYMBOL_POST_INC = 80,                  /* POST_INC  */
  YYSYMBOL_POST_DEC = 81,                  /* POST_DEC  */
  YYSYMBOL_ADD = 82,                       /* ADD  */
  YYSYMBOL_SUB = 83,                       /* SUB  */
  YYSYMBOL_DEFINITIONS = 84,               /* DEFINITIONS  */
  YYSYMBOL_ERROR = 85,                     /* ERROR  */
  YYSYMBOL_MODULE = 86,                    /* MODULE  */
  YYSYMBOL_VARIABLE = 87,                  /* VARIABLE  */
  YYSYMBOL_ARGUMENTS = 88,                 /* ARGUMENTS  */
  YYSYMBOL_PARAMETERS = 89,                /* PARAMETERS  */
  YYSYMBOL_SENTENCES = 90,                 /* SENTENCES  */
  YYSYMBOL_INCLUDE = 91,                   /* INCLUDE  */
  YYSYMBOL_RANGES = 92,                    /* RANGES  */
  YYSYMBOL_RANGE = 93,                     /* RANGE  */
  YYSYMBOL_RULE = 94,                      /* RULE  */
  YYSYMBOL_INDEXES = 95,                   /* INDEXES  */
  YYSYMBOL_MEMBRANES = 96,                 /* MEMBRANES  */
  YYSYMBOL_MEMBRANE = 97,                  /* MEMBRANE  */
  YYSYMBOL_CHARGE = 98,                    /* CHARGE  */
  YYSYMBOL_LABEL = 99,                     /* LABEL  */
  YYSYMBOL_MULTISET = 100,                 /* MULTISET  */
  YYSYMBOL_PATTERN = 101,                  /* PATTERN  */
  YYSYMBOL_RULES = 102,                    /* RULES  */
  YYSYMBOL_REXP_TYPE = 103,                /* REXP_TYPE  */
  YYSYMBOL_PROBABILITY = 104,              /* PROBABILITY  */
  YYSYMBOL_PRIORITY = 105,                 /* PRIORITY  */
  YYSYMBOL_PLINGUA = 106,                  /* PLINGUA  */
  YYSYMBOL_ANONYMOUS_VARIABLE = 107,       /* ANONYMOUS_VARIABLE  */
  YYSYMBOL_INT_TYPE = 108,                 /* INT_TYPE  */
  YYSYMBOL_LONG_TYPE = 109,                /* LONG_TYPE  */
  YYSYMBOL_DOUBLE_TYPE = 110,              /* DOUBLE_TYPE  */
  YYSYMBOL_STRING_TYPE = 111,              /* STRING_TYPE  */
  YYSYMBOL_SYSTEM_CONSTANT = 112,          /* SYSTEM_CONSTANT  */
  YYSYMBOL_MODEL_DEFINITION = 113,         /* MODEL_DEFINITION  */
  YYSYMBOL_MODEL_BODY = 114,               /* MODEL_BODY  */
  YYSYMBOL_MODEL_ELEMENT = 115,            /* MODEL_ELEMENT  */
  YYSYMBOL_SYSTEM_CALL = 116,              /* SYSTEM_CALL  */
  YYSYMBOL_INNER_MEMBRANE = 117,           /* INNER_MEMBRANE  */
  YYSYMBOL_INNER_MEMBRANES = 118,          /* INNER_MEMBRANES  */
  YYSYMBOL_OUTER_MEMBRANE = 119,           /* OUTER_MEMBRANE  */
  YYSYMBOL_OUTER_MEMBRANES = 120,          /* OUTER_MEMBRANES  */
  YYSYMBOL_RIGHT_HAND_RULE = 121,          /* RIGHT_HAND_RULE  */
  YYSYMBOL_LEFT_HAND_RULE = 122,           /* LEFT_HAND_RULE  */
  YYSYMBOL_YYACCEPT = 123,                 /* $accept  */
  YYSYMBOL_plingua = 124,                  /* plingua  */
  YYSYMBOL_definitions = 125,              /* definitions  */
  YYSYMBOL_definition = 126,               /* definition  */
  YYSYMBOL_features = 127,                 /* features  */
  YYSYMBOL_feature = 128,                  /* feature  */
  YYSYMBOL_type = 129,                     /* type  */
  YYSYMBOL_model_definition = 130,         /* model_definition  */
  YYSYMBOL_model_body = 131,               /* model_body  */
  YYSYMBOL_model_element = 132,            /* model_element  */
  YYSYMBOL_pattern = 133,                  /* pattern  */
  YYSYMBOL_rules = 134,                    /* rules  */
  YYSYMBOL_model = 135,                    /* model  */
  YYSYMBOL_include = 136,                  /* include  */
  YYSYMBOL_id = 137,                       /* id  */
  YYSYMBOL_variable = 138,                 /* variable  */
  YYSYMBOL_arguments = 139,                /* arguments  */
  YYSYMBOL_module = 140,                   /* module  */
  YYSYMBOL_parameters = 141,               /* parameters  */
  YYSYMBOL_sentences = 142,                /* sentences  */
  YYSYMBOL_sentence = 143,                 /* sentence  */
  YYSYMBOL_if = 144,                       /* if  */
  YYSYMBOL_else = 145,                     /* else  */
  YYSYMBOL_while = 146,                    /* while  */
  YYSYMBOL_dowhile = 147,                  /* dowhile  */
  YYSYMBOL_for = 148,                      /* for  */
  YYSYMBOL_ranges = 149,                   /* ranges  */
  YYSYMBOL_range = 150,                    /* range  */
  YYSYMBOL_rangeCmp = 151,                 /* rangeCmp  */
  YYSYMBOL_instruction = 152,              /* instruction  */
  YYSYMBOL_regular_call = 153,             /* regular_call  */
  YYSYMBOL_system_call = 154,              /* system_call  */
  YYSYMBOL_call = 155,                     /* call  */
  YYSYMBOL_assignment = 156,               /* assignment  */
  YYSYMBOL_simple_assignment = 157,        /* simple_assignment  */
  YYSYMBOL_increment = 158,                /* increment  */
  YYSYMBOL_anonymous = 159,                /* anonymous  */
  YYSYMBOL_initialMembraneStructure = 160, /* initialMembraneStructure  */
  YYSYMBOL_extendMembraneStructure = 161,  /* extendMembraneStructure  */
  YYSYMBOL_membranes = 162,                /* membranes  */
  YYSYMBOL_membrane = 163,                 /* membrane  */
  YYSYMBOL_multiset = 164,                 /* multiset  */
  YYSYMBOL_multiset0 = 165,                /* multiset0  */
  YYSYMBOL_multiobject = 166,              /* multiobject  */
  YYSYMBOL_multiobject0 = 167,             /* multiobject0  */
  YYSYMBOL_lsquare = 168,                  /* lsquare  */
  YYSYMBOL_lsquare0 = 169,                 /* lsquare0  */
  YYSYMBOL_charge = 170,                   /* charge  */
  YYSYMBOL_charge0 = 171,                  /* charge0  */
  YYSYMBOL_rsquare = 172,                  /* rsquare  */
  YYSYMBOL_rsquare0 = 173,                 /* rsquare0  */
  YYSYMBOL_non_negative_long = 174,        /* non_negative_long  */
  YYSYMBOL_label = 175,                    /* label  */
  YYSYMBOL_initialMultiset = 176,          /* initialMultiset  */
  YYSYMBOL_labels = 177,                   /* labels  */
  YYSYMBOL_asigOrIncBy = 178,              /* asigOrIncBy  */
  YYSYMBOL_rule = 179,                     /* rule  */
  YYSYMBOL_probability = 180,              /* probability  */
  YYSYMBOL_priority = 181,                 /* priority  */
  YYSYMBOL_ruleBody = 182,                 /* ruleBody  */
  YYSYMBOL_left_hand_rule = 183,           /* left_hand_rule  */
  YYSYMBOL_right_hand_rule = 184,          /* right_hand_rule  */
  YYSYMBOL_left_outer_membrane = 185,      /* left_outer_membrane  */
  YYSYMBOL_right_outer_membrane = 186,     /* right_outer_membrane  */
  YYSYMBOL_right_outer_membranes = 187,    /* right_outer_membranes  */
  YYSYMBOL_inner_membrane = 188,           /* inner_membrane  */
  YYSYMBOL_inner_membranes = 189,          /* inner_membranes  */
  YYSYMBOL_arrow = 190,                    /* arrow  */
  YYSYMBOL_expr = 191,                     /* expr  */
  YYSYMBOL_expr80 = 192,                   /* expr80  */
  YYSYMBOL_expr70 = 193,                   /* expr70  */
  YYSYMBOL_expr66 = 194,                   /* expr66  */
  YYSYMBOL_expr64 = 195,                   /* expr64  */
  YYSYMBOL_expr62 = 196,                   /* expr62  */
  YYSYMBOL_expr60 = 197,                   /* expr60  */
  YYSYMBOL_expr50 = 198,                   /* expr50  */
  YYSYMBOL_expr45 = 199,                   /* expr45  */
  YYSYMBOL_expr40 = 200,                   /* expr40  */
  YYSYMBOL_expr30 = 201,                   /* expr30  */
  YYSYMBOL_expr20 = 202,                   /* expr20  */
  YYSYMBOL_expr10 = 203,                   /* expr10  */
  YYSYMBOL_expr5 = 204,                    /* expr5  */
  YYSYMBOL_expr0 = 205                     /* expr0  */
};
typedef enum yysymbol_kind_t yysymbol_kind_t;




#ifdef short
# undef short
#endif

/* On compilers that do not define __PTRDIFF_MAX__ etc., make sure
   <limits.h> and (if available) <stdint.h> are included
   so that the code can choose integer types of a good width.  */

#ifndef __PTRDIFF_MAX__
# include <limits.h> /* INFRINGES ON USER NAME SPACE */
# if defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stdint.h> /* INFRINGES ON USER NAME SPACE */
#  define YY_STDINT_H
# endif
#endif

/* Narrow types that promote to a signed type and that can represent a
   signed or unsigned integer of at least N bits.  In tables they can
   save space and decrease cache pressure.  Promoting to a signed type
   helps avoid bugs in integer arithmetic.  */

#ifdef __INT_LEAST8_MAX__
typedef __INT_LEAST8_TYPE__ yytype_int8;
#elif defined YY_STDINT_H
typedef int_least8_t yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef __INT_LEAST16_MAX__
typedef __INT_LEAST16_TYPE__ yytype_int16;
#elif defined YY_STDINT_H
typedef int_least16_t yytype_int16;
#else
typedef short yytype_int16;
#endif

/* Work around bug in HP-UX 11.23, which defines these macros
   incorrectly for preprocessor constants.  This workaround can likely
   be removed in 2023, as HPE has promised support for HP-UX 11.23
   (aka HP-UX 11i v2) only through the end of 2022; see Table 2 of
   <https://h20195.www2.hpe.com/V2/getpdf.aspx/4AA4-7673ENW.pdf>.  */
#ifdef __hpux
# undef UINT_LEAST8_MAX
# undef UINT_LEAST16_MAX
# define UINT_LEAST8_MAX 255
# define UINT_LEAST16_MAX 65535
#endif

#if defined __UINT_LEAST8_MAX__ && __UINT_LEAST8_MAX__ <= __INT_MAX__
typedef __UINT_LEAST8_TYPE__ yytype_uint8;
#elif (!defined __UINT_LEAST8_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST8_MAX <= INT_MAX)
typedef uint_least8_t yytype_uint8;
#elif !defined __UINT_LEAST8_MAX__ && UCHAR_MAX <= INT_MAX
typedef unsigned char yytype_uint8;
#else
typedef short yytype_uint8;
#endif

#if defined __UINT_LEAST16_MAX__ && __UINT_LEAST16_MAX__ <= __INT_MAX__
typedef __UINT_LEAST16_TYPE__ yytype_uint16;
#elif (!defined __UINT_LEAST16_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST16_MAX <= INT_MAX)
typedef uint_least16_t yytype_uint16;
#elif !defined __UINT_LEAST16_MAX__ && USHRT_MAX <= INT_MAX
typedef unsigned short yytype_uint16;
#else
typedef int yytype_uint16;
#endif

#ifndef YYPTRDIFF_T
# if defined __PTRDIFF_TYPE__ && defined __PTRDIFF_MAX__
#  define YYPTRDIFF_T __PTRDIFF_TYPE__
#  define YYPTRDIFF_MAXIMUM __PTRDIFF_MAX__
# elif defined PTRDIFF_MAX
#  ifndef ptrdiff_t
#   include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  endif
#  define YYPTRDIFF_T ptrdiff_t
#  define YYPTRDIFF_MAXIMUM PTRDIFF_MAX
# else
#  define YYPTRDIFF_T long
#  define YYPTRDIFF_MAXIMUM LONG_MAX
# endif
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned
# endif
#endif

#define YYSIZE_MAXIMUM                                  \
  YY_CAST (YYPTRDIFF_T,                                 \
           (YYPTRDIFF_MAXIMUM < YY_CAST (YYSIZE_T, -1)  \
            ? YYPTRDIFF_MAXIMUM                         \
            : YY_CAST (YYSIZE_T, -1)))

#define YYSIZEOF(X) YY_CAST (YYPTRDIFF_T, sizeof (X))


/* Stored state numbers (used for stacks). */
typedef yytype_int16 yy_state_t;

/* State numbers in computations.  */
typedef int yy_state_fast_t;

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif


#ifndef YY_ATTRIBUTE_PURE
# if defined __GNUC__ && 2 < __GNUC__ + (96 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define YY_ATTRIBUTE_PURE
# endif
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# if defined __GNUC__ && 2 < __GNUC__ + (7 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_UNUSED __attribute__ ((__unused__))
# else
#  define YY_ATTRIBUTE_UNUSED
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YY_USE(E) ((void) (E))
#else
# define YY_USE(E) /* empty */
#endif

/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
#if defined __GNUC__ && ! defined __ICC && 406 <= __GNUC__ * 100 + __GNUC_MINOR__
# if __GNUC__ * 100 + __GNUC_MINOR__ < 407
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")
# else
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")              \
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# endif
# define YY_IGNORE_MAYBE_UNINITIALIZED_END      \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

#if defined __cplusplus && defined __GNUC__ && ! defined __ICC && 6 <= __GNUC__
# define YY_IGNORE_USELESS_CAST_BEGIN                          \
    _Pragma ("GCC diagnostic push")                            \
    _Pragma ("GCC diagnostic ignored \"-Wuseless-cast\"")
# define YY_IGNORE_USELESS_CAST_END            \
    _Pragma ("GCC diagnostic pop")
#endif
#ifndef YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_END
#endif


#define YY_ASSERT(E) ((void) (0 && (E)))

#if !defined yyoverflow

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
             && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* !defined yyoverflow */

#if (! defined yyoverflow \
     && (! defined __cplusplus \
         || (defined YYLTYPE_IS_TRIVIAL && YYLTYPE_IS_TRIVIAL \
             && defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yy_state_t yyss_alloc;
  YYSTYPE yyvs_alloc;
  YYLTYPE yyls_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (YYSIZEOF (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (YYSIZEOF (yy_state_t) + YYSIZEOF (YYSTYPE) \
             + YYSIZEOF (YYLTYPE)) \
      + 2 * YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYPTRDIFF_T yynewbytes;                                         \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * YYSIZEOF (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / YYSIZEOF (*yyptr);                        \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, YY_CAST (YYSIZE_T, (Count)) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYPTRDIFF_T yyi;                      \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  35
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   1260

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  123
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  83
/* YYNRULES -- Number of rules.  */
#define YYNRULES  262
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  494

/* YYMAXUTOK -- Last valid token kind.  */
#define YYMAXUTOK   377


/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                \
  (0 <= (YYX) && (YYX) <= YYMAXUTOK                     \
   ? YY_CAST (yysymbol_kind_t, yytranslate[YYX])        \
   : YYSYMBOL_YYUNDEF)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_int8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
      65,    66,    67,    68,    69,    70,    71,    72,    73,    74,
      75,    76,    77,    78,    79,    80,    81,    82,    83,    84,
      85,    86,    87,    88,    89,    90,    91,    92,    93,    94,
      95,    96,    97,    98,    99,   100,   101,   102,   103,   104,
     105,   106,   107,   108,   109,   110,   111,   112,   113,   114,
     115,   116,   117,   118,   119,   120,   121,   122
};

#if YYDEBUG
/* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_int16 yyrline[] =
{
       0,   101,   101,   103,   104,   107,   108,   109,   110,   111,
     112,   113,   114,   115,   116,   120,   121,   124,   125,   126,
     129,   130,   131,   132,   133,   134,   138,   141,   142,   145,
     146,   147,   150,   153,   154,   159,   162,   163,   166,   169,
     170,   173,   174,   177,   178,   179,   180,   183,   184,   187,
     188,   191,   192,   193,   194,   195,   196,   197,   198,   199,
     200,   203,   206,   209,   212,   215,   219,   220,   223,   224,
     227,   228,   231,   232,   233,   234,   235,   236,   237,   241,
     242,   245,   248,   249,   250,   251,   254,   255,   256,   259,
     262,   263,   264,   265,   266,   267,   268,   269,   270,   271,
     272,   273,   277,   278,   281,   284,   287,   288,   292,   293,
     296,   297,   300,   301,   305,   306,   309,   310,   311,   314,
     315,   319,   320,   325,   326,   327,   331,   332,   335,   336,
     339,   342,   345,   346,   347,   350,   351,   354,   355,   359,
     360,   364,   365,   366,   367,   368,   369,   372,   373,   377,
     378,   381,   382,   383,   384,   385,   386,   387,   388,   389,
     390,   391,   392,   393,   394,   395,   396,   397,   398,   399,
     400,   401,   402,   406,   407,   408,   411,   412,   413,   414,
     417,   418,   419,   420,   421,   424,   425,   426,   427,   428,
     433,   434,   438,   439,   442,   443,   447,   448,   449,   450,
     454,   455,   456,   457,   458,   459,   460,   461,   462,   463,
     464,   465,   468,   469,   473,   474,   478,   479,   482,   483,
     487,   488,   491,   492,   493,   497,   498,   499,   500,   501,
     504,   505,   506,   510,   511,   512,   515,   516,   517,   518,
     522,   523,   524,   525,   526,   527,   528,   531,   532,   533,
     537,   538,   539,   540,   541,   544,   545,   546,   547,   548,
     549,   550,   551
};
#endif

/** Accessing symbol of state STATE.  */
#define YY_ACCESSING_SYMBOL(State) YY_CAST (yysymbol_kind_t, yystos[State])

#if YYDEBUG || 0
/* The user-facing name of the symbol whose (internal) number is
   YYSYMBOL.  No bounds checking.  */
static const char *yysymbol_name (yysymbol_kind_t yysymbol) YY_ATTRIBUTE_UNUSED;

/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "\"end of file\"", "error", "\"invalid token\"", "MODEL", "ASIG",
  "SEPARATOR", "ID", "LESS_THAN", "GREATER_THAN", "DEF", "LPAR", "RPAR",
  "LBRACE", "RBRACE", "LET", "SYMBOL", "COMMA", "NON_NEGATIVE_LONG",
  "NON_NEGATIVE_DOUBLE", "DIFF", "SYSTEM", "PLUS", "MINUS", "MUL", "DIV",
  "MOD", "COLON", "LESS_OR_EQUAL_THAN", "GREATER_OR_EQUAL_THAN", "CALL",
  "LSQUARE", "RSQUARE", "QUOTE", "MU", "EMPTY", "MS", "LONG_RIGHT_ARROW",
  "SHORT_RIGHT_ARROW", "DOUBLE_COLON", "DISSOLUTION_SYMBOL",
  "LONG_DOUBLE_ARROW", "SHORT_DOUBLE_ARROW", "EQUAL", "AND", "OR", "NOT",
  "LABELS", "FEATURE", "EMU", "PROB_TYPE", "IF", "ELSE", "WHILE", "DO",
  "FOR", "INC", "DEC", "INC_BY", "DEC_BY", "MUL_BY", "DIV_BY", "MOD_BY",
  "BITWISE_OR", "BITWISE_AND", "BITWISE_NOT", "BITWISE_LEFT",
  "BITWISE_RIGHT", "BITWISE_XOR", "QUESTION_MARK", "BITWISE_LEFT_BY",
  "BITWISE_RIGHT_BY", "STRING", "AT_SYMBOL", "BITWISE_AND_BY",
  "BITWISE_OR_BY", "BITWISE_XOR_BY", "RETURN", "INTEGER_LITERAL",
  "DOUBLE_LITERAL", "STRING_LITERAL", "POST_INC", "POST_DEC", "ADD", "SUB",
  "DEFINITIONS", "ERROR", "MODULE", "VARIABLE", "ARGUMENTS", "PARAMETERS",
  "SENTENCES", "INCLUDE", "RANGES", "RANGE", "RULE", "INDEXES",
  "MEMBRANES", "MEMBRANE", "CHARGE", "LABEL", "MULTISET", "PATTERN",
  "RULES", "REXP_TYPE", "PROBABILITY", "PRIORITY", "PLINGUA",
  "ANONYMOUS_VARIABLE", "INT_TYPE", "LONG_TYPE", "DOUBLE_TYPE",
  "STRING_TYPE", "SYSTEM_CONSTANT", "MODEL_DEFINITION", "MODEL_BODY",
  "MODEL_ELEMENT", "SYSTEM_CALL", "INNER_MEMBRANE", "INNER_MEMBRANES",
  "OUTER_MEMBRANE", "OUTER_MEMBRANES", "RIGHT_HAND_RULE", "LEFT_HAND_RULE",
  "$accept", "plingua", "definitions", "definition", "features", "feature",
  "type", "model_definition", "model_body", "model_element", "pattern",
  "rules", "model", "include", "id", "variable", "arguments", "module",
  "parameters", "sentences", "sentence", "if", "else", "while", "dowhile",
  "for", "ranges", "range", "rangeCmp", "instruction", "regular_call",
  "system_call", "call", "assignment", "simple_assignment", "increment",
  "anonymous", "initialMembraneStructure", "extendMembraneStructure",
  "membranes", "membrane", "multiset", "multiset0", "multiobject",
  "multiobject0", "lsquare", "lsquare0", "charge", "charge0", "rsquare",
  "rsquare0", "non_negative_long", "label", "initialMultiset", "labels",
  "asigOrIncBy", "rule", "probability", "priority", "ruleBody",
  "left_hand_rule", "right_hand_rule", "left_outer_membrane",
  "right_outer_membrane", "right_outer_membranes", "inner_membrane",
  "inner_membranes", "arrow", "expr", "expr80", "expr70", "expr66",
  "expr64", "expr62", "expr60", "expr50", "expr45", "expr40", "expr30",
  "expr20", "expr10", "expr5", "expr0", YY_NULLPTR
};

static const char *
yysymbol_name (yysymbol_kind_t yysymbol)
{
  return yytname[yysymbol];
}
#endif

#define YYPACT_NINF (-402)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-79)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int16 yypact[] =
{
      62,  -402,   128,  -402,    -3,    -3,    -3,    -3,    21,    64,
     476,  -402,  -402,  -402,  -402,  -402,   107,   841,  -402,   124,
    -402,  -402,    -3,    -3,   118,   133,  -402,   153,   197,  -402,
     341,   133,  -402,    -3,  -402,  -402,  -402,  1168,  1168,  -402,
    -402,  1168,  1168,  1168,  1168,  1168,  1168,  1168,  1168,  1168,
    1168,  -402,  1168,   161,   162,    78,   775,  -402,    -3,  1168,
      -9,   176,   715,  -402,  -402,   158,  1168,  1168,  1168,    -3,
      -3,  1168,  -402,   346,   899,   262,  -402,  -402,  -402,  -402,
     156,   173,   220,   192,   227,    32,   135,   203,   306,   213,
    -402,  -402,  -402,  -402,  -402,  -402,  -402,  -402,  -402,  -402,
    -402,  -402,  -402,  -402,  -402,   261,   188,  -402,   113,  -402,
     293,   310,  -402,   241,  1109,  -402,  -402,  -402,  -402,  -402,
     323,   402,   321,  -402,   384,  -402,  -402,  1052,   334,   362,
     273,    23,   297,   102,  -402,   193,  -402,  -402,  -402,  -402,
    -402,  -402,   359,  -402,   365,   374,   376,   381,   383,    -3,
    -402,  -402,  -402,  -402,  -402,  -402,  1150,  1168,  -402,  -402,
    1168,  1168,  1168,  1168,  1168,  1168,  1168,  1168,  1168,  1168,
    -402,  1168,  1168,  1168,  1168,  1168,  1168,  1168,  1168,  1168,
    1168,  1168,  1168,  1168,  1168,  1168,  1168,  1168,  1168,  1168,
    -402,  1168,  -402,  1168,  -402,    -3,     3,   798,   387,    -3,
     385,   393,  -402,  -402,   408,    73,   102,  1052,  -402,   375,
     646,   152,  -402,  -402,   994,  -402,  -402,   337,  1168,    -3,
     344,  -402,  -402,  -402,  -402,   273,   412,  -402,  -402,    73,
      73,    73,    73,  -402,  -402,  -402,  -402,   242,   156,   156,
     156,   156,   156,   156,   156,   156,   156,   156,   156,  -402,
     173,   220,   192,   227,    32,   135,   135,   203,   203,   203,
     203,   306,   306,   213,   213,  -402,  -402,  -402,  -402,   203,
      27,   274,   223,  -402,  -402,   428,  1083,  -402,   406,    60,
     147,   432,   444,  1083,   456,  1083,   458,  1168,   457,   855,
    -402,  -402,  -402,  -402,  -402,  -402,   126,  -402,  -402,  -402,
    -402,  -402,  -402,  -402,  -402,   912,  -402,  -402,  -402,  -402,
    1168,  -402,  -402,  -402,   467,  1052,   168,  -402,  1161,  1052,
     108,  -402,   465,  -402,  -402,  1052,    -3,   370,  -402,   451,
      -3,   384,  1119,  -402,  -402,   273,  -402,  -402,  -402,  -402,
    -402,  1168,     3,   462,  -402,     3,  -402,   969,    -3,   474,
    -402,  -402,   368,   168,   168,  1168,  -402,  1168,   423,    -3,
     486,  -402,  -402,  -402,  1168,  -402,  1026,   250,   108,  1168,
    -402,  -402,  -402,   477,  -402,  1052,   467,  -402,  1052,  -402,
    -402,  1052,   467,  -402,  1052,   451,   635,   451,   473,   375,
     672,  -402,  -402,  1119,   412,  -402,   203,   295,     3,  -402,
     198,  -402,  -402,  -402,  -402,   234,   469,   282,   285,   489,
     493,   497,   505,  -402,   229,  -402,   498,   168,   467,  -402,
    1052,  -402,   250,   108,  -402,   467,  -402,  1052,  -402,   250,
     108,  -402,   508,  -402,   404,   145,  -402,  -402,   308,   234,
    -402,  -402,  -402,   463,    28,  1083,  1083,  1168,  1168,  -402,
    -402,  -402,  -402,   250,   108,  -402,  -402,  -402,  -402,   250,
     108,  -402,  -402,  -402,  -402,  -402,  -402,  -402,  -402,  -402,
     368,  -402,  -402,    71,  -402,  -402,   511,   519,  -402,  -402,
    -402,  -402,  -402,   509,  -402,   523,    -3,    71,  -402,  1185,
     518,  -402,  1083,  -402
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_int16 yydefact[] =
{
       0,    14,     0,    38,     0,     0,     0,     0,     0,     0,
       0,     4,     7,     8,     6,     5,    39,     0,     9,     0,
      86,    88,     0,     0,     0,     0,    87,     0,     0,    16,
      39,    18,    17,     0,    36,     1,     3,     0,     0,   100,
     101,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    12,     0,     0,     0,     0,     0,    10,     0,     0,
       0,     0,     0,   131,   256,     0,     0,     0,     0,     0,
       0,     0,   258,    39,   257,     0,   259,   260,   255,    42,
     211,   213,   215,   217,   219,   221,   224,   229,   232,   235,
     239,   246,   249,   254,    89,    90,    91,    92,    93,    94,
      95,    96,    97,    98,    99,   257,     0,    67,     0,    35,
       0,     0,    48,     0,     0,   123,   124,   120,   118,   115,
     102,     0,   116,   125,     0,   111,   114,     0,     0,     0,
       0,   141,     0,   174,    15,     0,    24,    25,    20,    21,
      22,    23,     0,    37,     0,     0,     0,     0,     0,     0,
     240,   241,   242,   244,   245,   243,     0,     0,   247,   248,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      40,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      13,     0,    70,     0,    71,     0,     0,     0,     0,     0,
       0,     0,   103,    32,     0,     0,     0,     0,   173,     0,
       0,     0,   180,   195,     0,   119,    34,   143,     0,     0,
     142,   196,   197,   198,   199,   151,   175,    11,    19,     0,
       0,     0,     0,   262,   261,    81,    79,     0,   200,   201,
     202,   203,   204,   205,   206,   207,   208,   209,   210,    41,
     212,   214,   216,   218,   220,   223,   222,   225,   227,   226,
     228,   230,   231,   233,   234,   236,   237,   238,    66,    68,
       0,     0,     0,    28,    31,     0,     0,    43,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,   116,     0,
      50,    55,    56,    57,    58,    59,     0,    82,    83,    72,
      73,    74,    75,    76,    77,     0,    47,   150,   149,    33,
       0,   257,   117,   110,     0,     0,     0,   181,     0,     0,
       0,   192,     0,   182,   194,     0,     0,    39,   147,   144,
       0,   176,     0,   152,   191,   177,   250,   251,   252,   253,
      80,     0,     0,     0,    26,     0,    60,     0,     0,     0,
      84,    85,     0,     0,     0,     0,    62,     0,     0,     0,
       0,    44,    49,    51,     0,    45,     0,     0,     0,     0,
     132,   133,   138,   130,   183,     0,     0,   153,     0,   193,
     184,     0,     0,   158,     0,   146,     0,   145,   178,   128,
       0,   185,   129,     0,   179,   190,    69,     0,     0,    27,
      53,   126,   127,   122,   104,     0,     0,     0,     0,     0,
       0,     0,     0,    54,     0,    46,     0,     0,     0,   163,
       0,   154,     0,     0,   155,     0,   168,     0,   159,     0,
       0,   160,     0,   186,     0,     0,   187,    30,     0,     0,
     107,   108,   121,     0,     0,     0,     0,     0,     0,    52,
     134,   137,   164,     0,     0,   165,   156,   157,   169,     0,
       0,   170,   161,   162,   148,   188,   189,    29,   106,   109,
       0,   139,   140,   136,    61,    63,     0,     0,   166,   167,
     171,   172,   105,   135,   113,     0,     0,     0,    64,     0,
       0,   112,     0,    65
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -402,  -402,  -402,   524,  -208,   475,   151,  -402,  -289,   199,
    -402,  -402,  -402,  -402,   244,     0,   501,  -402,  -402,  -270,
    -172,  -402,  -402,  -402,  -402,  -402,   -58,   351,   275,  -402,
      63,   112,  -402,   115,    24,    61,   435,  -402,  -402,  -402,
    -366,   246,  -402,   340,  -401,   -43,  -402,  -402,  -402,  -267,
     329,  -257,   134,  -402,    65,  -402,   -23,  -402,  -402,   420,
    -402,  -402,   429,  -278,   221,  -212,  -155,  -206,   -26,   445,
     382,   389,   390,   391,   380,   253,     8,   254,   279,   -41,
    -402,  -402,   131
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
       0,     9,    10,    11,    28,    29,   142,    12,   272,   273,
      13,   121,    14,    15,    73,   105,   237,    18,   113,   289,
     290,   291,   292,   293,   294,   295,   106,   107,   195,   296,
      76,    77,   299,   300,    20,    21,   123,   301,   302,   439,
     404,   124,   483,   125,   126,   211,   405,   128,   406,   391,
     392,    78,   372,   303,   373,   473,   304,   220,   130,   131,
     132,   333,   133,   334,   335,   213,   214,   225,    79,    80,
      81,    82,    83,    84,    85,    86,    87,    88,    89,    90,
      91,    92,    93
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int16 yytable[] =
{
      17,   135,   324,     3,   319,    25,   347,    31,   325,     3,
      17,   329,    94,   127,   343,    95,    96,    97,    98,    99,
     100,   101,   102,   103,   104,   150,   151,   152,    33,    26,
     155,    32,   471,   129,   192,   366,   148,    74,    74,   440,
     136,    74,    74,    74,    74,    74,    74,    74,    74,    74,
      74,   177,   315,   397,   194,   318,   122,   395,    31,   371,
     108,   218,    74,     1,    35,     2,     3,   108,     3,   153,
     154,     4,   484,   468,   178,   271,     5,     3,   127,     3,
     278,   207,    32,   310,     3,   472,   491,   127,   201,   111,
      63,    64,    34,    65,   137,   219,   371,   371,   204,   138,
     139,   140,   141,   324,   482,   118,   324,     6,     3,   438,
     395,   356,   375,   358,    74,    19,   381,   362,   385,    37,
     192,   122,   387,   433,   206,    19,   436,   122,    55,    51,
     122,   363,   193,   122,     7,    22,   118,    38,    23,   209,
     194,   119,   179,   180,    72,   249,   265,   266,   267,   234,
      52,   352,   364,     8,   127,   324,    74,   353,     3,   367,
     371,   206,   181,   182,   378,    56,   324,   465,   466,   109,
     384,    74,   324,   110,     3,   362,   389,   393,   183,   184,
     369,   324,   332,   209,   143,    63,   118,   257,   258,   259,
     260,   119,   328,   190,   362,   270,   149,   288,   227,   108,
     172,   269,    57,   -78,   191,   311,   122,   122,   324,   191,
     324,   122,   235,    58,   122,   324,   173,   324,    74,    31,
     420,   422,   324,    59,   -78,   122,   427,   429,   344,   311,
     311,   311,   311,   127,   449,   434,   187,   188,   189,   345,
     127,   324,   127,    32,    16,   191,   127,   324,    24,    16,
      27,    30,   198,   340,    16,   401,   402,   199,   171,   175,
     297,   360,   127,   453,   403,   209,    53,    54,   183,   184,
     459,   115,   116,   474,   475,   170,   288,    61,   171,     3,
     117,   209,   174,   288,   148,   288,   342,    74,   332,   288,
     176,    63,   332,   443,   115,   116,   444,   196,   417,   112,
      16,   417,    30,   117,   127,   288,   414,   118,   437,   298,
      74,   345,   119,    16,    16,   122,   158,   159,   120,   122,
     493,   467,   197,   127,   345,   122,    31,   185,   186,   409,
      31,   410,   122,   221,   222,   122,   312,   223,   224,   297,
     202,   120,   350,   416,   205,   332,   297,   288,   297,   396,
      32,    60,   297,    37,    32,    74,   156,    74,    37,    25,
     336,   337,   338,   339,   215,    16,   288,   216,   297,    74,
     228,    16,   108,   210,    16,   122,   229,    16,   122,   226,
     386,   122,    37,   412,   122,   230,    74,   231,   298,   401,
     402,   351,   232,   122,   233,   298,   307,   298,   403,   305,
     206,   298,   127,   127,   308,   115,   116,   316,     3,   326,
     297,   235,   114,   309,   117,   203,   330,   298,   407,   408,
     122,   476,   477,   115,   116,   115,   116,   122,   206,   297,
     255,   256,   117,   346,   117,   389,   118,   261,   262,    16,
     274,   119,   354,   306,   348,   288,   288,    74,    74,   127,
      16,    16,   120,   314,   355,    16,   212,   320,    16,   298,
     322,    38,   327,    30,   263,   264,   357,    58,   359,    16,
     120,   331,   120,   122,   398,   411,    -2,     1,   298,     2,
     205,   206,     3,   206,   156,     4,   489,   122,   115,   116,
       5,   413,   288,   417,   115,   116,   209,   117,   209,   442,
     445,   221,   222,   117,   446,   223,   224,   447,   297,   297,
     448,   450,    39,    40,    41,    42,    43,    44,    45,   464,
     470,     6,   485,   349,   486,   487,    46,    47,   488,   492,
      48,    49,    50,   134,    36,   120,   212,   432,    75,   317,
     321,   120,   268,   323,   399,   341,   313,   490,     7,   200,
     217,   451,   388,   208,   250,   297,   254,   298,   298,    16,
     370,   368,   251,    16,   252,   376,   253,     8,     0,    16,
      30,   382,     0,     0,    30,     0,    16,     0,   390,    16,
       0,   394,     0,     0,     0,     0,   274,     0,     0,   274,
       0,     0,   349,     0,     0,     0,     0,   370,   370,     0,
       0,     0,   238,    16,   298,   239,   240,   241,   242,   243,
     244,   245,   246,   247,   248,     0,     0,     0,     0,    16,
       0,   418,    16,     0,   423,    16,     0,   425,    16,     0,
     430,     0,     0,     0,     0,     0,     0,    16,     0,   435,
       0,     3,   274,   317,   323,    62,   236,   374,   377,   379,
       0,   380,    63,    64,   383,    65,    66,    67,     0,     0,
       0,   370,   206,     0,    16,     0,   454,   115,   116,     0,
       0,    16,     0,   460,     0,     0,   117,   209,     0,     0,
      68,     0,   221,   222,   136,     0,   223,   224,   206,     0,
      69,    70,     0,   115,   116,     0,   374,   380,     0,    71,
       0,     0,   117,   389,   419,   421,    72,   424,     0,     0,
     426,   428,     0,   431,   120,     0,     0,    16,     0,     0,
       0,     3,     0,     0,     0,    62,     0,     0,     0,     0,
      16,    16,    63,    64,   441,    65,    66,    67,   137,     0,
     120,     0,     0,   138,   139,   140,   141,   452,     0,   455,
       0,   456,   457,     0,   458,     0,   461,     0,   462,   463,
      68,     0,     0,     0,     0,     0,     0,     0,   469,     0,
      69,    70,     0,     0,     0,     0,     0,     0,     0,    71,
       0,     3,   478,   479,     0,   114,    72,     0,   480,   481,
       0,     0,     0,     0,     0,     0,   115,   116,     0,   275,
       0,     0,     0,     0,     3,   117,     0,     0,   114,   118,
     276,   277,     5,     0,   119,     0,     0,     0,   278,   115,
     116,     0,     0,   144,   145,   146,   147,   279,   117,     0,
       0,   280,   118,   281,     0,     0,     0,   119,     0,     0,
       0,     0,     0,   120,     0,    38,     0,     0,   282,   283,
     284,   285,   286,     0,     0,     0,   275,     0,     0,     0,
       0,     3,     0,     0,     0,   114,   120,   276,   361,     5,
       0,     0,     0,     0,   287,   278,   115,   116,     0,     0,
       0,     0,     0,     0,   279,   117,     0,     0,   280,   118,
     281,     0,     0,     0,   119,     0,    39,    40,    41,    42,
      43,    44,    45,   157,     0,   282,   283,   284,   285,   286,
      46,    47,     0,   275,    48,    49,    50,     0,     3,     0,
       0,     0,   114,   120,   276,   365,     5,     0,     0,     0,
       0,   287,   278,   115,   116,     0,     0,     0,     0,     0,
       0,   279,   117,     0,     0,   280,   118,   281,     0,     0,
       0,   119,     0,     0,   158,   159,   160,   161,   162,   163,
     164,     0,   282,   283,   284,   285,   286,     0,   165,   166,
     275,     0,   167,   168,   169,     3,     0,     0,     0,   114,
     120,   276,   400,     5,     0,     0,     0,     0,   287,   278,
     115,   116,     0,     0,     0,     0,     0,     0,   279,   117,
       3,     0,   280,   118,   281,     0,     0,     0,   119,     0,
       0,     0,     0,     0,     0,   115,   116,     0,     0,   282,
     283,   284,   285,   286,   117,   209,     0,   275,   118,     0,
     221,   222,     3,   119,   223,   224,   114,   120,   276,   415,
       5,     0,     0,     0,     0,   287,   278,   115,   116,     0,
       0,     0,     0,     0,     0,   279,   117,     0,     3,   280,
     118,   281,   120,     0,     0,   119,     0,     0,     0,     0,
       0,     0,     0,   115,   116,     0,   282,   283,   284,   285,
     286,     0,   117,   209,   275,     0,   118,     0,     0,     3,
       0,   119,     0,   114,   120,   276,     0,     5,     0,     0,
       0,     0,   287,   278,   115,   116,     0,     0,     0,     0,
       0,     0,   279,   117,     0,     3,   280,   118,   281,    62,
     120,     0,   119,     0,     0,     3,    63,    64,     0,    65,
      66,    67,     0,   282,   283,   284,   285,   286,     0,     0,
     115,   116,     0,     0,     0,     0,     0,     0,     0,   117,
     389,   120,     0,   118,    68,     0,     3,     0,   119,   287,
      62,   236,     0,     0,    69,    70,     0,    63,    64,     0,
      65,    66,    67,    71,     3,     0,     0,   120,    62,     0,
      72,     0,   115,   116,     0,    63,    64,   120,    65,    66,
      67,   117,   209,     0,     0,    68,     0,   221,   222,     0,
       0,   223,   224,     0,     0,    69,    70,     0,     0,     0,
       0,     0,     0,    68,    71,     0,     0,     0,     0,     0,
       0,    72,     0,    69,    70,     0,     0,     0,     0,   120,
       0,     0,    71,     0,     0,     0,     0,     0,     0,    72,
      39,    40,    41,    42,    43,    44,    45,     0,     0,     0,
       0,     0,     0,     0,    46,    47,     0,     0,    48,    49,
      50
};

static const yytype_int16 yycheck[] =
{
       0,    59,   214,     6,   210,     5,   276,     7,   214,     6,
      10,   219,    38,    56,   271,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    66,    67,    68,     7,     5,
      71,     7,     4,    56,     7,   305,    62,    37,    38,   405,
      49,    41,    42,    43,    44,    45,    46,    47,    48,    49,
      50,    19,   207,   342,    27,   210,    56,   335,    58,   316,
      52,    38,    62,     1,     0,     3,     6,    59,     6,    69,
      70,     9,   473,   439,    42,    72,    14,     6,   121,     6,
      20,   124,    58,    10,     6,    57,   487,   130,   114,    11,
      17,    18,    71,    20,   103,    72,   353,   354,   121,   108,
     109,   110,   111,   315,   470,    34,   318,    45,     6,   398,
     388,   283,   318,   285,   114,     0,   322,   289,   326,    12,
       7,   121,   330,   390,    16,    10,   393,   127,    10,     5,
     130,     5,    19,   133,    72,     7,    34,     4,    10,    31,
      27,    39,     7,     8,    71,   171,   187,   188,   189,   149,
      26,     4,    26,    91,   197,   367,   156,    10,     6,   314,
     417,    16,    27,    28,   319,    12,   378,   434,   435,     8,
     325,   171,   384,    11,     6,   347,    31,   332,    65,    66,
      12,   393,   225,    31,     8,    17,    34,   179,   180,   181,
     182,    39,   218,     5,   366,   195,    38,   197,     5,   191,
      44,   193,     5,     5,    16,   205,   206,   207,   420,    16,
     422,   211,   149,    16,   214,   427,    43,   429,   218,   219,
     375,   376,   434,    26,    26,   225,   381,   382,     5,   229,
     230,   231,   232,   276,     5,   390,    23,    24,    25,    16,
     283,   453,   285,   219,     0,    16,   289,   459,     4,     5,
       6,     7,    11,    11,    10,    21,    22,    16,    16,    67,
     197,   287,   305,   418,    30,    31,    22,    23,    65,    66,
     425,    21,    22,   445,   446,    13,   276,    33,    16,     6,
      30,    31,    62,   283,   310,   285,    12,   287,   331,   289,
      63,    17,   335,    11,    21,    22,    11,     4,    16,    55,
      56,    16,    58,    30,   347,   305,   364,    34,    13,   197,
     310,    16,    39,    69,    70,   315,    55,    56,    68,   319,
     492,    13,    12,   366,    16,   325,   326,    21,    22,   355,
     330,   357,   332,    36,    37,   335,   205,    40,    41,   276,
      17,    68,   279,   369,    23,   388,   283,   347,   285,   341,
     326,    10,   289,    12,   330,   355,    10,   357,    12,   359,
     229,   230,   231,   232,    30,   121,   366,     5,   305,   369,
      11,   127,   364,   127,   130,   375,    11,   133,   378,   133,
      10,   381,    12,   359,   384,    11,   386,    11,   276,    21,
      22,   279,    11,   393,    11,   283,    11,   285,    30,    12,
      16,   289,   445,   446,    11,    21,    22,    32,     6,    72,
     347,   348,    10,     5,    30,    13,    72,   305,   353,   354,
     420,   447,   448,    21,    22,    21,    22,   427,    16,   366,
     177,   178,    30,     5,    30,    31,    34,   183,   184,   195,
     196,    39,    10,   199,    38,   445,   446,   447,   448,   492,
     206,   207,    68,   207,    10,   211,   127,   211,   214,   347,
     214,     4,   218,   219,   185,   186,    10,    16,    10,   225,
      68,   225,    68,   473,    12,    52,     0,     1,   366,     3,
      23,    16,     6,    16,    10,     9,   486,   487,    21,    22,
      14,     5,   492,    16,    21,    22,    31,    30,    31,    30,
      11,    36,    37,    30,    11,    40,    41,    10,   445,   446,
       5,    13,    55,    56,    57,    58,    59,    60,    61,    11,
      57,    45,    11,   279,     5,    16,    69,    70,     5,    11,
      73,    74,    75,    58,    10,    68,   207,   386,    37,   210,
     211,    68,   191,   214,   345,   270,   206,   486,    72,   114,
     130,   417,   331,   124,   172,   492,   176,   445,   446,   315,
     316,   315,   173,   319,   174,   319,   175,    91,    -1,   325,
     326,   325,    -1,    -1,   330,    -1,   332,    -1,   332,   335,
      -1,   335,    -1,    -1,    -1,    -1,   342,    -1,    -1,   345,
      -1,    -1,   348,    -1,    -1,    -1,    -1,   353,   354,    -1,
      -1,    -1,   157,   359,   492,   160,   161,   162,   163,   164,
     165,   166,   167,   168,   169,    -1,    -1,    -1,    -1,   375,
      -1,   375,   378,    -1,   378,   381,    -1,   381,   384,    -1,
     384,    -1,    -1,    -1,    -1,    -1,    -1,   393,    -1,   393,
      -1,     6,   398,   314,   315,    10,    11,   318,   319,   320,
      -1,   322,    17,    18,   325,    20,    21,    22,    -1,    -1,
      -1,   417,    16,    -1,   420,    -1,   420,    21,    22,    -1,
      -1,   427,    -1,   427,    -1,    -1,    30,    31,    -1,    -1,
      45,    -1,    36,    37,    49,    -1,    40,    41,    16,    -1,
      55,    56,    -1,    21,    22,    -1,   367,   368,    -1,    64,
      -1,    -1,    30,    31,   375,   376,    71,   378,    -1,    -1,
     381,   382,    -1,   384,    68,    -1,    -1,   473,    -1,    -1,
      -1,     6,    -1,    -1,    -1,    10,    -1,    -1,    -1,    -1,
     486,   487,    17,    18,   405,    20,    21,    22,   103,    -1,
      68,    -1,    -1,   108,   109,   110,   111,   418,    -1,   420,
      -1,   422,   423,    -1,   425,    -1,   427,    -1,   429,   430,
      45,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   439,    -1,
      55,    56,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    64,
      -1,     6,   453,   454,    -1,    10,    71,    -1,   459,   460,
      -1,    -1,    -1,    -1,    -1,    -1,    21,    22,    -1,     1,
      -1,    -1,    -1,    -1,     6,    30,    -1,    -1,    10,    34,
      12,    13,    14,    -1,    39,    -1,    -1,    -1,    20,    21,
      22,    -1,    -1,   108,   109,   110,   111,    29,    30,    -1,
      -1,    33,    34,    35,    -1,    -1,    -1,    39,    -1,    -1,
      -1,    -1,    -1,    68,    -1,     4,    -1,    -1,    50,    51,
      52,    53,    54,    -1,    -1,    -1,     1,    -1,    -1,    -1,
      -1,     6,    -1,    -1,    -1,    10,    68,    12,    13,    14,
      -1,    -1,    -1,    -1,    76,    20,    21,    22,    -1,    -1,
      -1,    -1,    -1,    -1,    29,    30,    -1,    -1,    33,    34,
      35,    -1,    -1,    -1,    39,    -1,    55,    56,    57,    58,
      59,    60,    61,     4,    -1,    50,    51,    52,    53,    54,
      69,    70,    -1,     1,    73,    74,    75,    -1,     6,    -1,
      -1,    -1,    10,    68,    12,    13,    14,    -1,    -1,    -1,
      -1,    76,    20,    21,    22,    -1,    -1,    -1,    -1,    -1,
      -1,    29,    30,    -1,    -1,    33,    34,    35,    -1,    -1,
      -1,    39,    -1,    -1,    55,    56,    57,    58,    59,    60,
      61,    -1,    50,    51,    52,    53,    54,    -1,    69,    70,
       1,    -1,    73,    74,    75,     6,    -1,    -1,    -1,    10,
      68,    12,    13,    14,    -1,    -1,    -1,    -1,    76,    20,
      21,    22,    -1,    -1,    -1,    -1,    -1,    -1,    29,    30,
       6,    -1,    33,    34,    35,    -1,    -1,    -1,    39,    -1,
      -1,    -1,    -1,    -1,    -1,    21,    22,    -1,    -1,    50,
      51,    52,    53,    54,    30,    31,    -1,     1,    34,    -1,
      36,    37,     6,    39,    40,    41,    10,    68,    12,    13,
      14,    -1,    -1,    -1,    -1,    76,    20,    21,    22,    -1,
      -1,    -1,    -1,    -1,    -1,    29,    30,    -1,     6,    33,
      34,    35,    68,    -1,    -1,    39,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    21,    22,    -1,    50,    51,    52,    53,
      54,    -1,    30,    31,     1,    -1,    34,    -1,    -1,     6,
      -1,    39,    -1,    10,    68,    12,    -1,    14,    -1,    -1,
      -1,    -1,    76,    20,    21,    22,    -1,    -1,    -1,    -1,
      -1,    -1,    29,    30,    -1,     6,    33,    34,    35,    10,
      68,    -1,    39,    -1,    -1,     6,    17,    18,    -1,    20,
      21,    22,    -1,    50,    51,    52,    53,    54,    -1,    -1,
      21,    22,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    30,
      31,    68,    -1,    34,    45,    -1,     6,    -1,    39,    76,
      10,    11,    -1,    -1,    55,    56,    -1,    17,    18,    -1,
      20,    21,    22,    64,     6,    -1,    -1,    68,    10,    -1,
      71,    -1,    21,    22,    -1,    17,    18,    68,    20,    21,
      22,    30,    31,    -1,    -1,    45,    -1,    36,    37,    -1,
      -1,    40,    41,    -1,    -1,    55,    56,    -1,    -1,    -1,
      -1,    -1,    -1,    45,    64,    -1,    -1,    -1,    -1,    -1,
      -1,    71,    -1,    55,    56,    -1,    -1,    -1,    -1,    68,
      -1,    -1,    64,    -1,    -1,    -1,    -1,    -1,    -1,    71,
      55,    56,    57,    58,    59,    60,    61,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    69,    70,    -1,    -1,    73,    74,
      75
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_uint8 yystos[] =
{
       0,     1,     3,     6,     9,    14,    45,    72,    91,   124,
     125,   126,   130,   133,   135,   136,   137,   138,   140,   156,
     157,   158,     7,    10,   137,   138,   157,   137,   127,   128,
     137,   138,   157,     7,    71,     0,   126,    12,     4,    55,
      56,    57,    58,    59,    60,    61,    69,    70,    73,    74,
      75,     5,    26,   137,   137,    10,    12,     5,    16,    26,
      10,   137,    10,    17,    18,    20,    21,    22,    45,    55,
      56,    64,    71,   137,   138,   139,   153,   154,   174,   191,
     192,   193,   194,   195,   196,   197,   198,   199,   200,   201,
     202,   203,   204,   205,   191,   191,   191,   191,   191,   191,
     191,   191,   191,   191,   191,   138,   149,   150,   199,     8,
      11,    11,   137,   141,    10,    21,    22,    30,    34,    39,
      68,   134,   138,   159,   164,   166,   167,   168,   170,   179,
     181,   182,   183,   185,   128,   149,    49,   103,   108,   109,
     110,   111,   129,     8,   108,   109,   110,   111,   191,    38,
     202,   202,   202,   138,   138,   202,    10,     4,    55,    56,
      57,    58,    59,    60,    61,    69,    70,    73,    74,    75,
      13,    16,    44,    43,    62,    67,    63,    19,    42,     7,
       8,    27,    28,    65,    66,    21,    22,    23,    24,    25,
       5,    16,     7,    19,    27,   151,     4,    12,    11,    16,
     159,   191,    17,    13,   179,    23,    16,   168,   185,    31,
     164,   168,   173,   188,   189,    30,     5,   182,    38,    72,
     180,    36,    37,    40,    41,   190,   164,     5,    11,    11,
      11,    11,    11,    11,   138,   153,    11,   139,   192,   192,
     192,   192,   192,   192,   192,   192,   192,   192,   192,   191,
     193,   194,   195,   196,   197,   198,   198,   199,   199,   199,
     199,   200,   200,   201,   201,   202,   202,   202,   150,   199,
     138,    72,   131,   132,   137,     1,    12,    13,    20,    29,
      33,    35,    50,    51,    52,    53,    54,    76,   138,   142,
     143,   144,   145,   146,   147,   148,   152,   153,   154,   155,
     156,   160,   161,   176,   179,    12,   137,    11,    11,     5,
      10,   138,   205,   166,   164,   189,    32,   173,   189,   190,
     164,   173,   164,   173,   188,   190,    72,   137,   191,   127,
      72,   164,   168,   184,   186,   187,   205,   205,   205,   205,
      11,   151,    12,   174,     5,    16,     5,   142,    38,   137,
     153,   154,     4,    10,    10,    10,   143,    10,   143,    10,
     191,    13,   143,     5,    26,    13,   142,   189,   164,    12,
     137,   174,   175,   177,   173,   190,   164,   173,   189,   173,
     173,   190,   164,   173,   189,   127,    10,   127,   187,    31,
     164,   172,   173,   189,   164,   186,   199,   131,    12,   132,
      13,    21,    22,    30,   163,   169,   171,   177,   177,   191,
     191,    52,   157,     5,   149,    13,   191,    16,   164,   173,
     189,   173,   189,   164,   173,   164,   173,   189,   173,   189,
     164,   173,   129,   172,   189,   164,   172,    13,   131,   162,
     163,   173,    30,    11,    11,    11,    11,    10,     5,     5,
      13,   175,   173,   189,   164,   173,   173,   173,   173,   189,
     164,   173,   173,   173,    11,   172,   172,    13,   163,   173,
      57,     4,    57,   178,   143,   143,   191,   191,   173,   173,
     173,   173,   163,   165,   167,    11,     5,    16,     5,   138,
     158,   167,    11,   143
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_uint8 yyr1[] =
{
       0,   123,   124,   125,   125,   126,   126,   126,   126,   126,
     126,   126,   126,   126,   126,   127,   127,   128,   128,   128,
     129,   129,   129,   129,   129,   129,   130,   131,   131,   132,
     132,   132,   133,   134,   134,   135,   136,   136,   137,   138,
     138,   139,   139,   140,   140,   140,   140,   141,   141,   142,
     142,   143,   143,   143,   143,   143,   143,   143,   143,   143,
     143,   144,   145,   146,   147,   148,   149,   149,   150,   150,
     151,   151,   152,   152,   152,   152,   152,   152,   152,   153,
     153,   154,   155,   155,   155,   155,   156,   156,   156,   157,
     158,   158,   158,   158,   158,   158,   158,   158,   158,   158,
     158,   158,   159,   159,   160,   161,   162,   162,   163,   163,
     164,   164,   165,   165,   166,   166,   167,   167,   167,   168,
     168,   169,   169,   170,   170,   170,   171,   171,   172,   172,
     173,   174,   175,   175,   175,   176,   176,   177,   177,   178,
     178,   179,   179,   179,   179,   179,   179,   180,   180,   181,
     181,   182,   182,   182,   182,   182,   182,   182,   182,   182,
     182,   182,   182,   182,   182,   182,   182,   182,   182,   182,
     182,   182,   182,   183,   183,   183,   184,   184,   184,   184,
     185,   185,   185,   185,   185,   186,   186,   186,   186,   186,
     187,   187,   188,   188,   189,   189,   190,   190,   190,   190,
     191,   191,   191,   191,   191,   191,   191,   191,   191,   191,
     191,   191,   192,   192,   193,   193,   194,   194,   195,   195,
     196,   196,   197,   197,   197,   198,   198,   198,   198,   198,
     199,   199,   199,   200,   200,   200,   201,   201,   201,   201,
     202,   202,   202,   202,   202,   202,   202,   203,   203,   203,
     204,   204,   204,   204,   204,   205,   205,   205,   205,   205,
     205,   205,   205
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     1,     2,     1,     1,     1,     1,     1,     1,
       3,     5,     2,     4,     1,     3,     1,     1,     1,     4,
       1,     1,     1,     1,     1,     1,     7,     3,     1,     5,
       4,     1,     5,     3,     2,     4,     2,     4,     1,     1,
       4,     3,     1,     6,     7,     7,     8,     3,     1,     2,
       1,     2,     4,     3,     3,     1,     1,     1,     1,     1,
       2,     5,     2,     5,     7,     9,     3,     1,     3,     5,
       1,     1,     1,     1,     1,     1,     1,     1,     3,     3,
       4,     3,     1,     1,     2,     2,     1,     2,     1,     3,
       3,     3,     3,     3,     3,     3,     3,     3,     3,     3,
       2,     2,     1,     2,     3,     6,     2,     1,     2,     3,
       3,     1,     3,     1,     1,     1,     1,     3,     1,     2,
       1,     2,     1,     1,     1,     1,     1,     1,     1,     1,
       3,     1,     1,     1,     3,     6,     5,     3,     1,     1,
       1,     1,     2,     2,     3,     4,     4,     2,     5,     3,
       3,     2,     3,     4,     5,     5,     6,     6,     4,     5,
       5,     6,     6,     5,     6,     6,     7,     7,     5,     6,
       6,     7,     7,     2,     1,     2,     1,     1,     2,     2,
       2,     3,     3,     4,     4,     2,     3,     3,     4,     4,
       2,     1,     2,     3,     2,     1,     1,     1,     1,     1,
       3,     3,     3,     3,     3,     3,     3,     3,     3,     3,
       3,     1,     3,     1,     3,     1,     3,     1,     3,     1,
       3,     1,     3,     3,     1,     3,     3,     3,     3,     1,
       3,     3,     1,     3,     3,     1,     3,     3,     3,     1,
       2,     2,     2,     2,     2,     2,     1,     2,     2,     1,
       4,     4,     4,     4,     1,     1,     1,     1,     1,     1,
       1,     3,     3
};


enum { YYENOMEM = -2 };

#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab
#define YYNOMEM         goto yyexhaustedlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
  do                                                              \
    if (yychar == YYEMPTY)                                        \
      {                                                           \
        yychar = (Token);                                         \
        yylval = (Value);                                         \
        YYPOPSTACK (yylen);                                       \
        yystate = *yyssp;                                         \
        goto yybackup;                                            \
      }                                                           \
    else                                                          \
      {                                                           \
        yyerror (YY_("syntax error: cannot back up")); \
        YYERROR;                                                  \
      }                                                           \
  while (0)

/* Backward compatibility with an undocumented macro.
   Use YYerror or YYUNDEF. */
#define YYERRCODE YYUNDEF

/* YYLLOC_DEFAULT -- Set CURRENT to span from RHS[1] to RHS[N].
   If N is 0, then set CURRENT to the empty location which ends
   the previous symbol: RHS[0] (always defined).  */

#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)                                \
    do                                                                  \
      if (N)                                                            \
        {                                                               \
          (Current).first_line   = YYRHSLOC (Rhs, 1).first_line;        \
          (Current).first_column = YYRHSLOC (Rhs, 1).first_column;      \
          (Current).last_line    = YYRHSLOC (Rhs, N).last_line;         \
          (Current).last_column  = YYRHSLOC (Rhs, N).last_column;       \
        }                                                               \
      else                                                              \
        {                                                               \
          (Current).first_line   = (Current).last_line   =              \
            YYRHSLOC (Rhs, 0).last_line;                                \
          (Current).first_column = (Current).last_column =              \
            YYRHSLOC (Rhs, 0).last_column;                              \
        }                                                               \
    while (0)
#endif

#define YYRHSLOC(Rhs, K) ((Rhs)[K])


/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)


/* YYLOCATION_PRINT -- Print the location on the stream.
   This macro was not mandated originally: define only if we know
   we won't break user code: when these are the locations we know.  */

# ifndef YYLOCATION_PRINT

#  if defined YY_LOCATION_PRINT

   /* Temporary convenience wrapper in case some people defined the
      undocumented and private YY_LOCATION_PRINT macros.  */
#   define YYLOCATION_PRINT(File, Loc)  YY_LOCATION_PRINT(File, *(Loc))

#  elif defined YYLTYPE_IS_TRIVIAL && YYLTYPE_IS_TRIVIAL

/* Print *YYLOCP on YYO.  Private, do not rely on its existence. */

YY_ATTRIBUTE_UNUSED
static int
yy_location_print_ (FILE *yyo, YYLTYPE const * const yylocp)
{
  int res = 0;
  int end_col = 0 != yylocp->last_column ? yylocp->last_column - 1 : 0;
  if (0 <= yylocp->first_line)
    {
      res += YYFPRINTF (yyo, "%d", yylocp->first_line);
      if (0 <= yylocp->first_column)
        res += YYFPRINTF (yyo, ".%d", yylocp->first_column);
    }
  if (0 <= yylocp->last_line)
    {
      if (yylocp->first_line < yylocp->last_line)
        {
          res += YYFPRINTF (yyo, "-%d", yylocp->last_line);
          if (0 <= end_col)
            res += YYFPRINTF (yyo, ".%d", end_col);
        }
      else if (0 <= end_col && yylocp->first_column < end_col)
        res += YYFPRINTF (yyo, "-%d", end_col);
    }
  return res;
}

#   define YYLOCATION_PRINT  yy_location_print_

    /* Temporary convenience wrapper in case some people defined the
       undocumented and private YY_LOCATION_PRINT macros.  */
#   define YY_LOCATION_PRINT(File, Loc)  YYLOCATION_PRINT(File, &(Loc))

#  else

#   define YYLOCATION_PRINT(File, Loc) ((void) 0)
    /* Temporary convenience wrapper in case some people defined the
       undocumented and private YY_LOCATION_PRINT macros.  */
#   define YY_LOCATION_PRINT  YYLOCATION_PRINT

#  endif
# endif /* !defined YYLOCATION_PRINT */


# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Kind, Value, Location); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo,
                       yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep, YYLTYPE const * const yylocationp)
{
  FILE *yyoutput = yyo;
  YY_USE (yyoutput);
  YY_USE (yylocationp);
  if (!yyvaluep)
    return;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo,
                 yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep, YYLTYPE const * const yylocationp)
{
  YYFPRINTF (yyo, "%s %s (",
             yykind < YYNTOKENS ? "token" : "nterm", yysymbol_name (yykind));

  YYLOCATION_PRINT (yyo, yylocationp);
  YYFPRINTF (yyo, ": ");
  yy_symbol_value_print (yyo, yykind, yyvaluep, yylocationp);
  YYFPRINTF (yyo, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yy_state_t *yybottom, yy_state_t *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yy_state_t *yyssp, YYSTYPE *yyvsp, YYLTYPE *yylsp,
                 int yyrule)
{
  int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %d):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       YY_ACCESSING_SYMBOL (+yyssp[yyi + 1 - yynrhs]),
                       &yyvsp[(yyi + 1) - (yynrhs)],
                       &(yylsp[(yyi + 1) - (yynrhs)]));
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, yylsp, Rule); \
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args) ((void) 0)
# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif






/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg,
            yysymbol_kind_t yykind, YYSTYPE *yyvaluep, YYLTYPE *yylocationp)
{
  YY_USE (yyvaluep);
  YY_USE (yylocationp);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yykind, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/* Lookahead token kind.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;
/* Location data for the lookahead symbol.  */
YYLTYPE yylloc
# if defined YYLTYPE_IS_TRIVIAL && YYLTYPE_IS_TRIVIAL
  = { 1, 1, 1, 1 }
# endif
;
/* Number of syntax errors so far.  */
int yynerrs;




/*----------.
| yyparse.  |
`----------*/

int
yyparse (void)
{
    yy_state_fast_t yystate = 0;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus = 0;

    /* Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* Their size.  */
    YYPTRDIFF_T yystacksize = YYINITDEPTH;

    /* The state stack: array, bottom, top.  */
    yy_state_t yyssa[YYINITDEPTH];
    yy_state_t *yyss = yyssa;
    yy_state_t *yyssp = yyss;

    /* The semantic value stack: array, bottom, top.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs = yyvsa;
    YYSTYPE *yyvsp = yyvs;

    /* The location stack: array, bottom, top.  */
    YYLTYPE yylsa[YYINITDEPTH];
    YYLTYPE *yyls = yylsa;
    YYLTYPE *yylsp = yyls;

  int yyn;
  /* The return value of yyparse.  */
  int yyresult;
  /* Lookahead symbol kind.  */
  yysymbol_kind_t yytoken = YYSYMBOL_YYEMPTY;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;
  YYLTYPE yyloc;

  /* The locations where the error started and ended.  */
  YYLTYPE yyerror_range[3];



#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N), yylsp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yychar = YYEMPTY; /* Cause a token to be read.  */

  yylsp[0] = yylloc;
  goto yysetstate;


/*------------------------------------------------------------.
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yysetstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  YYDPRINTF ((stderr, "Entering state %d\n", yystate));
  YY_ASSERT (0 <= yystate && yystate < YYNSTATES);
  YY_IGNORE_USELESS_CAST_BEGIN
  *yyssp = YY_CAST (yy_state_t, yystate);
  YY_IGNORE_USELESS_CAST_END
  YY_STACK_PRINT (yyss, yyssp);

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    YYNOMEM;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYPTRDIFF_T yysize = yyssp - yyss + 1;

# if defined yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        yy_state_t *yyss1 = yyss;
        YYSTYPE *yyvs1 = yyvs;
        YYLTYPE *yyls1 = yyls;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * YYSIZEOF (*yyssp),
                    &yyvs1, yysize * YYSIZEOF (*yyvsp),
                    &yyls1, yysize * YYSIZEOF (*yylsp),
                    &yystacksize);
        yyss = yyss1;
        yyvs = yyvs1;
        yyls = yyls1;
      }
# else /* defined YYSTACK_RELOCATE */
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        YYNOMEM;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yy_state_t *yyss1 = yyss;
        union yyalloc *yyptr =
          YY_CAST (union yyalloc *,
                   YYSTACK_ALLOC (YY_CAST (YYSIZE_T, YYSTACK_BYTES (yystacksize))));
        if (! yyptr)
          YYNOMEM;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
        YYSTACK_RELOCATE (yyls_alloc, yyls);
#  undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;
      yylsp = yyls + yysize - 1;

      YY_IGNORE_USELESS_CAST_BEGIN
      YYDPRINTF ((stderr, "Stack size increased to %ld\n",
                  YY_CAST (long, yystacksize)));
      YY_IGNORE_USELESS_CAST_END

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */


  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;


/*-----------.
| yybackup.  |
`-----------*/
yybackup:
  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yypact_value_is_default (yyn))
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either empty, or end-of-input, or a valid lookahead.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token\n"));
      yychar = yylex ();
    }

  if (yychar <= YYEOF)
    {
      yychar = YYEOF;
      yytoken = YYSYMBOL_YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else if (yychar == YYerror)
    {
      /* The scanner already issued an error message, process directly
         to error recovery.  But do not keep the error token as
         lookahead, it is too special and may lead us to an endless
         loop in error recovery. */
      yychar = YYUNDEF;
      yytoken = YYSYMBOL_YYerror;
      yyerror_range[1] = yylloc;
      goto yyerrlab1;
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yytable_value_is_error (yyn))
        goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);
  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END
  *++yylsp = yylloc;

  /* Discard the shifted token.  */
  yychar = YYEMPTY;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];

  /* Default location. */
  YYLLOC_DEFAULT (yyloc, (yylsp - yylen), yylen);
  yyerror_range[1] = yyloc;
  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
  case 2: /* plingua: definitions  */
#line 101 "src/parser/plingua.y"
                      {plingua::parser::PARSER.addNode((yyvsp[0].node));}
#line 1923 "src/parser/y.tab.c"
    break;

  case 3: /* definitions: definitions definition  */
#line 103 "src/parser/plingua.y"
                                     {(yyval.node) = (yyvsp[-1].node)->addChild((yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yyvsp[0].node));}
#line 1929 "src/parser/y.tab.c"
    break;

  case 4: /* definitions: definition  */
#line 104 "src/parser/plingua.y"
                                                         {(yyval.node) = new Node(DEFINITIONS,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 1935 "src/parser/y.tab.c"
    break;

  case 5: /* definition: include  */
#line 107 "src/parser/plingua.y"
                                                                   {(yyval.node) = (yyvsp[0].node);}
#line 1941 "src/parser/y.tab.c"
    break;

  case 6: /* definition: model  */
#line 108 "src/parser/plingua.y"
                                                                           {(yyval.node) = (yyvsp[0].node);}
#line 1947 "src/parser/y.tab.c"
    break;

  case 7: /* definition: model_definition  */
#line 109 "src/parser/plingua.y"
                                                                           {(yyval.node) = (yyvsp[0].node);}
#line 1953 "src/parser/y.tab.c"
    break;

  case 8: /* definition: pattern  */
#line 110 "src/parser/plingua.y"
                                                                           {(yyval.node) = (yyvsp[0].node);}
#line 1959 "src/parser/y.tab.c"
    break;

  case 9: /* definition: module  */
#line 111 "src/parser/plingua.y"
                                                                           {(yyval.node) = (yyvsp[0].node);}
#line 1965 "src/parser/y.tab.c"
    break;

  case 10: /* definition: AT_SYMBOL features SEPARATOR  */
#line 112 "src/parser/plingua.y"
                                                               {(yyval.node) = (yyvsp[-1].node);}
#line 1971 "src/parser/y.tab.c"
    break;

  case 11: /* definition: AT_SYMBOL features COLON ranges SEPARATOR  */
#line 113 "src/parser/plingua.y"
                                                               {(yyval.node) = (yyvsp[-3].node)->addChild((yyvsp[-1].node));}
#line 1977 "src/parser/y.tab.c"
    break;

  case 12: /* definition: assignment SEPARATOR  */
#line 114 "src/parser/plingua.y"
                                                                           {(yyval.node) = (yyvsp[-1].node);}
#line 1983 "src/parser/y.tab.c"
    break;

  case 13: /* definition: assignment COLON ranges SEPARATOR  */
#line 115 "src/parser/plingua.y"
                                                               {(yyval.node) = (yyvsp[-3].node)->addChild((yyvsp[-1].node));}
#line 1989 "src/parser/y.tab.c"
    break;

  case 14: /* definition: error  */
#line 116 "src/parser/plingua.y"
                                                                                           {(yyval.node) = new Node(ERROR); (yyval.node)->setLoc((yylsp[0]));}
#line 1995 "src/parser/y.tab.c"
    break;

  case 15: /* features: features COMMA feature  */
#line 120 "src/parser/plingua.y"
                                    {(yyval.node) = (yyvsp[-2].node)->addChild((yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2001 "src/parser/y.tab.c"
    break;

  case 16: /* features: feature  */
#line 121 "src/parser/plingua.y"
                                    {(yyval.node) = new Node(FEATURE,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2007 "src/parser/y.tab.c"
    break;

  case 17: /* feature: simple_assignment  */
#line 124 "src/parser/plingua.y"
                                       {(yyval.node) = (yyvsp[0].node);}
#line 2013 "src/parser/y.tab.c"
    break;

  case 18: /* feature: variable  */
#line 125 "src/parser/plingua.y"
                                       {(yyval.node) = (yyvsp[0].node);}
#line 2019 "src/parser/y.tab.c"
    break;

  case 19: /* feature: id LPAR type RPAR  */
#line 126 "src/parser/plingua.y"
                                       {(yyval.node) = (yyvsp[-3].node)->addChild((yyvsp[-1].node));(yyval.node)->setLoc((yyvsp[-3].node),(yylsp[0]));}
#line 2025 "src/parser/y.tab.c"
    break;

  case 20: /* type: INT_TYPE  */
#line 129 "src/parser/plingua.y"
                     {(yyval.node) = new Node(INT_TYPE); }
#line 2031 "src/parser/y.tab.c"
    break;

  case 21: /* type: LONG_TYPE  */
#line 130 "src/parser/plingua.y"
                     {(yyval.node) = new Node(LONG_TYPE); }
#line 2037 "src/parser/y.tab.c"
    break;

  case 22: /* type: DOUBLE_TYPE  */
#line 131 "src/parser/plingua.y"
                     {(yyval.node) = new Node(DOUBLE_TYPE); }
#line 2043 "src/parser/y.tab.c"
    break;

  case 23: /* type: STRING_TYPE  */
#line 132 "src/parser/plingua.y"
                     {(yyval.node) = new Node(STRING_TYPE); }
#line 2049 "src/parser/y.tab.c"
    break;

  case 24: /* type: PROB_TYPE  */
#line 133 "src/parser/plingua.y"
                     {(yyval.node) = new Node(PROB_TYPE); }
#line 2055 "src/parser/y.tab.c"
    break;

  case 25: /* type: REXP_TYPE  */
#line 134 "src/parser/plingua.y"
                     {(yyval.node) = new Node(REXP_TYPE); }
#line 2061 "src/parser/y.tab.c"
    break;

  case 26: /* model_definition: MODEL LPAR id RPAR ASIG model_body SEPARATOR  */
#line 138 "src/parser/plingua.y"
                                                                {(yyval.node) = new Node(MODEL_DEFINITION, (yyvsp[-4].node), (yyvsp[-1].node)); (yyval.node)->setLoc((yylsp[-6]),(yyvsp[-1].node));}
#line 2067 "src/parser/y.tab.c"
    break;

  case 27: /* model_body: model_body COMMA model_element  */
#line 141 "src/parser/plingua.y"
                                                        {(yyval.node) = (yyvsp[-2].node)->addChild((yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2073 "src/parser/y.tab.c"
    break;

  case 28: /* model_body: model_element  */
#line 142 "src/parser/plingua.y"
                                                                        {(yyval.node) = new Node(MODEL_BODY,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2079 "src/parser/y.tab.c"
    break;

  case 29: /* model_element: AT_SYMBOL non_negative_long LBRACE model_body RBRACE  */
#line 145 "src/parser/plingua.y"
                                                                     {(yyval.node) = new Node(MODEL_ELEMENT,(yyvsp[-3].node),(yyvsp[-1].node));(yyval.node)->setLoc((yylsp[-4]),(yylsp[0]));}
#line 2085 "src/parser/y.tab.c"
    break;

  case 30: /* model_element: AT_SYMBOL LBRACE model_body RBRACE  */
#line 146 "src/parser/plingua.y"
                                                   {(yyval.node) = new Node(MODEL_ELEMENT,(yyvsp[-1].node));(yyval.node)->setLoc((yylsp[-3]),(yylsp[0]));}
#line 2091 "src/parser/y.tab.c"
    break;

  case 31: /* model_element: id  */
#line 147 "src/parser/plingua.y"
                        {(yyval.node) = (yyvsp[0].node);}
#line 2097 "src/parser/y.tab.c"
    break;

  case 32: /* pattern: NOT id LBRACE rules RBRACE  */
#line 150 "src/parser/plingua.y"
                                      {(yyval.node) = new Node(PATTERN,(yyvsp[-3].node),(yyvsp[-1].node)); (yyval.node)->setLoc((yylsp[-4]),(yylsp[0]));}
#line 2103 "src/parser/y.tab.c"
    break;

  case 33: /* rules: rules rule SEPARATOR  */
#line 153 "src/parser/plingua.y"
                                {(yyval.node) = (yyvsp[-2].node)->addChild((yyvsp[-1].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[-1].node));}
#line 2109 "src/parser/y.tab.c"
    break;

  case 34: /* rules: rule SEPARATOR  */
#line 154 "src/parser/plingua.y"
                                    {(yyval.node) = new Node(RULES,(yyvsp[-1].node)); (yyval.node)->setLoc((yyvsp[-1].node));}
#line 2115 "src/parser/y.tab.c"
    break;

  case 35: /* model: MODEL LESS_THAN id GREATER_THAN  */
#line 159 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(MODEL,(yyvsp[-1].node)); (yyval.node)->setLoc((yylsp[-3]),(yylsp[0]));}
#line 2121 "src/parser/y.tab.c"
    break;

  case 36: /* include: INCLUDE STRING  */
#line 162 "src/parser/plingua.y"
                         {(yyval.node) = new Node(INCLUDE,(yyvsp[0].stringValue)); (yyval.node)->setLoc((yylsp[-1]),(yylsp[0]));}
#line 2127 "src/parser/y.tab.c"
    break;

  case 37: /* include: INCLUDE LESS_THAN id GREATER_THAN  */
#line 163 "src/parser/plingua.y"
                                                    {(yyval.node) = new Node(INCLUDE,(yyvsp[-1].node)); (yyval.node)->setLoc((yylsp[-3]),(yylsp[0]));}
#line 2133 "src/parser/y.tab.c"
    break;

  case 38: /* id: ID  */
#line 166 "src/parser/plingua.y"
        {(yyval.node) = new Node(ID,(yyvsp[0].stringValue)); (yyval.node)->setLoc((yylsp[0]));}
#line 2139 "src/parser/y.tab.c"
    break;

  case 39: /* variable: id  */
#line 169 "src/parser/plingua.y"
              {(yyval.node) = new Node(VARIABLE,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2145 "src/parser/y.tab.c"
    break;

  case 40: /* variable: id LBRACE arguments RBRACE  */
#line 170 "src/parser/plingua.y"
                                              {(yyval.node) = new Node(VARIABLE, (yyvsp[-3].node), (yyvsp[-1].node)->setType(INDEXES)); (yyval.node)->setLoc((yyvsp[-3].node),(yylsp[0]));}
#line 2151 "src/parser/y.tab.c"
    break;

  case 41: /* arguments: arguments COMMA expr  */
#line 173 "src/parser/plingua.y"
                                 {(yyval.node) = (yyvsp[-2].node)->addChild((yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2157 "src/parser/y.tab.c"
    break;

  case 42: /* arguments: expr  */
#line 174 "src/parser/plingua.y"
                                                 {(yyval.node) = new Node(ARGUMENTS,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2163 "src/parser/y.tab.c"
    break;

  case 43: /* module: DEF id LPAR RPAR LBRACE RBRACE  */
#line 177 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(MODULE,(yyvsp[-4].node)); (yyval.node)->setLoc((yylsp[-5]),(yylsp[0]));}
#line 2169 "src/parser/y.tab.c"
    break;

  case 44: /* module: DEF id LPAR RPAR LBRACE sentences RBRACE  */
#line 178 "src/parser/plingua.y"
                                                  {(yyval.node) = new Node(MODULE,(yyvsp[-5].node),(yyvsp[-1].node)); (yyval.node)->setLoc((yylsp[-6]),(yylsp[0]));}
#line 2175 "src/parser/y.tab.c"
    break;

  case 45: /* module: DEF id LPAR parameters RPAR LBRACE RBRACE  */
#line 179 "src/parser/plingua.y"
                                                   {(yyval.node) = new Node(MODULE,(yyvsp[-5].node),(yyvsp[-3].node)); (yyval.node)->setLoc((yylsp[-6]),(yylsp[0]));}
#line 2181 "src/parser/y.tab.c"
    break;

  case 46: /* module: DEF id LPAR parameters RPAR LBRACE sentences RBRACE  */
#line 180 "src/parser/plingua.y"
                                                                 {(yyval.node) = new Node(MODULE,(yyvsp[-6].node),(yyvsp[-4].node),(yyvsp[-1].node)); (yyval.node)->setLoc((yylsp[-7]),(yylsp[0]));}
#line 2187 "src/parser/y.tab.c"
    break;

  case 47: /* parameters: parameters COMMA id  */
#line 183 "src/parser/plingua.y"
                                        {(yyval.node) = (yyvsp[-2].node)->addChild(new Node(VARIABLE,(yyvsp[0].node))); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2193 "src/parser/y.tab.c"
    break;

  case 48: /* parameters: id  */
#line 184 "src/parser/plingua.y"
                                                        {(yyval.node) = new Node(PARAMETERS,new Node(VARIABLE,(yyvsp[0].node))); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2199 "src/parser/y.tab.c"
    break;

  case 49: /* sentences: sentences sentence  */
#line 187 "src/parser/plingua.y"
                                {(yyval.node) = (yyvsp[-1].node)->addChild((yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yyvsp[0].node));}
#line 2205 "src/parser/y.tab.c"
    break;

  case 50: /* sentences: sentence  */
#line 188 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(SENTENCES,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2211 "src/parser/y.tab.c"
    break;

  case 51: /* sentence: instruction SEPARATOR  */
#line 191 "src/parser/plingua.y"
                                                        {(yyval.node) = (yyvsp[-1].node);}
#line 2217 "src/parser/y.tab.c"
    break;

  case 52: /* sentence: instruction COLON ranges SEPARATOR  */
#line 192 "src/parser/plingua.y"
                                                {(yyval.node) = (yyvsp[-3].node)->addChild((yyvsp[-1].node));}
#line 2223 "src/parser/y.tab.c"
    break;

  case 53: /* sentence: LBRACE sentences RBRACE  */
#line 193 "src/parser/plingua.y"
                                                                {(yyval.node) = (yyvsp[-1].node);}
#line 2229 "src/parser/y.tab.c"
    break;

  case 54: /* sentence: RETURN expr SEPARATOR  */
#line 194 "src/parser/plingua.y"
                                                                {(yyval.node) = new Node(RETURN,(yyvsp[-1].node)); (yyval.node)->setLoc((yylsp[-2]),(yyvsp[-1].node));}
#line 2235 "src/parser/y.tab.c"
    break;

  case 55: /* sentence: if  */
#line 195 "src/parser/plingua.y"
                                                                                {(yyval.node) = (yyvsp[0].node);}
#line 2241 "src/parser/y.tab.c"
    break;

  case 56: /* sentence: else  */
#line 196 "src/parser/plingua.y"
                                                                                {(yyval.node) = (yyvsp[0].node);}
#line 2247 "src/parser/y.tab.c"
    break;

  case 57: /* sentence: while  */
#line 197 "src/parser/plingua.y"
                                                                                {(yyval.node) = (yyvsp[0].node);}
#line 2253 "src/parser/y.tab.c"
    break;

  case 58: /* sentence: dowhile  */
#line 198 "src/parser/plingua.y"
                                                                                {(yyval.node) = (yyvsp[0].node);}
#line 2259 "src/parser/y.tab.c"
    break;

  case 59: /* sentence: for  */
#line 199 "src/parser/plingua.y"
                                                                                {(yyval.node) = (yyvsp[0].node);}
#line 2265 "src/parser/y.tab.c"
    break;

  case 60: /* sentence: error SEPARATOR  */
#line 200 "src/parser/plingua.y"
                                                        {(yyval.node) = new Node(ERROR); (yyval.node)->setLoc((yylsp[-1]),(yylsp[0]));}
#line 2271 "src/parser/y.tab.c"
    break;

  case 61: /* if: IF LPAR expr RPAR sentence  */
#line 203 "src/parser/plingua.y"
                                {(yyval.node) = new Node(IF,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-4]),(yyvsp[0].node));}
#line 2277 "src/parser/y.tab.c"
    break;

  case 62: /* else: ELSE sentence  */
#line 206 "src/parser/plingua.y"
                     {(yyval.node) = new Node(ELSE,(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-1]),(yyvsp[0].node));}
#line 2283 "src/parser/y.tab.c"
    break;

  case 63: /* while: WHILE LPAR expr RPAR sentence  */
#line 209 "src/parser/plingua.y"
                                      {(yyval.node) = new Node(WHILE,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-4]),(yyvsp[0].node));}
#line 2289 "src/parser/y.tab.c"
    break;

  case 64: /* dowhile: DO sentence WHILE LPAR expr RPAR SEPARATOR  */
#line 212 "src/parser/plingua.y"
                                                     {(yyval.node) = new Node(DO,(yyvsp[-5].node),(yyvsp[-2].node)); (yyval.node)->setLoc((yylsp[-6]),(yylsp[-1]));}
#line 2295 "src/parser/y.tab.c"
    break;

  case 65: /* for: FOR LPAR simple_assignment SEPARATOR expr SEPARATOR increment RPAR sentence  */
#line 216 "src/parser/plingua.y"
      {(yyval.node) = new Node(FOR,(yyvsp[-6].node),(yyvsp[-4].node),(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-8]),(yyvsp[0].node));}
#line 2301 "src/parser/y.tab.c"
    break;

  case 66: /* ranges: ranges COMMA range  */
#line 219 "src/parser/plingua.y"
                                {(yyval.node) = (yyvsp[-2].node)->addChild((yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2307 "src/parser/y.tab.c"
    break;

  case 67: /* ranges: range  */
#line 220 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(RANGES,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2313 "src/parser/y.tab.c"
    break;

  case 68: /* range: expr45 DIFF expr45  */
#line 223 "src/parser/plingua.y"
                                                                        {(yyval.node) = new Node(DIFF,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2319 "src/parser/y.tab.c"
    break;

  case 69: /* range: expr45 rangeCmp variable rangeCmp expr45  */
#line 224 "src/parser/plingua.y"
                                                        {(yyval.node) = new Node(RANGE,(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-4].node),(yyvsp[0].node));}
#line 2325 "src/parser/y.tab.c"
    break;

  case 70: /* rangeCmp: LESS_THAN  */
#line 227 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(LESS_THAN); (yyval.node)->setLoc((yylsp[0]));}
#line 2331 "src/parser/y.tab.c"
    break;

  case 71: /* rangeCmp: LESS_OR_EQUAL_THAN  */
#line 228 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(LESS_OR_EQUAL_THAN); (yyval.node)->setLoc((yylsp[0]));}
#line 2337 "src/parser/y.tab.c"
    break;

  case 72: /* instruction: call  */
#line 231 "src/parser/plingua.y"
                                                                {(yyval.node) = (yyvsp[0].node);}
#line 2343 "src/parser/y.tab.c"
    break;

  case 73: /* instruction: assignment  */
#line 232 "src/parser/plingua.y"
                                                        {(yyval.node) = (yyvsp[0].node);}
#line 2349 "src/parser/y.tab.c"
    break;

  case 74: /* instruction: initialMembraneStructure  */
#line 233 "src/parser/plingua.y"
                                                    {(yyval.node) = (yyvsp[0].node);}
#line 2355 "src/parser/y.tab.c"
    break;

  case 75: /* instruction: extendMembraneStructure  */
#line 234 "src/parser/plingua.y"
                                                    {(yyval.node) = (yyvsp[0].node);}
#line 2361 "src/parser/y.tab.c"
    break;

  case 76: /* instruction: initialMultiset  */
#line 235 "src/parser/plingua.y"
                                                                {(yyval.node) = (yyvsp[0].node);}
#line 2367 "src/parser/y.tab.c"
    break;

  case 77: /* instruction: rule  */
#line 236 "src/parser/plingua.y"
                                                                        {(yyval.node) = (yyvsp[0].node);}
#line 2373 "src/parser/y.tab.c"
    break;

  case 78: /* instruction: LBRACE sentences RBRACE  */
#line 237 "src/parser/plingua.y"
                                                    {(yyval.node) = (yyvsp[-1].node);}
#line 2379 "src/parser/y.tab.c"
    break;

  case 79: /* regular_call: id LPAR RPAR  */
#line 241 "src/parser/plingua.y"
                                                    {(yyval.node) = new Node(CALL,(yyvsp[-2].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yylsp[0]));}
#line 2385 "src/parser/y.tab.c"
    break;

  case 80: /* regular_call: id LPAR arguments RPAR  */
#line 242 "src/parser/plingua.y"
                                                    {(yyval.node) = new Node(CALL,(yyvsp[-3].node),(yyvsp[-1].node)); (yyval.node)->setLoc((yyvsp[-3].node),(yylsp[0]));}
#line 2391 "src/parser/y.tab.c"
    break;

  case 81: /* system_call: SYSTEM DOUBLE_COLON regular_call  */
#line 245 "src/parser/plingua.y"
                                               {(yyval.node) = new Node(SYSTEM_CALL,(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-2]),(yyvsp[0].node));}
#line 2397 "src/parser/y.tab.c"
    break;

  case 82: /* call: regular_call  */
#line 248 "src/parser/plingua.y"
                    {(yyval.node) = (yyvsp[0].node);}
#line 2403 "src/parser/y.tab.c"
    break;

  case 83: /* call: system_call  */
#line 249 "src/parser/plingua.y"
                    {(yyval.node) = (yyvsp[0].node);}
#line 2409 "src/parser/y.tab.c"
    break;

  case 84: /* call: CALL regular_call  */
#line 250 "src/parser/plingua.y"
                         {(yyval.node) = (yyvsp[0].node);}
#line 2415 "src/parser/y.tab.c"
    break;

  case 85: /* call: CALL system_call  */
#line 251 "src/parser/plingua.y"
                        {(yyval.node) = (yyvsp[0].node);}
#line 2421 "src/parser/y.tab.c"
    break;

  case 86: /* assignment: simple_assignment  */
#line 254 "src/parser/plingua.y"
                                                    {(yyval.node) = (yyvsp[0].node);}
#line 2427 "src/parser/y.tab.c"
    break;

  case 87: /* assignment: LET simple_assignment  */
#line 255 "src/parser/plingua.y"
                                                                {(yyval.node) = (yyvsp[0].node); (yyval.node)->setLoc((yylsp[-1]),(yyvsp[0].node));}
#line 2433 "src/parser/y.tab.c"
    break;

  case 88: /* assignment: increment  */
#line 256 "src/parser/plingua.y"
                                                    {(yyval.node) = (yyvsp[0].node);}
#line 2439 "src/parser/y.tab.c"
    break;

  case 89: /* simple_assignment: variable ASIG expr  */
#line 259 "src/parser/plingua.y"
                                           {(yyval.node) = new Node(ASIG,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2445 "src/parser/y.tab.c"
    break;

  case 90: /* increment: variable INC_BY expr  */
#line 262 "src/parser/plingua.y"
                                                        {(yyval.node) = new Node(INC_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2451 "src/parser/y.tab.c"
    break;

  case 91: /* increment: variable DEC_BY expr  */
#line 263 "src/parser/plingua.y"
                                                                {(yyval.node) = new Node(DEC_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2457 "src/parser/y.tab.c"
    break;

  case 92: /* increment: variable MUL_BY expr  */
#line 264 "src/parser/plingua.y"
                                                                {(yyval.node) = new Node(MUL_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2463 "src/parser/y.tab.c"
    break;

  case 93: /* increment: variable DIV_BY expr  */
#line 265 "src/parser/plingua.y"
                                                                {(yyval.node) = new Node(DIV_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2469 "src/parser/y.tab.c"
    break;

  case 94: /* increment: variable MOD_BY expr  */
#line 266 "src/parser/plingua.y"
                                                        {(yyval.node) = new Node(MOD_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2475 "src/parser/y.tab.c"
    break;

  case 95: /* increment: variable BITWISE_LEFT_BY expr  */
#line 267 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(BITWISE_LEFT_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2481 "src/parser/y.tab.c"
    break;

  case 96: /* increment: variable BITWISE_RIGHT_BY expr  */
#line 268 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(BITWISE_RIGHT_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2487 "src/parser/y.tab.c"
    break;

  case 97: /* increment: variable BITWISE_AND_BY expr  */
#line 269 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(BITWISE_AND_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2493 "src/parser/y.tab.c"
    break;

  case 98: /* increment: variable BITWISE_OR_BY expr  */
#line 270 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(BITWISE_OR_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2499 "src/parser/y.tab.c"
    break;

  case 99: /* increment: variable BITWISE_XOR_BY expr  */
#line 271 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(BITWISE_XOR_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2505 "src/parser/y.tab.c"
    break;

  case 100: /* increment: variable INC  */
#line 272 "src/parser/plingua.y"
                                                                        {(yyval.node) = new Node(POST_INC,(yyvsp[-1].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yylsp[0]));}
#line 2511 "src/parser/y.tab.c"
    break;

  case 101: /* increment: variable DEC  */
#line 273 "src/parser/plingua.y"
                                                                        {(yyval.node) = new Node(POST_DEC,(yyvsp[-1].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yylsp[0]));}
#line 2517 "src/parser/y.tab.c"
    break;

  case 102: /* anonymous: QUESTION_MARK  */
#line 277 "src/parser/plingua.y"
                                                                        {(yyval.node) = new Node(ANONYMOUS_VARIABLE,0L); (yyval.node)->setLoc((yylsp[0]));}
#line 2523 "src/parser/y.tab.c"
    break;

  case 103: /* anonymous: QUESTION_MARK NON_NEGATIVE_LONG  */
#line 278 "src/parser/plingua.y"
                                                                {(yyval.node) = new Node(ANONYMOUS_VARIABLE,(yyvsp[0].longValue)+1); (yyval.node)->setLoc((yylsp[-1]),(yylsp[0]));}
#line 2529 "src/parser/y.tab.c"
    break;

  case 104: /* initialMembraneStructure: MU ASIG membrane  */
#line 281 "src/parser/plingua.y"
                                                 {(yyval.node) = new Node(MU,(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-2]),(yyvsp[0].node));}
#line 2535 "src/parser/y.tab.c"
    break;

  case 105: /* extendMembraneStructure: MU LPAR labels RPAR INC_BY membrane  */
#line 284 "src/parser/plingua.y"
                                                                {(yyval.node) = new Node(EMU,(yyvsp[-3].node),(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-5]),(yyvsp[0].node));}
#line 2541 "src/parser/y.tab.c"
    break;

  case 106: /* membranes: membranes membrane  */
#line 287 "src/parser/plingua.y"
                                {(yyval.node) = (yyvsp[-1].node)->addChild((yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yyvsp[0].node));}
#line 2547 "src/parser/y.tab.c"
    break;

  case 107: /* membranes: membrane  */
#line 288 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(MEMBRANES,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2553 "src/parser/y.tab.c"
    break;

  case 108: /* membrane: lsquare0 rsquare0  */
#line 292 "src/parser/plingua.y"
                                                          {(yyval.node) = new Node(MEMBRANE,(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yyvsp[0].node));}
#line 2559 "src/parser/y.tab.c"
    break;

  case 109: /* membrane: lsquare0 membranes rsquare0  */
#line 293 "src/parser/plingua.y"
                                              {(yyval.node) = new Node(MEMBRANE,(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2565 "src/parser/y.tab.c"
    break;

  case 110: /* multiset: multiset COMMA multiobject  */
#line 296 "src/parser/plingua.y"
                                      {(yyval.node) = (yyvsp[-2].node)->addChild((yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2571 "src/parser/y.tab.c"
    break;

  case 111: /* multiset: multiobject  */
#line 297 "src/parser/plingua.y"
                                                          {(yyval.node) = new Node(MULTISET,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2577 "src/parser/y.tab.c"
    break;

  case 112: /* multiset0: multiset0 COMMA multiobject0  */
#line 300 "src/parser/plingua.y"
                                          {(yyval.node) = (yyvsp[-2].node)->addChild((yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2583 "src/parser/y.tab.c"
    break;

  case 113: /* multiset0: multiobject0  */
#line 301 "src/parser/plingua.y"
                                                          {(yyval.node) = new Node(MULTISET,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2589 "src/parser/y.tab.c"
    break;

  case 114: /* multiobject: multiobject0  */
#line 305 "src/parser/plingua.y"
                                                {(yyval.node) = (yyvsp[0].node);}
#line 2595 "src/parser/y.tab.c"
    break;

  case 115: /* multiobject: DISSOLUTION_SYMBOL  */
#line 306 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(DISSOLUTION_SYMBOL); (yyval.node)->setLoc((yylsp[0]));}
#line 2601 "src/parser/y.tab.c"
    break;

  case 116: /* multiobject0: variable  */
#line 309 "src/parser/plingua.y"
                                                    {(yyval.node) = (yyvsp[0].node);}
#line 2607 "src/parser/y.tab.c"
    break;

  case 117: /* multiobject0: variable MUL expr0  */
#line 310 "src/parser/plingua.y"
                                                    {(yyval.node) = new Node(MUL,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2613 "src/parser/y.tab.c"
    break;

  case 118: /* multiobject0: EMPTY  */
#line 311 "src/parser/plingua.y"
                                                                        {(yyval.node) = new Node(EMPTY); (yyval.node)->setLoc((yylsp[0]));}
#line 2619 "src/parser/y.tab.c"
    break;

  case 119: /* lsquare: charge LSQUARE  */
#line 314 "src/parser/plingua.y"
                         {(yyval.node) = (yyvsp[-1].node);}
#line 2625 "src/parser/y.tab.c"
    break;

  case 120: /* lsquare: LSQUARE  */
#line 315 "src/parser/plingua.y"
                         {(yyval.node) = new Node(CHARGE,0L); (yyval.node)->setLoc((yylsp[0]));}
#line 2631 "src/parser/y.tab.c"
    break;

  case 121: /* lsquare0: charge0 LSQUARE  */
#line 319 "src/parser/plingua.y"
                           {(yyval.node) = (yyvsp[-1].node);}
#line 2637 "src/parser/y.tab.c"
    break;

  case 122: /* lsquare0: LSQUARE  */
#line 320 "src/parser/plingua.y"
                           {(yyval.node) = new Node(CHARGE,0L); (yyval.node)->setLoc((yylsp[0]));}
#line 2643 "src/parser/y.tab.c"
    break;

  case 123: /* charge: PLUS  */
#line 325 "src/parser/plingua.y"
                                {(yyval.node) = new Node(CHARGE,1L); (yyval.node)->setLoc((yylsp[0]));}
#line 2649 "src/parser/y.tab.c"
    break;

  case 124: /* charge: MINUS  */
#line 326 "src/parser/plingua.y"
                                {(yyval.node) = new Node(CHARGE,-1L); (yyval.node)->setLoc((yylsp[0]));}
#line 2655 "src/parser/y.tab.c"
    break;

  case 125: /* charge: anonymous  */
#line 327 "src/parser/plingua.y"
                            {(yyval.node) = new Node(CHARGE,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2661 "src/parser/y.tab.c"
    break;

  case 126: /* charge0: PLUS  */
#line 331 "src/parser/plingua.y"
                                {(yyval.node) = new Node(CHARGE,1L); (yyval.node)->setLoc((yylsp[0]));}
#line 2667 "src/parser/y.tab.c"
    break;

  case 127: /* charge0: MINUS  */
#line 332 "src/parser/plingua.y"
                                {(yyval.node) = new Node(CHARGE,-1L); (yyval.node)->setLoc((yylsp[0]));}
#line 2673 "src/parser/y.tab.c"
    break;

  case 128: /* rsquare: RSQUARE  */
#line 335 "src/parser/plingua.y"
                                           {(yyval.node) = new Node(LABELS); (yyval.node)->setLoc((yylsp[0]));}
#line 2679 "src/parser/y.tab.c"
    break;

  case 129: /* rsquare: rsquare0  */
#line 336 "src/parser/plingua.y"
                                       {(yyval.node) = (yyvsp[0].node);}
#line 2685 "src/parser/y.tab.c"
    break;

  case 130: /* rsquare0: RSQUARE QUOTE labels  */
#line 339 "src/parser/plingua.y"
                                {(yyval.node) = (yyvsp[0].node);}
#line 2691 "src/parser/y.tab.c"
    break;

  case 131: /* non_negative_long: NON_NEGATIVE_LONG  */
#line 342 "src/parser/plingua.y"
                                      {(yyval.node) = new Node(NON_NEGATIVE_LONG,(yyvsp[0].longValue)); (yyval.node)->setLoc((yylsp[0]));}
#line 2697 "src/parser/y.tab.c"
    break;

  case 132: /* label: id  */
#line 345 "src/parser/plingua.y"
                                                        {(yyval.node) = new Node(LABEL,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2703 "src/parser/y.tab.c"
    break;

  case 133: /* label: non_negative_long  */
#line 346 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(LABEL,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2709 "src/parser/y.tab.c"
    break;

  case 134: /* label: LBRACE expr RBRACE  */
#line 347 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(LABEL,(yyvsp[-1].node)); (yyval.node)->setLoc((yylsp[-2]),(yylsp[0]));}
#line 2715 "src/parser/y.tab.c"
    break;

  case 135: /* initialMultiset: MS LPAR labels RPAR asigOrIncBy multiset0  */
#line 350 "src/parser/plingua.y"
                                                            {(yyval.node) = new Node(MS,(yyvsp[-3].node),(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-5]),(yyvsp[0].node));}
#line 2721 "src/parser/y.tab.c"
    break;

  case 136: /* initialMultiset: MS LPAR labels RPAR asigOrIncBy  */
#line 351 "src/parser/plingua.y"
                                                                            {(yyval.node) = new Node(MS,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-4]),(yyvsp[0].node));}
#line 2727 "src/parser/y.tab.c"
    break;

  case 137: /* labels: labels COMMA label  */
#line 354 "src/parser/plingua.y"
                              {(yyval.node) = (yyvsp[-2].node)->addChild((yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2733 "src/parser/y.tab.c"
    break;

  case 138: /* labels: label  */
#line 355 "src/parser/plingua.y"
                              {(yyval.node) = new Node(LABELS,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2739 "src/parser/y.tab.c"
    break;

  case 139: /* asigOrIncBy: ASIG  */
#line 359 "src/parser/plingua.y"
                                {(yyval.node) = new Node(ASIG); (yyval.node)->setLoc((yylsp[0]));}
#line 2745 "src/parser/y.tab.c"
    break;

  case 140: /* asigOrIncBy: INC_BY  */
#line 360 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(INC_BY); (yyval.node)->setLoc((yylsp[0]));}
#line 2751 "src/parser/y.tab.c"
    break;

  case 141: /* rule: ruleBody  */
#line 364 "src/parser/plingua.y"
                                                {(yyval.node) = (yyvsp[0].node);}
#line 2757 "src/parser/y.tab.c"
    break;

  case 142: /* rule: ruleBody probability  */
#line 365 "src/parser/plingua.y"
                                                {(yyval.node) = (yyvsp[-1].node)->addChild((yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yyvsp[0].node));}
#line 2763 "src/parser/y.tab.c"
    break;

  case 143: /* rule: priority ruleBody  */
#line 366 "src/parser/plingua.y"
                                                {(yyval.node) = (yyvsp[0].node)->addChild((yyvsp[-1].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yyvsp[0].node));}
#line 2769 "src/parser/y.tab.c"
    break;

  case 144: /* rule: ruleBody AT_SYMBOL features  */
#line 367 "src/parser/plingua.y"
                                                {(yyval.node) = (yyvsp[-2].node)->addChild((yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2775 "src/parser/y.tab.c"
    break;

  case 145: /* rule: ruleBody probability AT_SYMBOL features  */
#line 368 "src/parser/plingua.y"
                                                {(yyval.node) = (yyvsp[-3].node)->addChild((yyvsp[-2].node))->addChild((yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-3].node),(yyvsp[0].node));}
#line 2781 "src/parser/y.tab.c"
    break;

  case 146: /* rule: priority ruleBody AT_SYMBOL features  */
#line 369 "src/parser/plingua.y"
                                                {(yyval.node) = (yyvsp[-2].node)->addChild((yyvsp[-3].node))->addChild((yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-3].node),(yyvsp[0].node));}
#line 2787 "src/parser/y.tab.c"
    break;

  case 147: /* probability: DOUBLE_COLON expr  */
#line 372 "src/parser/plingua.y"
                                {(yyval.node) = new Node(PROBABILITY,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2793 "src/parser/y.tab.c"
    break;

  case 148: /* probability: DOUBLE_COLON id LPAR type RPAR  */
#line 373 "src/parser/plingua.y"
                                                          {(yyval.node) = (yyvsp[-3].node)->addChild((yyvsp[-1].node));(yyval.node)->setLoc((yyvsp[-3].node),(yylsp[0]));}
#line 2799 "src/parser/y.tab.c"
    break;

  case 149: /* priority: LPAR expr RPAR  */
#line 377 "src/parser/plingua.y"
                          {(yyval.node) = new Node(PRIORITY,(yyvsp[-1].node)); (yyval.node)->setLoc((yyvsp[-1].node));}
#line 2805 "src/parser/y.tab.c"
    break;

  case 150: /* priority: LPAR anonymous RPAR  */
#line 378 "src/parser/plingua.y"
                               {(yyval.node) = new Node(PRIORITY,(yyvsp[-1].node)); (yyval.node)->setLoc((yyvsp[-1].node));}
#line 2811 "src/parser/y.tab.c"
    break;

  case 151: /* ruleBody: left_hand_rule arrow  */
#line 381 "src/parser/plingua.y"
                                                                                        {(yyval.node) = new Node(RULE,(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yyvsp[0].node));}
#line 2817 "src/parser/y.tab.c"
    break;

  case 152: /* ruleBody: left_hand_rule arrow right_hand_rule  */
#line 382 "src/parser/plingua.y"
                                                            {(yyval.node) = new Node(RULE,(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2823 "src/parser/y.tab.c"
    break;

  case 153: /* ruleBody: lsquare multiset arrow rsquare0  */
#line 383 "src/parser/plingua.y"
                                                                              {(yyval.node) = new Node(RULE,(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-3].node),(yyvsp[0].node));}
#line 2829 "src/parser/y.tab.c"
    break;

  case 154: /* ruleBody: lsquare multiset arrow multiset rsquare0  */
#line 384 "src/parser/plingua.y"
                                                                              {(yyval.node) = new Node(RULE,(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-4].node),(yyvsp[0].node));}
#line 2835 "src/parser/y.tab.c"
    break;

  case 155: /* ruleBody: lsquare multiset arrow inner_membranes rsquare0  */
#line 385 "src/parser/plingua.y"
                                                                              {(yyval.node) = new Node(RULE,(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-4].node),(yyvsp[0].node));}
#line 2841 "src/parser/y.tab.c"
    break;

  case 156: /* ruleBody: lsquare multiset arrow multiset inner_membranes rsquare0  */
#line 386 "src/parser/plingua.y"
                                                                              {(yyval.node) = new Node(RULE,(yyvsp[-5].node),(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-5].node),(yyvsp[0].node));}
#line 2847 "src/parser/y.tab.c"
    break;

  case 157: /* ruleBody: lsquare multiset arrow inner_membranes multiset rsquare0  */
#line 387 "src/parser/plingua.y"
                                                                              {(yyval.node) = new Node(RULE,(yyvsp[-5].node),(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-5].node),(yyvsp[0].node));}
#line 2853 "src/parser/y.tab.c"
    break;

  case 158: /* ruleBody: lsquare inner_membranes arrow rsquare0  */
#line 388 "src/parser/plingua.y"
                                                                                    {(yyval.node) = new Node(RULE,(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-3].node),(yyvsp[0].node));}
#line 2859 "src/parser/y.tab.c"
    break;

  case 159: /* ruleBody: lsquare inner_membranes arrow multiset rsquare0  */
#line 389 "src/parser/plingua.y"
                                                                                    {(yyval.node) = new Node(RULE,(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-4].node),(yyvsp[0].node));}
#line 2865 "src/parser/y.tab.c"
    break;

  case 160: /* ruleBody: lsquare inner_membranes arrow inner_membranes rsquare0  */
#line 390 "src/parser/plingua.y"
                                                                                    {(yyval.node) = new Node(RULE,(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-4].node),(yyvsp[0].node));}
#line 2871 "src/parser/y.tab.c"
    break;

  case 161: /* ruleBody: lsquare inner_membranes arrow multiset inner_membranes rsquare0  */
#line 391 "src/parser/plingua.y"
                                                                                    {(yyval.node) = new Node(RULE,(yyvsp[-5].node),(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-5].node),(yyvsp[0].node));}
#line 2877 "src/parser/y.tab.c"
    break;

  case 162: /* ruleBody: lsquare inner_membranes arrow inner_membranes multiset rsquare0  */
#line 392 "src/parser/plingua.y"
                                                                                    {(yyval.node) = new Node(RULE,(yyvsp[-5].node),(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-5].node),(yyvsp[0].node));}
#line 2883 "src/parser/y.tab.c"
    break;

  case 163: /* ruleBody: lsquare multiset inner_membranes arrow rsquare0  */
#line 393 "src/parser/plingua.y"
                                                                                             {(yyval.node) = new Node(RULE,(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-4].node),(yyvsp[0].node));}
#line 2889 "src/parser/y.tab.c"
    break;

  case 164: /* ruleBody: lsquare multiset inner_membranes arrow multiset rsquare0  */
#line 394 "src/parser/plingua.y"
                                                                                             {(yyval.node) = new Node(RULE,(yyvsp[-5].node),(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-5].node),(yyvsp[0].node));}
#line 2895 "src/parser/y.tab.c"
    break;

  case 165: /* ruleBody: lsquare multiset inner_membranes arrow inner_membranes rsquare0  */
#line 395 "src/parser/plingua.y"
                                                                                             {(yyval.node) = new Node(RULE,(yyvsp[-5].node),(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-5].node),(yyvsp[0].node));}
#line 2901 "src/parser/y.tab.c"
    break;

  case 166: /* ruleBody: lsquare multiset inner_membranes arrow multiset inner_membranes rsquare0  */
#line 396 "src/parser/plingua.y"
                                                                                             {(yyval.node) = new Node(RULE,(yyvsp[-6].node),(yyvsp[-5].node),(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-6].node),(yyvsp[0].node));}
#line 2907 "src/parser/y.tab.c"
    break;

  case 167: /* ruleBody: lsquare multiset inner_membranes arrow inner_membranes multiset rsquare0  */
#line 397 "src/parser/plingua.y"
                                                                                             {(yyval.node) = new Node(RULE,(yyvsp[-6].node),(yyvsp[-5].node),(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-6].node),(yyvsp[0].node));}
#line 2913 "src/parser/y.tab.c"
    break;

  case 168: /* ruleBody: lsquare inner_membranes multiset arrow rsquare0  */
#line 398 "src/parser/plingua.y"
                                                                                             {(yyval.node) = new Node(RULE,(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-4].node),(yyvsp[0].node));}
#line 2919 "src/parser/y.tab.c"
    break;

  case 169: /* ruleBody: lsquare inner_membranes multiset arrow multiset rsquare0  */
#line 399 "src/parser/plingua.y"
                                                                                             {(yyval.node) = new Node(RULE,(yyvsp[-5].node),(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-5].node),(yyvsp[0].node));}
#line 2925 "src/parser/y.tab.c"
    break;

  case 170: /* ruleBody: lsquare inner_membranes multiset arrow inner_membranes rsquare0  */
#line 400 "src/parser/plingua.y"
                                                                                             {(yyval.node) = new Node(RULE,(yyvsp[-5].node),(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-5].node),(yyvsp[0].node));}
#line 2931 "src/parser/y.tab.c"
    break;

  case 171: /* ruleBody: lsquare inner_membranes multiset arrow multiset inner_membranes rsquare0  */
#line 401 "src/parser/plingua.y"
                                                                                             {(yyval.node) = new Node(RULE,(yyvsp[-6].node),(yyvsp[-5].node),(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-6].node),(yyvsp[0].node));}
#line 2937 "src/parser/y.tab.c"
    break;

  case 172: /* ruleBody: lsquare inner_membranes multiset arrow inner_membranes multiset rsquare0  */
#line 402 "src/parser/plingua.y"
                                                                                             {(yyval.node) = new Node(RULE,(yyvsp[-6].node),(yyvsp[-5].node),(yyvsp[-4].node),(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node));(yyval.node)->setLoc((yyvsp[-6].node),(yyvsp[0].node));}
#line 2943 "src/parser/y.tab.c"
    break;

  case 173: /* left_hand_rule: multiset left_outer_membrane  */
#line 406 "src/parser/plingua.y"
                                                            {(yyval.node) = new Node(LEFT_HAND_RULE,(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yyvsp[0].node));}
#line 2949 "src/parser/y.tab.c"
    break;

  case 174: /* left_hand_rule: left_outer_membrane  */
#line 407 "src/parser/plingua.y"
                                                                                {(yyval.node) = new Node(LEFT_HAND_RULE,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2955 "src/parser/y.tab.c"
    break;

  case 175: /* left_hand_rule: left_outer_membrane multiset  */
#line 408 "src/parser/plingua.y"
                                                            {(yyval.node) = new Node(LEFT_HAND_RULE,(yyvsp[0].node),(yyvsp[-1].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yyvsp[0].node));}
#line 2961 "src/parser/y.tab.c"
    break;

  case 176: /* right_hand_rule: multiset  */
#line 411 "src/parser/plingua.y"
                                                                                           {(yyval.node) = new Node(RIGHT_HAND_RULE,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2967 "src/parser/y.tab.c"
    break;

  case 177: /* right_hand_rule: right_outer_membranes  */
#line 412 "src/parser/plingua.y"
                                                           {(yyval.node) = new Node(RIGHT_HAND_RULE,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 2973 "src/parser/y.tab.c"
    break;

  case 178: /* right_hand_rule: multiset right_outer_membranes  */
#line 413 "src/parser/plingua.y"
                                                           {(yyval.node) = new Node(RIGHT_HAND_RULE,(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yyvsp[0].node));}
#line 2979 "src/parser/y.tab.c"
    break;

  case 179: /* right_hand_rule: right_outer_membranes multiset  */
#line 414 "src/parser/plingua.y"
                                                                           {(yyval.node) = new Node(RIGHT_HAND_RULE,(yyvsp[0].node),(yyvsp[-1].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yyvsp[0].node));}
#line 2985 "src/parser/y.tab.c"
    break;

  case 180: /* left_outer_membrane: lsquare rsquare0  */
#line 417 "src/parser/plingua.y"
                                                                     {(yyval.node) = new Node(OUTER_MEMBRANE,(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yyvsp[0].node));}
#line 2991 "src/parser/y.tab.c"
    break;

  case 181: /* left_outer_membrane: lsquare multiset rsquare0  */
#line 418 "src/parser/plingua.y"
                                                                 {(yyval.node) = new Node(OUTER_MEMBRANE,(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 2997 "src/parser/y.tab.c"
    break;

  case 182: /* left_outer_membrane: lsquare inner_membranes rsquare0  */
#line 419 "src/parser/plingua.y"
                                                                 {(yyval.node) = new Node(OUTER_MEMBRANE,(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3003 "src/parser/y.tab.c"
    break;

  case 183: /* left_outer_membrane: lsquare multiset inner_membranes rsquare0  */
#line 420 "src/parser/plingua.y"
                                                                 {(yyval.node) = new Node(OUTER_MEMBRANE,(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-3].node),(yyvsp[0].node));}
#line 3009 "src/parser/y.tab.c"
    break;

  case 184: /* left_outer_membrane: lsquare inner_membranes multiset rsquare0  */
#line 421 "src/parser/plingua.y"
                                                                 {(yyval.node) = new Node(OUTER_MEMBRANE,(yyvsp[-3].node),(yyvsp[-1].node),(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-3].node),(yyvsp[0].node));}
#line 3015 "src/parser/y.tab.c"
    break;

  case 185: /* right_outer_membrane: lsquare rsquare  */
#line 424 "src/parser/plingua.y"
                                                                     {(yyval.node) = new Node(OUTER_MEMBRANE,(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yyvsp[0].node));}
#line 3021 "src/parser/y.tab.c"
    break;

  case 186: /* right_outer_membrane: lsquare multiset rsquare  */
#line 425 "src/parser/plingua.y"
                                                                 {(yyval.node) = new Node(OUTER_MEMBRANE,(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3027 "src/parser/y.tab.c"
    break;

  case 187: /* right_outer_membrane: lsquare inner_membranes rsquare  */
#line 426 "src/parser/plingua.y"
                                                                 {(yyval.node) = new Node(OUTER_MEMBRANE,(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3033 "src/parser/y.tab.c"
    break;

  case 188: /* right_outer_membrane: lsquare multiset inner_membranes rsquare  */
#line 427 "src/parser/plingua.y"
                                                                 {(yyval.node) = new Node(OUTER_MEMBRANE,(yyvsp[-3].node),(yyvsp[-2].node),(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-3].node),(yyvsp[0].node));}
#line 3039 "src/parser/y.tab.c"
    break;

  case 189: /* right_outer_membrane: lsquare inner_membranes multiset rsquare  */
#line 428 "src/parser/plingua.y"
                                                                 {(yyval.node) = new Node(OUTER_MEMBRANE,(yyvsp[-3].node),(yyvsp[-1].node),(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-3].node),(yyvsp[0].node));}
#line 3045 "src/parser/y.tab.c"
    break;

  case 190: /* right_outer_membranes: right_outer_membranes right_outer_membrane  */
#line 433 "src/parser/plingua.y"
                                                                   {(yyval.node) = (yyvsp[-1].node)->addChild((yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yyvsp[0].node));}
#line 3051 "src/parser/y.tab.c"
    break;

  case 191: /* right_outer_membranes: right_outer_membrane  */
#line 434 "src/parser/plingua.y"
                                                                           {(yyval.node) = new Node(OUTER_MEMBRANES,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 3057 "src/parser/y.tab.c"
    break;

  case 192: /* inner_membrane: lsquare rsquare0  */
#line 438 "src/parser/plingua.y"
                                                        {(yyval.node) = new Node(INNER_MEMBRANE,(yyvsp[-1].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yyvsp[0].node));}
#line 3063 "src/parser/y.tab.c"
    break;

  case 193: /* inner_membrane: lsquare multiset rsquare0  */
#line 439 "src/parser/plingua.y"
                                             {(yyval.node) = new Node(INNER_MEMBRANE,(yyvsp[-2].node),(yyvsp[0].node),(yyvsp[-1].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3069 "src/parser/y.tab.c"
    break;

  case 194: /* inner_membranes: inner_membranes inner_membrane  */
#line 442 "src/parser/plingua.y"
                                                  {(yyval.node) = (yyvsp[-1].node)->addChild((yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yyvsp[0].node));}
#line 3075 "src/parser/y.tab.c"
    break;

  case 195: /* inner_membranes: inner_membrane  */
#line 443 "src/parser/plingua.y"
                                                                  {(yyval.node) = new Node(INNER_MEMBRANES,(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[0].node));}
#line 3081 "src/parser/y.tab.c"
    break;

  case 196: /* arrow: LONG_RIGHT_ARROW  */
#line 447 "src/parser/plingua.y"
                                {(yyval.node) = new Node(LONG_RIGHT_ARROW); (yyval.node)->setLoc((yylsp[0]));}
#line 3087 "src/parser/y.tab.c"
    break;

  case 197: /* arrow: SHORT_RIGHT_ARROW  */
#line 448 "src/parser/plingua.y"
                                {(yyval.node) = new Node(SHORT_RIGHT_ARROW); (yyval.node)->setLoc((yylsp[0]));}
#line 3093 "src/parser/y.tab.c"
    break;

  case 198: /* arrow: LONG_DOUBLE_ARROW  */
#line 449 "src/parser/plingua.y"
                                {(yyval.node) = new Node(LONG_DOUBLE_ARROW); (yyval.node)->setLoc((yylsp[0]));}
#line 3099 "src/parser/y.tab.c"
    break;

  case 199: /* arrow: SHORT_DOUBLE_ARROW  */
#line 450 "src/parser/plingua.y"
                                {(yyval.node) = new Node(SHORT_DOUBLE_ARROW); (yyval.node)->setLoc((yylsp[0]));}
#line 3105 "src/parser/y.tab.c"
    break;

  case 200: /* expr: variable ASIG expr80  */
#line 454 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(ASIG,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3111 "src/parser/y.tab.c"
    break;

  case 201: /* expr: variable INC_BY expr80  */
#line 455 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(INC_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3117 "src/parser/y.tab.c"
    break;

  case 202: /* expr: variable DEC_BY expr80  */
#line 456 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(DEC_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3123 "src/parser/y.tab.c"
    break;

  case 203: /* expr: variable MUL_BY expr80  */
#line 457 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(MUL_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3129 "src/parser/y.tab.c"
    break;

  case 204: /* expr: variable DIV_BY expr80  */
#line 458 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(DIV_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3135 "src/parser/y.tab.c"
    break;

  case 205: /* expr: variable MOD_BY expr80  */
#line 459 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(MOD_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3141 "src/parser/y.tab.c"
    break;

  case 206: /* expr: variable BITWISE_LEFT_BY expr80  */
#line 460 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(BITWISE_LEFT_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3147 "src/parser/y.tab.c"
    break;

  case 207: /* expr: variable BITWISE_RIGHT_BY expr80  */
#line 461 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(BITWISE_RIGHT_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3153 "src/parser/y.tab.c"
    break;

  case 208: /* expr: variable BITWISE_AND_BY expr80  */
#line 462 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(BITWISE_AND_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3159 "src/parser/y.tab.c"
    break;

  case 209: /* expr: variable BITWISE_OR_BY expr80  */
#line 463 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(BITWISE_OR_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3165 "src/parser/y.tab.c"
    break;

  case 210: /* expr: variable BITWISE_XOR_BY expr80  */
#line 464 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(BITWISE_XOR_BY,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3171 "src/parser/y.tab.c"
    break;

  case 211: /* expr: expr80  */
#line 465 "src/parser/plingua.y"
                                                                {(yyval.node) = (yyvsp[0].node);}
#line 3177 "src/parser/y.tab.c"
    break;

  case 212: /* expr80: expr80 OR expr70  */
#line 468 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(OR,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3183 "src/parser/y.tab.c"
    break;

  case 213: /* expr80: expr70  */
#line 469 "src/parser/plingua.y"
                                                        {(yyval.node) = (yyvsp[0].node);}
#line 3189 "src/parser/y.tab.c"
    break;

  case 214: /* expr70: expr70 AND expr66  */
#line 473 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(AND,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3195 "src/parser/y.tab.c"
    break;

  case 215: /* expr70: expr66  */
#line 474 "src/parser/plingua.y"
                                                        {(yyval.node) = (yyvsp[0].node);}
#line 3201 "src/parser/y.tab.c"
    break;

  case 216: /* expr66: expr66 BITWISE_OR expr64  */
#line 478 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(BITWISE_OR,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3207 "src/parser/y.tab.c"
    break;

  case 217: /* expr66: expr64  */
#line 479 "src/parser/plingua.y"
                                                                {(yyval.node) = (yyvsp[0].node);}
#line 3213 "src/parser/y.tab.c"
    break;

  case 218: /* expr64: expr64 BITWISE_XOR expr62  */
#line 482 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(BITWISE_XOR,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3219 "src/parser/y.tab.c"
    break;

  case 219: /* expr64: expr62  */
#line 483 "src/parser/plingua.y"
                                                                {(yyval.node) = (yyvsp[0].node);}
#line 3225 "src/parser/y.tab.c"
    break;

  case 220: /* expr62: expr62 BITWISE_AND expr60  */
#line 487 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(BITWISE_AND,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3231 "src/parser/y.tab.c"
    break;

  case 221: /* expr62: expr60  */
#line 488 "src/parser/plingua.y"
                                                                {(yyval.node) = (yyvsp[0].node);}
#line 3237 "src/parser/y.tab.c"
    break;

  case 222: /* expr60: expr60 EQUAL expr50  */
#line 491 "src/parser/plingua.y"
                                {(yyval.node) = new Node(EQUAL,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3243 "src/parser/y.tab.c"
    break;

  case 223: /* expr60: expr60 DIFF expr50  */
#line 492 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(DIFF,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3249 "src/parser/y.tab.c"
    break;

  case 224: /* expr60: expr50  */
#line 493 "src/parser/plingua.y"
                                                        {(yyval.node) = (yyvsp[0].node);}
#line 3255 "src/parser/y.tab.c"
    break;

  case 225: /* expr50: expr50 LESS_THAN expr45  */
#line 497 "src/parser/plingua.y"
                                                                {(yyval.node) = new Node(LESS_THAN,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3261 "src/parser/y.tab.c"
    break;

  case 226: /* expr50: expr50 LESS_OR_EQUAL_THAN expr45  */
#line 498 "src/parser/plingua.y"
                                                        {(yyval.node) = new Node(LESS_OR_EQUAL_THAN,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3267 "src/parser/y.tab.c"
    break;

  case 227: /* expr50: expr50 GREATER_THAN expr45  */
#line 499 "src/parser/plingua.y"
                                                                {(yyval.node) = new Node(GREATER_THAN,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3273 "src/parser/y.tab.c"
    break;

  case 228: /* expr50: expr50 GREATER_OR_EQUAL_THAN expr45  */
#line 500 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(GREATER_OR_EQUAL_THAN,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3279 "src/parser/y.tab.c"
    break;

  case 229: /* expr50: expr45  */
#line 501 "src/parser/plingua.y"
                                                                                {(yyval.node) = (yyvsp[0].node);}
#line 3285 "src/parser/y.tab.c"
    break;

  case 230: /* expr45: expr45 BITWISE_LEFT expr40  */
#line 504 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(BITWISE_LEFT,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3291 "src/parser/y.tab.c"
    break;

  case 231: /* expr45: expr45 BITWISE_RIGHT expr40  */
#line 505 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(BITWISE_RIGHT,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3297 "src/parser/y.tab.c"
    break;

  case 232: /* expr45: expr40  */
#line 506 "src/parser/plingua.y"
                                                                        {(yyval.node) = (yyvsp[0].node);}
#line 3303 "src/parser/y.tab.c"
    break;

  case 233: /* expr40: expr40 PLUS expr30  */
#line 510 "src/parser/plingua.y"
                                        {(yyval.node) = new Node(ADD,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3309 "src/parser/y.tab.c"
    break;

  case 234: /* expr40: expr40 MINUS expr30  */
#line 511 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(SUB,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3315 "src/parser/y.tab.c"
    break;

  case 235: /* expr40: expr30  */
#line 512 "src/parser/plingua.y"
                                                                {(yyval.node) = (yyvsp[0].node);}
#line 3321 "src/parser/y.tab.c"
    break;

  case 236: /* expr30: expr30 MUL expr20  */
#line 515 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(MUL,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3327 "src/parser/y.tab.c"
    break;

  case 237: /* expr30: expr30 DIV expr20  */
#line 516 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(DIV,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3333 "src/parser/y.tab.c"
    break;

  case 238: /* expr30: expr30 MOD expr20  */
#line 517 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(MOD,(yyvsp[-2].node),(yyvsp[0].node)); (yyval.node)->setLoc((yyvsp[-2].node),(yyvsp[0].node));}
#line 3339 "src/parser/y.tab.c"
    break;

  case 239: /* expr30: expr20  */
#line 518 "src/parser/plingua.y"
                                                        {(yyval.node) = (yyvsp[0].node);}
#line 3345 "src/parser/y.tab.c"
    break;

  case 240: /* expr20: PLUS expr20  */
#line 522 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(PLUS,(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-1]),(yyvsp[0].node));}
#line 3351 "src/parser/y.tab.c"
    break;

  case 241: /* expr20: MINUS expr20  */
#line 523 "src/parser/plingua.y"
                                                        {(yyval.node) = new Node(MINUS,(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-1]),(yyvsp[0].node));}
#line 3357 "src/parser/y.tab.c"
    break;

  case 242: /* expr20: NOT expr20  */
#line 524 "src/parser/plingua.y"
                                                        {(yyval.node) = new Node(NOT,(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-1]),(yyvsp[0].node));}
#line 3363 "src/parser/y.tab.c"
    break;

  case 243: /* expr20: BITWISE_NOT expr20  */
#line 525 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(BITWISE_NOT,(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-1]),(yyvsp[0].node));}
#line 3369 "src/parser/y.tab.c"
    break;

  case 244: /* expr20: INC variable  */
#line 526 "src/parser/plingua.y"
                                                        {(yyval.node) = new Node(INC,(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-1]),(yyvsp[0].node));}
#line 3375 "src/parser/y.tab.c"
    break;

  case 245: /* expr20: DEC variable  */
#line 527 "src/parser/plingua.y"
                                                        {(yyval.node) = new Node(DEC,(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-1]),(yyvsp[0].node));}
#line 3381 "src/parser/y.tab.c"
    break;

  case 246: /* expr20: expr10  */
#line 528 "src/parser/plingua.y"
                                                                {(yyval.node) = (yyvsp[0].node);}
#line 3387 "src/parser/y.tab.c"
    break;

  case 247: /* expr10: variable INC  */
#line 531 "src/parser/plingua.y"
                                                {(yyval.node) = new Node(POST_INC,(yyvsp[-1].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yylsp[0]));}
#line 3393 "src/parser/y.tab.c"
    break;

  case 248: /* expr10: variable DEC  */
#line 532 "src/parser/plingua.y"
                                                        {(yyval.node) = new Node(POST_DEC,(yyvsp[-1].node)); (yyval.node)->setLoc((yyvsp[-1].node),(yylsp[0]));}
#line 3399 "src/parser/y.tab.c"
    break;

  case 249: /* expr10: expr5  */
#line 533 "src/parser/plingua.y"
                                                        {(yyval.node) = (yyvsp[0].node);}
#line 3405 "src/parser/y.tab.c"
    break;

  case 250: /* expr5: LPAR INT_TYPE RPAR expr0  */
#line 537 "src/parser/plingua.y"
                                      {(yyval.node) = new Node(INT_TYPE,(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-3]),(yyvsp[0].node));}
#line 3411 "src/parser/y.tab.c"
    break;

  case 251: /* expr5: LPAR LONG_TYPE RPAR expr0  */
#line 538 "src/parser/plingua.y"
                                      {(yyval.node) = new Node(LONG_TYPE,(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-3]),(yyvsp[0].node));}
#line 3417 "src/parser/y.tab.c"
    break;

  case 252: /* expr5: LPAR DOUBLE_TYPE RPAR expr0  */
#line 539 "src/parser/plingua.y"
                                      {(yyval.node) = new Node(DOUBLE_TYPE,(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-3]),(yyvsp[0].node));}
#line 3423 "src/parser/y.tab.c"
    break;

  case 253: /* expr5: LPAR STRING_TYPE RPAR expr0  */
#line 540 "src/parser/plingua.y"
                                          {(yyval.node) = new Node(STRING_TYPE,(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-3]),(yyvsp[0].node));}
#line 3429 "src/parser/y.tab.c"
    break;

  case 254: /* expr5: expr0  */
#line 541 "src/parser/plingua.y"
                                                          {(yyval.node) = (yyvsp[0].node);}
#line 3435 "src/parser/y.tab.c"
    break;

  case 255: /* expr0: non_negative_long  */
#line 544 "src/parser/plingua.y"
                                              {(yyval.node) = (yyvsp[0].node);}
#line 3441 "src/parser/y.tab.c"
    break;

  case 256: /* expr0: NON_NEGATIVE_DOUBLE  */
#line 545 "src/parser/plingua.y"
                                          {(yyval.node) = new Node(NON_NEGATIVE_DOUBLE,(yyvsp[0].doubleValue)); (yyval.node)->setLoc((yylsp[0]));}
#line 3447 "src/parser/y.tab.c"
    break;

  case 257: /* expr0: variable  */
#line 546 "src/parser/plingua.y"
                                                          {(yyval.node) = (yyvsp[0].node);}
#line 3453 "src/parser/y.tab.c"
    break;

  case 258: /* expr0: STRING  */
#line 547 "src/parser/plingua.y"
                                                          {(yyval.node) = new Node(STRING,(yyvsp[0].stringValue)); (yyval.node)->setLoc((yylsp[0]));}
#line 3459 "src/parser/y.tab.c"
    break;

  case 259: /* expr0: regular_call  */
#line 548 "src/parser/plingua.y"
                                      {(yyval.node) = (yyvsp[0].node);}
#line 3465 "src/parser/y.tab.c"
    break;

  case 260: /* expr0: system_call  */
#line 549 "src/parser/plingua.y"
                                                          {(yyval.node) = (yyvsp[0].node);}
#line 3471 "src/parser/y.tab.c"
    break;

  case 261: /* expr0: SYSTEM DOUBLE_COLON variable  */
#line 550 "src/parser/plingua.y"
                                      {(yyval.node) = new Node(SYSTEM_CONSTANT,(yyvsp[0].node)); (yyval.node)->setLoc((yylsp[-2]),(yyvsp[0].node));}
#line 3477 "src/parser/y.tab.c"
    break;

  case 262: /* expr0: LPAR expr RPAR  */
#line 551 "src/parser/plingua.y"
                                      {(yyval.node) = (yyvsp[-1].node); (yyval.node)->setLoc((yylsp[-2]),(yylsp[0]));}
#line 3483 "src/parser/y.tab.c"
    break;


#line 3487 "src/parser/y.tab.c"

      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
  YY_SYMBOL_PRINT ("-> $$ =", YY_CAST (yysymbol_kind_t, yyr1[yyn]), &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;

  *++yyvsp = yyval;
  *++yylsp = yyloc;

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
yyerrlab:
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == YYEMPTY ? YYSYMBOL_YYEMPTY : YYTRANSLATE (yychar);
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
      yyerror (YY_("syntax error"));
    }

  yyerror_range[1] = yylloc;
  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
         error, discard it.  */

      if (yychar <= YYEOF)
        {
          /* Return failure if at end of input.  */
          if (yychar == YYEOF)
            YYABORT;
        }
      else
        {
          yydestruct ("Error: discarding",
                      yytoken, &yylval, &yylloc);
          yychar = YYEMPTY;
        }
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;
  ++yynerrs;

  /* Do not reclaim the symbols of the rule whose action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

  /* Pop stack until we find a state that shifts the error token.  */
  for (;;)
    {
      yyn = yypact[yystate];
      if (!yypact_value_is_default (yyn))
        {
          yyn += YYSYMBOL_YYerror;
          if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYSYMBOL_YYerror)
            {
              yyn = yytable[yyn];
              if (0 < yyn)
                break;
            }
        }

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
        YYABORT;

      yyerror_range[1] = *yylsp;
      yydestruct ("Error: popping",
                  YY_ACCESSING_SYMBOL (yystate), yyvsp, yylsp);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  yyerror_range[2] = yylloc;
  ++yylsp;
  YYLLOC_DEFAULT (*yylsp, yyerror_range, 2);

  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", YY_ACCESSING_SYMBOL (yyn), yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturnlab;


/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturnlab;


/*-----------------------------------------------------------.
| yyexhaustedlab -- YYNOMEM (memory exhaustion) comes here.  |
`-----------------------------------------------------------*/
yyexhaustedlab:
  yyerror (YY_("memory exhausted"));
  yyresult = 2;
  goto yyreturnlab;


/*----------------------------------------------------------.
| yyreturnlab -- parsing is finished, clean up and return.  |
`----------------------------------------------------------*/
yyreturnlab:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval, &yylloc);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  YY_ACCESSING_SYMBOL (+*yyssp), yyvsp, yylsp);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif

  return yyresult;
}

#line 556 "src/parser/plingua.y"



int main(int argc, char* argv[]) {
	return PARSER.parse(argc,argv);
}



